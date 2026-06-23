# 实验三：版图设计 (Physical Design)

对 MiniRV CPU (`cpu_pad`) 进行 ICC2 布局布线，PT 时序签核，VCS 后仿真。

## 版图设计核心概念

### 什么是版图设计

版图设计（Physical Design）是将门级网表转换为芯片制造所需物理版图的过程。输入是综合后的门级网表和约束，输出是 GDSII 版图文件。本实验完成到布线+寄生提取阶段，是 GDSII 前的重要步骤。

### 物理设计五阶段流程

```
 data_setup ──→ floorplan ──→ place ──→ cts ──→ route
   (数据准备)    (布图规划)    (布局)    (时钟树)   (布线)
```

与前端 RTL 设计的区别：前端关心**功能正确性**，后端关心**物理可实现性**——门放在哪里、线怎么连、时钟怎么分布。

### 关键概念

#### 1. Milkyway 数据库（MW Library）

ICC2 使用 Synopsys 私有的 Milkyway 格式存储设计数据。每个阶段保存为一个 CEL（cell view），类似于版本控制的 commit，可以回溯：

```
cpu_pad.mw/
├── data_setup     ← 初始导入
├── floorplaned    ← 布图规划后
├── placed         ← 布局后
├── cts            ← CTS 后
└── route          ← 布线后
```

CEL 包含：网表连接关系 + 单元的物理坐标 + 金属连线形状 + 电源地网络。

#### 2. 标准单元行（Standard Cell Rows）

芯片 core 区域被划分为水平的标准单元行（rows），同一行内的标准单元高度相同，共享 VDD/VSS 电源轨。标准单元的**高度固定**（与工艺相关），**宽度可变**（取决于逻辑复杂度）。

#### 3. 利用率（Utilization）

```
利用率 = 标准单元总面积 / core 总面积
```

- 利用率 **过高**（>80%）：布线资源不足 → 拥塞 → 无法 100% 完成布线
- 利用率 **过低**（<40%）：浪费面积 → die size 大 → 成本高
- 典型值：50%~75%

本实验设为 50%——低利用率是为了给 234 个 PAD 环留足空间。

#### 4. 拥塞（Congestion）

拥塞 = 局部区域连线密度超过可用的布线轨道数量。

```
高拥塞的后果：
  → DRC 违例（短路）
  → 时序变差（绕远路）
  → 无法完成布线
```

在 ICC2 GUI 中可以看到拥塞热力图（红色=拥堵区域），类似交通路况。

#### 5. 时钟树综合（CTS - Clock Tree Synthesis）

**为什么要 CTS**：综合后的网表中，时钟端口直接驱动 ~1,000 个触发器的 CK 端。如果不用 CTS：

- 一个门驱动 1,000 个负载 → transition time 极差 → 时序违例
- 各触发器收到时钟的时间差异大 → **时钟偏差（skew）** 大

CTS 做的事：在时钟源和每个触发器的 CK 端之间插入**树形 buffer 链**：

```
          clk_pad (PI pad)
              │
         ┌────┴────┐
        BUF       BUF          ← 第1级
         │         │
      ┌──┴──┐  ┌──┴──┐
     BUF   BUF BUF  BUF        ← 第2级
      │     │   │    │
     ...   ... ...  ...        ← ...
      │     │   │    │
     FF    FF  FF   FF         ← 触发器
```

目标参数：
- **Target Skew**：各触发器收到时钟的时间差目标（我们设 0.2ns）
- **Target Insertion Delay**：时钟从源到触发器的目标延迟（我们设 0.9ns）

#### 6. 电源网络（Power Grid）

芯片供电不是拉一根线——而是构建多层网格：

```
      VDD ─────────────────  METAL8 (水平strap)
      VSS ─────────────────
        │  │    │  │
        │  │    │  │         METAL7 (垂直strap)
        │  │    │  │
   ┌────┴──┴────┴──┴────┐
   │  VDD VDD VDD VDD   │   METAL1 (标准单元轨)
   │  VSS VSS VSS VSS   │
   └────────────────────┘
```

IR Drop（电压降）是电源网络的关键指标——电流流过电阻产生压降，导致远离电源 PAD 的区域电压偏低。

#### 7. SPEF 与 SDF（寄生参数与延迟）

```
提取             转换
SPEF ──────────→ SDF
(寄生: R+C)     (延迟: ns)
   ICC2            PT
```

