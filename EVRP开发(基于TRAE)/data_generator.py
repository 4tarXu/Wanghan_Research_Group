"""
EVRP数据生成器
Electric Vehicle Routing Problem Data Generator
"""

import numpy as np
import random
from typing import List, Tuple
import json
import os
from evrp_solver import EVRPProblem, Customer, ChargingStation, Depot


class EVRPDataGenerator:
    """EVRP数据生成器"""
    
    def __init__(self, seed: int = 42):
        self.seed = seed
        random.seed(seed)
        np.random.seed(seed)
        
    def generate_uniform_customers(self, num_customers: int, map_size: float = 100.0,
                                 min_demand: float = 5.0, max_demand: float = 20.0,
                                 min_service_time: float = 2.0, max_service_time: float = 8.0,
                                 time_window_width: float = 30.0) -> List[Customer]:
        """生成均匀分布的客户"""
        customers = []
        
        for i in range(1, num_customers + 1):
            x = random.uniform(0, map_size)
            y = random.uniform(0, map_size)
            demand = random.uniform(min_demand, max_demand)
            service_time = random.uniform(min_service_time, max_service_time)
            
            # 生成时间窗
            earliest = random.uniform(0, 100 - time_window_width)
            latest = earliest + time_window_width
            time_window = (earliest, latest)
            
            customer = Customer(
                id=i,
                x=x,
                y=y,
                demand=demand,
                service_time=service_time,
                time_window=time_window
            )
            customers.append(customer)
            
        return customers
        
    def generate_clustered_customers(self, num_customers: int, map_size: float = 100.0,
                                   num_clusters: int = 3, cluster_radius: float = 15.0,
                                   min_demand: float = 5.0, max_demand: float = 20.0) -> List[Customer]:
        """生成聚类分布的客户"""
        customers = []
        
        # 生成聚类中心
        cluster_centers = []
        for _ in range(num_clusters):
            center_x = random.uniform(cluster_radius, map_size - cluster_radius)
            center_y = random.uniform(cluster_radius, map_size - cluster_radius)
            cluster_centers.append((center_x, center_y))
            
        # 为每个客户分配聚类
        customers_per_cluster = num_customers // num_clusters
        remaining = num_customers % num_clusters
        
        customer_id = 1
        for cluster_idx, (center_x, center_y) in enumerate(cluster_centers):
            count = customers_per_cluster + (1 if cluster_idx < remaining else 0)
            
            for _ in range(count):
                angle = random.uniform(0, 2 * np.pi)
                distance = random.uniform(0, cluster_radius)
                
                x = center_x + distance * np.cos(angle)
                y = center_y + distance * np.sin(angle)
                
                # 确保在地图范围内
                x = max(0, min(map_size, x))
                y = max(0, min(map_size, y))
                
                demand = random.uniform(min_demand, max_demand)
                service_time = random.uniform(2.0, 8.0)
                time_window = (random.uniform(0, 70), random.uniform(30, 100))
                
                customer = Customer(
                    id=customer_id,
                    x=x,
                    y=y,
                    demand=demand,
                    service_time=service_time,
                    time_window=time_window
                )
                customers.append(customer)
                customer_id += 1
                
        return customers
        
    def generate_charging_stations(self, num_stations: int, map_size: float = 100.0,
                                   min_rate: float = 1.0, max_rate: float = 3.0,
                                   distribution: str = 'uniform') -> List[ChargingStation]:
        """生成充电站"""
        stations = []
        
        if distribution == 'uniform':
            for i in range(100, 100 + num_stations):
                x = random.uniform(map_size * 0.2, map_size * 0.8)
                y = random.uniform(map_size * 0.2, map_size * 0.8)
                rate = random.uniform(min_rate, max_rate)
                
                station = ChargingStation(
                    id=i,
                    x=x,
                    y=y,
                    charging_rate=rate,
                    waiting_cost=random.uniform(0.05, 0.15)
                )
                stations.append(station)
                
        elif distribution == 'strategic':
            # 战略性放置充电站（在地图中心和边缘）
            positions = [
                (map_size * 0.25, map_size * 0.25),
                (map_size * 0.75, map_size * 0.25),
                (map_size * 0.25, map_size * 0.75),
                (map_size * 0.75, map_size * 0.75),
                (map_size * 0.5, map_size * 0.5)
            ]
            
            for i, (x, y) in enumerate(positions[:num_stations]):
                rate = random.uniform(min_rate, max_rate)
                station = ChargingStation(
                    id=100 + i,
                    x=x,
                    y=y,
                    charging_rate=rate,
                    waiting_cost=random.uniform(0.05, 0.15)
                )
                stations.append(station)
                
        return stations
        
    def generate_depot(self, map_size: float = 100.0, 
                      position: str = 'center') -> Depot:
        """生成配送中心"""
        if position == 'center':
            x, y = map_size / 2, map_size / 2
        elif position == 'corner':
            x, y = 0, 0
        elif position == 'random':
            x = random.uniform(0, map_size)
            y = random.uniform(0, map_size)
        else:
            x, y = map_size / 2, map_size / 2
            
        return Depot(
            id=0,
            x=x,
            y=y,
            ready_time=0.0,
            due_time=200.0
        )
        
    def create_problem_instance(self, num_customers: int = 15, 
                              num_stations: int = 4,
                              customer_distribution: str = 'uniform',
                              station_distribution: str = 'uniform',
                              map_size: float = 100.0,
                              vehicle_capacity: float = 50.0,
                              vehicle_battery: float = 100.0,
                              consumption_rate: float = 0.5) -> EVRPProblem:
        """创建完整的问题实例"""
        problem = EVRPProblem()
        
        # 生成配送中心
        depot = self.generate_depot(map_size)
        problem.add_depot(depot)
        
        # 生成客户
        if customer_distribution == 'uniform':
            customers = self.generate_uniform_customers(num_customers, map_size)
        elif customer_distribution == 'clustered':
            customers = self.generate_clustered_customers(num_customers, map_size)
        else:
            customers = self.generate_uniform_customers(num_customers, map_size)
            
        for customer in customers:
            problem.add_customer(customer)
            
        # 生成充电站
        stations = self.generate_charging_stations(num_stations, map_size, 
                                                  distribution=station_distribution)
        for station in stations:
            problem.add_charging_station(station)
            
        # 设置车辆约束
        problem.set_vehicle_constraints(
            capacity=vehicle_capacity,
            battery=vehicle_battery,
            consumption_rate=consumption_rate,
            loading_time=2.0
        )
        
        return problem
        
    def save_problem_instance(self, problem: EVRPProblem, filename: str):
        """保存问题实例到JSON文件"""
        data = {
            'depot': {
                'id': problem.depot.id,
                'x': problem.depot.x,
                'y': problem.depot.y,
                'ready_time': problem.depot.ready_time,
                'due_time': problem.depot.due_time
            },
            'customers': [
                {
                    'id': c.id,
                    'x': c.x,
                    'y': c.y,
                    'demand': c.demand,
                    'service_time': c.service_time,
                    'time_window': c.time_window
                } for c in problem.customers
            ],
            'charging_stations': [
                {
                    'id': s.id,
                    'x': s.x,
                    'y': s.y,
                    'charging_rate': s.charging_rate,
                    'waiting_cost': s.waiting_cost
                } for s in problem.charging_stations
            ],
            'vehicle_constraints': {
                'capacity': problem.vehicle_capacity,
                'battery': problem.vehicle_battery,
                'consumption_rate': problem.consumption_rate,
                'loading_time': problem.loading_time
            }
        }
        
        os.makedirs(os.path.dirname(filename), exist_ok=True)
        with open(filename, 'w') as f:
            json.dump(data, f, indent=2)
            
    def load_problem_instance(self, filename: str) -> EVRPProblem:
        """从JSON文件加载问题实例"""
        with open(filename, 'r') as f:
            data = json.load(f)
            
        problem = EVRPProblem()
        
        # 加载配送中心
        depot_data = data['depot']
        depot = Depot(
            id=depot_data['id'],
            x=depot_data['x'],
            y=depot_data['y'],
            ready_time=depot_data['ready_time'],
            due_time=depot_data['due_time']
        )
        problem.add_depot(depot)
        
        # 加载客户
        for c_data in data['customers']:
            customer = Customer(
                id=c_data['id'],
                x=c_data['x'],
                y=c_data['y'],
                demand=c_data['demand'],
                service_time=c_data['service_time'],
                time_window=tuple(c_data['time_window'])
            )
            problem.add_customer(customer)
            
        # 加载充电站
        for s_data in data['charging_stations']:
            station = ChargingStation(
                id=s_data['id'],
                x=s_data['x'],
                y=s_data['y'],
                charging_rate=s_data['charging_rate'],
                waiting_cost=s_data['waiting_cost']
            )
            problem.add_charging_station(station)
            
        # 设置车辆约束
        vc = data['vehicle_constraints']
        problem.set_vehicle_constraints(
            capacity=vc['capacity'],
            battery=vc['battery'],
            consumption_rate=vc['consumption_rate'],
            loading_time=vc['loading_time']
        )
        
        return problem
        
    def generate_test_suite(self, base_dir: str = "test_instances"):
        """生成测试套件"""
        test_cases = [
            # 小规模问题
            {"name": "small_uniform", "customers": 10, "stations": 2, "distribution": "uniform"},
            {"name": "small_clustered", "customers": 10, "stations": 2, "distribution": "clustered"},
            
            # 中等规模问题
            {"name": "medium_uniform", "customers": 25, "stations": 4, "distribution": "uniform"},
            {"name": "medium_clustered", "customers": 25, "stations": 4, "distribution": "clustered"},
            
            # 大规模问题
            {"name": "large_uniform", "customers": 50, "stations": 8, "distribution": "uniform"},
            {"name": "large_clustered", "customers": 50, "stations": 8, "distribution": "clustered"},
            
            # 不同约束条件
            {"name": "low_capacity", "customers": 20, "stations": 4, "distribution": "uniform", "capacity": 30},
            {"name": "low_battery", "customers": 20, "stations": 4, "distribution": "uniform", "battery": 60},
            {"name": "high_consumption", "customers": 20, "stations": 4, "distribution": "uniform", "consumption": 0.8}
        ]
        
        os.makedirs(base_dir, exist_ok=True)
        
        for case in test_cases:
            problem = self.create_problem_instance(
                num_customers=case["customers"],
                num_stations=case["stations"],
                customer_distribution=case["distribution"],
                vehicle_capacity=case.get("capacity", 50.0),
                vehicle_battery=case.get("battery", 100.0),
                consumption_rate=case.get("consumption", 0.5)
            )
            
            filename = f"{base_dir}/{case['name']}.json"
            self.save_problem_instance(problem, filename)
            print(f"生成测试实例: {filename}")


if __name__ == "__main__":
    generator = EVRPDataGenerator(seed=42)
    generator.generate_test_suite()
    print("测试套件生成完成!")