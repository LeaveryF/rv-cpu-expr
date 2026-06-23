#===========================================================================
# route.tcl — ICC2 布线 + 寄生参数提取
#
# 功能：对设计进行金属层布线，提取 RC 寄生参数，写出最终网表/SPEF/SDF
# 输入：上一个 CEL (cts)
# 输出：MW CEL (route), output/cpu_pad_final.v, .spef, .sdf
#
# 布线做什么：
#   1) 时钟网布线（优先，因为时钟最关键）
#   2) 信号线全局布线——规划每根线的大致路径
#   3) 信号线详细布线——在具体金属层上分配轨道(track)
#   4) DRC 检查和修复——修短线/开路/间距违例
#   5) RC 寄生提取——从实际连线几何计算 R 和 C
#===========================================================================

source ../rm_setups/lcrm_setup.tcl
source -echo ../rm_setups/icc_setup.tcl

puts "\n============================================"
puts "  Routing: $DESIGN_NAME"
puts "============================================"

open_mw_lib $DESIGN_NAME.mw
copy_mw_cel -from cts -to route
open_mw_cel route

source -echo ../scripts/common_optimization_settings_icc.tcl
source -echo ../scripts/common_placement_settings_icc.tcl

#---------------------------------------------------------------------
# 1. 布线前检查
#    - 确认所有标准单元已放置、时钟树已综合
#    - all_ideal_nets: 列出还标记为 ideal 的网（应该为空了）
#    - all_high_fanout -threshold 20: 列出扇出>20的网
#      CTS 后高扇出网应该主要是 scan enable / reset（这些是全局信号）
#---------------------------------------------------------------------
check_physical_design -stage pre_route_opt
all_ideal_nets
all_high_fanout -nets -threshold 20

#---------------------------------------------------------------------
# 2. 最后确认电源/地连接
#    -tie: 将顶层未连接的 P/G pin 连到对应网络
#    (在电源轨布线后，可能有浮空的 P/G pin 需要最终 tie-off)
#---------------------------------------------------------------------
derive_pg_connection -power_net VDD -power_pin VDD \
                     -ground_net VSS -ground_pin VSS -tie

#---------------------------------------------------------------------
# 3. 时钟网布线（优先级最高）
#    时钟网络对信号完整性和 skew 要求最高
#    通常使用更宽的线宽 + 两倍间距 + 专用屏蔽线
#    必须在信号线之前完成，因为信号线需要绕开时钟线
#---------------------------------------------------------------------
route_zrt_group -all_clock_nets -reuse_existing_global_route true

#---------------------------------------------------------------------
# 4. 信号线布线（Initial Route Only）
#    route_opt -initial_route_only: 只做初始布线
#    包含两步：
#      a) Global Route: 把芯片划分为网格，计算每格的连线密度
#                      规划每根线的大致路径（类似导航的路线规划）
#      b) Track Assignment: 在具体金属层上分配走线轨道
#    注意：此处跳过了 post-route 全优化（-skip_initial_route）
#    因为我们的设计在此时有较大 WNS ≈ 14ns
#    → route_opt 的全优化模式会试图通过调整布线修复时序
#    → 但 14ns 远大于 20ns 周期，物理上无法通过布线修复
#    → 会导致优化死循环（运行 11+ 分钟不收敛）
#    完整时序签核应在 PT 中完成
#---------------------------------------------------------------------
route_opt -initial_route_only

#---------------------------------------------------------------------
# 5. DRC 清理
#    verify_zrt_route: 检查布线后的 DRC 违例（短路、间距等）
#    route_zrt_detail -incremental: 增量修复检测到的 DRC 违例
#    只修物理违例，不动单元位置
#---------------------------------------------------------------------
verify_zrt_route
route_zrt_detail -incremental true

save_mw_cel -as route

#---------------------------------------------------------------------
# 6. 写出输出文件
#---------------------------------------------------------------------

# 网表命名规范化：将 ICC2 内部命名转为标准 Verilog 命名规则
# (统一大小写、去掉特殊字符、保证层次边界命名一致)
change_names -hierarchy -rules verilog

# 写出最终版图后门级网表
# -no_physical_only_cells: 不写物理-only cell（如 corner/filler）
# -no_unconnected_cells: 不写没有连接的单元
# -no_tap_cells: 不写 tap cell（衬底接触，对逻辑仿真无意义）
write_verilog -no_physical_only_cells \
              -no_unconnected_cells \
              -no_tap_cells \
              ../output/$DESIGN_NAME\_final.v

# RC 寄生参数提取
# extract_rc -coupling_cap: 计算互连线电阻 R + 对地电容 C + 耦合电容 CC
#   耦合电容 = 相邻走线之间的电容（串扰的物理来源）
write_parasitics -output ../output/$DESIGN_NAME.spef \
                 -format SPEF \
                 -compress \
                 -no_name_mapping

# ICC2 直接写 SDF（备选方案，PT 版本的 SDF 更精确）
# SDF 内容：每个标准单元的 pin-to-pin 延迟（IOPATH）+ 互连线延迟（INTERCONNECT）
write_sdf ../output/$DESIGN_NAME.sdf

puts "\n\[INFO\] 布线完成"
puts "  网表: ../output/$DESIGN_NAME\_final.v"
puts "  SPEF: ../output/$DESIGN_NAME.spef (RC寄生参数)"
puts "  SDF:  ../output/$DESIGN_NAME.sdf (延迟文件)"
puts "============================================\n"