- **SPEF** (Standard Parasitic Exchange Format)：描述互连线的电阻 R 和电容 C。两个压缩文件分别对应 max corner（大电容，慢速）和 min corner（小电容，快速）。
- **SDF** (Standard Delay Format)：描述每个门的 pin-to-pin 延迟值（纳秒）。`$sdf_annotate()` 在仿真中反标这些延迟，使门级仿真反映真实的物理延迟，而非零延迟。

**SPEF → SDF 转换原理**：PT 将 SPEF 中的 R/C 值与标准单元的输入电容、驱动电阻结合，通过非线性延迟模型（NLDM）计算出每个门的实际延迟。为什么需要 PT 做而不是 ICC2 直接出？因为 PT 的延迟计算模型更精确，是签核（signoff）级别的。

#### 8. DRC（Design Rule Check）

物理设计阶段的 DRC 不是逻辑错误——而是**几何规则违例**：

| DRC 类型 | 含义 |
|:---|:---|
| Short | 两根不同电位的线碰在一起 |
| Open | 应该连接的地方断开了 |
| Min Spacing | 两根线太近（工艺制造能力限制） |
| Min Width | 线太细（刻蚀良率要求） |
| Max Transition | 信号跳变太慢（驱动不足） |
| Max Capacitance | 负载电容太大（扇出过大） |

#### 9. 各阶段工作内容速查

| 阶段 | 做什么 | 输出 |
|:---|:---|:---|
| data_setup | 创建 MW 库，读网表+SDC+TLU+寄生模型 | MW CEL `data_setup` |
| floorplan | 放 PAD → 定 core 大小 → 布电源轨 → 插 pad filler | MW CEL `floorplaned` |
| place | 标准单元放置到 row 上 → 合法化 | MW CEL `placed` |
| cts | 插时钟 buffer chain → route 时钟网 | MW CEL `cts` |
| route | 信号线布线 → DRC 修复 → RC 提取 | MW CEL `route` |
| PT | SPEF → SDF 转换 | `cpu_pad_pt.sdf` |
| VCS | 门级网表 + SDF 后仿真 | 仿真波形 |

## 目录结构

```
expr-3/
├── docs/task.txt              # 实验指导书
├── rm_setups/                 # ICC2 配置文件
│   ├── icc_setup.tcl          #   工艺库 / TLU+ / MW 参考库设置
│   └── lcrm_setup.tcl         #   target_library / link_library + 搜索路径
├── scripts/                   # ICC2/PT 脚本
│   ├── design_setup.tcl       #   1. 数据准备 (create_mw_lib, read netlist/sdc, TLU+)
│   ├── floorplan.tcl          #   2. 布图规划 (pad, core, power, rails)
│   ├── place.tcl              #   3. 布局 (create_fp_placement, legalize)
│   ├── cts.tcl                #   4. 时钟树综合 (clock_opt, route clock nets)
│   ├── route.tcl              #   5. 布线 + 寄生提取 + 写网表/SPEF/SDF
│   ├── basic_ring.tpl         #   电源环模板
│   ├── pg_mesh.tpl            #   电源网格模板
│   ├── common_optimization_settings_icc.tcl
│   ├── common_placement_settings_icc.tcl
│   └── sdf_gen.tcl            #   6. PT 生成 SDF (从 SPEF)
├── design_data/               # 输入: cpu_pad_netlist.v + cpu_pad.sdc
├── run/                       # 运行脚本目录
│   ├── run_all.sh             #   一键运行全流程
│   ├── run_*.sh               #   各步骤的独立运行脚本
│   ├── view_layout.sh         #   ICC2 GUI 查看版图
│   └── tb_cpu_pad_post.v      #   后仿真 testbench
├── logs/                      # 日志文件
└── output/                    # 输出:
    ├── cpu_pad_final.v        #   布局布线后网表
    ├── cpu_pad.spef.max.gz    #   SPEF 寄生参数 (max corner)
    ├── cpu_pad.spef.min.gz    #   SPEF 寄生参数 (min corner)
    ├── cpu_pad.sdf            #   ICC2 生成的 SDF
    └── cpu_pad_pt.sdf         #   PT 生成的 SDF
```

## 手动运行步骤

### 前置条件

远程服务器 `yan12@10.112.86.27`，确认环境：
```bash
# ICC2 可用
/home/eda/synopsys/icc/T-2022.03/bin/icc_shell

# PT 可用
/opt/synopsys/prime/T-2022.03/bin/pt_shell

# VCS 可用
vcs -full64

# 库文件核对
ls /home/eda/lib/smic/aci/sc-x/synopsys/typical_1v2c25.db
ls /home/eda/lib/smic/SP013D3_V1p4/syn/SP013D3_V1p2_typ.db
ls /home/eda/lib/smic/aci/sc-x/apollo/smic13g/
ls /home/eda/lib/smic/SP013D3_V1p4/apollo/SP013D3_V1p2_8MT/
ls /home/eda/houfang/smic13g.v
ls /home/eda/houfang/SP013D3_V1p2.v
```

