#===========================================================================
# dc_scripts.tcl — MiniRV CPU 逻辑综合脚本
#
# 功能：将 RTL 代码综合为 SMIC 0.13µm 门级网表
# 目标频率：50MHz (20ns 时钟周期)
# 顶层模块：cpu_pad (包含 myCPU + IO PAD)
#===========================================================================

#===========================================================================
# 0. 准备工作：创建输出目录 + 配置工作库
#===========================================================================

# 确保输出目录存在（mapped=最终产物, rpt=报告, unmapped=中间文件, work=编译临时文件）
exec mkdir -p ./mapped ./rpt ./unmapped ./work

# 将 DC 编译产生的中间文件(.mr, .pvl, .syn)定向到 work/ 目录，保持根目录整洁
# define_design_lib: 创建一个名为 WORK 的设计库，analyze 输出放在 ./work 下
define_design_lib WORK -path ./work
# alib_library_analysis_path: DC 内部库分析缓存也放 work/
set_app_var alib_library_analysis_path ./work

puts "============================================"
puts "  MiniRV CPU Logic Synthesis (50MHz)"
puts "============================================"

#===========================================================================
# 1. 读入 RTL 设计
#    - analyze: 语法分析 + 中间编译 (类似 C 的 gcc -c)
#    - elaborate: 链接所有模块 + 生成顶层设计的未优化网表 (类似 C 的 ld)
#    注意：analyze 需要在 elaborate 之前，因为 SystemVerilog 不支持 link 时直接读
#===========================================================================

