#===========================================================================
# design_setup.tcl — ICC2 数据准备
#
# 功能：创建 Milkyway 物理库，读入门级网表 + SDC 约束 + TLU+ 寄生模型
# 输入：design_data/cpu_pad_netlist.v, design_data/cpu_pad.sdc
# 输出：cpu_pad.mw (MW 物理库，含 CEL: data_setup)
#===========================================================================

# 加载库和工艺配置文件
source ../rm_setups/lcrm_setup.tcl
source -echo ../rm_setups/icc_setup.tcl

puts "\n============================================"
puts "  Data Setup: $DESIGN_NAME"
puts "============================================"

#---------------------------------------------------------------------
# 1. 创建 Milkyway 物理库
#    MW 库 = ICC2 的项目数据库，存储所有设计数据（CEL视图）
#    参数说明：
#      -technology:   工艺 TF 文件（定义金属层、via、设计规则）
#      -mw_reference_library: 参考库 = 标准单元 + PAD 的物理视图(FRAM)
#        FRAM 视图 = 单元的金属引脚形状 + 阻塞区域（不包含内部晶体管）
#---------------------------------------------------------------------
# 如果上次运行残留了 MW 库，先删除（MW 库创建后不能覆盖）
if {[file exists $DESIGN_NAME.mw]} {
    puts "\[WARN\] $DESIGN_NAME.mw 已存在，删除旧库 ..."
    exec rm -rf $DESIGN_NAME.mw
}

create_mw_lib $DESIGN_NAME.mw \
    -open \
    -technology $TECH_FILE \
    -mw_reference_library $MW_REFERENCE_LIB_DIRS

puts "\[INFO\] MW 库创建完成"

#---------------------------------------------------------------------
# 2. 读入门级网表
#    read_verilog: 读取综合生成的 Verilog 网表（标准单元 + PAD 实例）
#    uniquify: 对多次例化的模块创建独立副本（为后续布局布线做准备）
#    save_mw_cel: 将当前设计状态保存为一个 CEL 视图
#---------------------------------------------------------------------
read_verilog -top $DESIGN_NAME $ICC_INPUTS_PATH/$ICC_IN_VERILOG_NETLIST_FILE

current_design $DESIGN_NAME
uniquify
save_mw_cel -as $DESIGN_NAME

puts "\[INFO\] 网表已读入并唯一化"

#---------------------------------------------------------------------
# 3. 设置 TLU+ 寄生模型
#    TLU+ (Table Look-Up Plus): StarRC 的互连线 RC 寄生模型格式
#    作用：在时序计算中，ICC2 查表得到每段金属线的 R 和 C 值
#    max/min: 分别对应最慢 corner（大 R/C）和最快 corner（小 R/C）
#    tech2itf_map: ITF 工艺参数到 TLU+ 层的映射文件
#---------------------------------------------------------------------
set_tlu_plus_files \
    -max_tluplus $TLUPLUS_MAX_FILE \
    -min_tluplus $TLUPLUS_MIN_FILE \
    -tech2itf_map $TECH2ITF_MAP_FILE

puts "\[INFO\] TLU+ 寄生模型已加载"

#---------------------------------------------------------------------
# 4. 建立电源/地连接
#    derive_pg_connection: 推导 P/G 网络连接关系
#    -create_net: 如果 VDD/VSS 网络不存在则自动创建
#    -power_net/-ground_net: 指定电源/地网络名
#    -power_pin/-ground_pin: 指定单元上电源/地引脚名（库中定义）
#    -create_ports top -tie: 在顶层创建 VDD/VSS 端口并连接到 1'b1/1'b0
#    含义：所有标准单元的 VDD 引脚连到 VDD 网络，VSS 连到 VSS 网络
#---------------------------------------------------------------------
derive_pg_connection -create_net
derive_pg_connection -power_net VDD -power_pin VDD -ground_net VSS -ground_pin VSS
derive_pg_connection -power_net VDD -ground_net VSS -create_ports top -tie

check_mv_design

puts "\[INFO\] 电源地连接建立完成"

#---------------------------------------------------------------------
# 5. 读入时序约束 (SDC)
#    从实验二的综合结果中获取时钟定义、输入输出延迟等约束
#    check_timing: 检查设计是否正确约束（时钟是否定义了、路径是否可检查等）
#---------------------------------------------------------------------
read_sdc $ICC_INPUTS_PATH/$DESIGN_NAME.sdc
check_timing
report_timing_requirements
report_disable_timing

puts "\[INFO\] SDC 时序约束已加载"

#---------------------------------------------------------------------
# 6. 时钟报告——确认时钟定义正确
#---------------------------------------------------------------------
report_clock
report_clock -skew

#---------------------------------------------------------------------
# 7. 初始时序检查（零互连线延迟模式）
#    先把所有互连线延迟设为 0，仅看单元自身延迟
#    目的：快速验证 SDC 约束和网表是否正确，排除连线延迟干扰
#    完成后恢复正常模式，移除时钟/复位上的 ideal_network 属性
#    (ideal_network = 零延迟、无限驱动、不检查 DRC)
#---------------------------------------------------------------------
source ../scripts/common_optimization_settings_icc.tcl
# 开启零连线延迟模式，检查纯单元延迟
set_zero_interconnect_delay_mode true
report_constraint -all
report_timing
# 恢复真实连线延迟模式
set_zero_interconnect_delay_mode false

# 移除时钟和复位上的理想网络属性——后续placement会插入真实buffer
remove_ideal_network [get_ports clk_pad]
remove_ideal_network [get_ports rst_n_pad]

#---------------------------------------------------------------------
# 8. 保存初始 CEL——后续所有阶段从此 cell 开始
#---------------------------------------------------------------------
save_mw_cel -as data_setup

puts "\n\[INFO\] 数据准备完成，CEL 'data_setup' 已保存"
puts "============================================\n"