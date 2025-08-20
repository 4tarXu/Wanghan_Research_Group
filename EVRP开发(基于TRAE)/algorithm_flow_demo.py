#!/usr/bin/env python3
"""
EVRP算法流程演示脚本
为初学者设计的交互式学习工具
"""

import matplotlib.pyplot as plt
import matplotlib.patches as patches
from matplotlib.patches import FancyBboxPatch, ConnectionPatch
import numpy as np
import time

def setup_chinese_fonts():
    """设置中文字体"""
    try:
        plt.rcParams['font.sans-serif'] = ['SimHei', 'DejaVu Sans', 'Arial Unicode MS']
        plt.rcParams['axes.unicode_minus'] = False
        print("✅ 中文字体配置成功")
    except:
        print("⚠️ 使用默认字体")

def create_algorithm_flow_chart():
    """创建算法流程图"""
    fig, ax = plt.subplots(1, 1, figsize=(16, 12))
    ax.set_xlim(0, 16)
    ax.set_ylim(0, 12)
    ax.set_aspect('equal')
    
    # 定义颜色方案
    colors = {
        'start': '#90EE90',
        'process': '#87CEEB',
        'decision': '#FFB6C1',
        'data': '#FFE4B5',
        'end': '#DDA0DD'
    }
    
    # 1. 开始节点
    start = FancyBboxPatch((1, 10.5), 2, 0.8, boxstyle="round,pad=0.1", 
                          facecolor=colors['start'], edgecolor='black', linewidth=2)
    ax.add_patch(start)
    ax.text(2, 10.9, '开始', ha='center', va='center', fontsize=14, fontweight='bold')
    
    # 2. 配置加载
    config = FancyBboxPatch((1, 9.2), 2, 0.8, boxstyle="round,pad=0.1", 
                           facecolor=colors['process'], edgecolor='black', linewidth=2)
    ax.add_patch(config)
    ax.text(2, 9.6, '加载配置\n(config.py)', ha='center', va='center', fontsize=12)
    
    # 3. 数据初始化
    data_init = FancyBboxPatch((1, 7.8), 2, 0.8, boxstyle="round,pad=0.1", 
                              facecolor=colors['data'], edgecolor='black', linewidth=2)
    ax.add_patch(data_init)
    ax.text(2, 8.2, '数据初始化\n(data_generator.py)', ha='center', va='center', fontsize=12)
    
    # 4. 遗传算法主循环
    ga_loop = FancyBboxPatch((4.5, 6.5), 3, 1.2, boxstyle="round,pad=0.1", 
                            facecolor=colors['process'], edgecolor='black', linewidth=2)
    ax.add_patch(ga_loop)
    ax.text(6, 7.1, '遗传算法主循环\n(evolution_solver.py)', ha='center', va='center', fontsize=12)
    
    # 5. 初始化种群
    init_pop = FancyBboxPatch((1, 5.5), 2, 0.8, boxstyle="round,pad=0.1", 
                           facecolor=colors['process'], edgecolor='black', linewidth=2)
    ax.add_patch(init_pop)
    ax.text(2, 5.9, '初始化种群\n(随机生成路径)', ha='center', va='center', fontsize=11)
    
    # 6. 适应度评估
    fitness = FancyBboxPatch((1, 4.2), 2, 0.8, boxstyle="round,pad=0.1", 
                          facecolor=colors['process'], edgecolor='black', linewidth=2)
    ax.add_patch(fitness)
    ax.text(2, 4.6, '计算适应度\n(距离+惩罚)', ha='center', va='center', fontsize=11)
    
    # 7. 选择操作
    selection = FancyBboxPatch((4.5, 4.2), 1.5, 0.8, boxstyle="round,pad=0.1", 
                             facecolor=colors['process'], edgecolor='black', linewidth=2)
    ax.add_patch(selection)
    ax.text(5.25, 4.6, '选择操作\n(锦标赛)', ha='center', va='center', fontsize=10)
    
    # 8. 交叉操作
    crossover = FancyBboxPatch((6.5, 4.2), 1.5, 0.8, boxstyle="round,pad=0.1", 
                            facecolor=colors['process'], edgecolor='black', linewidth=2)
    ax.add_patch(crossover)
    ax.text(7.25, 4.6, '交叉操作\n(路径重组)', ha='center', va='center', fontsize=10)
    
    # 9. 变异操作
    mutation = FancyBboxPatch((8.5, 4.2), 1.5, 0.8, boxstyle="round,pad=0.1", 
                           facecolor=colors['process'], edgecolor='black', linewidth=2)
    ax.add_patch(mutation)
    ax.text(9.25, 4.6, '变异操作\n(交换/插入)', ha='center', va='center', fontsize=10)
    
    # 10. 约束修复
    repair = FancyBboxPatch((10.5, 4.2), 1.5, 0.8, boxstyle="round,pad=0.1", 
                         facecolor=colors['process'], edgecolor='black', linewidth=2)
    ax.add_patch(repair)
    ax.text(11.25, 4.6, '约束修复\n(插入充电站)', ha='center', va='center', fontsize=10)
    
    # 11. 决策节点
    decision = patches.Polygon([[12.5, 5.5], [13.5, 5.9], [13.5, 5.1]], 
                              closed=True, facecolor=colors['decision'], 
                              edgecolor='black', linewidth=2)
    ax.add_patch(decision)
    ax.text(13, 5.5, '达到最大\n迭代次数?', ha='center', va='center', fontsize=10)
    
    # 12. 可视化
    visualize = FancyBboxPatch((4.5, 2.5), 3, 0.8, boxstyle="round,pad=0.1", 
                            facecolor=colors['data'], edgecolor='black', linewidth=2)
    ax.add_patch(visualize)
    ax.text(6, 2.9, '结果可视化\n(路径图+收敛曲线)', ha='center', va='center', fontsize=12)
    
    # 13. 结果保存
    save = FancyBboxPatch((8.5, 1.2), 2, 0.8, boxstyle="round,pad=0.1", 
                        facecolor=colors['data'], edgecolor='black', linewidth=2)
    ax.add_patch(save)
    ax.text(9.5, 1.6, '结果保存\n(JSON+图片)', ha='center', va='center', fontsize=12)
    
    # 14. 结束节点
    end = FancyBboxPatch((13, 0.5), 2, 0.8, boxstyle="round,pad=0.1", 
                       facecolor=colors['end'], edgecolor='black', linewidth=2)
    ax.add_patch(end)
    ax.text(14, 0.9, '结束', ha='center', va='center', fontsize=14, fontweight='bold')
    
    # 添加箭头连接
    # 垂直连接
    ax.annotate('', xy=(2, 10.2), xytext=(2, 11),
                arrowprops=dict(arrowstyle='->', lw=2, color='black'))
    ax.annotate('', xy=(2, 8.9), xytext=(2, 10),
                arrowprops=dict(arrowstyle='->', lw=2, color='black'))
    ax.annotate('', xy=(2, 7.6), xytext=(2, 8.7),
                arrowprops=dict(arrowstyle='->', lw=2, color='black'))
    ax.annotate('', xy=(6, 7.7), xytext=(3, 8.2),
                arrowprops=dict(arrowstyle='->', lw=2, color='black'))
    ax.annotate('', xy=(2, 6.3), xytext=(2, 7.7),
                arrowprops=dict(arrowstyle='->', lw=2, color='black'))
    ax.annotate('', xy=(2, 5), xytext=(2, 5.9),
                arrowprops=dict(arrowstyle='->', lw=2, color='black'))
    ax.annotate('', xy=(2, 3.7), xytext=(2, 4.6),
                arrowprops=dict(arrowstyle='->', lw=2, color='black'))
    
    # 水平连接
    ax.annotate('', xy=(4.5, 4.6), xytext=(3, 4.6),
                arrowprops=dict(arrowstyle='->', lw=2, color='black'))
    ax.annotate('', xy=(6.5, 4.6), xytext=(6, 4.6),
                arrowprops=dict(arrowstyle='->', lw=2, color='black'))
    ax.annotate('', xy=(8.5, 4.6), xytext=(8, 4.6),
                arrowprops=dict(arrowstyle='->', lw=2, color='black'))
    ax.annotate('', xy=(10.5, 4.6), xytext=(10, 4.6),
                arrowprops=dict(arrowstyle='->', lw=2, color='black'))
    ax.annotate('', xy=(12.5, 5.5), xytext=(12, 5.5),
                arrowprops=dict(arrowstyle='->', lw=2, color='black'))
    
    # 循环连接
    ax.annotate('', xy=(13, 5.9), xytext=(13, 7.1),
                arrowprops=dict(arrowstyle='->', lw=2, color='black', 
                              connectionstyle="arc3,rad=0.3"))
    ax.annotate('', xy=(14, 5.5), xytext=(15, 5.5),
                arrowprops=dict(arrowstyle='->', lw=2, color='black'))
    ax.annotate('', xy=(15, 2.9), xytext=(15, 5.1),
                arrowprops=dict(arrowstyle='->', lw=2, color='black'))
    ax.annotate('', xy=(8.5, 2.9), xytext=(7.5, 2.9),
                arrowprops=dict(arrowstyle='->', lw=2, color='black'))
    ax.annotate('', xy=(9.5, 1.6), xytext=(9.5, 2.5),
                arrowprops=dict(arrowstyle='->', lw=2, color='black'))
    ax.annotate('', xy=(14, 1.3), xytext=(11.5, 1.3),
                arrowprops=dict(arrowstyle='->', lw=2, color='black'))
    
    # 添加图例
    legend_elements = [
        patches.Patch(color=colors['start'], label='开始/结束'),
        patches.Patch(color=colors['process'], label='处理过程'),
        patches.Patch(color=colors['decision'], label='决策判断'),
        patches.Patch(color=colors['data'], label='数据操作')
    ]
    ax.legend(handles=legend_elements, loc='upper right', fontsize=10)
    
    ax.set_xlim(0, 16)
    ax.set_ylim(0, 12)
    ax.axis('off')
    ax.set_title('EVRP遗传算法执行流程图', fontsize=18, fontweight='bold', pad=20)
    
    plt.tight_layout()
    plt.savefig('algorithm_flow_chart.png', dpi=300, bbox_inches='tight')
    plt.show()
    print("📊 算法流程图已保存为: algorithm_flow_chart.png")

