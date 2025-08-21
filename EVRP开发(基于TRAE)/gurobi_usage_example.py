"""
EVRP Gurobi求解器使用示例
演示如何使用Gurobi求解电动车路径规划问题
"""

import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from evrp_solver import EVRPProblem, Customer, ChargingStation, Depot
from evrp_gurobi_solver import solve_evrp_with_gurobi
from data_generator import EVRPDataGenerator


def simple_usage_example():
    """简单使用示例"""
    print("🚛 EVRP Gurobi求解器使用示例")
    print("=" * 50)
    
    # 1. 创建数据生成器
    generator = EVRPDataGenerator(seed=42)
    
    # 2. 生成问题实例（与遗传算法相同的格式）
    problem = generator.create_problem_instance(
        num_customers=8,          # 8个客户
        num_stations=2,           # 2个充电站
        map_size=80.0,            # 80x80地图
        vehicle_capacity=30.0,    # 车辆容量30
        vehicle_battery=70.0,     # 电池容量70
        consumption_rate=0.9      # 耗电率0.9
    )
    
    # 3. 打印问题信息
    print(f"📍 配送中心: ({problem.depot.x}, {problem.depot.y})")
    print(f"👥 客户数: {len(problem.customers)}")
    print(f"🔋 充电站数: {len(problem.charging_stations)}")
    print(f"🚛 车辆容量: {problem.vehicle_capacity}")
    print(f"🔋 电池容量: {problem.vehicle_battery}")
    
    print("\n📋 客户信息:")
    for i, customer in enumerate(problem.customers, 1):
        print(f"  客户{i}: 位置({customer.x:.1f}, {customer.y:.1f}), "
              f"需求{customer.demand}, 时间窗{customer.time_window}")
    
    print("\n🔌 充电站信息:")
    for i, station in enumerate(problem.charging_stations, 1):
        print(f"  充电站{i}: 位置({station.x:.1f}, {station.y:.1f}), "
              f"充电速率{station.charging_rate}")
    
    print("\n🧮 正在使用Gurobi求解...")
    
    # 4. 使用Gurobi求解
    result = solve_evrp_with_gurobi(
        problem=problem,
        time_limit=60,      # 60秒时间限制
        max_vehicles=3      # 最多使用3辆车
    )
    
    return result


def advanced_usage_example():
    """高级使用示例"""
    print("\n🔧 高级使用示例")
    print("=" * 50)
    
    # 创建自定义问题
    problem = EVRPProblem()
    
    # 手动添加配送中心
    depot = Depot(id=0, x=50, y=50, ready_time=0, due_time=200)
    problem.add_depot(depot)
    
    # 手动添加客户
    customers = [
        Customer(id=1, x=20, y=30, demand=10, service_time=5, time_window=(10, 40)),
        Customer(id=2, x=80, y=20, demand=15, service_time=8, time_window=(20, 50)),
        Customer(id=3, x=60, y=70, demand=8, service_time=6, time_window=(30, 60)),
        Customer(id=4, x=30, y=80, demand=12, service_time=7, time_window=(15, 45)),
        Customer(id=5, x=70, y=40, demand=20, service_time=10, time_window=(25, 55))
    ]
    
    for customer in customers:
        problem.add_customer(customer)
    
    # 手动添加充电站
    stations = [
        ChargingStation(id=100, x=35, y=35, charging_rate=2.0, waiting_cost=0.1),
        ChargingStation(id=101, x=65, y=65, charging_rate=1.5, waiting_cost=0.15)
    ]
    
    for station in stations:
        problem.add_charging_station(station)
    
    # 设置车辆约束
    problem.set_vehicle_constraints(
        capacity=50.0,
        battery=100.0,
        consumption_rate=1.0,
        loading_time=0
    )
    problem.speed = 1.0
    
    # 创建求解器并求解
    from evrp_gurobi_solver import EVRPGurobiSolver
    
    solver = EVRPGurobiSolver(problem, time_limit=120)
    result = solver.solve(max_vehicles=2)
    
    return result


def performance_comparison():
    """性能比较示例"""
    print("\n📊 性能比较示例")
    print("=" * 50)
    
    generator = EVRPDataGenerator(seed=42)
    
    # 不同规模的问题
    test_cases = [
        ("小规模", {'num_customers': 5, 'num_stations': 1}),
        ("中等规模", {'num_customers': 8, 'num_stations': 2}),
        ("大规模", {'num_customers': 12, 'num_stations': 3})
    ]
    
    results = []
    
    for name, params in test_cases:
        print(f"\n🧪 测试 {name}...")
        
        problem = generator.create_problem_instance(
            **params,
            map_size=100.0,
            vehicle_capacity=30.0,
            vehicle_battery=80.0,
            consumption_rate=0.8
        )
        
        result = solve_evrp_with_gurobi(
            problem=problem,
            time_limit=60,
            max_vehicles=3
        )
        
        results.append({
            'name': name,
            'customers': len(problem.customers),
            'stations': len(problem.charging_stations),
            'status': result['status'],
            'objective': result.get('objective_value'),
            'time': result['solve_time']
        })
    
    # 打印结果汇总
    print("\n📈 结果汇总:")
    print("-" * 50)
    for r in results:
        print(f"{r['name']:<10} | "
              f"客户: {r['customers']} | "
              f"状态: {r['status']:<10} | "
              f"距离: {r['objective']:<8.2f} | "
              f"时间: {r['time']:<6.2f}s")


def interactive_demo():
    """交互式演示"""
    print("\n🎯 交互式EVRP求解器")
    print("=" * 50)
    
    try:
        # 获取用户输入
        num_customers = int(input("请输入客户数量 (3-15): ") or "8")
        num_stations = int(input("请输入充电站数量 (1-5): ") or "2")
        time_limit = int(input("请输入求解时间限制(秒) (30-300): ") or "120")
        
        # 验证输入
        num_customers = max(3, min(15, num_customers))
        num_stations = max(1, min(5, num_stations))
        time_limit = max(30, min(300, time_limit))
        
        print(f"\n🚀 正在求解 {num_customers}客户, {num_stations}充电站 的问题...")
        
        # 创建并求解
        generator = EVRPDataGenerator(seed=42)
        problem = generator.create_problem_instance(
            num_customers=num_customers,
            num_stations=num_stations,
            map_size=100.0,
            vehicle_capacity=40.0,
            vehicle_battery=90.0,
            consumption_rate=0.8
        )
        
        result = solve_evrp_with_gurobi(
            problem=problem,
            time_limit=time_limit,
            max_vehicles=min(5, num_customers // 2 + 1)
        )
        
        return result
        
    except ValueError:
        print("❌ 请输入有效的数字")
        return None


def main():
    """主函数 - 运行示例"""
    print("欢迎使用EVRP Gurobi求解器示例！")
    print("\n选择运行模式:")
    print("1. 简单示例 (推荐)")
    print("2. 高级示例")
    print("3. 性能比较")
    print("4. 交互式演示")
    
    choice = input("\n请输入选择 (1-4): ") or "1"
    
    if choice == "1":
        result = simple_usage_example()
    elif choice == "2":
        result = advanced_usage_example()
    elif choice == "3":
        performance_comparison()
        return
    elif choice == "4":
        result = interactive_demo()
    else:
        print("使用默认简单示例")
        result = simple_usage_example()
    
    if result:
        print(f"\n✅ 求解完成！")
        print(f"📁 完整结果已保存到当前目录")


if __name__ == "__main__":
    main()