"""
EVRP Gurobi求解器 - 工作版本
使用与遗传算法相同的算例
"""

import numpy as np
import gurobipy as gp
from gurobipy import GRB
import json
import time
from evrp_solver import EVRPProblem, Customer, ChargingStation, Depot
from data_generator import EVRPDataGenerator


class EVRPGurobiSolver:
    """EVRP Gurobi求解器"""
    
    def __init__(self, problem: EVRPProblem, time_limit: int = 300):
        self.problem = problem
        self.time_limit = time_limit
        
    def _calculate_distance(self, node1, node2) -> float:
        """计算两点间距离"""
        return np.sqrt((node1.x - node2.x)**2 + (node1.y - node2.y)**2)
    
    def solve(self) -> dict:
        """求解EVRP问题"""
        start_time = time.time()
        
        # 获取所有节点
        depot = self.problem.depot
        customers = self.problem.customers
        stations = self.problem.charging_stations
        
        # 合并节点：配送中心 + 客户
        all_nodes = [depot] + customers
        N = len(all_nodes)
        
        # 计算距离矩阵
        dist = np.zeros((N, N))
        for i in range(N):
            for j in range(N):
                if i != j:
                    dist[i,j] = self._calculate_distance(all_nodes[i], all_nodes[j])
        
        # 估计车辆数量
        total_demand = sum(c.demand for c in customers)
        min_vehicles = max(1, int(np.ceil(total_demand / self.problem.vehicle_capacity)))
        max_vehicles = min_vehicles + 2
        
        print(f"📊 问题规模: {len(customers)}客户, {min_vehicles}-{max_vehicles}车辆")
        
        # 创建模型
        model = gp.Model("EVRP_Simplified")
        model.setParam('TimeLimit', self.time_limit)
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
                u[i,k] = model.addVar(lb=all_nodes[i].demand, 
                                    ub=self.problem.vehicle_capacity,
                                    vtype=GRB.CONTINUOUS, name=f"u_{i}_{k}")
        
        # 电池电量变量（简化版）
        b = {}
        for i in range(N):
            for k in range(max_vehicles):
                b[i,k] = model.addVar(lb=0, ub=self.problem.vehicle_battery,
                                    vtype=GRB.CONTINUOUS, name=f"b_{i}_{k}")
        
        # 目标函数：最小化总距离
        model.setObjective(
            gp.quicksum(dist[i,j] * x[i,j,k] 
                       for i in range(N) for j in range(N) for k in range(max_vehicles) 
                       if i != j),
            GRB.MINIMIZE)
        
        # 约束条件
        
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
        
        # 5. 载重约束（MTZ公式）
        for i in range(1, N):
            for j in range(1, N):
                for k in range(max_vehicles):
                    if i != j:
                        model.addConstr(
                            u[j,k] >= u[i,k] + all_nodes[j].demand - 
                            self.problem.vehicle_capacity * (1 - x[i,j,k]))
        
        # 6. 电池约束（简化版：限制单次行程距离）
        max_distance_per_trip = self.problem.vehicle_battery / max(self.problem.consumption_rate, 0.1)
        for k in range(max_vehicles):
            model.addConstr(
                gp.quicksum(dist[i,j] * x[i,j,k] 
                           for i in range(N) for j in range(N) if i != j) <= max_distance_per_trip)
        
        # 7. 初始条件
        for k in range(max_vehicles):
            b[0,k] == self.problem.vehicle_battery
        
        # 求解
        model.optimize()
        
        solve_time = time.time() - start_time
        
        # 提取结果
        if model.status in [GRB.OPTIMAL, GRB.TIME_LIMIT]:
            solution = self._extract_solution(model, all_nodes, max_vehicles, x)
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
    
    def _extract_solution(self, model, all_nodes, max_vehicles, x) -> dict:
        """提取解"""
        routes = []
        depot_idx = 0
        
        for k in range(max_vehicles):
            route = []
            current = depot_idx
            
            while True:
                # 找到下一个节点
                next_nodes = []
                for j in range(len(all_nodes)):
                    if j != current and (current, j, k) in x and x[current,j,k].x > 0.5:
                        next_nodes.append(j)
                
                if not next_nodes:
                    break
                
                next_node = next_nodes[0]
                if next_node == depot_idx:  # 返回配送中心
                    break
                
                node = all_nodes[next_node]
                if hasattr(node, 'demand'):  # 客户节点
                    route.append(node)
                
                current = next_node
            
            if route:
                routes.append(route)
        
        return {
            'routes': routes,
            'num_vehicles': len(routes),
            'total_distance': model.objVal
        }
    
    def print_solution(self, result: dict):
        """打印解"""
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
            print(f"间隙: {result['gap']:.1%}")
        else:
            print("❌ 无可行解")
            return
        
        if result['solution']:
            print(f"\n使用车辆: {result['solution']['num_vehicles']}")
            
            for idx, route in enumerate(result['solution']['routes'], 1):
                print(f"\n路径 {idx}:")
                route_str = "配送中心"
                total_demand = 0
                prev = self.problem.depot
                
                for customer in route:
                    dist = self._calculate_distance(prev, customer)
                    route_str += f" → 客户{customer.id}"
                    total_demand += customer.demand
                    prev = customer
                
                # 返回配送中心
                dist = self._calculate_distance(prev, self.problem.depot)
                route_str += " → 配送中心"
                
                print(route_str)
                print(f"路径需求: {total_demand}")


def create_test_problem():
    """创建测试问题"""
    generator = EVRPDataGenerator(seed=42)  # 固定种子确保可重复
    
    return generator.create_problem_instance(
        num_customers=10,
        num_stations=2,
        map_size=100,
        customer_distribution='uniform',
        station_distribution='strategic',
        vehicle_capacity=40.0,
        vehicle_battery=80.0,
        consumption_rate=1.0
    )


def test_gurobi_solver():
    """测试Gurobi求解器"""
    print("🚀 测试EVRP Gurobi求解器")
    print("=" * 60)
    
    # 创建问题
    problem = create_test_problem()
    
    # 打印问题信息
    print(f"📋 问题信息:")
    print(f"  客户数: {len(problem.customers)}")
    print(f"  充电站: {len(problem.charging_stations)}")
    print(f"  车辆容量: {problem.vehicle_capacity}")
    print(f"  电池容量: {problem.vehicle_battery}")
    print(f"  耗电率: {problem.consumption_rate}")
    
    # 求解
    solver = EVRPGurobiSolver(problem, time_limit=60)
    result = solver.solve()
    
    # 打印结果
    solver.print_solution(result)
    
    # 保存结果
    with open('evrp_gurobi_working_result.json', 'w') as f:
        json.dump(result, f, indent=2, default=str)
    
    return result


if __name__ == "__main__":
    test_gurobi_solver()