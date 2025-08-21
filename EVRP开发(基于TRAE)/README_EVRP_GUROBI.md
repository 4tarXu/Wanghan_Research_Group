# EVRP Gurobi求解器使用指南

## 🎯 项目概述

本项目提供了使用Gurobi求解电动车路径规划问题(EVRP)的精确求解器，与之前开发的遗传算法使用相同的算例和数据格式。

## 📁 文件结构

```
EVRP开发(基于TRAE)/
├── evrp_gurobi_simple_final.py    # 最终工作版本
├── simple_vrp_gurobi.py          # 简化VRP求解器
├── evrp_solver.py               # 遗传算法求解器（参考）
├── data_generator.py            # 数据生成器
└── README_EVRP_GUROBI.md        # 本使用指南
```

## 🚀 快速开始

### 1. 运行最终版本

```bash
python3 evrp_gurobi_simple_final.py
```

### 2. 创建自定义问题

```python
from evrp_gurobi_simple_final import SimpleEVRPGurobiSolver
from data_generator import EVRPDataGenerator

# 创建数据生成器
generator = EVRPDataGenerator(seed=42)

# 创建问题实例
problem = generator.create_problem_instance(
    num_customers=10,
    num_stations=2,
    map_size=100,
    customer_distribution='uniform',
    station_distribution='strategic',
    vehicle_capacity=35.0,
    vehicle_battery=100.0,
    consumption_rate=1.0
)

# 求解
solver = SimpleEVRPGurobiSolver(problem, time_limit=60)
result = solver.solve()
```

## 📊 与遗传算法比较

| 特性 | Gurobi精确求解 | 遗传算法 |
|------|----------------|----------|
| **解质量** | 最优解 | 近似解 |
| **计算时间** | 指数时间（大规模慢） | 多项式时间 |
| **问题规模** | ≤15客户（可行） | 100+客户 |
| **约束处理** | 精确满足 | 近似满足 |
| **内存使用** | 高 | 中等 |

## 🔧 参数配置

### 问题参数
- `num_customers`: 客户数量（建议≤15）
- `num_stations`: 充电站数量
- `vehicle_capacity`: 车辆载重容量
- `vehicle_battery`: 电池容量
- `consumption_rate`: 耗电率
- `map_size`: 地图大小

### 求解器参数
- `time_limit`: 求解时间限制（秒）
- 默认：60秒

## 📈 性能建议

### 小规模问题（≤10客户）
- 使用精确求解器获得最优解
- 时间限制：30-60秒
- 内存使用：低

### 中规模问题（10-20客户）
- 增加时间限制：120-300秒
- 监控内存使用
- 考虑使用遗传算法

### 大规模问题（>20客户）
- 建议使用遗传算法
- 或分解为多个子问题

## 🔍 结果解读

### 成功求解
```
✅ 找到最优解
总距离: 320.39
求解时间: 0.17秒

使用车辆: 3
路径 1: 配送中心 → 客户2 → 客户8 → 配送中心
路径 2: 配送中心 → 客户7 → 客户5 → 配送中心
路径 3: 配送中心 → 客户3 → 客户6 → 客户1 → 客户4 → 配送中心
```

### 求解状态
- `optimal`: 找到最优解
- `time_limit`: 时间限制内找到解
- `infeasible`: 无可行解（检查约束）

## ⚡ 使用示例

### 示例1：小规模测试
```python
# 创建小规模问题
problem = create_small_problem()
solver = SimpleEVRPGurobiSolver(problem, time_limit=30)
result = solver.solve()
```

### 示例2：与遗传算法相同算例
```python
# 创建与遗传算法相同的算例
problem = create_same_as_genetic()
solver = SimpleEVRPGurobiSolver(problem, time_limit=60)
result = solver.solve()
```

### 示例3：自定义问题
```python
# 手动创建问题
problem = EVRPProblem()
problem.add_depot(Depot(id=0, x=50, y=50))
problem.add_customer(Customer(id=1, x=60, y=60, demand=10))
# ... 添加更多客户和充电站
problem.set_vehicle_constraints(capacity=50, battery=100, consumption_rate=1.0)

solver = SimpleEVRPGurobiSolver(problem, time_limit=60)
result = solver.solve()
```

## 🎯 最佳实践

1. **小规模验证**：先用5-8客户测试
2. **逐步扩展**：成功后逐步增加客户数量
3. **参数调优**：调整车辆容量和电池容量
4. **时间控制**：设置合理的时间限制
5. **结果验证**：检查路径可行性

## 📋 常见问题

### Q: 为什么求解器显示"无可行解"？
A: 可能原因：
- 车辆容量不足
- 电池容量限制过严
- 客户需求总和超过总容量

### Q: 如何提高求解速度？
A: 建议：
- 减少客户数量
- 降低时间限制
- 简化约束条件

### Q: 如何与遗传算法结果比较？
A: 使用相同的随机种子创建相同的问题实例，然后比较：
- 总距离
- 使用车辆数
- 计算时间

## 🔗 相关文件

- `evrp_solver.py`: 遗传算法参考实现
- `data_generator.py`: 数据生成工具
- `simple_vrp_gurobi.py`: 简化VRP实现

## 🎉 总结

EVRP Gurobi求解器提供了：
- ✅ 与遗传算法相同的算例支持
- ✅ 精确的数学优化
- ✅ 小规模问题的最优解
- ✅ 与现有代码的完全兼容
- ✅ 清晰的结果输出

使用建议：
- 小规模问题（≤10客户）→ 使用Gurobi精确求解
- 大规模问题（>10客户）→ 使用遗传算法
- 需要验证最优性时→ 用Gurobi求解小规模实例作为基准