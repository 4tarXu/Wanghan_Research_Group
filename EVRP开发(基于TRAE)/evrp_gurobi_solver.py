"""
电动车路径规划问题(EVRP) - Gurobi精确求解器
Electric Vehicle Routing Problem with Charging Stations - Gurobi Exact Solver

作者：基于王晗课题组研究需求开发
功能：使用Gurobi求解考虑充电站约束的电动车路径优化问题
兼容：与现有遗传算法使用相同的数据格式
"""

import numpy as np
import gurobipy as gp
from gurobipy import GRB
from typing import List, Tuple, Dict, Optional
import json
import time
from dataclasses import dataclass
from evrp_solver import EVRPProblem, Customer, ChargingStation, Depot


class EVRPGurobiSolver:
    """EVRP Gurobi精确求解器"""
    
    def __init__(self, problem: EVRPProblem, time_limit: int = 300):
        """
        初始化求解器
        
        Args:
            problem: EVRP问题实例
            time_limit: 求解时间限制（秒）
        """
        self.problem = problem
        self.time_limit = time_limit
        self.model = None
        self.solution = None
        
    def _get_all_nodes(self) -> List:
        """获取所有节点：配送中心、客户、充电站"""
        nodes = [self.problem.depot]
        nodes.extend(self.problem.customers)
        nodes.extend(self.problem.charging_stations)
        return nodes
    
    def _calculate_distance_matrix(self) -> Dict[Tuple[int, int], float]:
        """计算所有节点间的距离矩阵"""
        nodes = self._get_all_nodes()
        distance_matrix = {}
        
        for i, node_i in enumerate(nodes):
            for j, node_j in enumerate(nodes):
                if i != j:
                    dist = self.problem.calculate_distance(node_i, node_j)
                    distance_matrix[(node_i.id, node_j.id)] = dist
                    
        return distance_matrix
    
    def _get_node_by_id(self, node_id: int):
        """根据ID获取节点对象"""
        if node_id == 0:
            return self.problem.depot
        
        for customer in self.problem.customers:
            if customer.id == node_id:
                return customer
                
        for station in self.problem.charging_stations:
            if station.id == node_id:
                return station
                
        return None
    
    def build_model(self, max_vehicles: Optional[int] = None) -> gp.Model:
        """
        构建EVRP的Gurobi数学模型
        
        Args:
            max_vehicles: 最大车辆数，如果为None则使用客户数
            
        Returns:
            Gurobi模型实例
        """
        if max_vehicles is None:
            max_vehicles = len(self.problem.customers)
            
        # 创建模型
        self.model = gp.Model("EVRP")
        self.model.setParam('TimeLimit', self.time_limit)
        
        # 获取所有节点
        all_nodes = self._get_all_nodes()
        customers = self.problem.customers
        depot = self.problem.depot
        stations = self.problem.charging_stations
        
        # 节点ID集合
        N = [node.id for node in all_nodes]  # 所有节点
        C = [c.id for c in customers]        # 客户节点
        S = [s.id for s in stations]        # 充电站节点
        
        # 距离矩阵
        dist = self._calculate_distance_matrix()
        
        # 决策变量
        # x[i,j,k]: 二元变量，车辆k是否从节点i到节点j
        x = {}
        for i in N:
            for j in N:
                for k in range(max_vehicles):
                    if i != j:
                        x[i,j,k] = self.model.addVar(vtype=GRB.BINARY, 
                                                     name=f"x_{i}_{j}_{k}")
        
        # u[i,k]: 车辆k到达节点i时的载重
        u = {}
        for i in C:  # 仅对客户节点
            for k in range(max_vehicles):
                u[i,k] = self.model.addVar(lb=0, ub=self.problem.vehicle_capacity,
                                         vtype=GRB.CONTINUOUS, name=f"u_{i}_{k}")
        
        # b[i,k]: 车辆k到达节点i时的电池电量
        b = {}
        for i in N:
            for k in range(max_vehicles):
                b[i,k] = self.model.addVar(lb=0, ub=self.problem.vehicle_battery,
                                         vtype=GRB.CONTINUOUS, name=f"b_{i}_{k}")
        
        # t[i,k]: 车辆k到达节点i的时间
        t = {}
        for i in N:
            for k in range(max_vehicles):
                node = self._get_node_by_id(i)
                if hasattr(node, 'time_window'):
                    t[i,k] = self.model.addVar(lb=node.time_window[0], 
                                             ub=node.time_window[1],
                                             vtype=GRB.CONTINUOUS, name=f"t_{i}_{k}")
                else:
                    t[i,k] = self.model.addVar(lb=0, ub=200,
                                             vtype=GRB.CONTINUOUS, name=f"t_{i}_{k}")
        
        # 目标函数：最小化总行驶距离
        self.model.setObjective(
            gp.quicksum(dist[i,j] * x[i,j,k] 
                       for i in N for j in N for k in range(max_vehicles) 
                       if i != j),
            GRB.MINIMIZE)
        
        # 约束条件
        
        # 1. 每个客户必须被访问一次
        for i in C:
            self.model.addConstr(
                gp.quicksum(x[i,j,k] for j in N for k in range(max_vehicles) if j != i) == 1,
                name=f"visit_customer_{i}")
        
        # 2. 流量守恒约束
        for h in N:
            for k in range(max_vehicles):
                self.model.addConstr(
                    gp.quicksum(x[i,h,k] for i in N if i != h) == 
                    gp.quicksum(x[h,j,k] for j in N if j != h),
                    name=f"flow_conservation_{h}_{k}")
        
        # 3. 每辆车从配送中心出发
        for k in range(max_vehicles):
            self.model.addConstr(
                gp.quicksum(x[depot.id,j,k] for j in N if j != depot.id) <= 1,
                name=f"departure_{k}")
        
        # 4. 每辆车返回配送中心
        for k in range(max_vehicles):
            self.model.addConstr(
                gp.quicksum(x[i,depot.id,k] for i in N if i != depot.id) <= 1,
                name=f"return_{k}")
        
        # 5. 载重约束
        for i in C:
            for j in C:
                for k in range(max_vehicles):
                    if i != j:
                        customer_i = self._get_node_by_id(i)
                        customer_j = self._get_node_by_id(j)
                        self.model.addConstr(
                            u[j,k] >= u[i,k] + customer_j.demand - 
                            self.problem.vehicle_capacity * (1 - x[i,j,k]),
                            name=f"load_{i}_{j}_{k}")
        
        # 6. 电池容量约束
        for i in N:
            for j in N:
                for k in range(max_vehicles):
                    if i != j:
                        energy_needed = dist[i,j] * self.problem.consumption_rate
                        self.model.addConstr(
                            b[j,k] <= b[i,k] - energy_needed + 
                            self.problem.vehicle_battery * (1 - x[i,j,k]),
                            name=f"battery_{i}_{j}_{k}")
        
        # 7. 时间窗约束
        for i in N:
            for j in N:
                for k in range(max_vehicles):
                    if i != j:
                        travel_time = dist[i,j] / self.problem.speed
                        service_time = 0
                        if i in C:
                            customer = self._get_node_by_id(i)
                            service_time = customer.service_time
                        
                        self.model.addConstr(
                            t[j,k] >= t[i,k] + service_time + travel_time - 
                            200 * (1 - x[i,j,k]),
                            name=f"time_{i}_{j}_{k}")
        
        # 8. 充电站约束
        for s in S:
            for k in range(max_vehicles):
                # 充电站可以被多次访问，但不需要特殊约束
                pass
        
        # 9. 消除子回路约束（MTZ约束）
        for i in C:
            for j in C:
                for k in range(max_vehicles):
                    if i != j:
                        self.model.addConstr(
                            u[i,k] - u[j,k] + self.problem.vehicle_capacity * x[i,j,k] <= 
                            self.problem.vehicle_capacity - self._get_node_by_id(j).demand,
                            name=f"subtour_{i}_{j}_{k}")
        
        # 更新模型
        self.model.update()
        return self.model
    
    def solve(self, max_vehicles: Optional[int] = None) -> Dict:
        """
        求解EVRP问题
        
        Args:
            max_vehicles: 最大车辆数
            
        Returns:
            包含求解结果的词典
        """
        start_time = time.time()
        
        # 构建模型
        self.build_model(max_vehicles)
        
        # 求解
        self.model.optimize()
        
        # 获取求解结果
        solve_time = time.time() - start_time
        
        if self.model.status == GRB.OPTIMAL:
            solution = self._extract_solution()
            return {
                'status': 'optimal',
                'objective_value': self.model.objVal,
                'solution': solution,
                'solve_time': solve_time,
                'gap': 0.0,
                'node_count': self.model.nodeCount,
                'iteration_count': self.model.iterCount
            }
        elif self.model.status == GRB.TIME_LIMIT:
            solution = self._extract_solution()
            return {
                'status': 'time_limit',
                'objective_value': self.model.objVal if hasattr(self.model, 'objVal') else None,
                'solution': solution,
                'solve_time': solve_time,
                'gap': self.model.mipGap if hasattr(self.model, 'mipGap') else None,
                'node_count': self.model.nodeCount,
                'iteration_count': self.model.iterCount
            }
        else:
            return {
                'status': 'infeasible',
                'objective_value': None,
                'solution': None,
                'solve_time': solve_time,
                'gap': None,
                'node_count': 0,
                'iteration_count': 0
            }
    
    def _extract_solution(self) -> Dict:
        """从Gurobi结果中提取解"""
        if self.model is None or self.model.status not in [GRB.OPTIMAL, GRB.TIME_LIMIT]:
            return None
        
        # 获取所有变量值
        variables = self.model.getVars()
        x_vars = {}  # 路径变量
        
        for var in variables:
            if var.x > 0.5:  # 考虑浮点误差
                name = var.varName
                if name.startswith('x_'):
                    parts = name.split('_')
                    i, j, k = int(parts[1]), int(parts[2]), int(parts[3])
                    if (i, j, k) not in x_vars:
                        x_vars[i, j, k] = 1
        
        # 构建路径
        max_vehicles = max([k for _, _, k in x_vars.keys()]) + 1
        routes = []
        
        for k in range(max_vehicles):
            route = []
            current = self.problem.depot.id
            
            # 从配送中心开始
            while True:
                next_nodes = [j for (i, j, vehicle) in x_vars.keys() 
                             if i == current and vehicle == k]
                
                if not next_nodes:
                    break
                    
                next_node = next_nodes[0]
                if next_node == self.problem.depot.id:  # 返回配送中心
                    break
                    
                route.append(self._get_node_by_id(next_node))
                current = next_node
            
            if route:  # 如果有客户被访问
                routes.append(route)
        
        return {
            'routes': routes,
            'num_vehicles': len(routes),
            'total_distance': self.model.objVal
        }
    
    def print_solution(self, result: Dict):
        """打印求解结果"""
        print("=" * 60)
        print("EVRP Gurobi求解结果")
        print("=" * 60)
        
        if result['status'] == 'optimal':
            print(f"✅ 找到最优解")
            print(f"目标值（总距离）: {result['objective_value']:.2f}")
            print(f"求解时间: {result['solve_time']:.2f}秒")
            print(f"节点数: {result['node_count']}")
            print(f"迭代数: {result['iteration_count']}")
            
        elif result['status'] == 'time_limit':
            print(f"⏰ 达到时间限制")
            print(f"当前目标值: {result['objective_value']:.2f}")
            print(f"求解时间: {result['solve_time']:.2f}秒")
            print(f"相对间隙: {result['gap']:.2%}")
            
        else:
            print("❌ 问题无可行解")
            print(f"求解时间: {result['solve_time']:.2f}秒")
            return
        
        if result['solution']:
            print(f"\n使用车辆数: {result['solution']['num_vehicles']}")
            print("\n详细路径:")
            
            for idx, route in enumerate(result['solution']['routes'], 1):
                print(f"\n车辆 {idx}:")
                route_str = f"配送中心({self.problem.depot.id}) → "
                
                total_distance = 0
                prev_node = self.problem.depot
                
                for node in route:
                    distance = self.problem.calculate_distance(prev_node, node)
                    total_distance += distance
                    route_str += f"{node.id}({node.x:.1f},{node.y:.1f}) → "
                    prev_node = node
                
                # 返回配送中心
                distance = self.problem.calculate_distance(prev_node, self.problem.depot)
                total_distance += distance
                route_str += f"配送中心({self.problem.depot.id})"
                
                print(route_str)
                print(f"路径长度: {total_distance:.2f}")
        
        print("=" * 60)


