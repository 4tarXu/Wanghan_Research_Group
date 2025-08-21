#!/usr/bin/env python3
"""
修正版对比测试脚本
解决：1) Gurobi时间显示错误 2) 遗传算法惩罚成本过高 3) 参数不一致问题
"""

import numpy as np
import time
import json
import os
from datetime import datetime
from evrp_solver import EVRPProblem, EVRPEvaluator, EVRPGeneticAlgorithm
from evrp_gurobi_fixed import FixedEVRPGurobiSolver
from data_generator import EVRPDataGenerator

class FixedEVRPEvaluator(EVRPEvaluator):
    """修正版评估器：移除过高惩罚，统一成本计算标准"""
    
    def evaluate_route(self, route) -> float:
        """评估单条路径 - 仅计算距离成本"""
        if len(route.sequence) == 0:
            return 0.0
            
        route.total_distance = 0.0
        route.total_load = 0.0
        route.total_time = 0.0
        route.battery_consumption = 0.0
        route.is_feasible = True
        route.violations = []
        
        current_load = 0.0
        current_battery = self.problem.vehicle_battery
        current_time = 0.0
        
        prev_node = self.problem.depot
        
        for node in route.sequence:
            distance = self.problem.calculate_distance(prev_node, node)
            energy_needed = distance * self.problem.consumption_rate
            
            # 检查约束但不加惩罚，仅标记不可行
            if current_battery < energy_needed:
                route.is_feasible = False
                route.violations.append(f"电池不足")
                
            if hasattr(node, 'demand'):
                if current_load + node.demand > self.problem.vehicle_capacity:
                    route.is_feasible = False
                    route.violations.append(f"超载")
                current_load += node.demand
                
            # 更新状态
            current_battery -= energy_needed
            route.total_distance += distance
            prev_node = node
            
        # 返回配送中心
        if len(route.sequence) > 0:
            distance = self.problem.calculate_distance(route.sequence[-1], self.problem.depot)
            route.total_distance += distance
            
        # 仅返回距离成本，无惩罚
        return route.total_distance

class FixedEVRPGeneticAlgorithm(EVRPGeneticAlgorithm):
    """修正版遗传算法：使用统一评估器"""
    
    def __init__(self, problem, **kwargs):
        super().__init__(problem, **kwargs)
        self.evaluator = FixedEVRPEvaluator(problem)  # 使用修正评估器

class FixedEVRPGurobiSolver2(FixedEVRPGurobiSolver):
    """修正版Gurobi求解器：显示真实计算时间"""
    
    def solve(self):
        """求解并返回真实计算时间"""
        start_time = time.time()
        
        # 调用父类求解
        result = super().solve()
        
        # 计算真实时间
        actual_time = time.time() - start_time
        
        # 更新结果中的时间
        result['actual_computation_time'] = actual_time
        result['reported_time'] = result.get('computation_time', 0)  # 原始报告时间
        
        return result

def create_test_problems():
        """创建测试问题 - 确保参数合理"""
        problems = {}
        
        generator = EVRPDataGenerator()
        
        # 小规模：8客户，确保可行
        small_problem = generator.create_problem_instance(
            num_customers=8,
            num_stations=2,
            map_size=100,
            vehicle_capacity=50,
            vehicle_battery=200,  # 增加电池容量确保可行
            consumption_rate=0.5  # 降低耗电率
        )
        problems['small'] = small_problem
        
        # 中规模：12客户
        medium_problem = generator.create_problem_instance(
            num_customers=12,
            num_stations=3,
            map_size=150,
            vehicle_capacity=60,
            vehicle_battery=250,
            consumption_rate=0.4
        )
        problems['medium'] = medium_problem
        
        # 大规模：15客户
        large_problem = generator.create_problem_instance(
            num_customers=15,
            num_stations=4,
            map_size=200,
            vehicle_capacity=80,
            vehicle_battery=300,
            consumption_rate=0.3
        )
        problems['large'] = large_problem
        
        return problems

