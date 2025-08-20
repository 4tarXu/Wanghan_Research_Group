#!/usr/bin/env python3
"""
EVRP遗传算法运行脚本
Electric Vehicle Routing Problem Runner
"""

import argparse
import os
import time
import json
from datetime import datetime

from evrp_solver import EVRPProblem, EVRPGeneticAlgorithm, EVRPVisualizer
from data_generator import EVRPDataGenerator
from config import ConfigManager


def create_output_directory(base_dir: str = "results") -> str:
    """创建输出目录"""
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    output_dir = f"{base_dir}/{timestamp}"
    os.makedirs(output_dir, exist_ok=True)
    return output_dir


def save_results(solution, ga, output_dir: str, problem_name: str):
    """保存结果"""
    # 保存解决方案
    solution_data = {
        'problem_name': problem_name,
        'timestamp': datetime.now().isoformat(),
        'total_cost': solution.total_cost,
        'num_routes': len(solution.routes),
        'is_feasible': solution.is_feasible,
        'routes': []
    }
    
    for i, route in enumerate(solution.routes):
        route_data = {
            'route_id': i + 1,
            'sequence': [n.id for n in route.sequence],
            'total_distance': route.total_distance,
            'total_load': route.total_load,
            'total_time': route.total_time,
            'is_feasible': route.is_feasible,
            'violations': route.violations
        }
        solution_data['routes'].append(route_data)
        
    # 保存收敛历史
    if ga.generation_history:
        with open(f"{output_dir}/convergence.json", 'w') as f:
            json.dump(ga.generation_history, f, indent=2)
            
    # 保存解决方案
    with open(f"{output_dir}/solution.json", 'w') as f:
        json.dump(solution_data, f, indent=2)
        
    # 保存摘要
    summary = {
        'problem': problem_name,
        'total_cost': solution.total_cost,
        'num_vehicles': len(solution.routes),
        'feasible': solution.is_feasible,
        'computation_time': time.time() - start_time
    }
    
    with open(f"{output_dir}/summary.json", 'w') as f:
        json.dump(summary, f, indent=2)


def run_single_instance(problem: EVRPProblem, config: ConfigManager, 
                       output_dir: str, problem_name: str) -> dict:
    """运行单个实例"""
    print(f"\n{'='*60}")
    print(f"求解问题: {problem_name}")
    print(f"客户数量: {len(problem.customers)}")
    print(f"充电站数量: {len(problem.charging_stations)}")
    print(f"车辆容量: {problem.vehicle_capacity}")
    print(f"电池容量: {problem.vehicle_battery}")
    
    # 创建遗传算法
    ga = EVRPGeneticAlgorithm(
        problem=problem,
        population_size=config.ga.population_size,
        max_generations=config.ga.max_generations,
        crossover_rate=config.ga.crossover_rate,
        mutation_rate=config.ga.mutation_rate,
        elite_size=config.ga.elite_size
    )
    
    # 求解
    start_time = time.time()
    solution = ga.solve()
    end_time = time.time()
    
    # 可视化
    visualizer = EVRPVisualizer(problem)
    
    if config.visualization.save_plots:
        visualizer.plot_solution(solution, f"{output_dir}/solution.png")
        visualizer.plot_convergence(ga, f"{output_dir}/convergence.png")
    else:
        visualizer.plot_solution(solution)
        visualizer.plot_convergence(ga)
    
    # 保存结果
    save_results(solution, ga, output_dir, problem_name)
    
    return {
        'problem': problem_name,
        'total_cost': solution.total_cost,
        'num_vehicles': len(solution.routes),
        'feasible': solution.is_feasible,
        'computation_time': end_time - start_time
    }


