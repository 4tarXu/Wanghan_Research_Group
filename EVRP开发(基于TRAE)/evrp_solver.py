"""
电动车路径规划问题(EVRP)遗传算法求解器
Electric Vehicle Routing Problem with Charging Stations - Genetic Algorithm Solver

作者：基于王晗课题组研究需求开发
功能：解决考虑充电站约束的电动车路径优化问题
"""

import numpy as np
import matplotlib.pyplot as plt
import random
from typing import List, Tuple, Dict
import json
import time
from dataclasses import dataclass
from copy import deepcopy


@dataclass
class Customer:
    """客户节点类"""
    id: int
    x: float
    y: float
    demand: float
    service_time: float = 0.0
    time_window: Tuple[float, float] = (0, 1000)


@dataclass
class ChargingStation:
    """充电站节点类"""
    id: int
    x: float
    y: float
    charging_rate: float = 1.0  # 充电速率 (单位时间充电量)
    waiting_cost: float = 0.1  # 等待时间成本


@dataclass
class Depot:
    """配送中心类"""
    id: int
    x: float
    y: float
    ready_time: float = 0.0
    due_time: float = 1000.0


class EVRPProblem:
    """EVRP问题定义类"""
    
    def __init__(self):
        self.depot = None
        self.customers = []
        self.charging_stations = []
        self.vehicle_capacity = 0
        self.vehicle_battery = 0  # 电动车电池容量
        self.consumption_rate = 0  # 单位距离耗电量
        self.loading_time = 0
        self.speed = 1.0
        
    def add_depot(self, depot: Depot):
        """添加配送中心"""
        self.depot = depot
        
    def add_customer(self, customer: Customer):
        """添加客户"""
        self.customers.append(customer)
        
    def add_charging_station(self, station: ChargingStation):
        """添加充电站"""
        self.charging_stations.append(station)
        
    def set_vehicle_constraints(self, capacity: float, battery: float, 
                               consumption_rate: float, loading_time: float = 0):
        """设置车辆约束"""
        self.vehicle_capacity = capacity
        self.vehicle_battery = battery
        self.consumption_rate = consumption_rate
        self.loading_time = loading_time
        
    def calculate_distance(self, node1, node2) -> float:
        """计算两点间欧氏距离"""
        return np.sqrt((node1.x - node2.x)**2 + (node1.y - node2.y)**2)
    
    def get_all_nodes(self):
        """获取所有节点"""
        nodes = [self.depot]
        nodes.extend(self.customers)
        nodes.extend(self.charging_stations)
        return nodes


class Route:
    """单条路径类"""
    
    def __init__(self, problem: EVRPProblem):
        self.problem = problem
        self.sequence = []  # 节点访问序列
        self.total_distance = 0.0
        self.total_load = 0.0
        self.total_time = 0.0
        self.battery_consumption = 0.0
        self.is_feasible = True
        self.violations = []
        
    def copy(self):
        """创建路径副本"""
        new_route = Route(self.problem)
        new_route.sequence = self.sequence.copy()
        new_route.total_distance = self.total_distance
        new_route.total_load = self.total_load
        new_route.total_time = self.total_time
        new_route.battery_consumption = self.battery_consumption
        new_route.is_feasible = self.is_feasible
        new_route.violations = self.violations.copy()
        return new_route


class EVRPSolution:
    """EVRP解决方案类"""
    
    def __init__(self, problem: EVRPProblem):
        self.problem = problem
        self.routes = []  # 路径列表
        self.total_cost = 0.0
        self.fitness = 0.0
        self.is_feasible = True
        
    def copy(self):
        """创建解决方案副本"""
        new_solution = EVRPSolution(self.problem)
        new_solution.routes = [route.copy() for route in self.routes]
        new_solution.total_cost = self.total_cost
        new_solution.fitness = self.fitness
        new_solution.is_feasible = self.is_feasible
        return new_solution


