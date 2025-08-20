#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
EVRP代码示例演示 - 用最简单的方式展示Python结构

这个文件专门为您设计，每个概念都有中文注释和实际例子
运行方式：python 代码示例演示.py
"""

# 设置中文字体
import matplotlib.pyplot as plt
plt.rcParams['font.sans-serif'] = ['SimHei']  # 用来正常显示中文标签
plt.rcParams['axes.unicode_minus'] = False   # 用来正常显示负号

print("=" * 50)
print("🎯 开始Python代码结构演示")
print("=" * 50)

# 🟢 第一部分：变量 - 就像储物盒
print("\n📦 第一部分：变量（储物盒）")
print("-" * 30)

# 创建变量就像给盒子贴标签
客户数量 = 10
充电站数量 = 3
地图大小 = 100

# 列表变量 - 可以放多个东西的盒子
客户列表 = ["客户1", "客户2", "客户3"]
坐标列表 = [(10, 20), (30, 40), (50, 60)]

print(f"客户数量盒子里的值：{客户数量}")
print(f"客户列表盒子里的值：{客户列表}")

# 🟢 第二部分：函数(def) - 就像工具说明书
print("\n🔧 第二部分：函数（工具说明书）")
print("-" * 30)

def 计算两点距离(点1, 点2):
    """
    这个函数就像一把尺子
    输入：两个点的坐标 (x1, y1) 和 (x2, y2)
    输出：两点间的直线距离
    """
    x1, y1 = 点1
    x2, y2 = 点2
    距离 = ((x2 - x1) ** 2 + (y2 - y1) ** 2) ** 0.5
    return 距离  # return就像把结果交给你

# 使用这个工具（就像按照说明书使用尺子）
距离1 = 计算两点距离((0, 0), (3, 4))
距离2 = 计算两点距离((10, 20), (40, 50))

print(f"(0,0)到(3,4)的距离：{距离1}")
print(f"(10,20)到(40,50)的距离：{距离2}")

def 生成客户数据(数量, 地图范围):
    """
    这个函数就像客户生成器
    输入：要生成多少个客户，地图多大
    输出：客户列表
    """
    import random
    客户们 = []
    for i in range(数量):
        x = random.uniform(0, 地图范围)
        y = random.uniform(0, 地图范围)
        需求 = random.randint(10, 50)
        客户们.append({"编号": i+1, "x": x, "y": y, "需求": 需求})
    return 客户们

# 使用客户生成器
新客户们 = 生成客户数据(3, 100)
print(f"生成的3个客户：{新客户们}")

# 🟢 第三部分：类(class) - 就像工厂模板
print("\n🏭 第三部分：类（工厂模板）")
print("-" * 30)

class 客户类:
    """
    这个类就像"客户制造工厂"的模板
    每次使用这个模板，就能生产一个具体的客户
    """
    
    def __init__(self, 编号, x, y, 需求量):
        """
        __init__就像生产说明书
        每次创建客户时，都要按照这个说明书来
        """
        # self就像给每个产品贴的标签
        self.编号 = 编号
        self.x坐标 = x
        self.y坐标 = y
        self.需求量 = 需求量
        
    def 获取位置(self):
        """
        这是客户类的一个功能
        就像产品说明书里的一个功能介绍
        """
        return (self.x坐标, self.y坐标)
    
    def 显示信息(self):
        """
        这是客户类的另一个功能
        """
        return f"客户{self.编号}在({self.x坐标:.1f}, {self.y坐标:.1f})，需求{self.需求量}"

# 使用工厂模板生产具体客户（就像用模板制造产品）
客户A = 客户类(1, 10.5, 20.3, 25)
客户B = 客户类(2, 35.7, 45.2, 30)

print(f"客户A的信息：{客户A.显示信息()}")
print(f"客户B的位置：{客户B.获取位置()}")

class 路线类:
    """
    这个类就像"路线规划器"的模板
    用来记录一条完整的送货路线
    """
    
    def __init__(self, 客户顺序):
        """
        初始化路线
        客户顺序：比如[客户1, 客户3, 客户2]表示访问顺序
        """
        self.客户顺序 = 客户顺序
        self.总距离 = 0
        
    def 计算路线长度(self):
        """
        计算这条路线的总长度
        """
        总长度 = 0
        # 计算每两个连续客户间的距离
        for i in range(len(self.客户顺序) - 1):
            客户1 = self.客户顺序[i]
            客户2 = self.客户顺序[i+1]
            距离 = 计算两点距离(客户1.获取位置(), 客户2.获取位置())
            总长度 += 距离
        self.总距离 = 总长度
        return 总长度
    
    def 显示路线(self):
        """
        以文字形式显示路线
        """
        路线描述 = "路线："
        for 客户 in self.客户顺序:
            路线描述 += f"客户{客户.编号} → "
        路线描述 += f"总距离：{self.总距离:.2f}"
        return 路线描述

# 创建一条具体路线
路线1 = 路线类([客户A, 客户B])
距离 = 路线1.计算路线长度()
print(f"路线1的信息：{路线1.显示路线()}")

# 🟢 第四部分：综合应用 - 模拟EVRP
print("\n🚚 第四部分：综合应用（模拟EVRP）")
print("-" * 30)

class 简单EVRP:
    """
    简化版的EVRP问题
    展示各个部分如何协同工作
    """
    
    def __init__(self, 客户数量, 地图大小):
        """
        初始化EVRP问题
        """
        self.客户们 = []
        self.地图大小 = 地图大小
        
        # 生成客户
        for i in range(客户数量):
            x = 10 + i * 20  # 均匀分布
            y = 20 + i * 15
            需求 = 20 + i * 5
            客户 = 客户类(i+1, x, y, 需求)
            self.客户们.append(客户)
    
    def 创建随机路线(self):
        """
        创建一条随机访问路线
        """
        import random
        随机客户 = self.客户们.copy()
        random.shuffle(随机客户)  # 打乱顺序
        return 路线类(随机客户)
    
    def 求解(self):
        """
        简单的求解过程：尝试多条随机路线，选最好的
        """
        print("开始寻找最优路线...")
        
        最佳路线 = None
        最短距离 = float('inf')
        
        # 尝试10条随机路线
        for 尝试次数 in range(10):
            路线 = self.创建随机路线()
            距离 = 路线.计算路线长度()
            
            if 距离 < 最短距离:
                最短距离 = 距离
                最佳路线 = 路线
                print(f"找到更好路线：距离{距离:.2f}")
        
        return 最佳路线

# 运行完整的EVRP示例
print("\n🔍 运行完整示例：")
print("创建EVRP问题...")
evrp = 简单EVRP(5, 100)

print("\n生成的客户：")
for 客户 in evrp.客户们:
    print(f"  {客户.显示信息()}")

print("\n开始求解...")
最优路线 = evrp.求解()
print(f"\n🎯 最优路线：{最优路线.显示路线()}")

# 🟢 第五部分：可视化演示
print("\n📊 第五部分：可视化演示")
print("-" * 30)

def 简单可视化(客户列表, 路线):
    """
    简单的可视化函数
    """
    fig, ax = plt.subplots(figsize=(10, 8))
    
    # 绘制客户点
    x_coords = [客户.x坐标 for 客户 in 客户列表]
    y_coords = [客户.y坐标 for 客户 in 客户列表]
    
    ax.scatter(x_coords, y_coords, c='blue', s=100, label='客户')
    
    # 标注客户编号
    for 客户 in 客户列表:
        ax.annotate(f"客户{客户.编号}", 
                   (客户.x坐标, 客户.y坐标),
                   xytext=(5, 5), textcoords='offset points')
    
    # 绘制路线
    if 路线:
        route_x = [客户.x坐标 for 客户 in 路线.客户顺序]
        route_y = [客户.y坐标 for 客户 in 路线.客户顺序]
        ax.plot(route_x, route_y, 'r--', linewidth=2, label='路线')
    
    ax.set_xlabel('X坐标')
    ax.set_ylabel('Y坐标')
    ax.set_title('EVRP路线可视化')
    ax.legend()
    ax.grid(True)
    
    plt.tight_layout()
    plt.savefig('evrp_demo.png', dpi=150, bbox_inches='tight')
    print("可视化图片已保存为：evrp_demo.png")

# 生成可视化
简单可视化(evrp.客户们, 最优路线)

print("\n" + "=" * 50)
print("✅ 演示完成！")
print("=" * 50)
print("\n📚 总结：")
print("1. 变量：储物盒，用来存放数据")
print("2. 函数：工具说明书，输入→处理→输出")
print("3. 类：工厂模板，可以生产多个类似的对象")
print("4. self：每个对象的身份证")
print("5. 调用：就像按照说明书使用工具")

print("\n💡 记忆口诀：")
print("变量是盒子，函数是工具，类是模板，self是身份证！")