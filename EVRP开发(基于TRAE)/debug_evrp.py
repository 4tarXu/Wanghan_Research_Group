"""
EVRP问题调试脚本
检查问题设置的可行性
"""

import numpy as np
import json
from data_generator import EVRPDataGenerator
from evrp_solver import EVRPProblem, Customer, ChargingStation, Depot


def debug_problem_instance(problem: EVRPProblem):
    """调试问题实例"""
    print("🔍 EVRP问题调试信息")
    print("=" * 50)
    
    # 基本信息
    print(f"📊 基本信息:")
    print(f"  客户数量: {len(problem.customers)}")
    print(f"  充电站数量: {len(problem.charging_stations)}")
    print(f"  车辆容量: {problem.vehicle_capacity}")
    print(f"  电池容量: {problem.vehicle_battery}")
    print(f"  耗电率: {problem.consumption_rate}")
    
    # 客户需求分析
    total_demand = sum(c.demand for c in problem.customers)
    min_vehicles = max(1, int(np.ceil(total_demand / problem.vehicle_capacity)))
    
    print(f"\n📦 需求分析:")
    print(f"  总需求: {total_demand:.2f}")
    print(f"  车辆容量: {problem.vehicle_capacity}")
    print(f"  最小车辆数: {min_vehicles}")
    
    # 位置分析
    all_nodes = [problem.depot] + problem.customers + problem.charging_stations
    
    print(f"\n📍 位置分析:")
    print(f"  配送中心: ({problem.depot.x:.1f}, {problem.depot.y:.1f})")
    
    # 计算最大距离
    max_distance = 0
    min_distance = float('inf')
    
    for customer in problem.customers:
        dist = problem.calculate_distance(problem.depot, customer)
        max_distance = max(max_distance, dist)
        min_distance = min(min_distance, dist)
    
    print(f"  最大客户距离: {max_distance:.2f}")
    print(f"  最小客户距离: {min_distance:.2f}")
    
    # 电池分析
    max_trip_distance = max_distance * 2  # 往返
    max_energy_needed = max_trip_distance * problem.consumption_rate
    
    print(f"\n🔋 电池分析:")
    print(f"  最大往返距离: {max_trip_distance:.2f}")
    print(f"  最大能耗: {max_energy_needed:.2f}")
    print(f"  电池容量: {problem.vehicle_battery}")
    print(f"  电池充足: {'✅' if max_energy_needed <= problem.vehicle_battery else '❌'}")
    
    # 时间窗分析
    print(f"\n⏰ 时间窗分析:")
    depot = problem.depot
    for i, customer in enumerate(problem.customers[:3]):  # 显示前3个
        dist = problem.calculate_distance(depot, customer)
        travel_time = dist / problem.speed
        print(f"  客户{i+1}: 距离={dist:.1f}, 旅行时间={travel_time:.1f}, "
              f"时间窗={customer.time_window}, 服务时间={customer.service_time}")
    
    # 可行性检查
    feasible = True
    issues = []
    
    # 检查电池
    if max_energy_needed > problem.vehicle_battery:
        feasible = False
        issues.append("电池容量不足")
    
    # 检查时间窗
    for customer in problem.customers:
        dist = problem.calculate_distance(depot, customer)
        travel_time = dist / problem.speed
        
        if travel_time > customer.time_window[1]:
            feasible = False
            issues.append(f"客户{customer.id}时间窗不可达")
    
    print(f"\n✅ 可行性评估:")
    print(f"  状态: {'✅ 可行' if feasible else '❌ 不可行'}")
    if issues:
        print(f"  问题: {', '.join(issues)}")
    
    return {
        'feasible': feasible,
        'total_demand': total_demand,
        'min_vehicles': min_vehicles,
        'max_distance': max_distance,
        'max_energy_needed': max_energy_needed,
        'issues': issues
    }


