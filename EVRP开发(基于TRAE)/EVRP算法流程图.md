# EVRP遗传算法执行流程图

## 📋 算法整体架构

```mermaid
graph TD
    A[开始] --> B[配置加载]
    B --> C[数据初始化]
    C --> D[遗传算法求解]
    D --> E[结果可视化]
    E --> F[结果保存]
    F --> G[结束]
    
    style A fill:#90EE90
    style G fill:#FFB6C1
```

## 🔧 详细执行流程

### 1. 配置加载阶段
```mermaid
graph LR
    A[run_evrp.py启动] --> B[加载config.py配置]
    B --> C[读取算法参数]
    C --> D[读取问题参数]
    D --> E[读取可视化参数]
    
    style A fill:#E6E6FA
    style B fill:#FFE4B5
```

**配置内容包括：**
- **遗传算法参数**: 种群大小、迭代次数、交叉率、变异率
- **问题参数**: 客户数量、充电站数量、车辆容量、电池容量
- **可视化参数**: 是否保存图片、实时绘图开关

### 2. 数据初始化阶段
```mermaid
graph TD
    A[数据初始化] --> B[选择数据来源]
    B --> C{数据来源类型}
    
    C -->|现有实例| D[直接加载JSON文件]
    C -->|需要生成| E[调用data_generator.py]
    
    E --> F[生成客户坐标]
    E --> G[生成充电站坐标]
    E --> H[生成需求量]
    E --> I[生成时间窗]
    
    D --> J[创建EVRPProblem实例]
    F --> J
    G --> J
    H --> J
    I --> J
    
    style A fill:#E6E6FA
    style J fill:#98FB98
```

### 3. 遗传算法核心流程
```mermaid
graph TD
    A[遗传算法开始] --> B[初始化种群]
    B --> C[评估适应度]
    C --> D{达到最大迭代?}
    D -->|否| E[选择操作]
    E --> F[交叉操作]
    F --> G[变异操作]
    G --> H[修复不可行解]
    H --> I[评估新种群]
    I --> J[记录最优解]
    J --> D
    D -->|是| K[返回最优解]
    
    style A fill:#87CEEB
    style K fill:#90EE90
```

### 4. 染色体编码与解码
```mermaid
graph TD
    A[染色体表示] --> B[路径编码方式]
    B --> C[客户序列编码]
    B --> D[充电站插入策略]
    
    C --> E[示例: [1,2,3,4,5]]
    D --> F[动态插入充电站]
    F --> G[考虑电量约束]
    F --> H[考虑载重约束]
    
    style A fill:#F0E68C
    style E fill:#FFB6C1
```

**编码示例：**
```
原始客户序列: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
考虑充电站后: [1, 2, C1, 3, 4, 5, C2, 6, 7, 8, C1, 9, 10]
其中C1, C2表示充电站
```

### 5. 适应度计算流程
```mermaid
graph TD
    A[适应度计算] --> B[计算总距离]
    A --> C[检查电量约束]
    A --> D[检查载重约束]
    A --> E[检查时间窗约束]
    
    B --> F[距离成本 = Σ距离]
    C --> G[电量惩罚 = 超额电量 × 惩罚系数]
    D --> H[载重惩罚 = 超额载重 × 惩罚系数]
    E --> I[时间窗惩罚 = 延迟时间 × 惩罚系数]
    
    F --> J[总成本 = 距离成本 + 所有惩罚]
    G --> J
    H --> J
    I --> J
    
    J --> K[适应度 = 1/总成本]
    
    style A fill:#FFA07A
    style K fill:#98FB98
```

### 6. 遗传操作详解

#### 6.1 选择操作
```mermaid
graph LR
    A[选择操作] --> B[锦标赛选择]
    B --> C[随机选择k个个体]
    C --> D[选择最优个体]
    D --> E[重复直到选满种群]
    
    style A fill:#DDA0DD
```

#### 6.2 交叉操作
```mermaid
graph TD
    A[交叉操作] --> B{选择交叉方式}
    B -->|顺序交叉| C[Order Crossover]
    B -->|部分匹配交叉| D[PMX Crossover]
    
    C --> E[保留父代顺序]
    D --> F[交换基因片段]
    
    style A fill:#DDA0DD
```

