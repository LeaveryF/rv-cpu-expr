#===========================================================================
# cts.tcl — ICC2 时钟树综合 (Clock Tree Synthesis)
#
# 功能：为芯片构建低 skew 的时钟分布网络
# 输入：上一个 CEL (placed)
# 输出：MW CEL (cts)
#
# 时钟树综合做什么：
#   ┌─────────────────────────────────────────────────────────┐
#   │  CTS 前 (ideal network)        CTS 后 (real tree)      │
#   │                                                         │
#   │  clk ──── 1000个 FF 直接连     clk ─→ BUF ─→ BUF ─→ FF│
#   │   一条线驱动1000个负载               └→ BUF ─→ ... → FF│
#   │   物理上不可能                      ├→ BUF ─→ ... → FF│
#   │   无真实延迟                        有真实延迟 + skew   │
#   └─────────────────────────────────────────────────────────┘
#
# CTS 的关键指标：
#   - Skew: 各触发器收到时钟的时间差异（越小越好，设 0.2ns）
#   - Insertion Delay: 时钟从源到 FF 的总延迟（我们设 0.9ns）
#   - Transition: 时钟波形上升/下降时间（不能太慢）
#===========================================================================

source ../rm_setups/lcrm_setup.tcl
source -echo ../rm_setups/icc_setup.tcl

puts "\n============================================"
puts "  Clock Tree Synthesis: $DESIGN_NAME"
puts "============================================"

open_mw_lib $DESIGN_NAME.mw
copy_mw_cel -from placed -to cts
open_mw_cel cts

source -echo ../scripts/common_optimization_settings_icc.tcl
source -echo ../scripts/common_placement_settings_icc.tcl

#---------------------------------------------------------------------
# 1. CTS 前物理检查
#    确认布局结果满足 CTS 的前提条件：
#    - 所有标准单元已 legalize
#    - 有足够的空间插入时钟 buffer
#    check_clock_tree: 检查时钟源、时钟 pin 是否定义正确
#---------------------------------------------------------------------
check_physical_design -stage pre_clock_opt
check_clock_tree

#---------------------------------------------------------------------
# 2. 移除 ideal_network——让 CTS 接管时钟网
#    之前 ideal_network 是"零延迟+无限驱动"的虚拟网络
#    现在要建真实的时钟树了，必须先移除这个属性
#    否则 CTS 不会在 ideal net 上插 buffer
#---------------------------------------------------------------------
remove_ideal_network [get_ports clk_pad]

#---------------------------------------------------------------------
# 3. 设置 CTS 目标参数
#    -target_early_delay 0.9: 目标插入延迟（时钟从源到 FF 的时间）
#      0.9ns 是目标值，实际 CTS 会尽量接近
#      值越小=时钟越快到达 FF，但对 buffer 驱动能力要求更高
#    -target_skew 0.2: 目标时钟偏差
#      skew = 最快到达 FF 的时间 - 最慢到达 FF 的时间
#      0.2ns 是比较宽松的目标（对于 0.13µm 工艺，20ns 周期来说合理）
#---------------------------------------------------------------------
set_clock_tree_options -target_early_delay 0.9
set_clock_tree_options -target_skew 0.2
report_clock_tree -settings

#---------------------------------------------------------------------
# 4. 执行时钟树综合
#    clock_opt -no_clock_route -only_cts:
#      -no_clock_route: 先不实际走线，只规划 buffer 插入位置
#      -only_cts: 只做时钟树综合，不做逻辑优化
#    CTS 步骤（内部自动进行）：
#      1) 聚类：按物理位置把 FF 分组
#      2) 插 buffer：从时钟源逐级插入(buffer或inverter对)
#      3) 平衡延迟：调整各级 buffer 尺寸使 skew 达标
#---------------------------------------------------------------------
clock_opt -no_clock_route -only_cts

# update_clock_latency: 把 CTS 实际达到的延迟值更新到时序引擎
# 后续 route_opt 会基于这个实际延迟做建立/保持时间优化
update_clock_latency

report_clock_tree
report_clock_timing -type skew

#---------------------------------------------------------------------
# 5. 时钟网布线
#    route_zrt_group: 对时钟网络组进行实际金属层布线
#    -all_clock_nets: 所有标记为 clock 的网络
#    -reuse_existing_global_route true: 复用之前全局布线的规划结果
#    时钟布线规则比信号更严格：更大线宽、更多屏蔽、优先布线层
#---------------------------------------------------------------------
route_zrt_group -all_clock_nets -reuse_existing_global_route true

save_mw_cel -as cts

puts "\n\[INFO\] 时钟树综合完成，CEL 'cts' 已保存"
puts "============================================\n"
