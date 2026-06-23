#===========================================================================
# place.tcl — ICC2 布局 (Placement)
#
# 功能：将门级网表中的标准单元放到芯片 core 区域的物理位置上
# 输入：上一个 CEL (floorplaned)
# 输出：MW CEL (placed)
#
# 布局做什么：
#   1) 粗略放置——每个单元分配到大致区域（基于时序和连接关系）
#   2) 合法化——把单元"卡"到标准单元行上（坐标对齐到 row/site 网格）
#   3) (可选) 时序/面积优化——psynopt 增量优化
#
# 注意：本实验的布局跳过了时序优化（psynopt）。
#   原因：此时还没有时钟树，时钟网是 ideal_network
#      → 高扇出时钟路径的 setup/hold 无法真实评估
#      → CTS 构建真实时钟树后再做时序优化才有意义
#===========================================================================

source ../rm_setups/lcrm_setup.tcl
source -echo ../rm_setups/icc_setup.tcl

puts "\n============================================"
puts "  Placement: $DESIGN_NAME"
puts "============================================"

open_mw_lib $DESIGN_NAME.mw
copy_mw_cel -from floorplaned -to place
open_mw_cel place

# 加载优化和布局参数设置
source -echo ../scripts/common_optimization_settings_icc.tcl
source -echo ../scripts/common_placement_settings_icc.tcl

#---------------------------------------------------------------------
# 1. 预布局物理检查
#    验证 floorplan 阶段的结果是否满足布局的前提条件：
#    - 有足够的 core 面积
#    - 标准单元行已定义
#    - PAD 环完整
#---------------------------------------------------------------------
check_physical_design -stage pre_place_opt

#---------------------------------------------------------------------
# 2. 设置时钟网为理想网络
#    ideal_network: 零延迟、无限驱动能力、不检查 max_transition/max_cap
#    原因：此时没有时钟树，如果当作普通网络会被报大量 DRC 违例
#    CTS 阶段会用真实 buffer chain 替换 ideal_network
#---------------------------------------------------------------------
set_ideal_network [all_fanout -flat -clock_tree]

#---------------------------------------------------------------------
# 3. 粗放置 (Coarse Placement)
#    create_fp_placement: 基于时序和线长的全局放置
#      -timing: 时序驱动（将有关键时序关系的单元放得近一些）
#      -no_hierarchy_gravity: 不按模块层次聚拢单元
#        （关闭此选项可以让工具更自由地跨模块优化位置）
#---------------------------------------------------------------------
create_fp_placement -timing -no_hierarchy_gravity

#---------------------------------------------------------------------
# 4. 合法化 (Legalization)
#    粗放置后的单元坐标不精确——可能落在 site 网格间隙
#    legalize_placement: 把每个单元"推"到最近的合法 site 上
#    同时消除单元之间的重叠
#    合法化后：所有单元坐标都是 row/site 对齐的，且无重叠
#---------------------------------------------------------------------
legalize_placement

# 报告最终利用率——确认面积使用合理
report_design_physical -utilization

#---------------------------------------------------------------------
# 5. 保存 QoR 快照
#    记录布局完成时的设计质量指标（面积、拥塞、时序估计等）
#    可以在后续阶段与快照对比，了解各阶段的改善幅度
#---------------------------------------------------------------------
create_qor_snapshot -name placed
query_qor_snapshot -name placed

save_mw_cel -as placed

puts "\n\[INFO\] 布局完成，CEL 'placed' 已保存"
puts "============================================\n"
