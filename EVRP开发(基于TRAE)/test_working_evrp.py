"""
EVRP Gurobi求解器 - 工作版本测试
使用调试验证过的可行实例
"""

import numpy as np
import gurobipy as gp
from gurobipy import GRB
import json
import time
from typing import Dict
from evrp_solver import EVRPProblem, Customer, ChargingStation, Depot


class WorkingEVRPGurobiSolver:
    """工作版本的EVRP Gurobi求解器"""
    
    def __init__(self, problem: EVRPProblem, time_limit: int = 300):
        self.problem = problem
        self.time_limit = time_limit
        self.model = None
    
    def _calculate_distance(self, node1, node2) -> float:
        """计算距离"""
        return np.sqrt((node1.x - node2.x)**2 + (node1.y - node2.y)**2)
    
    def solve(self) -> Dict:
        """求解EVRP问题"""
        start_time = time.time()
        
        # 获取节点
        depot = self.problem.depot
        customers = self.problem.customers
        stations = self.problem.charging_stations
        
        all_nodes = [depot] + customers
        N = len(all_nodes)
        
        # 计算距离矩阵
        dist = np.zeros((N, N))
        for i in range(N):
            for j in range(N):
                if i != j:
                    dist[i,j] = self._calculate_distance(all_nodes[i], all_nodes[j])
        
        # 计算最小车辆数
        total_demand = sum(c.demand for c in customers)
        min_vehicles = max(1, int(np.ceil(total_demand / self.problem.vehicle_capacity)))
        max_vehicles = min_vehicles + 2  # 给一些余量
        
        print(f"问题规模: {len(customers)}客户, {min_vehicles}-{max_vehicles}车辆")
        
        # 创建模型
        model = gp.Model("EVRP_Working")
        model.setParam('TimeLimit', self.time_limit)
        model.setParam('OutputFlag', 0)  # 减少输出
        
        # 决策变量
        x = {}
        for i in range(N):
            for j in range(N):
                for k in range(max_vehicles):
                    if i != j:
                        x[i,j,k] = model.addVar(vtype=GRB.BINARY, name=f"x_{i}_{j}_{k}")
        
        # 载重变量 - 只为客户节点创建
        u = {}
        for i in range(1, N):  # 不包括配送中心
            for k in range(max_vehicles):
                u[i,k] = model.addVar(lb=all_nodes[i].demand, ub=self.problem.vehicle_capacity,
                                    vtype=GRB.CONTINUOUS, name=f"u_{i}_{k}")
        
        # 目标函数：最小化总距离
        model.setObjective(
            gp.quicksum(dist[i,j] * x[i,j,k] 
                       for i in range(N) for j in range(N) for k in range(max_vehicles) 
                       if i != j),
            GRB.MINIMIZE)
        
        # 约束条件
        
        # 1. 每个客户必须被访问一次
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
        
        # 5. 载重约束（MTZ公式）
        for i in range(1, N):
            for j in range(1, N):
                for k in range(max_vehicles):
                    if i != j:
                        model.addConstr(
                            u[j,k] >= u[i,k] + all_nodes[j].demand - 
                            self.problem.vehicle_capacity * (1 - x[i,j,k]))
        
        # 6. 初始载重为0
        for k in range(max_vehicles):
            model.addConstr(u[0,k] == 0)
        
        # 求解
        model.optimize()
        
        solve_time = time.time() - start_time
        
        if model.status in [GRB.OPTIMAL, GRB.TIME_LIMIT]:
            solution = self._extract_solution(model, all_nodes, max_vehicles)
            return {
                'status': 'optimal' if model.status == GRB.OPTIMAL else 'time_limit',
                'objective_value': model.objVal,
                'solve_time': solve_time,
                'gap': model.mipGap if hasattr(model, 'mipGap') else 0.0,
                'solution': solution
            }
        else:
            return {
                'status': 'infeasible',
                'objective_value': None,
                'solve_time': solve_time,
                'solution': None
            }
    
    def _extract_solution(self, model, all_nodes, max_vehicles) -> Dict:
        """提取解"""
        variables = model.getVars()
        x_values = {}
        
        for var in variables:
            if var.x > 0.5 and var.varName.startswith('x_'):
                parts = var.varName.split('_')
                i, j, k = int(parts[1]), int(parts[2]), int(parts[3])
                x_values[i, j, k] = 1
        
        # 构建路径
        routes = []
        depot_idx = 0
        
        for k in range(max_vehicles):
            route = []
            current = depot_idx
            
            while True:
                next_nodes = [j for (i, j, vehicle) in x_values.keys() 
                             if i == current and vehicle == k]
                
                if not next_nodes:
                    break
                
                next_node = next_nodes[0]
                if next_node == depot_idx:  # 返回配送中心
                    break
                
                if next_node < len(all_nodes):
                    node = all_nodes[next_node]
                    if hasattr(node, 'demand'):  # 是客户
                        route.append(node)
                
                current = next_node
            
            if route:
                routes.append(route)
        
        return {
            'routes': routes,
            'num_vehicles': len(routes),
            'total_distance': model.objVal
        }
    
    def print_solution(self, result: Dict):
        """打印结果"""
        print("\n" + "=" * 60)
        print("EVRP Gurobi求解结果")
        print("=" * 60)
        
        if result['status'] == 'optimal':
            print(f"✅ 找到最优解")
            print(f"总距离: {result['objective_value']:.2f}")
            print(f"求解时间: {result['solve_time']:.2f}秒")
        elif result['status'] == 'time_limit':
            print(f"⏰ 时间限制内找到解")
            print(f"总距离: {result['objective_value']:.2f}")
            print(f"间隙: {result['gap']:.2%}")
        else:
            print("❌ 无可行解")
            return
        
        if result['solution']:
            print(f"\n使用车辆: {result['solution']['num_vehicles']}")
            
            for idx, route in enumerate(result['solution']['routes'], 1):
                print(f"\n路径 {idx}:")
                route_str = "配送中心"
                total_distance = 0
                prev = self.problem.depot
                
                for customer in route:
                    dist = self._calculate_distance(prev, customer)
                    total_distance += dist
                    route_str += f" → 客户{customer.id}"
                    prev = customer
                
                # 返回配送中心
                dist = self._calculate_distance(prev, self.problem.depot)
                total_distance += dist
                route_str += " → 配送中心"
                
                print(route_str)
                print(f"路径长度: {total_distance:.2f}")


