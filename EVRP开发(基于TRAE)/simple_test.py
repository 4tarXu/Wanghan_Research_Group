#!/usr/bin/env python3
"""
简单的中文字体测试
"""

import matplotlib.pyplot as plt
import matplotlib.font_manager as fm
import numpy as np

# 打印所有可用字体
fonts = [f.name for f in fm.fontManager.ttflist]
chinese_fonts = [f for f in fonts if any(kw in f.lower() for kw in ['sim', 'hei', 'pingfang', 'heiti', 'cjk', 'unicode', 'noto'])]

print("可用的中文字体:")
for font in chinese_fonts[:10]:  # 只显示前10个
    print(f"  {font}")

# 使用DejaVu Sans作为备选方案
plt.rcParams['font.sans-serif'] = ['DejaVu Sans', 'Arial Unicode MS', 'SimHei', 'SimSun']
plt.rcParams['axes.unicode_minus'] = False

# 创建简单测试图
fig, ax = plt.subplots(figsize=(8, 6))
x = [1, 2, 3, 4, 5]
y = [2, 4, 3, 5, 4]

ax.plot(x, y, 'bo-', linewidth=2, markersize=8)
ax.set_title('EVRP Route Planning Test', fontsize=14)
ax.set_xlabel('Distance (km)', fontsize=12)
ax.set_ylabel('Energy Consumption', fontsize=12)
ax.grid(True, alpha=0.3)

# 添加英文标签以避免中文问题
ax.text(3, 4, 'Test Plot\nElectric Vehicle Routing', 
        ha='center', va='center', fontsize=10,
        bbox=dict(boxstyle="round,pad=0.3", facecolor="lightblue", alpha=0.7))

plt.tight_layout()
plt.savefig('simple_test.png', dpi=150, bbox_inches='tight')
plt.close()

print("简单测试图已生成: simple_test.png")
print("如果此图显示正常，可以尝试运行完整的EVRP算法")