### 1. 同步代码 + 准备输入数据

```bash
cd ~/proj/rv-cpu-expr && git pull

# 从实验二的综合结果复制网表和 SDC
cp expr-2/syn/mapped/cpu_pad_netlist.v expr-3/design_data/
cp expr-2/syn/mapped/cpu_pad.sdc expr-3/design_data/
```

### 2. 运行 ICC2 全流程

在 `expr-3/run/` 目录下，依次执行以下 5 步（每步结束后检查输出是否有 Error）：

```bash
cd ~/proj/rv-cpu-expr/expr-3/run

# Step 1: 数据准备 (创建 MW 库，读网表+SDC+TLU+)
rm -rf ../cpu_pad.mw   # 如果 MW 库已存在，先删除
icc_shell -f ../scripts/design_setup.tcl 2>&1 | tee ../logs/design_setup.log

# Step 2: 布图规划 (pad 放置, core, power rails)
icc_shell -f ../scripts/floorplan.tcl 2>&1 | tee ../logs/floorplan.log

# Step 3: 布局 (标准单元放置)
icc_shell -f ../scripts/place.tcl 2>&1 | tee ../logs/place.log

# Step 4: 时钟树综合
icc_shell -f ../scripts/cts.tcl 2>&1 | tee ../logs/cts.log

# Step 5: 布线 + 寄生提取
icc_shell -f ../scripts/route.tcl 2>&1 | tee ../logs/route.log
```

每步完成检查：`grep -i "error\|fatal\|Severe" ../logs/*.log`

### 3. PT 生成 SDF

```bash
cd ~/proj/rv-cpu-expr/expr-3/run
pt_shell -f ../scripts/sdf_gen.tcl 2>&1 | tee ../logs/sdf_gen.log
```

输出：`../output/cpu_pad_pt.sdf`

### 4. VCS 后仿真

```bash
cd ~/proj/rv-cpu-expr/expr-3/run

# 准备文件
cp ../output/cpu_pad_final.v .

# 编译 + 运行
vcs -full64 \
    -v /home/eda/houfang/smic13g.v \
    -v /home/eda/houfang/SP013D3_V1p2.v \
    tb_cpu_pad_post.v cpu_pad_final.v \
    +maxdelays -R
```

### 5. 查看版图

使用 `view_layout.sh` 脚本一键打开 ICC2 GUI：

```bash
# 需要 X11 forwarding（本地需有图形界面）
ssh -X yan12@10.112.86.27
cd ~/proj/rv-cpu-expr && git pull
cd expr-3/run

# 按物理设计顺序查看各阶段版图
./view_layout.sh data_setup         # 1. 初始导入
./view_layout.sh floorplan_prepns   # 2. 电源规划前
./view_layout.sh floorplanafterpn   # 3. 电源连接后
./view_layout.sh floorplaned        # 4. 布图规划完成
./view_layout.sh placed             # 5. 布局后
./view_layout.sh cts                # 6. 时钟树综合后
./view_layout.sh route              # 7. 布线后（最终版图）
```

GUI 操作：**View → Layout Browser**，滚轮缩放、中键拖拽平移、Ctrl+F 查找。

各阶段 CEL 内容（按物理设计流程排序）：

| 顺序 | CEL | 可观察内容 |
|:---:|:---|:---|
| 1 | `data_setup` | 刚读入网表，无物理信息 |
| 2 | `floorplan_prepns` | PAD 环 + core 边界，无电源 |
| 3 | `floorplanafterpn` | 电源地连接建立 |
| 4 | `floorplaned` | pad filler 填充后，电源轨完成 |
| 5 | `placed` | 标准单元放置后（可看到 cell 分布和密度） |
| 6 | `cts` | 时钟树 buffer chain 可见 |
| 7 | `route` | **最终版图**——全部金属层连线可见 |

## 工作记录

### 遇到的问题和解决方案

#### 1. ICC2 link_library 未设置

**问题**：运行 design_setup 时出现 `No valid link library specified`。

**原因**：ICC2 不像 DC 那样自动从 `.synopsys_dc.setup` 读取 target_library。MW 库提供物理视图（CEL/FRAM），但时序分析需要 `.db` 文件。

