"""
EVRP Gurobi求解器 - 简化版本
专注于基本的VRP问题，逐步添加电动车约束
"""

import numpy as np
import gurobipy as gp
from gurobipy import GRB
from typing import List, Tuple, Dict, Optional
import json
import time
from evrp_solver import EVRPProblem, Customer, ChargingStation, Depot


class SimpleEVRPGurobiSolver:
    """简化版EVRP Gurobi求解器"""
    
    def __init__(self, problem: EVRPProblem, time_limit: int = 300):
        self.problem = problem
        self.time_limit = time_limit
        self.model = None
    
    def _get_all_nodes(self) -> List:
        """获取所有节点"""
        nodes = [self.problem.depot]
        nodes.extend(self.problem.customers)
        return nodes
    
    def _calculate_distance_matrix(self) -> Dict[Tuple[int, int], float]:
        """计算距离矩阵"""
        nodes = self._get_all_nodes()
        distance_matrix = {}
        
        for i, node_i in enumerate(nodes):
            for j, node_j in enumerate(nodes):
                if i != j:
                    dist = self.problem.calculate_distance(node_i, node_j)
                    distance_matrix[(node_i.id, node_j.id)] = dist
                    
        return distance_matrix
    
    def build_simple_model(self, max_vehicles: Optional[int] = None) -> gp.Model:
        """构建简化模型（基本VRP + 电池约束）"""
        if max_vehicles is None:
            # 保守估计最大车辆数
            total_demand = sum(c.demand for c in self.problem.customers)
            max_vehicles = max(2, int(np.ceil(total_demand / self.problem.vehicle_capacity)) + 1)
        
        # 创建模型
        self.model = gp.Model("Simple_EVRP")
        self.model.setParam('TimeLimit', self.time_limit)
        self.model.setParam('MIPGap', 0.1)  # 10%间隙
        
        # 获取节点
        all_nodes = self._get_all_nodes()
        customers = self.problem.customers
        depot = self.problem.depot
        
        N = [node.id for node in all_nodes]
        C = [c.id for c in customers]
        
        # 距离矩阵
        dist = self._calculate_distance_matrix()
        
        # 决策变量
        x = {}
        for i in N:
            for j in N:
                for k in range(max_vehicles):
                    if i != j:
                        x[i,j,k] = self.model.addVar(vtype=GRB.BINARY, 
                                                     name=f"x_{i}_{j}_{k}")
        
        # 载重变量（仅对客户）
        u = {}
        for i in C:
            for k in range(max_vehicles):
                u[i,k] = self.model.addVar(lb=0, ub=self.problem.vehicle_capacity,
                                           vtype=GRB.CONTINUOUS, name=f"u_{i}_{k}")
        
        # 电池电量变量（对所有节点）
        b = {}
        for i in N:
            for k in range(max_vehicles):
                b[i,k] = self.model.addVar(lb=0, ub=self.problem.vehicle_battery,
                                         vtype=GRB.CONTINUOUS, name=f"b_{i}_{k}")
        
        # 目标函数：最小化总距离
        self.model.setObjective(
            gp.quicksum(dist[i,j] * x[i,j,k] 
                       for i in N for j in N for k in range(max_vehicles) 
                       if i != j),
            GRB.MINIMIZE)
        
        # 约束条件（简化版）
        
        # 1. 每个客户必须被访问一次
        for i in C:
            self.model.addConstr(
                gp.quicksum(x[i,j,k] for j in N for k in range(max_vehicles) if j != i) == 1,
                name=f"visit_{i}")
        
        # 2. 流量守恒
        for h in C:  # 仅对客户节点
            for k in range(max_vehicles):
                self.model.addConstr(
                    gp.quicksum(x[i,h,k] for i in N if i != h) == 
                    gp.quicksum(x[h,j,k] for j in N if j != h),
                    name=f"flow_{h}_{k}")
        
        # 3. 车辆从配送中心出发
        for k in range(max_vehicles):
            self.model.addConstr(
                gp.quicksum(x[depot.id,j,k] for j in C) <= 1,
                name=f"departure_{k}")
        
        # 4. 车辆返回配送中心
        for k in range(max_vehicles):
            self.model.addConstr(
                gp.quicksum(x[i,depot.id,k] for i in C) <= 1,
                name=f"return_{k}")
        
        # 5. 载重约束（MTZ公式）
        for i in C:
            for j in C:
                for k in range(max_vehicles):
                    if i != j:
                        customer_j = next(c for c in customers if c.id == j)
                        self.model.addConstr(
                            u[j,k] >= u[i,k] + customer_j.demand - 
                            self.problem.vehicle_capacity * (1 - x[i,j,k]),
                            name=f"load_{i}_{j}_{k}")
        
        # 6. 电池约束（简化版）
        for i in N:
            for j in N:
                for k in range(max_vehicles):
                    if i != j:
                        energy_needed = dist[i,j] * self.problem.consumption_rate
                        self.model.addConstr(
                            b[j,k] <= b[i,k] - energy_needed + 
                            self.problem.vehicle_battery * (1 - x[i,j,k]),
                            name=f"battery_{i}_{j}_{k}")
        
        # 7. 初始电量（从配送中心出发时满电）
        for k in range(max_vehicles):
            self.model.addConstr(b[depot.id,k] == self.problem.vehicle_battery)
        
        self.model.update()
        return self.model
    
    def solve(self) -> Dict:
        """求解问题"""
        start_time = time.time()
        
        # 构建并求解模型
        self.build_simple_model()
        self.model.optimize()
        
        solve_time = time.time() - start_time
        
        if self.model.status in [GRB.OPTIMAL, GRB.TIME_LIMIT]:
            solution = self._extract_solution()
            return {
                'status': 'optimal' if self.model.status == GRB.OPTIMAL else 'time_limit',
                'objective_value': self.model.objVal,
                'solve_time': solve_time,
                'gap': self.model.mipGap if hasattr(self.model, 'mipGap') else 0.0,
                'solution': solution
            }
        else:
            return {
                'status': 'infeasible',
                'objective_value': None,
                'solve_time': solve_time,
                'solution': None
            }
    
    def _extract_solution(self) -> Dict:
        """提取解"""
        variables = self.model.getVars()
        x_vars = {}
        
        for var in variables:
            if var.x > 0.5 and var.varName.startswith('x_'):
                parts = var.varName.split('_')
                i, j, k = int(parts[1]), int(parts[2]), int(parts[3])
                x_vars[i, j, k] = 1
        
        # 构建路径
        max_vehicles = max([k for _, _, k in x_vars.keys()]) + 1 if x_vars else 0
        routes = []
        
        depot = self.problem.depot
        customers = {c.id: c for c in self.problem.customers}
        
        for k in range(max_vehicles):
            route = []
            current = depot.id
            
            # 从配送中心开始
            visited = set()
            
            while True:
                next_nodes = [j for (i, j, vehicle) in x_vars.keys() 
                             if i == current and vehicle == k and j not in visited]
                
                if not next_nodes:
                    break
                    
                next_node = next_nodes[0]
                if next_node == depot.id:  # 返回配送中心
                    break
                
                if next_node in customers:
                    route.append(customers[next_node])
                    visited.add(next_node)
                
                current = next_node
            
            if route:
                routes.append(route)
        
        return {
            'routes': routes,
            'num_vehicles': len(routes)
        }
    
    def print_solution(self, result: Dict):
        """打印结果"""
        print("=" * 50)
        print("EVRP 简化模型求解结果")
        print("=" * 50)
        
        if result['status'] == 'optimal':
            print(f"✅ 找到最优解")
            print(f"总距离: {result['objective_value']:.2f}")
        elif result['status'] == 'time_limit':
            print(f"⏰ 时间限制内找到解")
            print(f"总距离: {result['objective_value']:.2f}")
            print(f"间隙: {result['gap']:.2%}")
        else:
            print("❌ 无可行解")
            return
        
        if result['solution']:
            print(f"使用车辆: {result['solution']['num_vehicles']}")
            
            for idx, route in enumerate(result['solution']['routes'], 1):
                print(f"\n路径 {idx}:")
                route_str = "配送中心 → "
                total_distance = 0
                prev = self.problem.depot
                
                for customer in route:
                    dist = self.problem.calculate_distance(prev, customer)
                    total_distance += dist
                    route_str += f"客户{customer.id} → "
                    prev = customer
                
                # 返回配送中心
                dist = self.problem.calculate_distance(prev, self.problem.depot)
                total_distance += dist
                route_str += "配送中心"
                
                print(route_str)
                print(f"路径长度: {total_distance:.2f}")


def solve_simple_evrp(problem: EVRPProblem, time_limit: int = 300) -> Dict:
    """便捷求解函数"""
    solver = SimpleEVRPGurobiSolver(problem, time_limit)
    result = solver.solve()
    solver.print_solution(result)
    return result


if __name__ == "__main__":
    # 测试简化模型
    from data_generator import EVRPDataGenerator
    
    print("🚛 测试EVRP简化模型...")
    
    # 创建小规模测试实例
    generator = EVRPDataGenerator(seed=42)
    problem = generator.create_problem_instance(
        num_customers=5,          # 更小的规模
        num_stations=1,           # 简化问题
        map_size=50.0,
        vehicle_capacity=25.0,
        vehicle_battery=60.0,
        consumption_rate=1.0
    )
    
    print(f"问题规模: {len(problem.customers)}客户, 1配送中心")
    
    # 求解
    result = solve_simple_evrp(problem, time_limit=30)
    
    # 保存结果
    with open('simple_evrp_result.json', 'w') as f:
        json.dump(result, f, indent=2, default=str)
    
    print(f"\n结果已保存到 simple_evrp_result.json")