def create_class_diagram():
    """创建类关系图"""
    fig, ax = plt.subplots(1, 1, figsize=(14, 10))
    
    # 定义类的位置和大小
    classes = {
        'EVRPProblem': {'pos': (2, 7), 'size': (3, 1.5), 'color': '#FFE4B5'},
        'Customer': {'pos': (0.5, 4), 'size': (2.5, 1), 'color': '#B0E0E6'},
        'ChargingStation': {'pos': (3.5, 4), 'size': (2.5, 1), 'color': '#B0E0E6'},
        'Vehicle': {'pos': (6.5, 4), 'size': (2.5, 1), 'color': '#B0E0E6'},
        'GeneticAlgorithm': {'pos': (7, 7), 'size': (3, 1.5), 'color': '#98FB98'},
        'EVRPVisualizer': {'pos': (12, 7), 'size': (3, 1.5), 'color': '#DDA0DD'},
        'Route': {'pos': (12, 4), 'size': (2.5, 1), 'color': '#F0E68C'},
        'ConfigManager': {'pos': (7, 2), 'size': (3, 1.2), 'color': '#E6E6FA'}
    }
    
    # 绘制类
    for class_name, info in classes.items():
        x, y = info['pos']
        w, h = info['size']
        
        rect = FancyBboxPatch((x, y), w, h, boxstyle="round,pad=0.1", 
                             facecolor=info['color'], edgecolor='black', linewidth=2)
        ax.add_patch(rect)
        ax.text(x + w/2, y + h/2, class_name, ha='center', va='center', 
               fontsize=12, fontweight='bold')
    
    # 添加类的方法和属性
    # EVRPProblem
    ax.text(3.5, 7.8, '+customers\n+charging_stations\n+depot\n+calculate_distance()', 
           fontsize=9, ha='center', va='center')
    
    # Customer
    ax.text(1.75, 4.3, '+id\n+x\n+y\n+demand\n+time_window', 
           fontsize=9, ha='center', va='center')
    
    # GeneticAlgorithm
    ax.text(8.5, 7.8, '+population\n+evolve()\n+select()\n+crossover()\n+mutate()', 
           fontsize=9, ha='center', va='center')
    
    # EVRPVisualizer
    ax.text(13.5, 7.8, '+plot_solution()\n+plot_convergence()\n+save_plots()', 
           fontsize=9, ha='center', va='center')
    
    # Route
    ax.text(13.25, 4.3, '+customers\n+total_distance\n+battery_level\n+calculate_cost()', 
           fontsize=9, ha='center', va='center')
    
    # 绘制关系箭头
    relationships = [
        ((3.5, 7), (1.75, 5), 'contains'),
        ((3.5, 7), (4.75, 5), 'contains'),
        ((8.5, 7), (3.5, 7), 'uses'),
        ((8.5, 7), (13.25, 5), 'creates'),
        ((13.5, 7), (13.25, 5), 'visualizes'),
        ((8.5, 2.5), (3.5, 7), 'configures'),
        ((8.5, 2.5), (8.5, 7), 'configures'),
    ]
    
    for (x1, y1), (x2, y2), label in relationships:
        ax.annotate('', xy=(x2, y2), xytext=(x1, y1),
                   arrowprops=dict(arrowstyle='->', lw=2, color='blue'))
    
    ax.set_xlim(0, 15)
    ax.set_ylim(0, 10)
    ax.axis('off')
    ax.set_title('EVRP算法类关系图', fontsize=18, fontweight='bold', pad=20)
    
    plt.tight_layout()
    plt.savefig('class_diagram.png', dpi=300, bbox_inches='tight')
    plt.show()
    print("📊 类关系图已保存为: class_diagram.png")

