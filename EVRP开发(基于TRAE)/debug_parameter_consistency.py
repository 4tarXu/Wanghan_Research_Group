#!/usr/bin/env python3
"""
参数一致性检查脚本
用于诊断Gurobi和遗传算法距离差距过大的原因
"""

import numpy as np
import time
from evrp_solver import EVRPProblem, EVRPEvaluator, EVRPGeneticAlgorithm
from evrp_gurobi_fixed import FixedEVRPGurobiSolver
from data_generator import EVRPDataGenerator

def create_debug_problem():
    """创建调试用的小规模问题"""
    problem = EVRPProblem()
    
    # 设置配送中心
    depot = type('Depot', (), {'id': 0, 'x': 50, 'y': 50})()
    problem.add_depot(depot)
    
    # 添加少量客户
    customers = [
        type('Customer', (), {'id': 1, 'x': 30, 'y': 70, 'demand': 10, 'service_time': 0})(),
        type('Customer', (), {'id': 2, 'x': 70, 'y': 30, 'demand': 8, 'service_time': 0})(),
        type('Customer', (), {'id': 3, 'x': 40, 'y': 40, 'demand': 12, 'service_time': 0})(),
    ]
    
    for customer in customers:
        problem.add_customer(customer)
    
    # 设置车辆参数
    problem.set_vehicle_constraints(
        capacity=50.0,
        battery=100.0,
        consumption_rate=1.0,
        loading_time=0
    )
    
    return problem

def debug_distance_calculation():
    """调试距离计算"""
    print("🔍 开始参数一致性检查...")
    print("=" * 60)
    
    # 创建问题
    problem = create_debug_problem()
    
    print("📊 问题参数:")
    print(f"  客户数: {len(problem.customers)}")
    print(f"  车辆容量: {problem.vehicle_capacity}")
    print(f"  电池容量: {problem.vehicle_battery}")
    print(f"  耗电率: {problem.consumption_rate}")
    
    # 检查节点坐标
    print("\n📍 节点坐标:")
    print(f"  配送中心: ({problem.depot.x}, {problem.depot.y})")
    for i, customer in enumerate(problem.customers):
        print(f"  客户{customer.id}: ({customer.x}, {customer.y})")
    
    # 计算实际距离矩阵
    print("\n📏 距离矩阵:")
    nodes = [problem.depot] + problem.customers
    for i, node_i in enumerate(nodes):
        for j, node_j in enumerate(nodes):
            if i != j:
                dist = np.sqrt((node_i.x - node_j.x)**2 + (node_i.y - node_j.y)**2)
                print(f"  {node_i.id}→{node_j.id}: {dist:.2f}")
    
    return problem

def debug_gurobi_vs_ga():
    """对比Gurobi和遗传算法在相同问题上的表现"""
    problem = debug_distance_calculation()
    
    print("\n🧪 算法对比测试:")
    print("=" * 60)
    
    # 1. 运行Gurobi
    print("\n🔍 运行Gurobi求解器...")
    gurobi_solver = FixedEVRPGurobiSolver(problem, time_limit=30)
    start_time = time.time()
    gurobi_result = gurobi_solver.solve()
    gurobi_time = time.time() - start_time
    
    print(f"  Gurobi结果:")
    print(f"    总距离: {gurobi_result['objective_value']:.2f}")
    print(f"    计算时间: {gurobi_time:.2f}s")
    print(f"    状态: {gurobi_result['status']}")
    
    # 2. 运行遗传算法
    print("\n🧬 运行遗传算法...")
    ga = EVRPGeneticAlgorithm(
        problem=problem,
        population_size=50,
        max_generations=100,
        crossover_rate=0.8,
        mutation_rate=0.1,
        elite_size=5
    )
    
    start_time = time.time()
    ga_result = ga.solve()
    ga_time = time.time() - start_time
    
    print(f"  遗传算法结果:")
    print(f"    总成本: {ga_result.total_cost:.2f}")
    print(f"    计算时间: {ga_time:.2f}s")
    print(f"    车辆数: {len(ga_result.routes)}")
    
    # 3. 详细分析遗传算法的成本构成
    print("\n📊 遗传算法成本构成分析:")
    evaluator = EVRPEvaluator(problem)
    
    # 重新评估遗传算法结果
    detailed_result = evaluator.evaluate_solution(ga_result)
    print(f"  重新评估后的总成本: {detailed_result:.2f}")
    
    # 检查每条路径
    for i, route in enumerate(ga_result.routes):
        print(f"  路径{i+1}:")
        print(f"    客户序列: {[n.id for n in route.sequence]}")
        print(f"    实际距离: {route.total_distance:.2f}")
        print(f"    总载重: {route.total_load:.2f}")
        print(f"    是否可行: {route.is_feasible}")
        if route.violations:
            print(f"    违规: {route.violations}")
    
    # 4. 对比结果
    print("\n⚖️ 对比分析:")
    if isinstance(gurobi_result['objective_value'], (int, float)):
        g_dist = gurobi_result['objective_value']
        ga_dist = ga_result.total_cost
        
        print(f"  距离差距: {abs(ga_dist - g_dist):.2f}")
        print(f"  相对差距: {abs(ga_dist - g_dist) / max(g_dist, 1) * 100:.1f}%")
        print(f"  时间比: {ga_time / gurobi_time:.1f}x")

def check_penalty_weights():
    """检查惩罚权重设置"""
    print("\n⚖️ 惩罚权重检查:")
    print("=" * 60)
    
    # 查看评估器中的惩罚设置
    problem = create_debug_problem()
    evaluator = EVRPEvaluator(problem)
    
    # 创建一个故意违规的路径来测试惩罚
    route = type('Route', (), {'sequence': [], 'problem': problem})()
    route.sequence = [problem.customers[0], problem.customers[1]]  # 故意超载
    route.total_distance = 0
    route.total_load = 0
    route.total_time = 0
    route.battery_consumption = 0
    route.is_feasible = True
    route.violations = []
    
    # 评估这个路径
    cost = evaluator.evaluate_route(route)
    print(f"  空路径成本: {cost:.2f}")
    
    # 测试不同载重情况
    test_loads = [10, 20, 30, 40, 50, 60, 70]
    for load in test_loads:
        route.total_load = load
        cost = evaluator.evaluate_route(route)
        print(f"  载重{load}: 成本={cost:.2f} (惩罚={max(0, load - problem.vehicle_capacity) * 1000:.0f})")

if __name__ == "__main__":
    debug_distance_calculation()
    debug_gurobi_vs_ga()
    check_penalty_weights()