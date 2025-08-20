# EVRP电动车路径规划遗传算法求解器

## 项目简介

本项目是一个基于遗传算法的电动车路径规划问题(EVRP - Electric Vehicle Routing Problem)求解器，专为王晗课题组研究需求开发。该算法考虑电动车特有的约束条件，如电池容量限制、充电站位置等，为电动车配送路径优化提供解决方案。

## 功能特点

- **电动车约束建模**: 考虑电池容量、耗电率、充电站约束
- **遗传算法优化**: 高效的全局优化算法
- **多目标优化**: 最小化总距离、车辆使用数量等
- **可视化支持**: 路径可视化、收敛曲线分析
- **灵活配置**: 支持不同规模问题的参数调整

## 文件结构

```
Wanghan_Research_Group/开发中代码/
├── evrp_solver.py      # 主求解器
├── run_evrp.py         # 运行脚本
├── config.py          # 配置管理
├── data_generator.py   # 数据生成器
├── font_config.py     # 中文字体配置
├── README.md          # 使用说明
└── test_instances/    # 测试实例
```

## 安装和配置

### 1. 环境要求

- Python 3.7+
- 依赖包：
  ```bash
  pip install numpy matplotlib
  ```

### 2. 中文字体配置

#### macOS系统
macOS系统通常已内置中文字体，无需额外安装。

#### Windows系统
Windows系统通常已内置以下中文字体：
- SimHei (黑体)
- SimSun (宋体)
- Microsoft YaHei (微软雅黑)

#### Linux系统
如缺少中文字体，可安装：
```bash
# Ubuntu/Debian
sudo apt-get install fonts-noto-cjk fonts-wqy-zenhei

# CentOS/RHEL
sudo yum install fonts-chinese fonts-ISO8859-2
```

### 3. 运行示例

#### 基本运行
```bash
python run_evrp.py
```

#### 使用配置文件
```bash
python run_evrp.py --config config.json
```

#### 运行基准测试
```bash
python run_evrp.py --benchmark
```

#### 生成新实例
```bash
python run_evrp.py --generate --customers 20 --stations 5
```

#### 指定问题文件
```bash
python run_evrp.py --problem test_instances/medium_uniform.json
```

## 使用方法

### 1. 快速开始

```python
from evrp_solver import create_sample_problem, EVRPGeneticAlgorithm, EVRPVisualizer

# 创建问题实例
problem = create_sample_problem()

# 创建求解器
ga = EVRPGeneticAlgorithm(
    problem=problem,
    population_size=200,
    max_generations=500
)

# 求解
solution = ga.solve()

# 可视化结果
visualizer = EVRPVisualizer(problem)
visualizer.plot_solution(solution)
```

### 2. 自定义问题

```python
from evrp_solver import EVRPProblem, Customer, ChargingStation, Depot

# 创建问题
problem = EVRPProblem()

# 添加配送中心
problem.add_depot(Depot(id=0, x=50, y=50))

# 添加客户
problem.add_customer(Customer(id=1, x=20, y=80, demand=10))

# 添加充电站
problem.add_charging_station(ChargingStation(id=100, x=30, y=60))

# 设置车辆约束
problem.set_vehicle_constraints(
    capacity=50,
    battery=100,
    consumption_rate=0.5
)
```

### 3. 使用数据生成器

```python
from data_generator import EVRPDataGenerator

generator = EVRPDataGenerator(seed=42)

# 生成随机问题
problem = generator.create_problem_instance(
    num_customers=25,
    num_stations=5,
    customer_distribution='clustered'
)

# 保存实例
generator.save_problem_instance(problem, 'my_instance.json')
```

## 参数说明

### 遗传算法参数
- `population_size`: 种群大小 (默认200)
- `max_generations`: 最大代数 (默认500)
- `crossover_rate`: 交叉率 (默认0.8)
- `mutation_rate`: 变异率 (默认0.1)
- `elite_size`: 精英保留数量 (默认20)

### 问题参数
- `vehicle_capacity`: 车辆载重容量
- `vehicle_battery`: 电池容量
- `consumption_rate`: 单位距离耗电量
- `loading_time`: 装载时间

## 输出结果

运行后会生成以下文件：
- `solution.png`: 路径可视化图
- `convergence.png`: 收敛曲线图
- `solution.json`: 详细解决方案
- `summary.json`: 结果摘要

## 故障排除

### 中文字体显示问题

如果图片中的中文显示为方块或乱码：

1. **检查字体安装**
   ```python
   from font_config import setup_chinese_fonts
   setup_chinese_fonts()
   ```

2. **手动设置字体**
   ```python
   import matplotlib.pyplot as plt
   plt.rcParams['font.sans-serif'] = ['SimHei']  # 或其他可用中文字体
   plt.rcParams['axes.unicode_minus'] = False
   ```

3. **查看可用字体**
   ```python
   import matplotlib.font_manager as fm
   fonts = [f.name for f in fm.fontManager.ttflist if 'Sim' in f.name or 'Hei' in f.name]
   print(fonts)
   ```

### 性能优化

对于大规模问题：
- 减少种群大小
- 降低最大代数
- 使用聚类分布的客户
- 调整交叉和变异率

## 联系信息

如有问题或建议，请联系课题组相关负责人。

## 更新日志

- v1.0: 基础EVRP求解器
- v1.1: 添加中文字体支持
- v1.2: 优化可视化效果