"""
EVRP Gurobi精确求解器 - 最终版本
使用与遗传算法相同的算例和数据格式
"""

import numpy as np
import gurobipy as gp
from gurobipy import GRB
import json
import time
from typing import Dict, List, Tuple
from evrp_solver import EVRPProblem, Customer, ChargingStation, Depot
from data_generator import EVRPDataGenerator


class EVRPGurobiSolver:
    """EVRP Gurobi精确求解器"""
    
    def __init__(self, problem: EVRPProblem, time_limit: int = 300):
        self.problem = problem
        self.time_limit = time_limit
        
    def _calculate_distance(self, node1, node2) -> float:
        """计算两点间距离"""
        return np.sqrt((node1.x - node2.x)**2 + (node1.y - node2.y)**2)
    
    def _calculate_time(self, node1, node2) -> float:
        """计算两点间时间"""
        return self._calculate_distance(node1, node2) / self.problem.speed
    
    def solve(self) -> Dict:
        """求解EVRP问题"""
        start_time = time.time()
        
        # 获取所有节点
        depot = self.problem.depot
        customers = self.problem.customers
        stations = self.problem.charging_stations
        
        # 合并所有节点：配送中心 + 客户 + 充电站
        all_nodes = [depot] + customers + stations
        node_types = ['depot'] + ['customer'] * len(customers) + ['station'] * len(stations)
        
        N = len(all_nodes)
        depot_idx = 0
        customer_indices = list(range(1, len(customers) + 1))
        station_indices = list(range(len(customers) + 1, N))
        
        print(f"📊 问题规模:")
        print(f"  总节点: {N}")
        print(f"  客户: {len(customers)}")
        print(f"  充电站: {len(stations)}")
        
        # 计算距离和时间矩阵
        dist = np.zeros((N, N))
        time_matrix = np.zeros((N, N))
        for i in range(N):
            for j in range(N):
                if i != j:
                    dist[i,j] = self._calculate_distance(all_nodes[i], all_nodes[j])
                    time_matrix[i,j] = self._calculate_time(all_nodes[i], all_nodes[j])
        
        # 估计车辆数量
        total_demand = sum(c.demand for c in customers)
        min_vehicles = max(1, int(np.ceil(total_demand / self.problem.vehicle_capacity)))
        max_vehicles = min_vehicles + 2  # 给一些余量
        
        print(f"  总需求: {total_demand}")
        print(f"  车辆容量: {self.problem.vehicle_capacity}")
        print(f"  估计车辆: {min_vehicles}-{max_vehicles}")
        
        # 创建模型
        model = gp.Model("EVRP_Gurobi")
        model.setParam('TimeLimit', self.time_limit)
        model.setParam('MIPGap', 0.05)  # 5%的间隙
        
        # 决策变量
        x = {}  # 弧变量
        for i in range(N):
            for j in range(N):
                for k in range(max_vehicles):
                    if i != j:
                        x[i,j,k] = model.addVar(vtype=GRB.BINARY, name=f"x_{i}_{j}_{k}")
        
        # 载重变量
        u = {}
        for i in customer_indices:  # 只为客户节点
            for k in range(max_vehicles):
                u[i,k] = model.addVar(lb=all_nodes[i].demand, 
                                    ub=self.problem.vehicle_capacity,
                                    vtype=GRB.CONTINUOUS, name=f"u_{i}_{k}")
        
        # 电池电量变量
        b = {}
        for i in range(N):
            for k in range(max_vehicles):
                b[i,k] = model.addVar(lb=0, ub=self.problem.vehicle_battery,
                                    vtype=GRB.CONTINUOUS, name=f"b_{i}_{k}")
        
        # 到达时间变量
        t = {}
        for i in range(N):
            for k in range(max_vehicles):
                t[i,k] = model.addVar(lb=0, ub=all_nodes[i].due_time,
                                    vtype=GRB.CONTINUOUS, name=f"t_{i}_{k}")
        
        # 目标函数：最小化总距离
        model.setObjective(
            gp.quicksum(dist[i,j] * x[i,j,k] 
                       for i in range(N) for j in range(N) for k in range(max_vehicles) 
                       if i != j),
            GRB.MINIMIZE)
        
        # 约束条件
        
        # 1. 每个客户必须被访问一次
        for i in customer_indices:
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
        for i in customer_indices:
            for j in customer_indices:
                for k in range(max_vehicles):
                    if i != j:
                        model.addConstr(
                            u[j,k] >= u[i,k] + all_nodes[j].demand - 
                            self.problem.vehicle_capacity * (1 - x[i,j,k]))
        
        # 6. 电池约束
        for i in range(N):
            for j in range(N):
                for k in range(max_vehicles):
                    if i != j:
                        energy_consumed = dist[i,j] * self.problem.consumption_rate
                        model.addConstr(
                            b[j,k] <= b[i,k] - energy_consumed + 
                            self.problem.vehicle_battery * (1 - x[i,j,k]))
        
        # 7. 充电站约束
        for s in station_indices:
            for k in range(max_vehicles):
                # 充电站可以多次访问，但电量不能超过电池容量
                model.addConstr(b[s,k] <= self.problem.vehicle_battery)
                # 充电时间约束（简化：假设瞬时充电）
                model.addConstr(b[s,k] >= 0)
        
        # 8. 时间窗约束
        for i in range(N):
            for k in range(max_vehicles):
                model.addConstr(t[i,k] >= all_nodes[i].ready_time)
                model.addConstr(t[i,k] <= all_nodes[i].due_time)
        
        # 9. 时间一致性约束
        for i in range(N):
            for j in range(N):
                for k in range(max_vehicles):
                    if i != j:
                        service_time = all_nodes[i].service_time if node_types[i] == 'customer' else 0
                        model.addConstr(
                            t[j,k] >= t[i,k] + service_time + time_matrix[i,j] - 
                            1000 * (1 - x[i,j,k]))
        
        # 10. 初始条件
        for k in range(max_vehicles):
            model.addConstr(b[0,k] == self.problem.vehicle_battery)
            model.addConstr(t[0,k] == 0)
        
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
                'solution': solution,
                'model_status': model.status
            }
        else:
            return {
                'status': 'infeasible',
                'objective_value': None,
                'solve_time': solve_time,
                'solution': None,
                'model_status': model.status
            }
    
    def _extract_solution(self, model, all_nodes, max_vehicles, x) -> Dict:
        """提取解"""
        routes = []
        depot_idx = 0
        
        for k in range(max_vehicles):
            route = []
            current = depot_idx
            visited = set()
            
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
                
                if next_node not in visited:
                    node = all_nodes[next_node]
                    if hasattr(node, 'demand'):  # 客户节点
                        route.append(node)
                    visited.add(next_node)
                
                current = next_node
                if len(visited) > 20:  # 防止无限循环
                    break
            
            if route:
                routes.append(route)
        
        return {
            'routes': routes,
            'num_vehicles': len(routes),
            'total_distance': model.objVal
        }
    
    def print_solution(self, result: Dict):
        """打印解"""
        print("\n" + "=" * 60)
        print("EVRP Gurobi精确求解结果")
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