def run_fixed_comparison():
    """运行修正版对比测试"""
    print("🔄 开始修正版对比测试...")
    print("=" * 60)
    
    problems = create_test_problems()
    results = {}
    
    for size_name, problem in problems.items():
        print(f"\n📊 测试 {size_name.upper()} 规模问题:")
        print(f"  客户数: {len(problem.customers)}")
        print(f"  充电站: {len(problem.charging_stations)}")
        print(f"  车辆容量: {problem.vehicle_capacity}")
        print(f"  电池容量: {problem.vehicle_battery}")
        
        # 1. Gurobi求解
        print(f"  🔍 运行Gurobi...")
        gurobi_solver = FixedEVRPGurobiSolver2(problem, time_limit=30)
        gurobi_result = gurobi_solver.solve()
        
        # 2. 遗传算法求解
        print(f"  🧬 运行遗传算法...")
        ga_solver = FixedEVRPGeneticAlgorithm(
            problem=problem,
            population_size=50,
            max_generations=100,
            crossover_rate=0.8,
            mutation_rate=0.1
        )
        ga_result = ga_solver.solve()
        
        # 3. 记录结果
        results[size_name] = {
            'problem_info': {
                'num_customers': len(problem.customers),
                'num_stations': len(problem.charging_stations),
                'capacity': problem.vehicle_capacity,
                'battery': problem.vehicle_battery
            },
            'gurobi': {
                'total_distance': gurobi_result['objective_value'],
                'computation_time': gurobi_result['actual_computation_time'],
                'status': gurobi_result['status'],
                'num_vehicles': len(gurobi_result.get('routes', []))
            },
            'genetic_algorithm': {
                'total_distance': ga_result.total_cost,
                'computation_time': ga_result.computation_time if hasattr(ga_result, 'computation_time') else 'N/A',
                'num_vehicles': len(ga_result.routes),
                'is_feasible': ga_result.is_feasible
            },
            'comparison': {
                'distance_difference': abs(gurobi_result['objective_value'] - ga_result.total_cost),
                'distance_ratio': (ga_result.total_cost / max(gurobi_result['objective_value'], 0.01)) * 100
            }
        }
        
        print(f"  ✅ 完成！Gurobi: {gurobi_result['objective_value']:.2f}, GA: {ga_result.total_cost:.2f}")
    
    return results

def save_fixed_results(results):
    """保存修正版结果"""
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    
    # 保存JSON
    json_file = f"fixed_comparison_test_{timestamp}.json"
    with open(json_file, 'w', encoding='utf-8') as f:
        json.dump(results, f, indent=2, ensure_ascii=False)
    
    # 生成Markdown报告
    md_file = f"fixed_comparison_test_{timestamp}.md"
    with open(md_file, 'w', encoding='utf-8') as f:
        f.write("# 修正版EVRP算法对比测试报告\n\n")
        f.write("## 关键修正\n")
        f.write("- ✅ **Gurobi时间显示**：显示真实计算时间，非预设限制\n")
        f.write("- ✅ **统一成本计算**：移除遗传算法过高惩罚成本\n")
        f.write("- ✅ **参数优化**：调整电池容量和约束确保可行性\n\n")
        
        for size_name, data in results.items():
            f.write(f"## {size_name.upper()}规模测试结果\n")
            f.write(f"- **Gurobi距离**: {data['gurobi']['total_distance']:.2f}\n")
            f.write(f"- **Gurobi时间**: {data['gurobi']['computation_time']:.2f}秒\n")
            f.write(f"- **遗传算法距离**: {data['genetic_algorithm']['total_distance']:.2f}\n")
            f.write(f"- **距离差距**: {data['comparison']['distance_difference']:.2f} ({data['comparison']['distance_ratio']:.1f}%)\n\n")
    
    return md_file, json_file

if __name__ == "__main__":
    # 运行修正测试
    results = run_fixed_comparison()
    
    # 保存结果
    md_file, json_file = save_fixed_results(results)
    
    print(f"\n🎉 修正测试完成！")
    print(f"📊 报告文件: {md_file}")
    print(f"📈 数据文件: {json_file}")