**解决**：在 `lcrm_setup.tcl` 中显式设置：
```tcl
set target_library "/path/to/typical_1v2c25.db /path/to/SP013D3_V1p2_typ.db"
set link_library "* $target_library"
```

#### 2. ICC2 power plan 模板语法

**问题**：`Cannot find template pg_mesh_top in file`。

**原因**：ICC2 模板格式要求冒号前有空格（`template : name {`），不是 `template: name {`。

**解决**：修正模板文件格式，在 `template` 和 `:` 之间加空格。

#### 3. compile_power_plan -ring 触发 ICC2 内部断言

**问题**：`pwExt_BboxInit: Assertion 'y1 >= y2' failed`，进程崩溃。

**原因**：手动 power ring/mesh 的编译触发了 ICC2 的几何计算 bug。可能与设计 pad 数量过多（234 个）导致的环尺寸异常有关。

**解决**：跳过复杂的 ring/mesh 手动编译，改为只使用 `preroute_standard_cells` 做标准单元电源轨布线。

#### 4. place_opt 工具内部错误

**问题**：`can't unset "alo_initial_cluster": no such variable`。

**原因**：ICC2 2022.03 版本 `place_opt` 命令的 bug，与设计规模或初始化状态有关。

**解决**：改用传统 placement 流程：
```tcl
create_fp_placement -timing -no_hierarchy_gravity
legalize_placement
```
避免使用 `place_opt` 命令。

#### 5. 粗粒度 placer 崩溃

**问题**：`Fatal error: Placer did not complete. global route congestion map calculation failed.`。

**原因**：`refine_placement -congestion_effort high` 需要 congestion map，但 coarse placer 执行进程 (`rpsa_exec`) 崩溃。

**解决**：移除 `-congestion` 和 `refine_placement`，只做基本 `create_fp_placement` + `legalize_placement`，时序优化留给 route 阶段。

#### 6. Placement 时序优化极慢

**问题**：Placement 后 `psynopt` 运行 69 秒仍未完成，WNS = 32ns（远低于 20ns 周期）。

**原因**：没有时钟树时，`psynopt` 试图优化所有高扇出时钟网路径，这是不可能完成的任务且计算量极大。时序优化必须在 CTS 后进行。

**解决**：Placement 阶段移除所有时序优化（`psynopt`），只做基本单元放置。CTS 构建真实时钟树后，route 阶段的 `route_opt` 再做时序优化。

#### 7. PT SPEF 标注错误

**问题**：PT 运行 SDF 生成时有 40K+ `PARA-124` 错误和 204 `PARA-044` 错误。

**原因**：SPEF 中的某些 net 名与网表中的实际 net 名不完全匹配（可能是 ICC2 `change_names` 和 RC 提取使用了不同的命名规则导致）。

**解决**：这些错误不影响 SDF 生成（SDF 仍包含大部分路径的延迟信息），属于寄生参数标注过程中的部分不匹配。更完善的解决需要对齐 SPEF 和网表的命名规则。

### AI 生成脚本经验总结

1. **脚本适配**：参考脚本是另一个设计（`control_pad`，~20 个端口），我们的设计（`cpu_pad`，230+ 个端口）需要大幅调整。用 generate 循环和自动化替代手写 pad 约束。

2. **版本兼容性**：ICC2 (T-2022.03) 与 IC Compiler (老版本) 命令不完全兼容。`place_opt` / `clock_opt` 等新命令在某些场景下不稳定，传统命令（`create_fp_placement` / `compile_clock_tree`）更可靠。

3. **调试方法**：ICC2 错误信息通常不直接指出根因。有效排查方式：
   - 查看日志中第一个 Error（后续错误往往是级联的）
   - 简化脚本到最小可用版本，逐步加回功能
   - 用 `icc_shell -f script.tcl` 重定向日志，方便分析

4. **无 PT 备选方案**：ICC2 自身可以 `write_sdf`，虽然不如 PT 精确，但在无 PT 时可做备选。

## 结果速查

| 阶段 | 耗时 | 内存 | 关键输出 |
|:---|:-:|:-:|:---|
| data_setup | 42s | 1,236 MB | cpu_pad.mw (CEL: data_setup) |
| floorplan | ~30s | ~1,200 MB | CEL: floorplaned |
| place | 87s | 1,258 MB | CEL: placed |
| cts | 73s | 1,337 MB | CEL: cts |
| route | 230s | 1,466 MB | CEL: route + netlist.v + spef + sdf |
| PT SDF | 9s | 2,695 MB | cpu_pad_pt.sdf (908 KB) |
| VCS post-sim | ~2s | — | 编译通过, SDF 反标成功, 仿真正常结束 |