def test_with_same_instance():
    """使用与遗传算法相同的算例测试"""
    print("🚀 测试EVRP Gurobi求解器（与遗传算法相同算例）")
    print("=" * 60)
    
    # 创建与遗传算法相同的问题实例
    generator = EVRPDataGenerator()
    
    # 生成中规模实例（与遗传算法测试相同）
    problem = generator.create_problem_instance(
        num_customers=15,
        num_stations=3,
        map_size=100,
        customer_distribution='uniform',
        station_distribution='strategic',
        vehicle_capacity=50.0,
        vehicle_battery=100.0,
        consumption_rate=1.0
    )
    
    # 打印问题信息
    print(f"📋 问题信息:")
    print(f"  客户数: {len(problem.customers)}")
    print(f"  充电站: {len(problem.charging_stations)}")
    print(f"  车辆容量: {problem.vehicle_capacity}")
    print(f"  电池容量: {problem.vehicle_battery}")
    print(f"  耗电率: {problem.consumption_rate}")
    
    # 求解
    solver = EVRPGurobiSolver(problem, time_limit=120)
    result = solver.solve()
    
    # 打印结果
    solver.print_solution(result)
    
    # 保存结果
    with open('evrp_gurobi_final_result.json', 'w') as f:
        json.dump(result, f, indent=2, default=str)
    
    return result


def compare_with_genetic():
    """与遗传算法结果比较"""
    print("\n" + "=" * 60)
    print("与遗传算法结果比较")
    print("=" * 60)
    
    # 这里可以加载遗传算法的结果进行比较
    # 由于我们没有保存的遗传算法结果，这里只是框架
    
    print("📊 比较框架:")
    print("  1. 相同问题实例")
    print("  2. 相同约束条件")
    print("  3. 相同目标函数")
    print("  4. 计算时间比较")
    print("  5. 解质量比较")


if __name__ == "__main__":
    # 测试
    result = test_with_same_instance()
    compare_with_genetic()