class EVRPEvaluator:
    """EVRP评估器"""
    
    def __init__(self, problem: EVRPProblem):
        self.problem = problem
        
    def evaluate_route(self, route: Route) -> float:
        """评估单条路径的可行性和成本"""
        if len(route.sequence) == 0:
            return 0.0
            
        route.total_distance = 0.0
        route.total_load = 0.0
        route.total_time = 0.0
        route.battery_consumption = 0.0
        route.is_feasible = True
        route.violations = []
        
        current_load = 0.0
        current_battery = self.problem.vehicle_battery
        current_time = 0.0
        
        prev_node = self.problem.depot
        
        for i, node in enumerate(route.sequence):
            distance = self.problem.calculate_distance(prev_node, node)
            energy_needed = distance * self.problem.consumption_rate
            
            # 检查电池电量
            if current_battery < energy_needed:
                route.is_feasible = False
                route.violations.append(f"电池电量不足在节点{node.id}")
                
            # 检查载重
            if hasattr(node, 'demand'):
                if current_load + node.demand > self.problem.vehicle_capacity:
                    route.is_feasible = False
                    route.violations.append(f"超载在节点{node.id}")
                current_load += node.demand
                
            # 更新时间和电池
            travel_time = distance / self.problem.speed
            current_time += travel_time
            current_battery -= energy_needed
            
            # 如果是充电站
            if isinstance(node, ChargingStation):
                # 计算需要充电的时间
                charge_needed = self.problem.vehicle_battery - current_battery
                charge_time = charge_needed / node.charging_rate
                current_time += charge_time
                current_battery = self.problem.vehicle_battery
                
            # 如果是客户
            if isinstance(node, Customer):
                # 检查时间窗
                if not (node.time_window[0] <= current_time <= node.time_window[1]):
                    route.is_feasible = False
                    route.violations.append(f"违反时间窗在客户{node.id}")
                current_time += node.service_time
                
            route.total_distance += distance
            prev_node = node
            
        # 返回配送中心
        if len(route.sequence) > 0:
            distance = self.problem.calculate_distance(route.sequence[-1], self.problem.depot)
            route.total_distance += distance
            
        # 计算成本
        cost = route.total_distance
        if not route.is_feasible:
            cost += 1000 * len(route.violations)  # 惩罚成本
            
        return cost
        
    def evaluate_solution(self, solution: EVRPSolution) -> float:
        """评估整个解决方案"""
        solution.total_cost = 0.0
        solution.is_feasible = True
        
        for route in solution.routes:
            route_cost = self.evaluate_route(route)
            solution.total_cost += route_cost
            if not route.is_feasible:
                solution.is_feasible = False
                
        # 计算适应度（用于遗传算法）
        if solution.is_feasible:
            solution.fitness = 1.0 / (1.0 + solution.total_cost)
        else:
            solution.fitness = 1.0 / (1.0 + solution.total_cost + 1000)
            
        return solution.total_cost


