#===========================================================================
# sdf_gen.tcl — PrimeTime SDF 延迟文件生成
#
# 功能：从 ICC2 提取的 SPEF 寄生参数 + 版图后网表，计算真实门级延迟
# 输入：output/cpu_pad_final.v (版图后网表), output/cpu_pad.spef.max.gz (寄生)
# 输出：output/cpu_pad_pt.sdf (标准延迟格式文件)
#
# 为什么用 PT 而不是 ICC2 直接出 SDF：
#   ICC2 的 write_sdf 用的是简化延迟模型（Elmore delay）
#   PT 用的是签核级模型（NLDM/CCS），考虑了非线性输入 transition、
#   输出负载、多输入同时翻转(multi-input switching)等因素
#   → PT 的 SDF 更接近实际硅片的延迟
#
# SPEF → SDF 转换原理：
#   SPEF 提供了互连线的 R(电阻) 和 C(电容)
#   PT 用标准单元的 .db 库中的时序模型：
#     1) 计算每个门的输入 transition（前一极驱动+互连线RC的共同作用）
#     2) 计算每个门的输出延迟（查 NLDM 表：输入transition × 输出负载）
#     3) 输出 = cell delay + wire delay
#===========================================================================

# 设置链接库——PT 需要 .db 来做时序计算
# link_library 中的 * 表示让 PT 自动搜索已加载的设计中的模块
set link_library "\
    /home/eda/lib/smic/aci/sc-x/synopsys/typical_1v2c25.db \
    /home/eda/lib/smic/SP013D3_V1p4/syn/SP013D3_V1p2_typ.db"

set target_library $link_library

#---------------------------------------------------------------------
# 1. 读入版图后网表
#    current_design cpu_pad: 指定顶层设计
#    link: 让 PT 解析所有子模块引用，匹配到 .db 中的单元
#---------------------------------------------------------------------
read_verilog ../output/cpu_pad_final.v
current_design cpu_pad
link

#---------------------------------------------------------------------
# 2. 读入寄生参数 (SPEF)
#    -pin_cap_included: SPEF 中已经包含了 pin capacitance
#      (ICC2 extract_rc 时已计算引脚电容，不需要 PT 再算一遍)
#    使用 max corner 的 SPEF (最悲观，对应建立时间检查)
#---------------------------------------------------------------------
read_parasitics -pin_cap_included ../output/cpu_pad.spef.max.gz

#---------------------------------------------------------------------
# 3. 时序检查——验证标注是否成功
#    check_timing: 检查设计约束的完整性
#      如果有未约束的路径、未定义的时钟、unconstrained endpoint 等会报告
#    report_timing: 报告最差路径（验证寄生标注后时序计算正常）
#---------------------------------------------------------------------
check_timing
report_timing

#---------------------------------------------------------------------
# 4. 写出 SDF
#    SDF 文件包含：
#      (CELL ... (INSTANCE u_xxx) (DELAY (ABSOLUTE ...)))
#    每个单元的每个 pin-to-pin 都有 min:typ:max 三组延迟值
#    在 VCS 中用 $sdf_annotate() 反标后，仿真就会使用这些真实延迟
#---------------------------------------------------------------------
write_sdf ../output/cpu_pad_pt.sdf

puts "\[INFO\] SDF 已写出到 ../output/cpu_pad_pt.sdf"
