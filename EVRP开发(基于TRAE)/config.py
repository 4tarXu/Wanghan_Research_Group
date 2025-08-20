"""
EVRP遗传算法配置文件
Electric Vehicle Routing Problem Configuration
"""

from dataclasses import dataclass
from typing import List, Tuple


@dataclass
class GAConfig:
    """遗传算法配置"""
    population_size: int = 200
    max_generations: int = 500
    crossover_rate: float = 0.8
    mutation_rate: float = 0.1
    elite_size: int = 20
    tournament_size: int = 3


@dataclass
class ProblemConfig:
    """问题配置"""
    num_customers: int = 15
    num_charging_stations: int = 4
    vehicle_capacity: float = 50.0
    vehicle_battery: float = 100.0
    consumption_rate: float = 0.5
    loading_time: float = 2.0
    depot_x: float = 50.0
    depot_y: float = 50.0
    map_size: float = 100.0


@dataclass
class VisualizationConfig:
    """可视化配置"""
    save_plots: bool = True
    plot_during_evolution: bool = False
    save_interval: int = 50
    dpi: int = 300
    figsize: Tuple[int, int] = (12, 8)


@dataclass
class OutputConfig:
    """输出配置"""
    save_results: bool = True
    output_dir: str = "results"
    save_json: bool = True
    save_csv: bool = True


class ConfigManager:
    """配置管理器"""
    
    def __init__(self):
        self.ga = GAConfig()
        self.problem = ProblemConfig()
        self.visualization = VisualizationConfig()
        self.output = OutputConfig()
        
    def load_from_file(self, config_file: str):
        """从文件加载配置"""
        import json
        try:
            with open(config_file, 'r') as f:
                config_data = json.load(f)
                
            if 'ga' in config_data:
                self.ga = GAConfig(**config_data['ga'])
            if 'problem' in config_data:
                self.problem = ProblemConfig(**config_data['problem'])
            if 'visualization' in config_data:
                self.visualization = VisualizationConfig(**config_data['visualization'])
            if 'output' in config_data:
                self.output = OutputConfig(**config_data['output'])
                
        except FileNotFoundError:
            print(f"配置文件 {config_file} 不存在，使用默认配置")
        except Exception as e:
            print(f"加载配置文件时出错: {e}，使用默认配置")
            
    def save_to_file(self, config_file: str):
        """保存配置到文件"""
        import json
        config_data = {
            'ga': {
                'population_size': self.ga.population_size,
                'max_generations': self.ga.max_generations,
                'crossover_rate': self.ga.crossover_rate,
                'mutation_rate': self.ga.mutation_rate,
                'elite_size': self.ga.elite_size,
                'tournament_size': self.ga.tournament_size
            },
            'problem': {
                'num_customers': self.problem.num_customers,
                'num_charging_stations': self.problem.num_charging_stations,
                'vehicle_capacity': self.problem.vehicle_capacity,
                'vehicle_battery': self.problem.vehicle_battery,
                'consumption_rate': self.problem.consumption_rate,
                'loading_time': self.problem.loading_time,
                'depot_x': self.problem.depot_x,
                'depot_y': self.problem.depot_y,
                'map_size': self.problem.map_size
            },
            'visualization': {
                'save_plots': self.visualization.save_plots,
                'plot_during_evolution': self.visualization.plot_during_evolution,
                'save_interval': self.visualization.save_interval,
                'dpi': self.visualization.dpi,
                'figsize': self.visualization.figsize
            },
            'output': {
                'save_results': self.output.save_results,
                'output_dir': self.output.output_dir,
                'save_json': self.output.save_json,
                'save_csv': self.output.save_csv
            }
        }
        
        with open(config_file, 'w') as f:
            json.dump(config_data, f, indent=2)
            
    def __str__(self):
        """返回配置字符串"""
        return f"""
=== EVRP配置信息 ===
遗传算法:
  种群大小: {self.ga.population_size}
  最大代数: {self.ga.max_generations}
  交叉率: {self.ga.crossover_rate}
  变异率: {self.ga.mutation_rate}
  精英保留: {self.ga.elite_size}

问题设置:
  客户数量: {self.problem.num_customers}
  充电站数量: {self.problem.num_charging_stations}
  车辆载重: {self.problem.vehicle_capacity}
  电池容量: {self.problem.vehicle_battery}
  耗电率: {self.problem.consumption_rate}
  装载时间: {self.problem.loading_time}
  地图大小: {self.problem.map_size}x{self.problem.map_size}

可视化:
  保存图片: {self.visualization.save_plots}
  实时绘图: {self.visualization.plot_during_evolution}
  保存间隔: {self.visualization.save_interval}代

输出:
  保存结果: {self.output.save_results}
  输出目录: {self.output.output_dir}
"""