def create_feasible_instance():
    """创建保证可行的问题实例"""
    print("\n🛠️ 创建可行的问题实例")
    print("-" * 30)
    
    # 手动创建问题，确保所有约束都可行
    problem = EVRPProblem()
    
    # 配送中心在中心
    depot = Depot(id=0, x=50, y=50, ready_time=0, due_time=200)
    problem.add_depot(depot)
    
    # 客户位置靠近配送中心，确保电池和时间窗可行
    customers = [
        Customer(id=1, x=60, y=50, demand=5, service_time=2, time_window=(0, 50)),
        Customer(id=2, x=40, y=50, demand=8, service_time=3, time_window=(0, 60)),
        Customer(id=3, x=50, y=60, demand=6, service_time=2, time_window=(0, 55)),
        Customer(id=4, x=50, y=40, demand=7, service_time=3, time_window=(0, 65)),
    ]
    
    for customer in customers:
        problem.add_customer(customer)
    
    # 添加充电站（可选）
    stations = [
        ChargingStation(id=100, x=55, y=55, charging_rate=2.0, waiting_cost=0.1),
    ]
    
    for station in stations:
        problem.add_charging_station(station)
    
    # 设置宽松的约束
    problem.set_vehicle_constraints(
        capacity=30.0,        # 足够大的容量
        battery=100.0,        # 足够大的电池
        consumption_rate=0.5, # 较低的耗电率
        loading_time=0
    )
    problem.speed = 2.0     # 较快的速度
    
    return problem


def test_simple_vrp():
    """测试最简单的VRP问题"""
    print("\n🧪 测试最简单的VRP")
    print("-" * 30)
    
    problem = EVRPProblem()
    
    # 极简设置
    depot = Depot(id=0, x=0, y=0)
    problem.add_depot(depot)
    
    customers = [
        Customer(id=1, x=10, y=0, demand=5),
        Customer(id=2, x=0, y=10, demand=5),
    ]
    
    for customer in customers:
        problem.add_customer(customer)
    
    problem.set_vehicle_constraints(
        capacity=20.0,
        battery=50.0,
        consumption_rate=1.0
    )
    
    return problem


def create_well_scaled_instance():
    """创建比例合适的问题实例"""
    print("\n📐 创建比例合适的问题实例")
    print("-" * 30)
    
    generator = EVRPDataGenerator(seed=123)
    
    # 使用更合适的参数
    problem = generator.create_problem_instance(
        num_customers=4,          # 很小的规模
        num_stations=1,           # 1个充电站
        map_size=20.0,            # 小地图
        vehicle_capacity=20.0,    # 合适容量
        vehicle_battery=50.0,     # 充足电池
        consumption_rate=0.3,     # 低耗电率
        customer_distribution='uniform'
    )
    
    return problem


def main():
    """主调试函数"""
    print("🔧 EVRP问题调试开始")
    print("=" * 60)
    
    # 测试不同的问题实例
    test_cases = [
        ("可行实例", create_feasible_instance),
        ("简单VRP", test_simple_vrp),
        ("比例合适实例", create_well_scaled_instance)
    ]
    
    results = []
    
    for name, create_func in test_cases:
        print(f"\n🧪 测试: {name}")
        try:
            problem = create_func()
            debug_result = debug_problem_instance(problem)
            results.append({
                'name': name,
                'problem': problem,
                'debug': debug_result
            })
            
            # 保存调试结果
            with open(f'debug_{name.replace(" ", "_")}.json', 'w') as f:
                json.dump(debug_result, f, indent=2, default=str)
                
        except Exception as e:
            print(f"❌ 创建失败: {e}")
    
    # 汇总结果
    print("\n📊 调试结果汇总")
    print("=" * 60)
    
    for result in results:
        debug = result['debug']
        print(f"{result['name']:<15} | "
              f"可行: {'✅' if debug['feasible'] else '❌'} | "
              f"需求: {debug['total_demand']:<5.1f} | "
              f"最小车辆: {debug['min_vehicles']} | "
              f"最大距离: {debug['max_distance']:<5.1f}")
    
    return results


if __name__ == "__main__":
    main()