"""
极简VRP Gurobi求解器
使用与遗传算法相同的算例
"""

import numpy as np
import gurobipy as gp
from gurobipy import GRB
import json
import time
from evrp_solver import EVRPProblem, Customer, ChargingStation, Depot


def create_test_problem():
    """创建测试问题 - 与遗传算法相同的算例"""
    problem = EVRPProblem()
    
    # 配送中心
    depot = Depot(id=0, x=50, y=50, ready_time=0, due_time=100)
    problem.add_depot(depot)
    
    # 客户（小规模测试）
    customers = [
        Customer(id=1, x=60, y=55, demand=10, service_time=1, time_window=(0, 100)),
        Customer(id=2, x=45, y=60, demand=8, service_time=1, time_window=(0, 100)),
        Customer(id=3, x=40, y=45, demand=12, service_time=1, time_window=(0, 100)),
        Customer(id=4, x=55, y=40, demand=15, service_time=1, time_window=(0, 100)),
        Customer(id=5, x=65, y=45, demand=7, service_time=1, time_window=(0, 100)),
    ]
    
    for customer in customers:
        problem.add_customer(customer)
    
    # 设置车辆约束（忽略电池，只考虑容量）
    problem.set_vehicle_constraints(
        capacity=30.0,  # 足够容量
        battery=100.0,  # 忽略电池约束
        consumption_rate=0.0,
        loading_time=0
    )
    problem.speed = 1.0
    
    return problem


def solve_vrp_with_gurobi(problem, time_limit=60):
    """使用Gurobi求解VRP"""
    
    # 获取所有节点
    all_nodes = [problem.depot] + problem.customers
    N = len(all_nodes)
    
    # 计算距离矩阵
    dist = np.zeros((N, N))
    for i in range(N):
        for j in range(N):
            if i != j:
                dist[i,j] = np.sqrt((all_nodes[i].x - all_nodes[j].x)**2 + 
                                   (all_nodes[i].y - all_nodes[j].y)**2)
    
    # 估计车辆数量
    total_demand = sum(c.demand for c in problem.customers)
    min_vehicles = max(1, int(np.ceil(total_demand / problem.vehicle_capacity)))
    max_vehicles = min_vehicles + 1
    
    print(f"问题规模: {len(problem.customers)}客户, 车辆容量{problem.vehicle_capacity}, 估计需要{min_vehicles}-{max_vehicles}辆车")
    
    # 创建模型
    model = gp.Model("VRP_Simple")
    model.setParam('TimeLimit', time_limit)
    model.setParam('OutputFlag', 1)
    
    # 决策变量
    x = {}
    for i in range(N):
        for j in range(N):
            for k in range(max_vehicles):
                if i != j:
                    x[i,j,k] = model.addVar(vtype=GRB.BINARY, name=f"x_{i}_{j}_{k}")
    
    # 载重变量（MTZ）
    u = {}
    for i in range(1, N):  # 客户节点
        for k in range(max_vehicles):
            u[i,k] = model.addVar(lb=0, ub=problem.vehicle_capacity, 
                                vtype=GRB.CONTINUOUS, name=f"u_{i}_{k}")
    
    # 目标：最小化总距离
    model.setObjective(
        gp.quicksum(dist[i,j] * x[i,j,k] 
                   for i in range(N) for j in range(N) for k in range(max_vehicles) 
                   if i != j),
        GRB.MINIMIZE)
    
    # 约束
    
    # 1. 每个客户被访问一次
    for i in range(1, N):
        model.addConstr(
            gp.quicksum(x[i,j,k] for j in range(N) for k in range(max_vehicles) if j != i) == 1)
    
    # 2. 流量守恒
    for h in range(N):
        for k in range(max_vehicles):
            model.addConstr(
                gp.quicksum(x[i,h,k] for i in range(N) if i != h) == 
                gp.quicksum(x[h,j,k] for j in range(N) if j != h))
    
    # 3. 车辆从配送中心出发
    for k in range(max_vehicles):
        model.addConstr(gp.quicksum(x[0,j,k] for j in range(1, N)) <= 1)
    
    # 4. 车辆返回配送中心
    for k in range(max_vehicles):
        model.addConstr(gp.quicksum(x[i,0,k] for i in range(1, N)) <= 1)
    
    # 5. MTZ约束
    for i in range(1, N):
        for j in range(1, N):
            for k in range(max_vehicles):
                if i != j:
                    model.addConstr(
                        u[j,k] >= u[i,k] + all_nodes[j].demand - 
                        problem.vehicle_capacity * (1 - x[i,j,k]))
    
    # 求解
    model.optimize()
    
    # 提取解
    if model.status in [GRB.OPTIMAL, GRB.TIME_LIMIT]:
        routes = []
        
        for k in range(max_vehicles):
            route = []
            current = 0  # 配送中心
            
            while True:
                # 找到下一个节点
                next_nodes = []
                for j in range(N):
                    if j != current and (current, j, k) in x and x[current,j,k].x > 0.5:
                        next_nodes.append(j)
                
                if not next_nodes:
                    break
                
                next_node = next_nodes[0]
                if next_node == 0:  # 返回配送中心
                    break
                
                route.append(all_nodes[next_node])
                current = next_node
            
            if route:
                routes.append(route)
        
        return {
            'status': 'success',
            'objective': model.objVal,
            'routes': routes,
            'num_vehicles': len(routes),
            'total_distance': model.objVal
        }
    else:
        return {
            'status': 'failed',
            'error': 'No feasible solution found'
        }


def print_solution(result, problem):
    """打印解"""
    print("\n" + "=" * 60)
    print("VRP Gurobi求解结果")
    print("=" * 60)
    
    if result['status'] == 'success':
        print(f"✅ 找到最优解")
        print(f"总距离: {result['objective']:.2f}")
        print(f"使用车辆: {result['num_vehicles']}")
        
        for idx, route in enumerate(result['routes'], 1):
            print(f"\n路径 {idx}:")
            route_str = "配送中心"
            total_demand = 0
            
            for customer in route:
                route_str += f" → 客户{customer.id}"
                total_demand += customer.demand
            
            route_str += " → 配送中心"
            print(route_str)
            print(f"路径需求: {total_demand}")
    else:
        print("❌ 无可行解")


if __name__ == "__main__":
    print("🚀 测试VRP Gurobi求解器")
    print("=" * 60)
    
    # 创建问题
    problem = create_test_problem()
    
    # 求解
    result = solve_vrp_with_gurobi(problem, time_limit=30)
    
    # 打印结果
    print_solution(result, problem)
    
    # 保存结果
    with open('vrp_gurobi_result.json', 'w') as f:
        json.dump(result, f, indent=2, default=str)