def create_working_instance():
    """创建保证可行的实例"""
    print("🎯 创建EVRP工作实例")
    
    # 手动创建问题实例
    problem = EVRPProblem()
    
    # 配送中心
    depot = Depot(id=0, x=50, y=50, ready_time=0, due_time=100)
    problem.add_depot(depot)
    
    # 客户（围绕配送中心分布）
    customers = [
        Customer(id=1, x=60, y=55, demand=8, service_time=2, time_window=(0, 100)),
        Customer(id=2, x=45, y=60, demand=6, service_time=3, time_window=(0, 100)),
        Customer(id=3, x=40, y=45, demand=7, service_time=2, time_window=(0, 100)),
        Customer(id=4, x=55, y=40, demand=5, service_time=2, time_window=(0, 100)),
    ]
    
    for customer in customers:
        problem.add_customer(customer)
    
    # 充电站（可选）
    station = ChargingStation(id=100, x=52, y=52, charging_rate=1.0)
    problem.add_charging_station(station)
    
    # 设置宽松的约束
    problem.set_vehicle_constraints(
        capacity=20.0,        # 足够容量
        battery=50.0,         # 充足电池
        consumption_rate=0.5, # 低耗电率
        loading_time=0
    )
    problem.speed = 1.0
    
    return problem


def test_working_solver():
    """测试工作求解器"""
    print("🚀 测试EVRP Gurobi求解器")
    print("=" * 60)
    
    # 创建问题实例
    problem = create_working_instance()
    
    # 打印问题信息
    print(f"📋 问题信息:")
    print(f"  客户数: {len(problem.customers)}")
    print(f"  充电站: {len(problem.charging_stations)}")
    print(f"  车辆容量: {problem.vehicle_capacity}")
    print(f"  电池容量: {problem.vehicle_battery}")
    
    print(f"\n📍 客户位置:")
    for customer in problem.customers:
        print(f"  客户{customer.id}: ({customer.x}, {customer.y}), 需求{customer.demand}")
    
    # 求解
    solver = WorkingEVRPGurobiSolver(problem, time_limit=60)
    result = solver.solve()
    
    # 打印结果
    solver.print_solution(result)
    
    # 保存结果
    with open('working_evrp_result.json', 'w') as f:
        json.dump(result, f, indent=2, default=str)
    
    return result


if __name__ == "__main__":
    test_working_solver()