def solve_evrp_with_gurobi(problem: EVRPProblem, time_limit: int = 300, 
                         max_vehicles: Optional[int] = None) -> Dict:
    """
    便捷的求解函数
    
    Args:
        problem: EVRP问题实例
        time_limit: 求解时间限制
        max_vehicles: 最大车辆数
        
    Returns:
        求解结果
    """
    solver = EVRPGurobiSolver(problem, time_limit)
    result = solver.solve(max_vehicles)
    solver.print_solution(result)
    return result


if __name__ == "__main__":
    # 测试用例
    from data_generator import EVRPDataGenerator
    
    # 创建数据生成器
    generator = EVRPDataGenerator(seed=42)
    
    # 生成小规模测试实例
    problem = generator.create_problem_instance(
        num_customers=8,
        num_stations=2,
        map_size=50.0,
        vehicle_capacity=30.0,
        vehicle_battery=60.0,
        consumption_rate=1.0
    )
    
    print("正在求解EVRP问题...")
    print(f"客户数: {len(problem.customers)}")
    print(f"充电站数: {len(problem.charging_stations)}")
    print(f"车辆容量: {problem.vehicle_capacity}")
    print(f"电池容量: {problem.vehicle_battery}")
    
    # 使用Gurobi求解
    result = solve_evrp_with_gurobi(problem, time_limit=60, max_vehicles=3)
    
    # 保存结果
    with open('evrp_gurobi_solution.json', 'w', encoding='utf-8') as f:
        json.dump(result, f, ensure_ascii=False, indent=2, default=str)
    
    print("\n结果已保存到 evrp_gurobi_solution.json")