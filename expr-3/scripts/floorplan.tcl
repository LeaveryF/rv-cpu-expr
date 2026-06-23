#===========================================================================
# floorplan.tcl — ICC2 布图规划
#
# 功能：确定芯片尺寸、PAD 环布局、core 区域、电源轨布线
# 输入：上一个 CEL (data_setup)
# 输出：MW CEL: floorplan_prepns, floorplanafterpn, floorplaned
#
# 布图规划做什么：
#   1) PAD 放置——把 234 个 IO PAD 排在芯片四周
#   2) Core 创建——在 PAD 环内部划出标准单元放置区域
#   3) 电源网络——为标准单元行布 VDD/VSS 轨
#   4) Pad filler——填充 PAD 之间的空隙保证环形连续
#===========================================================================

source ../rm_setups/lcrm_setup.tcl
source -echo ../rm_setups/icc_setup.tcl

puts "\n============================================"
puts "  Floorplan: $DESIGN_NAME"
puts "============================================"

# 打开上次保存的 MW 库和 CEL，copy 为新 cell 开始布图规划
open_mw_lib $DESIGN_NAME.mw
copy_mw_cel -from data_setup -to floorplan
open_mw_cel floorplan

#---------------------------------------------------------------------
# 1. 创建 corner cell 和电源/地 PAD
#    PCORNER: 放在芯片四个角，保证 PAD 环物理连续性和 ESD 保护环路完整
#    PVSS1/PVDD1: Core 电源 PAD（给内部标准单元供电，1.2V）
#    PVSS2/PVDD2: IO 电源 PAD（给 PAD 自身供电，3.3V）
#    注意：这些是物理-only cell，只存在于版图中，不在逻辑网表里
#---------------------------------------------------------------------
create_cell {cornerll cornerlr cornerul cornerur} PCORNER

create_cell {vss1left vss1right} PVSS1
create_cell {vdd1left vdd1right} PVDD1

create_cell {vss2top vss2bottom} PVSS2
create_cell {vdd2top vdd2bottom} PVDD2

puts "\[INFO\] Corner 和电源 PAD cell 已创建"

#---------------------------------------------------------------------
# 2. 创建 Floorplan——定义芯片形状和 core 区域
#    -control_type aspect_ratio: 用长宽比控制（而非精确尺寸）
#    -core_aspect_ratio 1: 正方形 core
#    -core_utilization 0.5: 标准单元总面积占 core 面积的 50%
#      低利用率原因：设计有 234 个 PAD，PAD 环本身就占大量面积
#    -left/right/top/bottom_io2core 30: PAD 到 core 边界的间距 (µm)
#      这个空间用于布 PAD 到 core 的连线
#    -start_first_row: 从芯片边沿开始放第一行标准单元（而非留空）
#---------------------------------------------------------------------
create_floorplan \
    -control_type aspect_ratio \
    -core_aspect_ratio 1 \
    -core_utilization 0.5 \
    -left_io2core 30 \
    -bottom_io2core 30 \
    -right_io2core 30 \
    -top_io2core 30 \
    -start_first_row

puts "\[INFO\] Floorplan 已创建——core 尺寸和 PAD 环已确定"

#---------------------------------------------------------------------
# 3. 插入 Pad Filler——填充 PAD 之间的空隙
#    PAD 环中间有信号 PAD 和电源 PAD 之间的间隙
#    Pad filler 不实现逻辑功能，只是填充这些间隙保持 PAD 环的机械/电气连续性
#    使用多种尺寸（PFILL001~PFILL50）以适应不同间隙大小
#---------------------------------------------------------------------
insert_pad_filler -cell "PFILL001 PFILL01 PFILL1 PFILL10 PFILL2 PFILL20 PFILL5 PFILL50"

puts "\[INFO\] Pad filler 已插入"

#---------------------------------------------------------------------
# 4. 限制布线层
#    8 层金属 (METAL1~METAL8)，此处限制最多用到 METAL6
#    保留 METAL7/METAL8 给后续可能的电源网格或特殊布线
#    METAL1 通常给标准单元内部和标准单元轨使用
#---------------------------------------------------------------------
set_ignored_layers -max_routing_layer METAL6
report_ignored_layers

#---------------------------------------------------------------------
# 5. 电源/地连接——建立逻辑 P/G 网络到物理 P/G 的连接
#    保存中间状态: floorplan_prepns (电源规划前)
#                  floorplanafterpn (电源连接后)
#---------------------------------------------------------------------
save_mw_cel -as floorplan_prepns

derive_pg_connection -create_net
derive_pg_connection -power_net VDD -power_pin VDD -ground_net VSS -ground_pin VSS
derive_pg_connection -power_net VDD -ground_net VSS -create_ports top -tie

save_mw_cel -as floorplanafterpn

#---------------------------------------------------------------------
# 6. 为标准单元行布电源轨 (Standard Cell Rails)
#    preroute_standard_cells: 在每个标准单元行上布 VDD/VSS 轨
#    -min_layer METAL3: 最低到 METAL3（避开 METAL1/2 留给单元内部连线）
#    -max_layer METAL8: 最高到 METAL8
#    -remove_floating_pieces: 删除没有连接到主电源网络的孤立轨段
#    -do_not_route_over_macros: 不要跨过宏单元（如 PAD）
#    结果：每一行标准单元的上面是 VDD 轨，下面是 VSS 轨
#---------------------------------------------------------------------
set_preroute_drc_strategy -min_layer METAL3 -max_layer METAL8
preroute_standard_cells -nets "VDD VSS" -remove_floating_pieces -do_not_route_over_macros

#---------------------------------------------------------------------
# 7. 初始放置——快速预布局，检查拥塞
#    create_fp_placement: floorplan-level 粗放置
#    route_zrt_global -congestion_map_only: 只看全局布线拥塞，不实际布线
#    preroute_instances: 优化宏单元和 PAD 附近的连线
#    此步骤不保存为最终 placement——正式的精细布局在 place.tcl 中
#---------------------------------------------------------------------
create_fp_placement -congestion -timing -no_hierarchy_gravity
route_zrt_global -congestion_map_only true -exploration true
preroute_instances

save_mw_cel -as floorplaned

puts "\n\[INFO\] 布图规划完成，CEL 'floorplaned' 已保存"
puts "============================================\n"
