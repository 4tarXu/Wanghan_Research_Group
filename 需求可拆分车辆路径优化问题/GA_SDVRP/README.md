# SDVRP_MTZ_gurobi：基于YALMIP和GUROBI的需求可拆分车辆路径问题求解器

## 1. 简介

本代码实现了一种基于数学规划的方法，使用YALMIP优化建模工具和GUROBI求解器来求解需求可拆分车辆路径问题（Split Delivery Vehicle Routing Problem, SDVRP）。与传统的启发式算法（如仓库中的遗传算法代码）不同，本方法通过精确数学模型确保找到最优解。

## 2. 问题描述

需求可拆分车辆路径问题（SDVRP）是经典车辆路径问题（VRP）的一个重要变种。在传统VRP中，每个客户点的需求必须由一辆车辆一次性满足，而在SDVRP中，允许将单个客户的需求拆分成多个部分，由不同的车辆分别配送。这一特性使得SDVRP在实际应用中具有更大的灵活性和成本节约潜力。

### 问题特点：

- 允许将单个客户的需求分配给多辆车
- 每辆车有固定的容量限制
- 每辆车从配送中心出发，完成配送任务后返回配送中心
- 目标是最小化所有车辆的总行驶距离

## 3. 数学模型

### 3.1 符号定义

- **集合**

  - $V = \{1, 2, ..., n\}$：所有节点集合，其中1表示配送中心，$C = \{2, 3, ..., n\}$表示客户点集合
  - $K$：车辆集合
- **参数**

  - $d_i$：客户点$i$的需求量
  - $Q$：车辆的最大载重容量
  - $c_{ij}$：从节点$i$到节点$j$的运输距离
- **决策变量**

  - $x_{ijk} \in \{0,1\}$：二进制变量，若车辆$k$从节点$i$直接前往节点$j$，则为1，否则为0
  - $U_{ik}$：车辆$k$在客户点$i$的卸货量
  - $L_{ik}$：车辆$k$离开节点$i$时的载货量
  - $A_{ik}$：车辆$k$到达节点$i$时的载货量

### 3.2 目标函数

最小化总运输距离：

$
\min \sum_{k \in K} \sum_{i \in V} \sum_{j \in V} c_{ij} x_{ijk}
$

### 3.3 约束条件

1. **客户服务约束**：每个客户至少被一辆车服务一次，最多被2辆车服务

   $\sum_{j \in V} \sum_{k \in K} x_{ijk} \geq 1, \quad \forall i \in C$

   $
   \sum_{j \in V} \sum_{k \in K} x_{ijk} \leq 2, \quad \forall i \in C
   $
2. **车辆访问约束**：同一辆车对同一客户点最多访问一次

   $
   \sum_{j \in V} x_{ijk} \leq 1, \quad \forall i \in C, \forall k \in K
   $
3. **流量守恒约束**：确保每辆车从配送中心出发并最终返回配送中心

   $
   \sum_{i \in V} x_{ijk} = \sum_{i \in V} x_{jik}, \quad \forall j \in C, \forall k \in K
   $
4. **车辆出发和返回约束**：每辆车从配送中心出发并返回

   $
   \sum_{j \in V} x_{1jk} \leq 1, \quad \forall k \in K
   $

   $
   \sum_{j \in V} x_{j1k} \leq 1, \quad \forall k \in K
   $
5. **卸货量约束**：车辆在客户点的卸货量非负且与路径相关

   $
   U_{ik} \geq 0, \quad \forall i \in C, \forall k \in K
   $

   $
   U_{ik} \leq Q \cdot \sum_{j \in V} x_{ijk}, \quad \forall i \in C, \forall k \in K
   $
6. **车辆容量约束**：每辆车的总卸货量不能超过其容量

   $
   \sum_{i \in C} U_{ik} \leq Q, \quad \forall k \in K
   $
7. **需求满足约束**：每个客户的需求必须被完全满足

   $
   \sum_{k \in K} U_{ik} = d_i, \quad \forall i \in C
   $
8. **载货量约束**：车辆到达和离开节点时的载货量非负且与路径相关

   $
   L_{ik} \geq 0, \quad \forall i \in V, \forall k \in K
   $

   $
   L_{ik} \leq Q \cdot \sum_{j \in V} x_{ijk}, \quad \forall i \in V, \forall k \in K
   $

   $
   A_{ik} \geq 0, \quad \forall i \in V, \forall k \in K
   $

   $
   A_{ik} \leq Q \cdot \sum_{j \in V} x_{ijk}, \quad \forall i \in V, \forall k \in K
   $
9. **载货量连续性约束**：运输弧上载货量不变

   $
   -Q \cdot (1 - x_{ijk}) \leq L_{ik} - A_{jk} \leq Q \cdot (1 - x_{ijk}), \quad \forall i,j \in V, \forall k \in K
   $