#### 6.3 变异操作
```mermaid
graph LR
    A[变异操作] --> B[交换变异]
    A --> C[插入变异]
    A --> D[反转变异]
    
    B --> E[交换两个客户位置]
    C --> F[移动客户到新位置]
    D --> G[反转子序列]
    
    style A fill:#DDA0DD
```

### 7. 约束处理机制
```mermaid
graph TD
    A[约束检查] --> B[电量检查]
    A --> C[载重检查]
    A --> D[时间窗检查]
    
    B --> E{电量不足?}
    E -->|是| F[插入最近充电站]
    E -->|否| G[继续检查]
    
    C --> H{超载?}
    H -->|是| I[分割路线]
    H -->|否| J[继续检查]
    
    D --> K{超时?}
    K -->|是| L[调整出发时间]
    K -->|否| M[通过检查]
    
    style A fill:#FFB6C1
```

### 8. 可视化输出流程
```mermaid
graph TD
    A[可视化开始] --> B[创建图形]
    B --> C[绘制地图基础]
    C --> D[绘制客户点]
    C --> E[绘制充电站]
    C --> F[绘制配送中心]
    
    F --> G[绘制路径]
    G --> H[添加标签]
    H --> I[设置标题]
    I --> J[保存图片]
    
    style A fill:#87CEFA
    style J fill:#90EE90
```

## 📊 数据流动图

```mermaid
graph TD
    A[原始数据] --> B[客户坐标]
    A --> C[充电站坐标]
    A --> D[需求量]
    A --> E[时间窗]
    
    B --> F[EVRPProblem类]
    C --> F
    D --> F
    E --> F
    
    F --> G[遗传算法]
    G --> H[种群初始化]
    H --> I[适应度评估]
    I --> J[遗传操作]
    J --> K[新种群]
    K --> L[最优解]
    
    L --> M[可视化输出]
    M --> N[solution.png]
    M --> O[convergence.png]
    
    style A fill:#F5F5DC
    style L fill:#90EE90
    style N fill:#FFB6C1
```

## 🎯 关键类关系图

```mermaid
classDiagram
    class EVRPProblem {
        +customers: List[Customer]
        +charging_stations: List[ChargingStation]
        +depot: Depot
        +vehicle_capacity: float
        +battery_capacity: float
        +calculate_distance()
        +is_feasible()
    }
    
    class GeneticAlgorithm {
        +population_size: int
        +max_generations: int
        +crossover_rate: float
        +mutation_rate: float
        +evolve()
        +select()
        +crossover()
        +mutate()
    }
    
    class EVRPVisualizer {
        +plot_solution()
        +plot_convergence()
        +save_plots()
    }
    
    class Route {
        +customers: List[int]
        +total_distance: float
        +total_load: float
        +battery_level: float
        +calculate_cost()
    }
    
    EVRPProblem --> GeneticAlgorithm : 提供问题数据
    GeneticAlgorithm --> Route : 生成路径
    Route --> EVRPVisualizer : 可视化展示
```

## 🚀 快速开始指南

### 步骤1: 运行测试
```bash
# 生成测试实例
python run_evrp.py --generate --customers 10 --stations 3

# 运行算法
python run_evrp.py --problem results/evrp_10c_3s_uniform.json
```

### 步骤2: 查看结果
- 查看 `results/` 目录下的图片文件
- 检查 `solution.png` 查看路径规划
- 检查 `convergence.png` 查看算法收敛

### 步骤3: 理解输出
- **配送中心**: 红色星号标记
- **客户点**: 蓝色圆点标记
- **充电站**: 绿色三角形标记
- **路径**: 彩色线条表示不同车辆的路径

## 📈 算法性能指标

### 评估标准
1. **总行驶距离**: 所有车辆路径长度之和
2. **车辆利用率**: 实际载重/最大载重
3. **电池利用率**: 实际用电量/电池容量
4. **客户满意度**: 按时送达率

### 收敛指标
1. **最优成本**: 每代的最优解成本
2. **平均成本**: 种群的平均成本
3. **收敛速度**: 达到稳定解的迭代次数