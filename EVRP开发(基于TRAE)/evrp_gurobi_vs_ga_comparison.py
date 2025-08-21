#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
EVRP算法对比分析：Gurobi vs 遗传算法
对同一个算例进行求解并对比结果
"""

import time
import json
from datetime import datetime
import os
from typing import Dict, Any
from data_generator import EVRPDataGenerator
from evrp_solver import EVRPProblem, Customer, ChargingStation, Depot, EVRPGeneticAlgorithm
from evrp_gurobi_simple_final import SimpleEVRPGurobiSolver
from evrp_gurobi_fixed import FixedEVRPGurobiSolver  # 使用修复后的Gurobi求解器

class EVRPComparisonAnalyzer:
    """EVRP算法对比分析器"""
    
    def __init__(self, seed=42):
        self.seed = seed
        self.generator = EVRPDataGenerator(seed=seed)
        self.results = {}
        
    def create_test_instance(self, size='small'):
        """创建测试算例"""
        if size == 'small':
            return self.generator.create_problem_instance(
                num_customers=8,
                num_stations=2,
                map_size=100,
                customer_distribution='uniform',
                station_distribution='strategic',
                vehicle_capacity=30.0,
                vehicle_battery=80.0,
                consumption_rate=1.0
            )
        elif size == 'medium':
            return self.generator.create_problem_instance(
                num_customers=12,
                num_stations=3,
                map_size=150,
                customer_distribution='uniform',
                station_distribution='strategic',
                vehicle_capacity=40.0,
                vehicle_battery=100.0,
                consumption_rate=1.0
            )
        else:  # large
            return self.generator.create_problem_instance(
                num_customers=15,
                num_stations=3,
                map_size=200,
                customer_distribution='uniform',
                station_distribution='strategic',
                vehicle_capacity=50.0,
                vehicle_battery=120.0,
                consumption_rate=1.0
            )
    
    def run_gurobi_solver(self, problem, time_limit=60):
        """运行修复后的Gurobi求解器"""
        print("🔍 正在运行Gurobi精确求解器...")
        start_time = time.time()
        
        solver = FixedEVRPGurobiSolver(problem, time_limit=time_limit)
        gurobi_result = solver.solve()
        
        end_time = time.time()
        gurobi_time = end_time - start_time
        
        # 确保返回有效值
        if gurobi_result['status'] in ['optimal', 'time_limit', 'relaxed_optimal']:
            return {
                'solver': 'Gurobi',
                'total_distance': gurobi_result['objective_value'],
                'num_vehicles': gurobi_result['solution']['num_vehicles'] if gurobi_result['solution'] else 1,
                'routes': gurobi_result['solution']['routes'] if gurobi_result['solution'] else [],
                'computation_time': gurobi_time,
                'status': gurobi_result['status'],
                'gap': gurobi_result.get('gap', 0.0),
                'model_info': {
                    'num_variables': gurobi_result.get('num_variables', 0),
                    'num_constraints': gurobi_result.get('num_constraints', 0)
                }
            }
        else:
            # 如果Gurobi失败，使用简化计算
            print("⚠️ Gurobi求解失败，使用估计值")
            return {
                'solver': 'Gurobi',
                'total_distance': float('inf'),
                'num_vehicles': max(1, int(np.ceil(sum(c.demand for c in problem.customers) / problem.vehicle_capacity))),
                'routes': [],
                'computation_time': gurobi_time,
                'status': 'failed',
                'gap': None,
                'model_info': {'num_variables': 0, 'num_constraints': 0}
            }
        return {
            'solver': 'Gurobi',
            'total_distance': gurobi_result.get('total_distance', float('inf')),
            'num_vehicles': gurobi_result.get('num_vehicles', 0),
            'routes': gurobi_result.get('routes', []),
            'computation_time': gurobi_time,
            'status': gurobi_result.get('status', 'unknown'),
            'gap': gurobi_result.get('gap', None)
        }
    
    def run_genetic_algorithm(self, problem: EVRPProblem) -> Dict[str, Any]:
        """运行遗传算法求解"""
        print("🧬 运行遗传算法...")
        
        start_time = time.time()
        
        # 创建遗传算法求解器
        ga = EVRPGeneticAlgorithm(
            problem=problem,
            population_size=100,
            max_generations=200,
            crossover_rate=0.8,
            mutation_rate=0.1,
            elite_size=10
        )
        
        # 求解
        solution = ga.solve()
        
        end_time = time.time()
        
        # 提取结果
        result = {
            'solver': 'Genetic Algorithm',
            'total_distance': solution.total_cost,
            'num_vehicles': len(solution.routes),
            'routes': [],
            'computation_time': end_time - start_time,
            'status': 'success',
            'population_size': 100,
            'generations': 200
        }
        
        # 提取路径信息
        for i, route in enumerate(solution.routes):
            route_info = {
                'path': [0] + [node.id for node in route.sequence if node.id != 0] + [0],
                'demand': route.total_load,
                'distance': route.total_distance
            }
            result['routes'].append(route_info)
        
        return result
        
    def generate_comparison_report(self, problem_size='small'):
        """生成对比分析报告"""
        print(f"📊 开始生成{problem_size}规模问题的对比分析报告...")
        
        # 创建测试算例
        problem = self.create_test_instance(problem_size)
        
        # 保存算例详细信息
        instance_info = {
            'problem_size': problem_size,
            'num_customers': len(problem.customers),
            'num_stations': len(problem.charging_stations),
            'vehicle_capacity': problem.vehicle_capacity,
            'vehicle_battery': problem.vehicle_battery,
            'consumption_rate': problem.consumption_rate,
            'total_demand': sum(c.demand for c in problem.customers),
            'customers': [
                {
                    'id': c.id,
                    'x': c.x,
                    'y': c.y,
                    'demand': c.demand,
                    'ready_time': getattr(c, 'ready_time', 0),
                    'due_time': getattr(c, 'due_time', 1000),
                    'service_time': getattr(c, 'service_time', 0)
                }
                for c in problem.customers
            ],
            'stations': [
                {
                    'id': s.id,
                    'x': s.x,
                    'y': s.y
                }
                for s in problem.charging_stations
            ],
            'depot': {
                'id': problem.depot.id,
                'x': problem.depot.x,
                'y': problem.depot.y
            }
        }
        
        # 运行两种算法
        gurobi_result = self.run_gurobi_solver(problem)
        ga_result = self.run_genetic_algorithm(problem)
        
        # 计算对比指标
        comparison = {
            'instance_info': instance_info,
            'gurobi_result': gurobi_result,
            'ga_result': ga_result,
            'comparison_metrics': {
                'distance_difference': ga_result['total_distance'] - gurobi_result['total_distance'],
                'distance_ratio': ga_result['total_distance'] / gurobi_result['total_distance'],
                'time_difference': ga_result['computation_time'] - gurobi_result['computation_time'],
                'time_ratio': ga_result['computation_time'] / gurobi_result['computation_time'],
                'vehicle_difference': ga_result['num_vehicles'] - gurobi_result['num_vehicles']
            },
            'timestamp': datetime.now().isoformat()
        }
        
        return comparison
    
    def save_report(self, results, json_filename, filename):
        """保存详细报告到JSON和Markdown文件"""
        # 清理结果以便JSON序列化
        clean_results = {}
        for key, value in results.items():
            if isinstance(value, dict):
                clean_results[key] = {}
                for k, v in value.items():
                    if isinstance(v, (int, float, str, bool)) or v is None:
                        clean_results[key][k] = v
                    elif isinstance(v, list):
                        # 处理客户对象列表
                        clean_list = []
                        for item in v:
                            if hasattr(item, '__dict__'):
                                clean_list.append({
                                    'id': getattr(item, 'id', None),
                                    'x': getattr(item, 'x', None),
                                    'y': getattr(item, 'y', None),
                                    'demand': getattr(item, 'demand', None)
                                })
                            else:
                                clean_list.append(str(item))
                        clean_results[key][k] = clean_list
                    else:
                        clean_results[key][k] = str(v)
            else:
                clean_results[key] = str(value)
        
        # 保存JSON文件
        with open(json_filename, 'w', encoding='utf-8') as f:
            json.dump(clean_results, f, indent=2, ensure_ascii=False)
        
        # 保存Markdown报告（保持不变）
        with open(filename, 'w', encoding='utf-8') as f:
            f.write("# EVRP算法对比分析报告\n\n")
            
            # 实验概览
            f.write("## 📊 实验概览\n\n")
            for problem_size, data in results.items():
                if isinstance(data, dict) and 'problem_info' in data:
                    info = data['problem_info']
                    f.write(f"### {problem_size}规模问题\n")
                    f.write(f"- **客户数**: {info.get('customers', 'N/A')}\n")
                    f.write(f"- **充电站**: {info.get('stations', 'N/A')}\n")
                    f.write(f"- **车辆容量**: {info.get('capacity', 'N/A')}\n")
                    f.write(f"- **电池容量**: {info.get('battery', 'N/A')}\n")
                    f.write(f"- **随机种子**: 42\n\n")
                    
                    # 求解结果对比
                    if 'gurobi' in data and 'genetic' in data:
                        gurobi = data['gurobi']
                        genetic = data['genetic']
                        
                        f.write("#### 求解结果对比\n\n")
                        f.write("| 指标 | Gurobi精确求解 | 遗传算法 | 差异 |\n")
                        f.write("|------|----------------|----------|------|\n")
                        
                        g_dist = gurobi.get('total_distance', 'N/A')
                        ga_dist = genetic.get('total_distance', 'N/A')
                        
                        if isinstance(g_dist, (int, float)) and isinstance(ga_dist, (int, float)):
                            diff = abs(g_dist - ga_dist)
                            diff_pct = (diff / g_dist * 100) if g_dist > 0 else 0
                            diff_str = f"{diff:.2f} ({diff_pct:.1f}%)"
                        else:
                            diff_str = "N/A"
                        
                        f.write(f"| 总距离 | {g_dist} | {ga_dist} | {diff_str} |\n")
                        f.write(f"| 使用车辆 | {gurobi.get('num_vehicles', 'N/A')} | {genetic.get('num_vehicles', 'N/A')} | - |\n")
                        f.write(f"| 计算时间 | {gurobi.get('computation_time', 'N/A'):.2f}s | {genetic.get('computation_time', 'N/A'):.2f}s | - |\n")
                        f.write(f"| 求解状态 | {gurobi.get('status', 'N/A')} | {genetic.get('status', 'N/A')} | - |\n")
                        f.write("\n")
            
            # 性能分析
            f.write("## 🔍 性能深度分析\n\n")
            f.write("### 解质量评估\n")
            f.write("- **Gurobi**: 提供精确最优解或接近最优解\n")
            f.write("- **遗传算法**: 提供高质量的近似解，计算效率高\n")
            f.write("- **适用场景**: Gurobi适合小规模验证，遗传算法适合大规模实际问题\n\n")
            
            f.write("### 计算效率对比\n")
            f.write("- **Gurobi**: 指数时间复杂度，随问题规模增长急剧增加\n")
            f.write("- **遗传算法**: 多项式时间复杂度，计算时间随规模线性增长\n")
            f.write("- **建议**: 15个客户以下使用Gurobi，15个以上使用遗传算法\n\n")
            
            f.write("### 算法特点对比\n")
            f.write("| 特性 | Gurobi精确求解 | 遗传算法 |\n")
            f.write("|------|----------------|----------|\n")
            f.write("| **解的质量** | 最优或接近最优 | 近似解 |\n")
            f.write("| **计算时间** | 指数增长 | 多项式时间 |\n")
            f.write("| **问题规模** | 小规模(≤15客户) | 大规模(>50客户) |\n")
            f.write("| **约束处理** | 精确约束 | 惩罚函数 |\n")
            f.write("| **可扩展性** | 有限 | 良好 |\n")
            f.write("| **内存使用** | 高 | 低 |\n")
            f.write("| **并行性** | 有限 | 优秀 |\n")
        
        print(f"✅ 报告已保存: {filename}")
        print(f"✅ 数据已保存: {json_filename}")

def main():
    """主函数：运行对比分析"""
    analyzer = EVRPComparisonAnalyzer(seed=42)
    
    # 保存结果
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    
    # 小算例结果
    print("🔬 开始小规模问题对比分析...")
    small_results = analyzer.generate_comparison_report("small")
    analyzer.save_report(
        small_results,
        f"evrp_comparison_small_{timestamp}.json",
        f"evrp_comparison_small_{timestamp}.md"
    )
    
    print("\n📊 开始中规模问题对比分析...")
    medium_results = analyzer.generate_comparison_report("medium")
    analyzer.save_report(
        medium_results,
        f"evrp_comparison_medium_{timestamp}.json",
        f"evrp_comparison_medium_{timestamp}.md"
    )
    
    print("\n🎯 开始大规模问题对比分析...")
    large_results = analyzer.generate_comparison_report("large")
    analyzer.save_report(
        large_results,
        f"evrp_comparison_large_{timestamp}.json",
        f"evrp_comparison_large_{timestamp}.md"
    )
    
    print("\n✅ 所有对比分析完成！")
    print("📁 结果文件已保存在当前目录")

if __name__ == "__main__":
    main()