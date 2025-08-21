# EVRP Gurobi求解器使用指南

## 📋 简介

本项目提供了使用Gurobi求解电动车路径规划问题(EVRP)的完整解决方案，与现有的遗传算法求解器使用相同的数据格式，便于比较不同算法的性能。

## 🚀 快速开始

### 1. 运行简单示例

```bash
python gurobi_usage_example.py
```

### 2. 运行完整求解器

```bash
python run_evrp_gurobi.py --mode test --time-limit 120
```

### 3. 运行基准测试

```bash
python run_evrp_gurobi.py --mode benchmark
```

## 📁 文件结构

```
EVRP开发(基于TRAE)/
├── evrp_gurobi_solver.py    # Gurobi求解器核心实现
├── run_evrp_gurobi.py       # 运行脚本（命令行界面）
├── gurobi_usage_example.py  # 使用示例和演示
├── README_GUROBI.md         # 本使用指南
└── 其他现有文件...
```

## 🧮 数学模型

### 决策变量
- **x[i,j,k]**: 二元变量，车辆k是否从节点i到节点j
- **u[i,k]**: 车辆k到达客户i时的载重
- **b[i,k]**: 车辆k到达节点i时的电池电量
- **t[i,k]**: 车辆k到达节点i的时间

### 目标函数
最小化总行驶距离：
```
min Σ(i,j,k) dist[i,j] * x[i,j,k]
```

### 约束条件
1. **客户访问约束**: 每个客户必须被访问一次
2. **流量守恒**: 车辆进出节点平衡
3. **载重约束**: 不超过车辆容量
4. **电池约束**: 电量足够到达下一节点
5. **时间窗约束**: 满足客户时间要求
6. **子回路消除**: 防止无效回路

## 🔧 使用方法

### 方法1：使用数据生成器

```python
from data_generator import EVRPDataGenerator
from evrp_gurobi_solver import solve_evrp_with_gurobi

# 创建数据生成器
generator = EVRPDataGenerator(seed=42)

# 生成问题实例
problem = generator.create_problem_instance(
    num_customers=10,
    num_stations=3,
    map_size=100.0,
    vehicle_capacity=50.0,
    vehicle_battery=100.0,
    consumption_rate=0.8
)

# 使用Gurobi求解
result = solve_evrp_with_gurobi(problem, time_limit=300)
```

### 方法2：手动创建问题

```python
from evrp_solver import EVRPProblem, Customer, ChargingStation, Depot
from evrp_gurobi_solver import EVRPGurobiSolver

# 创建问题实例
problem = EVRPProblem()

# 添加配送中心
problem.add_depot(Depot(id=0, x=50, y=50))

# 添加客户
problem.add_customer(Customer(id=1, x=20, y=30, demand=10, 
                            service_time=5, time_window=(10, 40)))

# 添加充电站
problem.add_charging_station(ChargingStation(id=100, x=35, y=35))

# 设置车辆约束
problem.set_vehicle_constraints(capacity=50, battery=100, consumption_rate=0.8)

# 求解
solver = EVRPGurobiSolver(problem, time_limit=120)
result = solver.solve(max_vehicles=3)
```

### 方法3：命令行使用

```bash
# 基本使用
python run_evrp_gurobi.py

# 指定参数
python run_evrp_gurobi.py --mode test --time-limit 180 --max-vehicles 4

# 运行基准测试
python run_evrp_gurobi.py --mode benchmark

# 自定义配置
python run_evrp_gurobi.py --mode custom --config custom_config.json

# 加载保存的实例
python run_evrp_gurobi.py --mode load --load-instance saved_instance.json
```

## 📊 结果解读

求解结果包含以下信息：

```python
result = {
    'status': 'optimal',           # 求解状态
    'objective_value': 245.67,    # 最优目标值（总距离）
    'solve_time': 45.2,          # 求解时间（秒）
    'gap': 0.0,                  # 相对间隙（0表示最优）
    'solution': {
        'routes': [...],          # 详细路径
        'num_vehicles': 2,       # 使用车辆数
        'total_distance': 245.67 # 总行驶距离
    }
}
```

## ⚖️ 与遗传算法比较

| 特性 | Gurobi精确求解 | 遗传算法 |
|------|----------------|----------|
| **解的质量** | 最优或接近最优 | 近似解 |
| **求解时间** | 指数增长 | 多项式时间 |
| **问题规模** | 小规模(≤15客户) | 大规模(>50客户) |
| **约束处理** | 精确约束 | 惩罚函数 |
| **可扩展性** | 有限 | 良好 |

## 📈 性能建议

### 小规模问题（≤10客户）
- 时间限制：30-120秒
- 可以求得最优解

### 中等规模问题（10-15客户）
- 时间限制：5-10分钟
- 可能得到接近最优解

### 大规模问题（>15客户）
- 建议使用遗传算法
- Gurobi作为基准验证

## 🛠️ 参数调优

### 关键参数
```python
# 时间限制（秒）
time_limit = 300

# 最大车辆数
max_vehicles = None  # 自动计算

# 求解参数优化
model.setParam('MIPGap', 0.05)      # 5%间隙
model.setParam('Threads', 4)        # 使用4线程
model.setParam('Presolve', 2)        # 预求解级别
model.setParam('Cuts', 2)            # 割平面级别
```

## 🐛 常见问题

### 1. 求解时间过长
- 减少客户数量
- 缩短时间限制
- 增加最大车辆数约束

### 2. 内存不足
- 减少问题规模
- 使用更少的线程
- 关闭某些求解特性

### 3. 无可行解
- 检查约束设置
- 增加车辆容量或电池容量
- 放宽时间窗约束

## 🔍 调试技巧

### 检查问题可行性
```python
# 检查基本约束
print(f"总需求: {sum(c.demand for c in problem.customers)}")
print(f"车辆容量: {problem.vehicle_capacity}")
print(f"最小车辆数: {ceil(total_demand / vehicle_capacity)}")
```

### 保存和加载问题实例
```python
# 保存实例
save_problem_instance(problem, 'my_instance.json')

# 加载实例
problem = load_problem_instance('my_instance.json')
```

## 📚 扩展阅读

- [Gurobi官方文档](https://www.gurobi.com/documentation/)
- [VRP数学建模](https://en.wikipedia.org/wiki/Vehicle_routing_problem)
- [电动车路径规划研究综述](https://doi.org/10.1016/j.ejor.2020.09.038)

## 🤝 技术支持

如有问题，请检查：
1. Gurobi许可证是否有效
2. Python环境配置是否正确
3. 数据格式是否符合要求
4. 约束条件是否合理

## 📝 版本历史

- v1.0.0: 初始版本，支持基本EVRP求解
- v1.0.1: 增加时间窗和充电站约束
- v1.0.2: 优化求解性能，增加基准测试