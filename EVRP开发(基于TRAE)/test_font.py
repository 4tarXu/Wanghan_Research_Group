#!/usr/bin/env python3
"""
中文字体测试脚本
"""

import matplotlib.pyplot as plt
import numpy as np

# 测试中文字体配置
try:
    from font_config import setup_matplotlib_for_chinese
    setup_matplotlib_for_chinese()
    print("中文字体配置已加载")
except ImportError:
    print("使用备用字体配置")
    plt.rcParams['font.sans-serif'] = ['SimHei', 'DejaVu Sans', 'Arial Unicode MS']
    plt.rcParams['axes.unicode_minus'] = False

# 创建测试图
fig, ax = plt.subplots(figsize=(8, 6))

# 测试中文显示
x = np.linspace(0, 10, 100)
y = np.sin(x)

ax.plot(x, y, 'b-', linewidth=2, label='正弦函数')
ax.set_title('中文字体测试 - 电动车路径规划', fontsize=14, fontweight='bold')
ax.set_xlabel('X轴坐标', fontsize=12)
ax.set_ylabel('Y轴坐标', fontsize=12)
ax.legend()
ax.grid(True, alpha=0.3)

# 添加中文文本
ax.text(5, 0.5, '这是一个中文字体测试\n电动车路径规划问题', 
        ha='center', va='center', fontsize=12,
        bbox=dict(boxstyle="round,pad=0.3", facecolor="yellow", alpha=0.7))

plt.tight_layout()
plt.savefig('test_chinese_font.png', dpi=150, bbox_inches='tight')
plt.show()

print("测试完成！请检查生成的 test_chinese_font.png 文件")
print("如果中文显示正常，说明字体配置成功")