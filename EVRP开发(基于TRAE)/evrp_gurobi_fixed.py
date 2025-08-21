"""
EVRP Gurobi求解器 - 修复版本
修复了约束条件过于严格导致无可行解的问题
"""

import numpy as np
import gurobipy as gp
from gurobipy import GRB
import json
import time
from typing import Dict, List, Tuple
from evrp_solver import EVRPProblem, Customer, ChargingStation, Depot
from data_generator import EVRPDataGenerator


class FixedEVRPGurobiSolver:
    """修复后的EVRP Gurobi求解器"""
    
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
        
        # 估计车辆数量 - 使用更宽松的估计
        total_demand = sum(c.demand for c in customers)
        min_vehicles = max(1, int(np.ceil(total_demand / self.problem.vehicle_capacity)))
        max_vehicles = min_vehicles + 3  # 给更多余量
        
        print(f"  总需求: {total_demand}")
        print(f"  车辆容量: {self.problem.vehicle_capacity}")
        print(f"  估计车辆: {min_vehicles}-{max_vehicles}")
        
        # 创建模型
        model = gp.Model("EVRP_Fixed")
        model.setParam('TimeLimit', self.time_limit)
        model.setParam('MIPGap', 0.05)
        model.setParam('OutputFlag', 1)  # 显示求解过程
        
        # 决策变量
        x = {}  # 弧变量
        for i in range(N):
            for j in range(N):
                for k in range(max_vehicles):
                    if i != j:
                        x[i,j,k] = model.addVar(vtype=GRB.BINARY, name=f"x_{i}_{j}_{k}")
        
        # 载重变量 - 修复：使用更合理的上下界
        u = {}
        for i in customer_indices:
            for k in range(max_vehicles):
                u[i,k] = model.addVar(lb=0, ub=self.problem.vehicle_capacity,
                                    vtype=GRB.CONTINUOUS, name=f"u_{i}_{k}")
        
        # 电池电量变量 - 修复：允许在充电站充电
        b = {}
        for i in range(N):
            for k in range(max_vehicles):
                b[i,k] = model.addVar(lb=0, ub=self.problem.vehicle_battery,
                                    vtype=GRB.CONTINUOUS, name=f"b_{i}_{k}")
        
        # 到达时间变量 - 修复：使用合理的时间窗
        t = {}
        max_time = 1000  # 使用固定的大时间窗
        for i in range(N):
            for k in range(max_vehicles):
                t[i,k] = model.addVar(lb=0, ub=max_time,
                                    vtype=GRB.CONTINUOUS, name=f"t_{i}_{k}")
        
        # 客户时间窗约束 - 修复：检查属性存在性
        for i in customer_indices:
            customer = all_nodes[i]
            ready_time = getattr(customer, 'ready_time', 0)
            due_time = getattr(customer, 'due_time', 1000)
            for k in range(max_vehicles):
                model.addConstr(t[i,k] >= ready_time,
                               name=f"time_window_lower_{i}_{k}")
                model.addConstr(t[i,k] <= due_time,
                               name=f"time_window_upper_{i}_{k}")
        
        # 目标函数：最小化总距离
        model.setObjective(
            gp.quicksum(dist[i,j] * x[i,j,k] 
                       for i in range(N) for j in range(N) for k in range(max_vehicles) 
                       if i != j),
            GRB.MINIMIZE)
        
        # 约束条件 - 修复版本
        
        # 1. 每个客户必须被访问一次
        for i in customer_indices:
            model.addConstr(
                gp.quicksum(x[i,j,k] for j in range(N) for k in range(max_vehicles) if j != i) == 1,
                name=f"visit_customer_{i}")
        
        # 2. 流量守恒 - 修复：确保节点进出平衡
        for h in range(N):
            for k in range(max_vehicles):
                model.addConstr(
                    gp.quicksum(x[i,h,k] for i in range(N) if i != h) == 
                    gp.quicksum(x[h,j,k] for j in range(N) if j != h),
                    name=f"flow_conservation_{h}_{k}")
        
        # 3. 车辆从配送中心出发 - 修复：允许空车
        for k in range(max_vehicles):
            model.addConstr(gp.quicksum(x[0,j,k] for j in range(1, N)) <= 1,
                           name=f"depart_from_depot_{k}")
        
        # 4. 车辆返回配送中心 - 修复：确保返回
        for k in range(max_vehicles):
            model.addConstr(gp.quicksum(x[i,0,k] for i in range(1, N)) <= 1,
                           name=f"return_to_depot_{k}")
        
        # 5. 载重约束 - 修复：使用正确的MTZ公式
        for i in customer_indices:
            for j in customer_indices:
                for k in range(max_vehicles):
                    if i != j:
                        model.addConstr(
                            u[j,k] >= u[i,k] + all_nodes[j].demand - 
                            self.problem.vehicle_capacity * (1 - x[i,j,k]),
                            name=f"load_{i}_{j}_{k}")
        
        # 6. 电池约束 - 修复：允许在充电站充电
        for i in range(N):
            for j in range(N):
                for k in range(max_vehicles):
                    if i != j:
                        energy_consumed = dist[i,j] * self.problem.consumption_rate
                        # 如果j是充电站，可以充电到满电
                        if j in station_indices:
                            model.addConstr(
                                b[j,k] <= self.problem.vehicle_battery,
                                name=f"battery_charge_{i}_{j}_{k}")
                        else:
                            # 正常消耗
                            model.addConstr(
                                b[j,k] <= b[i,k] - energy_consumed + 
                                self.problem.vehicle_battery * (1 - x[i,j,k]),
                                name=f"battery_consume_{i}_{j}_{k}")
        
        # 7. 充电站约束 - 修复：允许多次访问
        for s in station_indices:
            for k in range(max_vehicles):
                model.addConstr(b[s,k] <= self.problem.vehicle_battery,
                               name=f"station_battery_{s}_{k}")
        
        # 8. 时间一致性约束 - 修复：使用合理的大M值
        big_M = 1000
        for i in range(N):
            for j in range(N):
                for k in range(max_vehicles):
                    if i != j:
                        service_time = all_nodes[i].service_time if node_types[i] == 'customer' else 0
                        model.addConstr(
                            t[j,k] >= t[i,k] + service_time + time_matrix[i,j] - 
                            big_M * (1 - x[i,j,k]),
                            name=f"time_consistency_{i}_{j}_{k}")
        
        # 9. 初始条件 - 修复：正确的初始状态
        for k in range(max_vehicles):
            model.addConstr(b[0,k] == self.problem.vehicle_battery,
                           name=f"initial_battery_{k}")
            model.addConstr(t[0,k] == 0,
                           name=f"initial_time_{k}")
        
        # 11. 消除子回路约束 - 修复：使用更强的MTZ约束
        for i in customer_indices:
            for j in customer_indices:
                for k in range(max_vehicles):
                    if i != j:
                        model.addConstr(
                            u[i,k] - u[j,k] + self.problem.vehicle_capacity * x[i,j,k] <= 
                            self.problem.vehicle_capacity - all_nodes[j].demand,
                            name=f"subtour_elimination_{i}_{j}_{k}")
        
        # 12. 充电站访问约束 - 修复：允许但不强制
        for s in station_indices:
            for k in range(max_vehicles):
                # 充电站可以被访问，但不是必须
                pass
        
        # 求解
        model.optimize()
        
        solve_time = time.time() - start_time
        
        # 提取结果
        if model.status in [GRB.OPTIMAL, GRB.TIME_LIMIT] and model.objVal < float('inf'):
            solution = self._extract_solution(model, all_nodes, max_vehicles, x)
            return {
                'status': 'optimal' if model.status == GRB.OPTIMAL else 'time_limit',
                'objective_value': model.objVal,
                'solve_time': solve_time,
                'gap': model.mipGap if hasattr(model, 'mipGap') else 0.0,
                'solution': solution,
                'model_status': model.status,
                'num_variables': model.numVars,
                'num_constraints': model.numConstrs
            }
        else:
            # 尝试简化问题
            print("❌ 无可行解，尝试简化约束...")
            return self._solve_relaxed_model(all_nodes, customer_indices, 
                                           station_indices, dist, time_matrix)
    
    def _solve_relaxed_model(self, all_nodes, customer_indices, 
                           station_indices, dist, time_matrix):
        """求解简化版本"""
        print("🔄 尝试求解简化VRP问题...")
        
        # 创建简化模型（忽略电池约束）
        model = gp.Model("EVRP_Relaxed")
        model.setParam('TimeLimit', 60)
        
        N = len(all_nodes)
        
        # 决策变量
        x = {}
        for i in range(N):
            for j in range(N):
                if i != j:
                    x[i,j] = model.addVar(vtype=GRB.BINARY, name=f"x_{i}_{j}")
        
        # 载重变量
        u = {}
        for i in customer_indices:
            u[i] = model.addVar(lb=0, ub=self.problem.vehicle_capacity,
                              vtype=GRB.CONTINUOUS, name=f"u_{i}")
        
        # 目标函数
        model.setObjective(
            gp.quicksum(dist[i,j] * x[i,j] for i in range(N) for j in range(N) if i != j),
            GRB.MINIMIZE)
        
        # 简化约束
        # 1. 每个客户访问一次
        for i in customer_indices:
            model.addConstr(gp.quicksum(x[i,j] for j in range(N) if j != i) == 1)
            model.addConstr(gp.quicksum(x[j,i] for j in range(N) if j != i) == 1)
        
        # 2. 流量守恒
        for h in range(N):
            model.addConstr(gp.quicksum(x[i,h] for i in range(N) if i != h) == 
                          gp.quicksum(x[h,j] for j in range(N) if j != h))
        
        # 3. 载重约束
        for i in customer_indices:
            for j in customer_indices:
                if i != j:
                    model.addConstr(
                        u[j] >= u[i] + all_nodes[j].demand - 
                        self.problem.vehicle_capacity * (1 - x[i,j]))
        
        # 求解
        model.optimize()
        
        if model.status == GRB.OPTIMAL:
            # 提取简化解
            routes = self._extract_simple_solution(model, all_nodes, x)
            return {
                'status': 'relaxed_optimal',
                'objective_value': model.objVal,
                'solve_time': 60,
                'solution': routes,
                'model_status': model.status
            }
        else:
            return {
                'status': 'infeasible',
                'objective_value': None,
                'solve_time': 60,
                'solution': None,
                'model_status': model.status
            }
    
    def _extract_solution(self, model, all_nodes, max_vehicles, x):
        """提取完整解"""
        routes = []
        depot_idx = 0
        
        for k in range(max_vehicles):
            route = []
            current = depot_idx
            visited = set()
            
            while True:
                next_nodes = []
                for j in range(len(all_nodes)):
                    if j != current and (current, j, k) in x and x[current,j,k].x > 0.5:
                        next_nodes.append(j)
                
                if not next_nodes:
                    break
                
                next_node = next_nodes[0]
                if next_node == depot_idx:
                    break
                
                if next_node not in visited:
                    node = all_nodes[next_node]
                    if hasattr(node, 'demand'):
                        route.append(node)
                    visited.add(next_node)
                
                current = next_node
                if len(visited) > 20:
                    break
            
            if route:
                routes.append(route)
        
        return {
            'routes': routes,
            'num_vehicles': len(routes),
            'total_distance': model.objVal
        }
    
    def _extract_simple_solution(self, model, all_nodes, x):
        """提取简化解"""
        # 简化版本的结果提取
        N = len(all_nodes)
        customer_indices = [i for i in range(1, N) if hasattr(all_nodes[i], 'demand')]
        
        # 构建路径
        routes = []
        visited = set()
        
        for start in customer_indices:
            if start in visited:
                continue
                
            route = []
            current = start
            
            while current != 0 and current not in visited:
                if current in customer_indices:
                    route.append(all_nodes[current])
                    visited.add(current)
                
                # 找到下一个节点
                next_node = None
                for j in range(N):
                    if j != current and (current, j) in x and x[current,j].x > 0.5:
                        next_node = j
                        break
                
                if next_node is None:
                    break
                current = next_node
            
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
        print("EVRP Gurobi修复版求解结果")
        print("=" * 60)
        
        if result['status'] == 'optimal':
            print(f"✅ 找到最优解")
            print(f"总距离: {result['objective_value']:.2f}")
            print(f"求解时间: {result['solve_time']:.2f}秒")
        elif result['status'] == 'time_limit':
            print(f"⏰ 时间限制内找到解")
            print(f"总距离: {result['objective_value']:.2f}")
            print(f"间隙: {result['gap']:.1%}")
        elif result['status'] == 'relaxed_optimal':
            print(f"✅ 找到简化问题的最优解")
            print(f"总距离: {result['objective_value']:.2f}")
            print(f"注意: 这是忽略电池约束的简化解")
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
                
                route_str += " → 配送中心"
                print(route_str)
                print(f"路径需求: {total_demand}")


def test_fixed_solver():
    """测试修复后的求解器"""
    print("🚀 测试EVRP Gurobi修复版求解器")
    print("=" * 60)
    
    # 创建与之前测试相同的问题实例
    generator = EVRPDataGenerator()
    
    # 小算例测试
    problem = generator.create_problem_instance(
        num_customers=8,
        num_stations=2,
        map_size=80.0,
        vehicle_capacity=30.0,
        vehicle_battery=70.0,
        consumption_rate=0.9
    )
    
    # 打印问题信息
    print(f"📋 问题信息:")
    print(f"  客户数: {len(problem.customers)}")
    print(f"  充电站: {len(problem.charging_stations)}")
    print(f"  车辆容量: {problem.vehicle_capacity}")
    print(f"  电池容量: {problem.vehicle_battery}")
    print(f"  耗电率: {problem.consumption_rate}")
    
    # 求解
    solver = FixedEVRPGurobiSolver(problem, time_limit=120)
    result = solver.solve()
    
    # 打印结果
    solver.print_solution(result)
    
    # 保存结果
    with open('evrp_gurobi_fixed_result.json', 'w') as f:
        json.dump(result, f, indent=2, default=str)
    
    return result


if __name__ == "__main__":
    result = test_fixed_solver()