# 收集 ./rtl/ 下所有 SystemVerilog 源文件
set sv_files [glob ./rtl/*.sv]
puts "\[INFO\] 读入 SystemVerilog 文件:"
foreach f $sv_files {
    puts "    $f"
}

# 语法分析阶段：将每个 .sv 文件转为中间表示 (.mr + .pvl + .syn 文件)
# -format sverilog: 指定使用 SystemVerilog 解析器
# -work WORK: 中间文件写入 ./work/ 目录
analyze -work WORK -format sverilog $sv_files

# 顶层展开阶段：选择顶层模块 cpu_pad，DC 自动拉取所有子模块
# 此阶段完成 parameter 实例化、generate 展开、模块连接等
puts "\[INFO\] 展开顶层模块: cpu_pad"
elaborate cpu_pad -work WORK

#===========================================================================
# 1.5 初始检查——确认设计正确读入
#===========================================================================

# 设置当前工作设计（后续所有操作都作用于此设计）
current_design cpu_pad

# link: 检查所有引用的模块/单元是否都能在 link_library 中找到
# 如果有 unresolved reference，link 会报错
link

# 保存未映射（未优化）的设计数据库，方便后续回到此状态
write -hierarchy -format ddc -output ./unmapped/cpu_pad_unmapped.ddc

# 打印设计层次结构（确认所有子模块都在）
puts "\n\[INFO\] 设计层次结构:"
list_designs
puts "\n\[INFO\] 已加载的库:"
list_libs

#===========================================================================
# 2. 设置库信息
#===========================================================================

# lib_name 用于后续 set_driving_cell / load_of 等命令
# typical_1v2c25: SMIC 0.13µm 标准单元库，typical corner, 1.2V, 25°C
set lib_name typical_1v2c25

#===========================================================================
# 3. 时钟约束（最重要的约束！决定目标频率）
#===========================================================================

# 时钟周期: 20ns → 50MHz
# 这是 DC 综合优化的目标——所有组合路径必须在此周期内完成
set CLK_PERIOD     20.0

# 时钟不确定性（uncertainty）: 为时钟抖动(jitter)和偏差(skew)预留的余量
# DC 综合阶段设为 0.2ns (200ps) 是比较保守的做法
# 实际 set_clock_uncertainty = jitter + skew + margin
set CLK_UNCERTAINTY 0.2

# 时钟端口: 外部 PAD 引脚 clk_pad（经过 PI pad → cpu_clk）
# DC 会从此端口开始传播时钟，计算所有时序路径
set CLK_PORT       clk_pad

# create_clock: 在指定端口定义时钟
# -period 20.0: 周期 20ns
# -name main_clk: 给时钟命名，后续命令引用此名
create_clock -period $CLK_PERIOD -name main_clk [get_ports $CLK_PORT]

# 将 uncertainty 绑定到时钟上
# DC 会在 setup 检查时减去此值（收紧约束），在 hold 检查时加上（也收紧）
set_clock_uncertainty $CLK_UNCERTAINTY [get_clocks main_clk]

puts "\[INFO\] 时钟定义: 端口=$CLK_PORT, 周期=${CLK_PERIOD}ns, uncertainty=${CLK_UNCERTAINTY}ns"

#===========================================================================
# 4. 输入约束——定义芯片外部信号的到达时间
#===========================================================================

# 从所有输入端口中排除时钟端口（时钟的约束在上面单独定义）
set all_inputs_no_clk [remove_from_collection [all_inputs] [get_ports $CLK_PORT]]
# 再排除复位（复位通常是异步的，不按时钟约束）
set all_inputs_no_clk_rst [remove_from_collection $all_inputs_no_clk [get_ports rst_n_pad]]

# set_driving_cell: 指定输入端口的驱动单元
# DC 假设输入信号由此单元驱动，影响输入信号的 transition time
# 使用 AND2X4: 库中最小的 AND 门之一，驱动能力弱 → 保守假设
# 如果真实前级驱动更强，DC 这样假设会给综合留更多余量
set_driving_cell -library $lib_name -lib_cell AND2X4 $all_inputs_no_clk_rst

# set_input_delay: 指定外部信号相对于时钟的到达延迟
# -max 0.1: 建立时间检查用的最大延迟（保守值，假设外部路径很快）
# -min 0.05: 保持时间检查用的最小延迟
# 含义: 外部数据在时钟沿前 0.1ns 才到达芯片引脚，留给芯片内部的时间 = 周期 - 0.1
set_input_delay 0.1 -max -clock main_clk $all_inputs_no_clk_rst
set_input_delay 0.05 -min -clock main_clk $all_inputs_no_clk_rst

# 复位信号不设 input_delay，因为它是异步信号
# DC 不检查异步复位路径的 setup/hold，改为检查 recovery/removal

#===========================================================================
# 5. 输出约束——定义芯片外部负载和后级路径
#===========================================================================

# set_output_delay: 指定输出信号在芯片外需要的传播时间
# -max 1.0: 最慢情况，输出信号到下一级芯片需要 1.0ns
# 含义: 芯片内部路径必须在 (周期 - 1.0) 内完成，扣掉外部时间
set_output_delay 1.0 -max -clock main_clk [all_outputs]
set_output_delay 0.5 -min -clock main_clk [all_outputs]

# set_load: 设置输出端口的负载电容
# load_of: 查询 AND2X4 的 A 输入端的电容值
# ×15: 假设输出驱动 15 个等效负载（模拟 PCB 走线 + 下一级输入电容）
# DC 会确保输出驱动单元能驱动此负载
set_load [expr [load_of $lib_name/AND2X4/A] * 15] [all_outputs]

#===========================================================================
# 6. PAD 保护——标记 PAD 单元为不可修改
#===========================================================================

# PAD 是预先设计的硬核（hard macro），综合时不能改动
# set_dont_touch: 告诉 DC 不要优化/移除/替换这些单元
# 用名称匹配找到所有 PI* 和 PO* 开头的 PAD 实例
set pad_cells [get_cells -hierarchical -filter "ref_name =~ PI* || ref_name =~ PO*"]
if {[sizeof_collection $pad_cells] > 0} {
    set_dont_touch $pad_cells true
    puts "\[INFO\] 已标记 [sizeof_collection $pad_cells] 个 PAD 单元为 dont_touch"
}

# 额外保护复位和时钟 PAD（按实例名精确匹配）
set_dont_touch [get_cells i_rst] true
set_dont_touch [get_cells i_clk] true

#===========================================================================
# 7. 设计规则约束（可选）
#===========================================================================

# 以下为可选约束，当前注释掉：
# set_max_area 0              # 将面积优化到最小（设为 0 即"尽可能小"）
# set_max_fanout 16 cpu_clk   # 限制最大扇出（超过此值 DC 自动插入 buffer）
# set_fix_multiple_port_nets -all -buffer_constants  # 多端口网络加 buffer

#===========================================================================
# 8. 编译——执行逻辑综合的核心步骤！
#===========================================================================

puts "\n\[INFO\] 开始 compile_ultra ..."

# compile_ultra: DC 最高级别的综合命令
# 做了三件事（按顺序）：
#   1) Translation:  RTL → 布尔逻辑表达式 (未映射的 GTECH 网表)
#   2) Optimization: 布尔优化（合并等价项、消除冗余、逻辑重构）
#   3) Mapping:      从工艺库选具体标准单元 (AND2X4, DFFRXL, INVX1 ...)
#
# 优化策略（-ultra）包含:
#   - 时序驱动的结构优化
#   - 面积恢复（在满足时序的前提下尽量用小单元）
#   - 数据通路优化
#   - 自动 ungrouping 边界优化
compile_ultra

puts "\[INFO\] 编译完成。"

#===========================================================================
# 9. 生成综合报告——分析综合结果
#===========================================================================

puts "\n\[INFO\] 生成报告 ..."

# 以下每个 redirect 将报告输出到 rpt/ 目录

# 约束违例报告——列出所有 setup/hold/DRC 违例的路径
# -all_violators: 列出所有不满足约束的端点
redirect -file ./rpt/rpt_constraints.rpt { report_constraint -all_violators }

# 时序报告——最差的一条路径的详细展开（能看到每一级门延迟）
redirect -file ./rpt/rpt_timing.rpt      { report_timing }

# 最差 10 条路径——定位设计中哪些路径是时序瓶颈
redirect -file ./rpt/rpt_timing_max.rpt  { report_timing -delay max -nworst 10 }

# 面积报告——组合/时序/宏单元的面积细分
# 单元面积单位: µm² (平方微米)
redirect -file ./rpt/rpt_area.rpt        { report_area }

# 功耗报告——动态功耗（内部翻转+连线开关）+ 静态漏电
# 综合阶段的功耗是粗略估计（基于线载模型 + 默认翻转率）
redirect -file ./rpt/rpt_power.rpt       { report_power }

# 单元明细——每个实例的面积和参考单元
redirect -file ./rpt/rpt_cell.rpt        { report_cell [get_cells -hierarchical] }

# 资源报告——DC 使用的硬件资源统计
redirect -file ./rpt/rpt_resource.rpt    { report_resources }

# QoR (Quality of Results)——一页总结
# 包含: Slack, 面积, 单元数, 违例数 → 最先看这个
redirect -file ./rpt/rpt_qor.rpt         { report_qor }

puts "\[INFO\] 报告已保存到 ./rpt/"

#===========================================================================
# 10. 写出最终输出——交给后续流程使用
#===========================================================================

puts "\n\[INFO\] 写出输出文件 ..."

# .ddc: DC 二进制数据库
# 可以后续 reload 继续优化，或送给 Formality 做形式验证
write -hierarchy -format ddc -output ./mapped/cpu_pad_mapped.ddc

# .v: 门级 Verilog 网表
# 送给 ICC2 (版图设计) 或 VCS (门级仿真) 使用
# 内容: 标准单元实例 + PAD 实例 + wire 连接，无行为级代码
write -hierarchy -format verilog -output ./mapped/cpu_pad_netlist.v

# .sdc: 综合后的时序约束文件
# 送给 ICC2 作为版图设计的输入约束
# 包含: 时钟定义、输入/输出延迟、负载等
write_sdc ./mapped/cpu_pad.sdc

# .sdf: 标准延迟格式文件
# 送给 VCS/ModelSim 做门级后仿真反标
# 包含: 每个门每个 pin-to-pin 的延迟值 (min:typ:max)
write_sdf ./mapped/cpu_pad.sdf

puts "\[INFO\] 输出已保存到 ./mapped/"
puts "\n============================================"
puts "  综合完成！"
puts "  报告: ./rpt/"
puts "  输出: ./mapped/ (网表 .v, 延迟 .sdf, 约束 .sdc)"
puts "============================================"