class EVRPGeneticAlgorithm:
    """EVRP遗传算法求解器"""
    
    def __init__(self, problem: EVRPProblem, population_size: int = 100,
                 max_generations: int = 1000, crossover_rate: float = 0.8,
                 mutation_rate: float = 0.1, elite_size: int = 10):
        self.problem = problem
        self.population_size = population_size
        self.max_generations = max_generations
        self.crossover_rate = crossover_rate
        self.mutation_rate = mutation_rate
        self.elite_size = elite_size
        
        self.evaluator = EVRPEvaluator(problem)
        self.population = []
        self.best_solution = None
        self.generation_history = []
        
    def create_initial_population(self):
        """创建初始种群"""
        self.population = []
        
        for _ in range(self.population_size):
            solution = self.create_random_solution()
            self.evaluator.evaluate_solution(solution)
            self.population.append(solution)
            
        self.population.sort(key=lambda x: x.total_cost)
        self.best_solution = self.population[0].copy()
        
    def create_random_solution(self) -> EVRPSolution:
        """创建随机解决方案"""
        solution = EVRPSolution(self.problem)
        
        # 获取所有客户
        customers = self.problem.customers.copy()
        random.shuffle(customers)
        
        # 简单的贪心分配
        while customers:
            route = Route(self.problem)
            current_load = 0.0
            current_battery = self.problem.vehicle_battery
            
            for customer in customers[:]:
                if current_load + customer.demand <= self.problem.vehicle_battery:
                    # 检查是否需要充电
                    if len(route.sequence) > 0:
                        last_node = route.sequence[-1]
                    else:
                        last_node = self.problem.depot
                        
                    distance = self.problem.calculate_distance(last_node, customer)
                    energy_needed = distance * self.problem.consumption_rate
                    
                    if current_battery >= energy_needed:
                        route.sequence.append(customer)
                        current_load += customer.demand
                        current_battery -= energy_needed
                        customers.remove(customer)
                    else:
                        # 尝试插入充电站
                        nearest_station = self.find_nearest_charging_station(customer)
                        if nearest_station:
                            route.sequence.append(nearest_station)
                            current_battery = self.problem.vehicle_battery
                            route.sequence.append(customer)
                            current_load += customer.demand
                            customers.remove(customer)
                        else:
                            break
                else:
                    break
                    
            if route.sequence:
                solution.routes.append(route)
                
        return solution
        
    def find_nearest_charging_station(self, node) -> ChargingStation:
        """找到最近的充电站"""
        if not self.problem.charging_stations:
            return None
            
        nearest = min(self.problem.charging_stations,
                     key=lambda s: self.problem.calculate_distance(node, s))
        return nearest
        
    def selection(self) -> List[EVRPSolution]:
        """选择操作 - 锦标赛选择"""
        selected = []
        
        # 保留精英
        selected.extend([sol.copy() for sol in self.population[:self.elite_size]])
        
        # 锦标赛选择
        while len(selected) < self.population_size:
            tournament = random.sample(self.population, 3)
            winner = min(tournament, key=lambda x: x.total_cost)
            selected.append(winner.copy())
            
        return selected
        
    def crossover(self, parent1: EVRPSolution, parent2: EVRPSolution) -> Tuple[EVRPSolution, EVRPSolution]:
        """交叉操作 - 基于路径的交叉"""
        child1 = parent1.copy()
        child2 = parent2.copy()
        
        if random.random() < self.crossover_rate:
            # 交换部分路径
            if len(parent1.routes) > 1 and len(parent2.routes) > 1:
                cut1 = random.randint(1, len(parent1.routes) - 1)
                cut2 = random.randint(1, len(parent2.routes) - 1)
                
                child1.routes = parent1.routes[:cut1] + parent2.routes[cut2:]
                child2.routes = parent2.routes[:cut2] + parent1.routes[cut1:]
                
                # 修复不可行解
                self.repair_solution(child1)
                self.repair_solution(child2)
                
        return child1, child2
        
    def mutation(self, solution: EVRPSolution):
        """变异操作"""
        if random.random() < self.mutation_rate:
            mutation_type = random.choice(['swap', 'relocate', 'reverse'])
            
            if mutation_type == 'swap' and solution.routes:
                route_idx = random.randint(0, len(solution.routes) - 1)
                route = solution.routes[route_idx]
                if len(route.sequence) > 2:
                    i, j = random.sample(range(len(route.sequence)), 2)
                    route.sequence[i], route.sequence[j] = route.sequence[j], route.sequence[i]
                    
            elif mutation_type == 'relocate' and solution.routes:
                route_idx = random.randint(0, len(solution.routes) - 1)
                route = solution.routes[route_idx]
                if len(route.sequence) > 1:
                    pos = random.randint(0, len(route.sequence) - 1)
                    node = route.sequence.pop(pos)
                    
                    # 插入到另一个位置
                    new_route_idx = random.randint(0, len(solution.routes) - 1)
                    new_pos = random.randint(0, len(solution.routes[new_route_idx].sequence))
                    solution.routes[new_route_idx].sequence.insert(new_pos, node)
                    
            elif mutation_type == 'reverse' and solution.routes:
                route_idx = random.randint(0, len(solution.routes) - 1)
                route = solution.routes[route_idx]
                if len(route.sequence) > 2:
                    i, j = sorted(random.sample(range(len(route.sequence)), 2))
                    route.sequence[i:j+1] = reversed(route.sequence[i:j+1])
                    
    def repair_solution(self, solution: EVRPSolution):
        """修复不可行解"""
        # 简单的修复策略：移除重复客户，重新分配
        visited_customers = set()
        new_routes = []
        
        for route in solution.routes:
            new_route = Route(self.problem)
            for node in route.sequence:
                if isinstance(node, Customer):
                    if node.id not in visited_customers:
                        new_route.sequence.append(node)
                        visited_customers.add(node.id)
                else:
                    new_route.sequence.append(node)
                    
            if new_route.sequence:
                new_routes.append(new_route)
                
        # 处理未访问的客户
        all_customers = {c.id: c for c in self.problem.customers}
        unvisited = [c for cid, c in all_customers.items() if cid not in visited_customers]
        
        for customer in unvisited:
            if not new_routes:
                new_routes.append(Route(self.problem))
                
            # 找到最适合的路径插入
            best_route = None
            best_pos = 0
            min_cost = float('inf')
            
            for route in new_routes:
                for pos in range(len(route.sequence) + 1):
                    new_route = route.copy()
                    new_route.sequence.insert(pos, customer)
                    cost = self.evaluator.evaluate_route(new_route)
                    if cost < min_cost:
                        min_cost = cost
                        best_route = route
                        best_pos = pos
                        
            if best_route:
                best_route.sequence.insert(best_pos, customer)
            else:
                new_routes[0].sequence.append(customer)
                
        solution.routes = [r for r in new_routes if r.sequence]
        
    def evolve(self):
        """进化一代"""
        # 选择
        new_population = self.selection()
        
        # 交叉和变异
        offspring = []
        for i in range(0, len(new_population), 2):
            if i + 1 < len(new_population):
                child1, child2 = self.crossover(new_population[i], new_population[i+1])
                self.mutation(child1)
                self.mutation(child2)
                
                self.evaluator.evaluate_solution(child1)
                self.evaluator.evaluate_solution(child2)
                
                offspring.extend([child1, child2])
                
        # 更新种群
        self.population = offspring
        self.population.sort(key=lambda x: x.total_cost)
        
        # 更新最优解
        if self.population[0].total_cost < self.best_solution.total_cost:
            self.best_solution = self.population[0].copy()
            
        self.generation_history.append({
            'generation': len(self.generation_history),
            'best_cost': self.best_solution.total_cost,
            'avg_cost': np.mean([sol.total_cost for sol in self.population]),
            'worst_cost': self.population[-1].total_cost
        })
        
    def solve(self) -> EVRPSolution:
        """求解EVRP问题"""
        print("开始创建初始种群...")
        self.create_initial_population()
        
        print(f"初始最优成本: {self.best_solution.total_cost:.2f}")
        
        for generation in range(self.max_generations):
            self.evolve()
            
            if generation % 50 == 0:
                print(f"第{generation}代: 最优成本 = {self.best_solution.total_cost:.2f}")
                
        print(f"最终最优成本: {self.best_solution.total_cost:.2f}")
        return self.best_solution