10. **货物守恒约束**：到达客户点后的载货量减去卸货量等于离开时的载货量

    $
    A_{ik} - U_{ik} = L_{ik}, \quad \forall i \in C, \forall k \in K
    $

## 4. YALMIP与GUROBI调用

### 4.1 YALMIP简介

YALMIP是一个用于MATLAB的建模语言，允许用户以高级语法描述优化问题，并自动调用适当的求解器来求解这些问题。

### 4.2 关键代码解析

1. **变量声明**：

   ```matlab
   Xijk = binvar(CityNum, CityNum, VehicleNum, 'full'); % 三维路径变量 x(i,j,k)
   Mu = sdpvar(CustomerNum, VehicleNum); % MTZ辅助变量 u(i,k)
   Uik = sdpvar(CityNum,VehicleNum); % 车辆k在节点i的卸货量
   Lik = sdpvar(CityNum,VehicleNum); % 车辆k离开节点i时的载货量
   Aik = sdpvar(CityNum,VehicleNum); % 车辆k到达节点i时的载货量
   ```
2. **目标函数构建**：

   ```matlab
   objective = 0;
   for k = 1:VehicleNum
       objective = objective + sum(sum(Distance .* Xijk(:,:,k)));
   end
   ```
3. **约束条件添加**：

   ```matlab
   constraints = [];
   % 添加各类约束...
   ```
4. **求解器设置与调用**：

   ```matlab
   ops = sdpsettings('verbose', 1, 'solver', 'gurobi');
   ops.gurobi.TuneTimeLimit = 300;    % 设置5分钟调参时间
   ops.gurobi.TimeLimit = 600;       % 求解时间限制
   sol = optimize(constraints, objective, ops);
   ```
5. **结果提取与分析**：

   ```matlab
   if sol.problem ~= 0
       % 提取解
       x_val = value(Xijk);
       u_val = value(Mu);
       % 输出结果...
   end
   ```

## 5. 求解参数设置

### 5.1 主要参数说明

| 参数名称      | 说明               | 默认值              | 调整建议                                   |
| ------------- | ------------------ | ------------------- | ------------------------------------------ |
| VehicleNum    | 车辆数量           | 8                   | 根据实际问题规模调整，过多会增加计算复杂度 |
| TuneTimeLimit | GUROBI调参时间(秒) | 300 (5分钟)         | 对于复杂问题可适当增加                     |
| TimeLimit     | 求解时间限制(秒)   | 600 (10分钟)        | 对于大规模问题可适当延长                   |
| Capacity      | 车辆容量           | 从Capacity.mat加载  | 根据实际车辆情况设置                       |
| Travelcon     | 行程约束           | 从Travelcon.mat加载 | 根据车辆续航里程设置                       |

### 5.2 数据文件说明

代码依赖以下数据文件：

- `City.mat`：需求点经纬度，用于画实际路径的XY坐标
- `Distance.mat`：距离矩阵
- `Demand.mat`：客户需求量
- `Capacity.mat`：车辆容量约束
- `Travelcon.mat`：行程约束

这些文件应放置在 `../test_data/`目录下。

## 6. 使用方法

1. 确保已安装MATLAB、YALMIP和GUROBI求解器
2. 准备好所需的数据文件，并放置在正确的目录下
3. 打开MATLAB，导航到代码所在目录
4. 运行 `SDVRP_MTZ_gurobi.m`文件
5. 查看求解结果，包括总距离和每辆车的路径

## 7. 输出结果解释

代码运行成功后，将输出以下结果：

- 总距离：所有车辆行驶的总距离
- 每辆车的路径：每辆车服务的客户点顺序和路线

例如：

```
求解成功！
总距离：125.67
车辆1的路径：[1, 3, 5, 1]
车辆2的路径：[1, 2, 4, 1]
车辆3的路径：未使用
...
```

## 8. 注意事项

1. 求解大规模问题时，可能需要较长时间，请耐心等待
2. 若求解失败，代码会显示失败信息，可根据提示调整参数或检查数据
3. 本代码假设每个客户最多由2辆车服务，如需调整，请修改约束条件1中的上界
4. 使用GUROBI求解器需要有效的许可证

## 9. 代码结构说明

| 函数/部分      | 说明                         |
| -------------- | ---------------------------- |
| 数据加载部分   | 加载问题所需的各类数据       |
| 参数设置部分   | 定义问题规模、车辆数量等参数 |
| 变量声明部分   | 使用YALMIP声明优化变量       |
| 目标函数构建   | 最小化总行驶距离             |
| 约束条件添加   | 添加所有问题约束             |
| 求解器设置     | 设置GUROBI求解器参数         |
| 求解与结果分析 | 调用求解器并处理结果         |
| find_path函数  | 辅助函数，从解矩阵中提取路径 |

## 10. 参考文献
