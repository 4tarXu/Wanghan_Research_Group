# Python代码结构详解 - 面向EVRP算法

## 🎯 写给不熟悉Python的您

本文档专门为不熟悉Python的您编写，用最直观的方式解释代码结构。把Python想象成一个工具箱，每个部分都有特定的用途。

## 📦 核心概念：从工具箱角度理解

### 1. 变量 = 储物盒
```python
# 就像给盒子贴标签
box_name = "EVRP问题"        # 文字标签
box_number = 10             # 数字标签  
box_list = [1, 2, 3, 4, 5]  # 列表标签（可以放多个东西）
```

### 2. 函数(def) = 工具说明书
```python
def 计算两点距离(点1, 点2):
    """就像说明书：输入两个点，输出距离"""
    距离 = ((点1.x - 点2.x)**2 + (点1.y - 点2.y)**2)**0.5
    return 距离  # 返回计算结果

# 使用这个工具
距离1 = 计算两点距离(客户A, 客户B)
```

### 3. 类(class) = 工具模板工厂
```python
class 客户类:  # 就像生产客户的工厂模板
    def __init__(self, 编号, x坐标, y坐标, 需求量):
        # 生产时给每个客户贴标签
        self.编号 = 编号
        self.x坐标 = x坐标
        self.y坐标 = y坐标
        self.需求量 = 需求量
    
    def 显示位置(self):
        return f"客户{self.编号}在({self.x坐标}, {self.y坐标})"

# 用模板生产具体客户
客户1 = 客户类(1, 100, 200, 50)
客户2 = 客户类(2, 300, 400, 30)
```

## 🔍 EVRP代码结构逐层解析

### 📁 文件结构地图
```
EVRP项目/
├── 📄 evrp_solver.py          # 主算法引擎
├── 📄 config.py               # 配置管理
├── 📄 data_generator.py       # 数据工厂
├── 📄 run_evrp.py             # 启动器
└── 📄 font_config.py          # 字体配置
```

## 🏗️ 详细代码结构分析

### 1. evrp_solver.py - 核心算法引擎

#### 1.1 类结构总览
```python
# 就像一个大工厂，里面有多个车间
class EVRPProblem:      # 车间1：问题定义
class Route:            # 车间2：路径计算  
class GeneticAlgorithm: # 车间3：遗传算法
class EVRPVisualizer:   # 车间4：可视化
```

#### 1.2 EVRPProblem类 - 问题定义车间
```python
class EVRPProblem:
    """
    这个类就像一个"问题描述表"
    它告诉程序：我们要解决什么样的问题
    """
    
    def __init__(self, customers, stations, depot):
        # __init__是"初始化方法"，就像填写表格的第一页
        # 参数说明：
        # customers: 客户列表 [客户1, 客户2, ...]
        # stations: 充电站列表 [充电站1, 充电站2, ...]  
        # depot: 配送中心位置
        
        self.customers = customers        # 保存客户信息
        self.charging_stations = stations # 保存充电站信息
        self.depot = depot                # 保存配送中心位置
        
    def calculate_distance(self, point1, point2):
        # 这是一个工具函数，专门计算两点间距离
        # 就像尺子，输入两个点，返回距离
        return ((point1.x - point2.x)**2 + (point1.y - point2.y)**2)**0.5
        
    def is_feasible(self, route):
        # 检查一条路径是否可行
        # 就像质检员，检查路线是否符合所有要求
        return True/False
```

#### 1.3 Route类 - 路径计算车间
```python
class Route:
    """
    这个类就像一张"送货路线图"
    它记录：从哪出发 → 经过哪些客户 → 到哪里结束
    """
    
    def __init__(self, customers_sequence):
        # customers_sequence: 客户访问顺序 [客户3, 客户1, 客户5, ...]
        self.customers = customers_sequence  # 保存访问顺序
        self.total_distance = 0              # 总距离（初始为0）
        self.total_load = 0                  # 总载重
        self.battery_level = 100             # 电池电量（假设满电）
        
    def calculate_total_distance(self, problem):
        # 计算这条路径的总距离
        # 就像用尺子量整条路线的长度
        distance = 0
        for i in range(len(self.customers) - 1):
            distance += problem.calculate_distance(
                self.customers[i], self.customers[i+1]
            )
        self.total_distance = distance
        return distance
```

#### 1.4 GeneticAlgorithm类 - 遗传算法车间
```python
class GeneticAlgorithm:
    """
    这个类就像一个"进化工厂"
    它负责：生成初始路线 → 评估好坏 → 改进路线 → 找到最优解
    """
    
    def __init__(self, problem, population_size=100):
        # 初始化进化工厂
        # problem: 要解决的问题
        # population_size: 同时处理多少条路线（种群大小）
        
        self.problem = problem
        self.population_size = population_size
        self.population = []  # 存放当前所有路线
        
    def initialize_population(self):
        # 生成初始路线群
        # 就像随机生成很多送货方案
        for i in range(self.population_size):
            route = self.create_random_route()
            self.population.append(route)
    
    def evolve(self, generations=100):
        # 进化过程，重复多代
        for generation in range(generations):
            self.evaluate_population()    # 评估当前路线
            self.select_parents()         # 选择好的路线
            self.crossover()              # 交叉产生新路线
            self.mutate()                 # 变异增加多样性
            
    def create_random_route(self):
        # 工具函数：生成一条随机路线
        import random
        customers = self.problem.customers.copy()
        random.shuffle(customers)
        return Route(customers)
```