class EVRPVisualizer:
    """EVRP结果可视化器"""
    
    def __init__(self, problem: EVRPProblem):
        self.problem = problem
        self._setup_chinese_fonts()
    
    def _setup_chinese_fonts(self):
        """设置中文字体"""
        try:
            from font_config import setup_chinese_fonts
            setup_chinese_fonts()
        except ImportError:
            # 备用方案
            import matplotlib.pyplot as plt
            plt.rcParams['font.sans-serif'] = ['DejaVu Sans', 'SimHei', 'Arial Unicode MS']
            plt.rcParams['axes.unicode_minus'] = False
        
    def plot_solution(self, solution: EVRPSolution, save_path: str = None):
        """绘制解决方案"""
        plt.figure(figsize=(12, 8))
        
        # 绘制配送中心
        depot = self.problem.depot
        plt.scatter(depot.x, depot.y, c='red', s=200, marker='s', label='配送中心')
        
        # 绘制客户
        customers_x = [c.x for c in self.problem.customers]
        customers_y = [c.y for c in self.problem.customers]
        plt.scatter(customers_x, customers_y, c='blue', s=100, label='客户')
        
        # 绘制充电站
        if self.problem.charging_stations:
            stations_x = [s.x for s in self.problem.charging_stations]
            stations_y = [s.y for s in self.problem.charging_stations]
            plt.scatter(stations_x, stations_y, c='green', s=150, marker='^', label='充电站')
            
        # 绘制路径
        colors = plt.cm.Set3(np.linspace(0, 1, len(solution.routes)))
        
        for i, route in enumerate(solution.routes):
            if route.sequence:
                # 绘制路径
                path_x = [depot.x]
                path_y = [depot.y]
                
                for node in route.sequence:
                    path_x.append(node.x)
                    path_y.append(node.y)
                    
                path_x.append(depot.x)
                path_y.append(depot.y)
                
                plt.plot(path_x, path_y, color=colors[i], linewidth=2, 
                        label=f'路径{i+1} (距离: {route.total_distance:.2f})')
                
                # 标记客户编号
                for node in route.sequence:
                    if isinstance(node, Customer):
                        plt.annotate(str(node.id), (node.x, node.y), 
                                   xytext=(5, 5), textcoords='offset points')
        
        plt.title('EVRP解决方案 - 电动车路径规划', fontsize=14, fontweight='bold')
        plt.xlabel('X坐标', fontsize=12)
        plt.ylabel('Y坐标', fontsize=12)
        plt.legend(fontsize=10)
        plt.grid(True, alpha=0.3)
        
        if save_path:
            plt.savefig(save_path, dpi=300, bbox_inches='tight')
        plt.show()
        
    def plot_convergence(self, ga: EVRPGeneticAlgorithm, save_path: str = None):
        """绘制收敛曲线"""
        if not ga.generation_history:
            return
            
        generations = [h['generation'] for h in ga.generation_history]
        best_costs = [h['best_cost'] for h in ga.generation_history]
        avg_costs = [h['avg_cost'] for h in ga.generation_history]
        worst_costs = [h['worst_cost'] for h in ga.generation_history]
        
        plt.figure(figsize=(10, 6))
        plt.plot(generations, best_costs, 'b-', linewidth=2, label='最优成本')
        plt.plot(generations, avg_costs, 'g--', linewidth=1, label='平均成本')
        plt.plot(generations, worst_costs, 'r:', linewidth=1, label='最差成本')
        
        plt.title('遗传算法收敛曲线', fontsize=14, fontweight='bold')
        plt.xlabel('代数', fontsize=12)
        plt.ylabel('成本', fontsize=12)
        plt.legend(fontsize=10)
        plt.grid(True, alpha=0.3)
        
        if save_path:
            plt.savefig(save_path, dpi=300, bbox_inches='tight')
        plt.show()