def run_benchmark(config: ConfigManager, test_dir: str = "test_instances"):
    """运行基准测试"""
    print("运行基准测试...")
    
    # 确保测试实例存在
    if not os.path.exists(test_dir):
        print("生成测试实例...")
        generator = EVRPDataGenerator(seed=42)
        generator.generate_test_suite(test_dir)
    
    # 创建输出目录
    output_dir = create_output_directory("benchmark_results")
    
    results = []
    test_files = [f for f in os.listdir(test_dir) if f.endswith('.json')]
    
    for test_file in test_files:
        problem_name = test_file.replace('.json', '')
        problem_path = f"{test_dir}/{test_file}"
        
        # 加载问题
        generator = EVRPDataGenerator()
        problem = generator.load_problem_instance(problem_path)
        
        # 创建子目录
        instance_dir = f"{output_dir}/{problem_name}"
        os.makedirs(instance_dir, exist_ok=True)
        
        # 运行
        result = run_single_instance(problem, config, instance_dir, problem_name)
        results.append(result)
        
        print(f"完成: {problem_name}, 成本: {result['total_cost']:.2f}, "
              f"车辆: {result['num_vehicles']}, 时间: {result['computation_time']:.2f}s")
    
    # 保存基准测试结果
    with open(f"{output_dir}/benchmark_results.json", 'w') as f:
        json.dump(results, f, indent=2)
        
    # 打印摘要
    print("\n" + "="*60)
    print("基准测试完成!")
    print(f"结果保存在: {output_dir}")
    
    return results


def main():
    """主函数"""
    # 设置中文字体
    try:
        from font_config import setup_matplotlib_for_chinese
        setup_matplotlib_for_chinese()
        print("中文字体配置已加载")
    except ImportError:
        import matplotlib.pyplot as plt
        plt.rcParams['font.sans-serif'] = ['DejaVu Sans', 'SimHei', 'Arial Unicode MS']
        plt.rcParams['axes.unicode_minus'] = False
        print("使用备用字体配置")
    
    parser = argparse.ArgumentParser(description='EVRP遗传算法求解器')
    parser.add_argument('--config', '-c', default='config.json',
                       help='配置文件路径')
    parser.add_argument('--problem', '-p', type=str,
                       help='问题实例文件路径')
    parser.add_argument('--benchmark', '-b', action='store_true',
                       help='运行基准测试')
    parser.add_argument('--generate', '-g', action='store_true',
                       help='生成新的测试实例')
    parser.add_argument('--output', '-o', type=str, default='results',
                       help='输出目录')
    parser.add_argument('--customers', type=int, default=15,
                       help='客户数量（用于生成新实例）')
    parser.add_argument('--stations', type=int, default=4,
                       help='充电站数量（用于生成新实例）')
    parser.add_argument('--distribution', choices=['uniform', 'clustered'],
                       default='uniform', help='客户分布类型')
    
    args = parser.parse_args()
    
    # 加载配置
    config = ConfigManager()
    if os.path.exists(args.config):
        config.load_from_file(args.config)
        print("加载配置文件:", args.config)
    else:
        print("使用默认配置")
    
    print(config)
    
    # 创建输出目录
    os.makedirs(args.output, exist_ok=True)
    
    if args.generate:
        # 生成测试实例
        print("生成测试实例...")
        generator = EVRPDataGenerator(seed=42)
        problem = generator.create_problem_instance(
            num_customers=args.customers,
            num_stations=args.stations,
            customer_distribution=args.distribution
        )
        
        problem_name = f"evrp_{args.customers}c_{args.stations}s_{args.distribution}"
        problem_file = f"{args.output}/{problem_name}.json"
        generator.save_problem_instance(problem, problem_file)
        print(f"已保存: {problem_file}")
        
    elif args.benchmark:
        # 运行基准测试
        results = run_benchmark(config)
        
    elif args.problem:
        # 运行单个问题实例
        if not os.path.exists(args.problem):
            print(f"错误: 问题文件 {args.problem} 不存在")
            return
            
        generator = EVRPDataGenerator()
        problem = generator.load_problem_instance(args.problem)
        problem_name = os.path.basename(args.problem).replace('.json', '')
        
        output_dir = create_output_directory(args.output)
        run_single_instance(problem, config, output_dir, problem_name)
        
    else:
        # 运行默认示例
        print("运行默认示例...")
        from evrp_solver import create_sample_problem
        
        problem = create_sample_problem()
        output_dir = create_output_directory(args.output)
        run_single_instance(problem, config, output_dir, "default_example")
    
    print("\n运行完成!")


if __name__ == "__main__":
    start_time = time.time()
    main()
    total_time = time.time() - start_time
    print(f"\n总运行时间: {total_time:.2f}秒")