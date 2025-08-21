"""
EVRP Gurobi求解器运行脚本
兼容现有遗传算法的数据格式
"""

import sys
import os
import json
import time
from typing import Dict, Optional

# 添加项目根目录到Python路径
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from evrp_solver import EVRPProblem, Customer, ChargingStation, Depot
from evrp_gurobi_solver import solve_evrp_with_gurobi, EVRPGurobiSolver
from data_generator import EVRPDataGenerator


def create_test_instance() -> EVRPProblem:
    """创建测试实例 - 与遗传算法相同的算例"""
    generator = EVRPDataGenerator(seed=42)
    
    # 生成中等规模实例（适合Gurobi求解）
    problem = generator.create_problem_instance(
        num_customers=10,      # 10个客户
        num_stations=3,        # 3个充电站
        map_size=100.0,        # 100x100的地图
        vehicle_capacity=50.0,  # 车辆容量50
        vehicle_battery=100.0,  # 电池容量100
        consumption_rate=0.8,   # 耗电量0.8单位/距离
        customer_distribution='uniform',
        station_distribution='strategic'
    )
    
    return problem


def create_large_instance() -> EVRPProblem:
    """创建大规模实例（可能需要较长时间求解）"""
    generator = EVRPDataGenerator(seed=123)
    
    problem = generator.create_problem_instance(
        num_customers=15,
        num_stations=4,
        map_size=120.0,
        vehicle_capacity=40.0,
        vehicle_battery=120.0,
        consumption_rate=0.7
    )
    
    return problem


def create_custom_instance(config: Dict) -> EVRPProblem:
    """根据配置创建自定义实例"""
    generator = EVRPDataGenerator(seed=config.get('seed', 42))
    
    problem = generator.create_problem_instance(
        num_customers=config.get('num_customers', 8),
        num_stations=config.get('num_stations', 2),
        map_size=config.get('map_size', 80.0),
        vehicle_capacity=config.get('vehicle_capacity', 30.0),
        vehicle_battery=config.get('vehicle_battery', 80.0),
        consumption_rate=config.get('consumption_rate', 0.9)
    )
    
    return problem


def save_problem_instance(problem: EVRPProblem, filename: str):
    """保存问题实例到JSON文件"""
    instance_data = {
        'depot': {
            'id': problem.depot.id,
            'x': problem.depot.x,
            'y': problem.depot.y,
            'ready_time': problem.depot.ready_time,
            'due_time': problem.depot.due_time
        },
        'customers': [
            {
                'id': c.id,
                'x': c.x,
                'y': c.y,
                'demand': c.demand,
                'service_time': c.service_time,
                'time_window': c.time_window
            }
            for c in problem.customers
        ],
        'charging_stations': [
            {
                'id': s.id,
                'x': s.x,
                'y': s.y,
                'charging_rate': s.charging_rate,
                'waiting_cost': s.waiting_cost
            }
            for s in problem.charging_stations
        ],
        'vehicle_constraints': {
            'capacity': problem.vehicle_capacity,
            'battery': problem.vehicle_battery,
            'consumption_rate': problem.consumption_rate,
            'loading_time': problem.loading_time,
            'speed': problem.speed
        }
    }
    
    with open(filename, 'w', encoding='utf-8') as f:
        json.dump(instance_data, f, ensure_ascii=False, indent=2)
    
    print(f"问题实例已保存到: {filename}")