### 2. config.py - 配置管理

#### 2.1 配置类结构
```python
from dataclasses import dataclass

@dataclass  # 这是一个装饰器，自动生成__init__方法
class GAConfig:
    """
    就像"算法设置表"
    记录：种群多大？迭代多少次？交叉率多少？
    """
    population_size: int = 100    # 种群大小
    max_generations: int = 500    # 最大迭代次数
    crossover_rate: float = 0.8   # 交叉率（80%）
    mutation_rate: float = 0.1    # 变异率（10%）
    elite_size: int = 20          # 保留优秀个体数量

@dataclass  
class ProblemConfig:
    """
    就像"问题设置表"
    记录：多少客户？多少充电站？车辆容量多大？
    """
    num_customers: int = 10       # 客户数量
    num_stations: int = 3         # 充电站数量
    vehicle_capacity: float = 50.0  # 车辆载重
    battery_capacity: float = 100.0 # 电池容量
```

### 3. data_generator.py - 数据工厂

#### 3.1 数据生成器类
```python
class EVRPDataGenerator:
    """
    这个类就像一个"数据制造工厂"
    专门生产：客户坐标、充电站坐标、需求量等数据
    """
    
    def __init__(self):
        # 初始化工厂
        pass
    
    def generate_customers(self, num_customers, map_size=100):
        # 制造客户数据
        # 就像随机在地图上撒客户点
        customers = []
        for i in range(num_customers):
            x = random.uniform(0, map_size)
            y = random.uniform(0, map_size)
            demand = random.uniform(10, 50)  # 随机需求量
            customers.append(Customer(i, x, y, demand))
        return customers
    
    def generate_stations(self, num_stations, map_size=100):
        # 制造充电站数据
        stations = []
        for i in range(num_stations):
            x = random.uniform(0, map_size)
            y = random.uniform(0, map_size)
            stations.append(ChargingStation(i, x, y))
        return stations
```

### 4. run_evrp.py - 启动器

#### 4.1 主函数结构
```python
def main():
    """
    就像"总控制台"
    负责：读取配置 → 生成数据 → 启动算法 → 显示结果
    """
    
    # 1. 读取配置（就像看说明书）
    config = load_config()
    
    # 2. 生成问题数据（就像准备原材料）
    generator = EVRPDataGenerator()
    customers = generator.generate_customers(config.num_customers)
    stations = generator.generate_stations(config.num_stations)
    
    # 3. 创建问题实例（就像组装问题）
    problem = EVRPProblem(customers, stations, depot=(50, 50))
    
    # 4. 启动遗传算法（就像启动工厂）
    ga = GeneticAlgorithm(problem, config.population_size)
    ga.evolve(config.max_generations)
    
    # 5. 显示结果（就像展示成品）
    visualizer = EVRPVisualizer()
    visualizer.plot_solution(ga.best_solution)

# 程序入口
if __name__ == "__main__":
    main()
```

## 🔄 类与函数调用关系图

### 调用链条示例
```
run_evrp.py(main)
    ↓
data_generator.py(生成数据) → EVRPProblem(定义问题)
    ↓
GeneticAlgorithm(解决算法) → Route(具体路线)
    ↓
EVRPVisualizer(展示结果)
```

### 实际调用流程（像打电话一样）
```python
# 1. 启动程序（拨号）
python run_evrp.py

# 2. main函数接电话
main():
    # 3. 创建数据生成器（找帮手）
    generator = EVRPDataGenerator()
    
    # 4. 生成客户（让帮手干活）
    customers = generator.generate_customers(10)
    
    # 5. 创建问题（定义任务）
    problem = EVRPProblem(customers, stations, depot)
    
    # 6. 创建算法（找专家）
    ga = GeneticAlgorithm(problem)
    
    # 7. 启动算法（专家开始工作）
    ga.evolve()
    
    # 8. 展示结果（公布答案）
    visualizer.plot_solution()
```

## 🎯 学习建议：从简单到复杂

### 阶段1：理解单个函数（今天）
- 重点理解def的作用：创建工具
- 理解参数：工具的输入
- 理解return：工具的输出

### 阶段2：理解类的作用（明天）
- 把类想象成"模板工厂"
- __init__就是"生产说明书"
- self就是"每个产品的标签"

### 阶段3：理解调用关系（后天）
- 像打电话一样理解函数调用
- 像组装产品一样理解类实例化
- 像流水线一样理解程序流程

## 📞 记忆口诀

**def口诀**：
"def定义工具箱，参数输入像门窗，return返回好结果"

**class口诀**：
"class像工厂，__init__是说明书，self是身份证"

**调用口诀**：
"创建实例像生产，点方法像下指令，传参数像给原料"

## 🚀 快速上手练习

### 练习1：创建第一个函数
```python
def 打招呼(名字):
    return f"你好，{名字}！"

结果 = 打招呼("小明")
print(结果)  # 输出：你好，小明！
```

### 练习2：创建第一个类
```python
class 学生:
    def __init__(self, 姓名, 年龄):
        self.姓名 = 姓名
        self.年龄 = 年龄
    
    def 自我介绍(self):
        return f"我是{self.姓名}，今年{self.年龄}岁"

学生1 = 学生("张三", 20)
print(学生1.自我介绍())  # 输出：我是张三，今年20岁
```

记住：**代码就是工具，函数就是说明书，类就是工厂模板！**