def create_sample_problem() -> EVRPProblem:
    """创建示例EVRP问题"""
    problem = EVRPProblem()
    
    # 设置配送中心
    depot = Depot(id=0, x=50, y=50, ready_time=0, due_time=100)
    problem.add_depot(depot)
    
    # 添加客户
    customers = [
        Customer(1, 20, 80, 10, 5, (10, 50)),
        Customer(2, 30, 70, 8, 3, (15, 55)),
        Customer(3, 40, 90, 12, 4, (20, 60)),
        Customer(4, 60, 85, 15, 6, (25, 65)),
        Customer(5, 70, 75, 10, 5, (30, 70)),
        Customer(6, 80, 60, 8, 4, (35, 75)),
        Customer(7, 90, 50, 14, 5, (40, 80)),
        Customer(8, 85, 40, 11, 3, (45, 85)),
        Customer(9, 75, 30, 9, 4, (50, 90)),
        Customer(10, 65, 20, 13, 5, (55, 95)),
        Customer(11, 45, 25, 7, 3, (60, 100)),
        Customer(12, 35, 35, 10, 4, (65, 105)),
        Customer(13, 25, 45, 8, 2, (70, 110)),
        Customer(14, 15, 55, 12, 5, (75, 115)),
        Customer(15, 10, 65, 9, 3, (80, 120))
    ]
    
    for customer in customers:
        problem.add_customer(customer)
        
    # 添加充电站
    charging_stations = [
        ChargingStation(100, 30, 60, charging_rate=2.0),
        ChargingStation(101, 70, 80, charging_rate=1.5),
        ChargingStation(102, 60, 40, charging_rate=2.5),
        ChargingStation(103, 40, 30, charging_rate=1.8)
    ]
    
    for station in charging_stations:
        problem.add_charging_station(station)
        
    # 设置车辆约束
    problem.set_vehicle_constraints(
        capacity=50,  # 载重50单位
        battery=100,  # 电池容量100单位
        consumption_rate=0.5,  # 每单位距离消耗0.5单位电量
        loading_time=2  # 装载时间2单位
    )
    
    return problem


def main():
    """主函数"""
    print("=== EVRP遗传算法求解器 ===")
    print("电动车路径规划问题求解")
    
    # 创建示例问题
    problem = create_sample_problem()
    print(f"问题规模: {len(problem.customers)}个客户, {len(problem.charging_stations)}个充电站")
    
    # 创建遗传算法求解器
    ga = EVRPGeneticAlgorithm(
        problem=problem,
        population_size=200,
        max_generations=500,
        crossover_rate=0.8,
        mutation_rate=0.1,
        elite_size=20
    )
    
    # 求解
    start_time = time.time()
    best_solution = ga.solve()
    end_time = time.time()
    
    print(f"\n求解完成! 耗时: {end_time - start_time:.2f}秒")
    print(f"最优总成本: {best_solution.total_cost:.2f}")
    print(f"使用车辆数: {len(best_solution.routes)}")
    
    # 打印详细路径
    for i, route in enumerate(best_solution.routes):
        print(f"\n路径{i+1}:")
        print(f"  序列: {[n.id for n in route.sequence]}")
        print(f"  距离: {route.total_distance:.2f}")
        print(f"  载重: {route.total_load:.2f}")
        print(f"  可行: {route.is_feasible}")
        
    # 可视化结果
    visualizer = EVRPVisualizer(problem)
    visualizer.plot_solution(best_solution)
    visualizer.plot_convergence(ga)
    
    return best_solution


if __name__ == "__main__":
    solution = main()