def load_problem_instance(filename: str) -> EVRPProblem:
    """从JSON文件加载问题实例"""
    with open(filename, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    problem = EVRPProblem()
    
    # 添加配送中心
    depot_data = data['depot']
    depot = Depot(
        id=depot_data['id'],
        x=depot_data['x'],
        y=depot_data['y'],
        ready_time=depot_data['ready_time'],
        due_time=depot_data['due_time']
    )
    problem.add_depot(depot)
    
    # 添加客户
    for customer_data in data['customers']:
        customer = Customer(
            id=customer_data['id'],
            x=customer_data['x'],
            y=customer_data['y'],
            demand=customer_data['demand'],
            service_time=customer_data['service_time'],
            time_window=tuple(customer_data['time_window'])
        )
        problem.add_customer(customer)
    
    # 添加充电站
    for station_data in data['charging_stations']:
        station = ChargingStation(
            id=station_data['id'],
            x=station_data['x'],
            y=station_data['y'],
            charging_rate=station_data['charging_rate'],
            waiting_cost=station_data['waiting_cost']
        )
        problem.add_charging_station(station)
    
    # 设置车辆约束
    vc = data['vehicle_constraints']
    problem.set_vehicle_constraints(
        capacity=vc['capacity'],
        battery=vc['battery'],
        consumption_rate=vc['consumption_rate'],
        loading_time=vc['loading_time']
    )
    problem.speed = vc['speed']
    
    print(f"问题实例已从 {filename} 加载")
    return problem


def run_benchmark():
    """运行基准测试，比较不同规模的问题"""
    print("=" * 60)
    print("EVRP Gurobi求解器基准测试")
    print("=" * 60)
    
    # 测试用例配置
    test_cases = [
        {
            'name': '小规模 (6客户, 2充电站)',
            'config': {
                'num_customers': 6,
                'num_stations': 2,
                'map_size': 60.0,
                'vehicle_capacity': 25.0,
                'vehicle_battery': 60.0,
                'consumption_rate': 1.0
            },
            'time_limit': 30
        },
        {
            'name': '中等规模 (10客户, 3充电站)',
            'config': {
                'num_customers': 10,
                'num_stations': 3,
                'map_size': 100.0,
                'vehicle_capacity': 40.0,
                'vehicle_battery': 90.0,
                'consumption_rate': 0.8
            },
            'time_limit': 120
        },
        {
            'name': '大规模 (12客户, 4充电站)',
            'config': {
                'num_customers': 12,
                'num_stations': 4,
                'map_size': 120.0,
                'vehicle_capacity': 45.0,
                'vehicle_battery': 100.0,
                'consumption_rate': 0.7
            },
            'time_limit': 300
        }
    ]
    
    results = []
    
    for case in test_cases:
        print(f"\n{case['name']}:")
        print("-" * 40)
        
        # 创建问题实例
        generator = EVRPDataGenerator(seed=42)
        problem = generator.create_problem_instance(**case['config'])
        
        # 求解
        start_time = time.time()
        result = solve_evrp_with_gurobi(problem, time_limit=case['time_limit'])
        total_time = time.time() - start_time
        
        # 记录结果
        case_result = {
            'name': case['name'],
            'problem_size': len(problem.customers),
            'solve_time': total_time,
            'status': result['status'],
            'objective_value': result.get('objective_value'),
            'num_vehicles': result['solution']['num_vehicles'] if result['solution'] else None
        }
        
        results.append(case_result)
        
        # 保存结果
        filename = f"benchmark_{case['name'].replace(' ', '_').replace('(', '').replace(')', '')}.json"
        with open(filename, 'w', encoding='utf-8') as f:
            json.dump(result, f, ensure_ascii=False, indent=2, default=str)
    
    # 打印汇总结果
    print("\n" + "=" * 60)
    print("基准测试结果汇总")
    print("=" * 60)
    
    for result in results:
        print(f"{result['name']:<25} | "
              f"状态: {result['status']:<12} | "
              f"目标值: {result['objective_value']:<8.2f} | "
              f"时间: {result['solve_time']:<6.2f}s")


def main():
    """主函数"""
    import argparse
    
    parser = argparse.ArgumentParser(description='EVRP Gurobi求解器')
    parser.add_argument('--mode', choices=['test', 'benchmark', 'custom', 'load'],
                       default='test', help='运行模式')
    parser.add_argument('--config', type=str, help='自定义配置JSON文件')
    parser.add_argument('--time-limit', type=int, default=300, help='求解时间限制')
    parser.add_argument('--max-vehicles', type=int, help='最大车辆数')
    parser.add_argument('--save-instance', type=str, help='保存问题实例到文件')
    parser.add_argument('--load-instance', type=str, help='从文件加载问题实例')
    
    args = parser.parse_args()
    
    if args.mode == 'test':
        # 测试模式
        problem = create_test_instance()
        if args.save_instance:
            save_problem_instance(problem, args.save_instance)
        
        result = solve_evrp_with_gurobi(problem, args.time_limit, args.max_vehicles)
        
    elif args.mode == 'benchmark':
        # 基准测试模式
        run_benchmark()
        
    elif args.mode == 'custom':
        # 自定义模式
        if args.config:
            with open(args.config, 'r') as f:
                config = json.load(f)
            problem = create_custom_instance(config)
        else:
            # 使用默认自定义配置
            config = {
                'num_customers': 8,
                'num_stations': 2,
                'map_size': 80.0,
                'vehicle_capacity': 35.0,
                'vehicle_battery': 70.0,
                'consumption_rate': 0.9
            }
            problem = create_custom_instance(config)
        
        result = solve_evrp_with_gurobi(problem, args.time_limit, args.max_vehicles)
        
    elif args.mode == 'load':
        # 加载实例模式
        if not args.load_instance:
            print("错误: 加载模式需要指定--load-instance参数")
            return
        
        problem = load_problem_instance(args.load_instance)
        result = solve_evrp_with_gurobi(problem, args.time_limit, args.max_vehicles)
    
    # 保存最终结果
    timestamp = int(time.time())
    filename = f"evrp_gurobi_result_{timestamp}.json"
    
    if 'result' in locals():
        with open(filename, 'w', encoding='utf-8') as f:
            json.dump(result, f, ensure_ascii=False, indent=2, default=str)
        print(f"结果已保存到: {filename}")


if __name__ == "__main__":
    main()