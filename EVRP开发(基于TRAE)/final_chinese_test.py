#!/usr/bin/env python3
"""
最终中文显示验证脚本
"""

import matplotlib.pyplot as plt
import numpy as np
import os

# 设置中文字体
from font_config import setup_chinese_fonts
setup_chinese_fonts()

# 创建一个模拟的EVRP结果图
fig, ((ax1, ax2), (ax3, ax4)) = plt.subplots(2, 2, figsize=(16, 12))

# 1. 路径规划图
np.random.seed(42)
customers = np.random.rand(12, 2) * 80 + 10
depot = np.array([[50, 50]])
charging_stations = np.array([[20, 30], [70, 60], [40, 80]])

# 绘制路径
ax1.scatter(depot[:, 0], depot[:, 1], c='red', s=200, marker='*', label='配送中心', zorder=5)
ax1.scatter(customers[:, 0], customers[:, 1], c='blue', s=100, label='客户点', zorder=4)
ax1.scatter(charging_stations[:, 0], charging_stations[:, 1], c='green', s=150, marker='^', label='充电站', zorder=4)

# 绘制一条示例路径
route = np.array([[50, 50], [25, 35], [30, 45], [40, 55], [50, 50]])
ax1.plot(route[:, 0], route[:, 1], 'r-', linewidth=3, label='示例路径')

ax1.set_title('电动车路径规划结果', fontsize=16, fontweight='bold')
ax1.set_xlabel('X坐标 (公里)', fontsize=12)
ax1.set_ylabel('Y坐标 (公里)', fontsize=12)
ax1.legend(fontsize=10)
ax1.grid(True, alpha=0.3)

# 2. 能耗分析
vehicles = ['车辆1', '车辆2', '车辆3', '车辆4']
energy_usage = [85.5, 92.3, 78.7, 95.2]
battery_capacity = [100] * 4

x = np.arange(len(vehicles))
width = 0.35

bars1 = ax2.bar(x - width/2, energy_usage, width, label='实际能耗', color='lightcoral', alpha=0.8)
bars2 = ax2.bar(x + width/2, battery_capacity, width, label='电池容量', color='lightblue', alpha=0.8)

ax2.set_title('各车辆能耗对比分析', fontsize=16, fontweight='bold')
ax2.set_xlabel('车辆编号', fontsize=12)
ax2.set_ylabel('能量 (kWh)', fontsize=12)
ax2.set_xticks(x)
ax2.set_xticklabels(vehicles)
ax2.legend(fontsize=10)

# 添加数值标签
for bar in bars1:
    height = bar.get_height()
    ax2.text(bar.get_x() + bar.get_width()/2., height + 1,
             f'{height} kWh', ha='center', va='bottom', fontsize=9)

# 3. 遗传算法收敛曲线
iterations = list(range(0, 501, 50))
best_costs = [15000, 14500, 13800, 13200, 12800, 12500, 12300, 12200, 12150, 12100, 12080]

ax3.plot(iterations, best_costs, 'b-o', linewidth=3, markersize=8, label='最优成本')
ax3.set_title('遗传算法收敛曲线', fontsize=16, fontweight='bold')
ax3.set_xlabel('迭代次数', fontsize=12)
ax3.set_ylabel('总成本', fontsize=12)
ax3.legend(fontsize=10)
ax3.grid(True, alpha=0.3)

# 4. 客户满意度
routes = ['路线1', '路线2', '路线3', '路线4', '路线5']
satisfaction = [95.2, 87.8, 92.5, 89.3, 94.1]
colors = ['#ff9999', '#66b3ff', '#99ff99', '#ffcc99', '#ff99cc']

bars = ax4.bar(routes, satisfaction, color=colors, alpha=0.8)
ax4.set_title('各路线客户满意度', fontsize=16, fontweight='bold')
ax4.set_xlabel('路线编号', fontsize=12)
ax4.set_ylabel('满意度 (%)', fontsize=12)
ax4.set_ylim(0, 100)

# 添加数值标签
for bar in bars:
    height = bar.get_height()
    ax4.text(bar.get_x() + bar.get_width()/2., height + 1,
             f'{height}%', ha='center', va='bottom', fontsize=9)

plt.suptitle('电动车路径规划系统 - 中文显示完整验证', fontsize=18, fontweight='bold')
plt.tight_layout()
plt.savefig('final_chinese_verification.png', dpi=300, bbox_inches='tight')
plt.show()

print("✅ 中文显示验证完成！")
print("📊 生成的图片文件: final_chinese_verification.png")
print("🎯 使用的中文字体: SimHei")
print("✨ 所有中文字符应该都能正常显示，不再出现方块问题")

# 显示当前目录下的图片文件
print("\n📁 当前目录中的图片文件:")
for file in os.listdir('.'):
    if file.endswith(('.png', '.jpg', '.jpeg', '.pdf')):
        print(f"   - {file}")