def create_step_by_step_demo():
    """创建逐步演示图"""
    fig, ((ax1, ax2), (ax3, ax4)) = plt.subplots(2, 2, figsize=(16, 12))
    
    # 步骤1: 问题定义
    ax1.set_xlim(0, 10)
    ax1.set_ylim(0, 10)
    ax1.set_title('步骤1: 问题定义\n定义客户、充电站和配送中心', fontsize=14, fontweight='bold')
    
    # 绘制基础场景
    depot = (5, 5)
    customers = [(2, 2), (8, 2), (2, 8), (8, 8), (5, 2), (5, 8)]
    stations = [(1, 5), (9, 5), (5, 1), (5, 9)]
    
    ax1.scatter(*depot, c='red', s=200, marker='*', label='配送中心')
    ax1.scatter([c[0] for c in customers], [c[1] for c in customers], 
               c='blue', s=100, label='客户')
    ax1.scatter([s[0] for s in stations], [s[1] for s in stations], 
               c='green', s=150, marker='^', label='充电站')
    ax1.legend()
    ax1.grid(True, alpha=0.3)
    
    # 步骤2: 初始化种群
    ax2.set_xlim(0, 10)
    ax2.set_ylim(0, 10)
    ax2.set_title('步骤2: 初始化种群\n随机生成初始路径', fontsize=14, fontweight='bold')
    
    # 绘制一条随机路径
    route1 = [depot, customers[0], customers[1], customers[2], depot]
    route2 = [depot, customers[3], customers[4], customers[5], depot]
    
    x1, y1 = zip(*route1)
    x2, y2 = zip(*route2)
    
    ax2.plot(x1, y1, 'r-o', linewidth=2, label='路径1')
    ax2.plot(x2, y2, 'b-o', linewidth=2, label='路径2')
    ax2.scatter(*depot, c='red', s=200, marker='*')
    ax2.scatter([c[0] for c in customers], [c[1] for c in customers], c='blue', s=100)
    ax2.legend()
    ax2.grid(True, alpha=0.3)
    
    # 步骤3: 遗传操作
    ax3.set_xlim(0, 10)
    ax3.set_ylim(0, 10)
    ax3.set_title('步骤3: 遗传操作\n选择、交叉、变异', fontsize=14, fontweight='bold')
    
    # 绘制优化后的路径
    opt_route1 = [depot, customers[0], customers[4], customers[1], depot]
    opt_route2 = [depot, customers[2], customers[5], customers[3], depot]
    
    x3, y3 = zip(*opt_route1)
    x4, y4 = zip(*opt_route2)
    
    ax3.plot(x3, y3, 'g--', linewidth=3, label='优化路径1')
    ax3.plot(x4, y4, 'm--', linewidth=3, label='优化路径2')
    ax3.scatter(*depot, c='red', s=200, marker='*')
    ax3.scatter([c[0] for c in customers], [c[1] for c in customers], c='blue', s=100)
    ax3.legend()
    ax3.grid(True, alpha=0.3)
    
    # 步骤4: 结果输出
    generations = list(range(0, 101, 10))
    costs = [150, 145, 138, 132, 128, 125, 123, 122, 121, 120, 119]
    
    ax4.plot(generations, costs, 'b-o', linewidth=3, markersize=8)
    ax4.set_title('步骤4: 结果输出\n收敛曲线和最优解', fontsize=14, fontweight='bold')
    ax4.set_xlabel('迭代次数', fontsize=12)
    ax4.set_ylabel('总成本', fontsize=12)
    ax4.grid(True, alpha=0.3)
    ax4.set_ylim(115, 155)
    
    plt.suptitle('EVRP遗传算法逐步演示', fontsize=18, fontweight='bold')
    plt.tight_layout()
    plt.savefig('step_by_step_demo.png', dpi=300, bbox_inches='tight')
    plt.show()
    print("📊 逐步演示图已保存为: step_by_step_demo.png")

def main():
    """主函数：展示所有流程图"""
    setup_chinese_fonts()
    
    print("🎯 EVRP遗传算法学习指南")
    print("=" * 50)
    print("📋 正在为您生成算法流程图...")
    
    # 创建所有图表
    create_algorithm_flow_chart()
    create_class_diagram()
    create_step_by_step_demo()
    
    print("\n✅ 所有图表生成完成！")
    print("\n📁 生成的学习文件:")
    print("   📊 algorithm_flow_chart.png - 算法执行流程图")
    print("   📊 class_diagram.png - 类关系图")
    print("   📊 step_by_step_demo.png - 逐步演示图")
    print("   📄 EVRP算法流程图.md - 详细说明文档")
    
    print("\n🎓 学习建议:")
    print("1. 先查看 step_by_step_demo.png 了解整体过程")
    print("2. 阅读 algorithm_flow_chart.png 理解详细流程")
    print("3. 参考 class_diagram.png 理解代码结构")
    print("4. 结合 EVRP算法流程图.md 深入学习")
    
    print("\n💡 运行示例:")
    print("   python run_evrp.py --generate --customers 5 --stations 2")
    print("   python run_evrp.py --problem results/xxx.json")

if __name__ == "__main__":
    main()