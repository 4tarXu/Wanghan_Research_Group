#!/usr/bin/env python3
"""
中文显示测试脚本
"""

import matplotlib.pyplot as plt
import numpy as np
import sys
import os

# 添加当前目录到路径
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

# 设置中文字体
from font_config import setup_chinese_fonts
setup_chinese_fonts()

# 创建测试数据
fig, ((ax1, ax2), (ax3, ax4)) = plt.subplots(2, 2, figsize=(12, 10))

# 测试1: 简单中文
x = np.linspace(0, 10, 100)
y = np.sin(x)
ax1.plot(x, y, 'b-', linewidth=2)
ax1.set_title('正弦函数', fontsize=14)
ax1.set_xlabel('时间', fontsize=12)
ax1.set_ylabel('振幅', fontsize=12)
ax1.grid(True, alpha=0.3)

# 测试2: 电动车路径规划
np.random.seed(42)
customers = np.random.rand(20, 2) * 10
depot = np.array([[5, 5]])
charging_stations = np.array([[2, 3], [7, 8], [4, 7]])

ax2.scatter(customers[:, 0], customers[:, 1], c='blue', s=50, label='客户')
ax2.scatter(depot[:, 0], depot[:, 1], c='red', s=100, marker='^', label='配送中心')
ax2.scatter(charging_stations[:, 0], charging_stations[:, 1], c='green', s=100, marker='s', label='充电站')
ax2.set_title('电动车路径规划', fontsize=14)
ax2.set_xlabel('X坐标', fontsize=12)
ax2.set_ylabel('Y坐标', fontsize=12)
ax2.legend()
ax2.grid(True, alpha=0.3)

# 测试3: 遗传算法收敛曲线
iterations = range(100)
best_fitness = [100 - i * 0.8 + np.random.normal(0, 2) for i in iterations]
avg_fitness = [120 - i * 0.6 + np.random.normal(0, 3) for i in iterations]

ax3.plot(iterations, best_fitness, 'r-', linewidth=2, label='最优适应度')
ax3.plot(iterations, avg_fitness, 'b--', linewidth=2, label='平均适应度')
ax3.set_title('遗传算法收敛曲线', fontsize=14)
ax3.set_xlabel('迭代次数', fontsize=12)
ax3.set_ylabel('适应度', fontsize=12)
ax3.legend()
ax3.grid(True, alpha=0.3)

# 测试4: 能耗分析
routes = ['路径1', '路径2', '路径3', '路径4']
energy = [85, 92, 78, 95]
colors = ['lightcoral', 'lightblue', 'lightgreen', 'gold']

bars = ax4.bar(routes, energy, color=colors, alpha=0.7)
ax4.set_title('各路径能耗对比', fontsize=14)
ax4.set_ylabel('能耗 (kWh)', fontsize=12)
ax4.set_ylim(0, 100)

# 添加数值标签
for bar in bars:
    height = bar.get_height()
    ax4.text(bar.get_x() + bar.get_width()/2., height + 1,
             f'{height} kWh', ha='center', va='bottom', fontsize=10)

plt.suptitle('电动车路径规划系统 - 中文显示测试', fontsize=16, fontweight='bold')
plt.tight_layout()
plt.savefig('chinese_display_test.png', dpi=150, bbox_inches='tight')
plt.show()

print("中文显示测试完成！")
print("请检查生成的 chinese_display_test.png 文件")
print("如果中文显示正常，说明字体配置成功")