% 需求可拆分的电动车辆路径优化问题 (EVRP-SDVRP)
% 完全脚本实现，无function函数
clc;
clear;
close all;

%% 参数设置
vehicle_capacity = 200;     % 车辆容量
battery_capacity = 100;     % 电池容量 (kWh)
energy_consumption = 0.2;   % 能耗率 (kWh/km)
depot_id = 1;               % 仓库节点ID
max_vehicles = 10;          % 最大车辆数
penalty_factor = 10000;     % 约束违反惩罚因子

% 遗传算法参数
pop_size = 30;              % 种群大小
max_gen = 100;              % 最大迭代次数
mutation_rate = 0.15;       % 变异率
crossover_rate = 0.75;      % 交叉率
elite_ratio = 0.15;         % 精英保留比例
tournament_size = 3;        % 锦标赛选择的大小

%% 加载Solomon算例数据
% 格式: [ID X Y Demand]
nodes = [
    1,  0,  0,  0;    % 仓库
    2,  10, 20, 10;   % 客户
    3,  20, 10, 15;
    4,  30, 30, 5;
    5,  40, 10, 20;
    6,  50, 30, 10;
    7,  60, 20, 25;
    8,  70, 40, 15;
    9,  80, 10, 30;
    10, 90, 50, 10;
    101, 25, 25, 0;   % 充电站1
    102, 55, 35, 0;   % 充电站2
    103, 75, 15, 0;   % 充电站3
];

% 节点数量
num_nodes = size(nodes, 1);

%% 计算距离矩阵
dist_matrix = zeros(num_nodes, num_nodes);
for i = 1:num_nodes
    for j = 1:num_nodes
        if i ~= j
            dist_matrix(i, j) = sqrt((nodes(i, 2) - nodes(j, 2))^2 + ...
                                 (nodes(i, 3) - nodes(j, 3))^2);
        end
    end
end

%% 初始化种群
% 获取客户节点索引
customer_indices = find(nodes(:, 4) > 0 & nodes(:, 1) ~= depot_id);
num_customers = length(customer_indices);

% 存储解决方案
population_routes = cell(pop_size, max_vehicles);
population_loads = zeros(pop_size, max_vehicles);
population_count = zeros(pop_size, 1); % 每行存储车辆数量
fitness_values = zeros(pop_size, 1);   % 存储适应度值

% 初始化种群
for sol_idx = 1:pop_size
    % 当前解的变量
    routes = cell(1, max_vehicles);
    loads = zeros(1, max_vehicles);
    vehicle_count = 0;
    
    % 复制客户需求（用于需求拆分）
    remaining_demands = nodes(customer_indices, 4);
    
    % 随机排列客户访问顺序
    shuffled_customers = customer_indices(randperm(num_customers));
    
    % 为每个客户分配访问
    for j = 1:num_customers
        customer_idx = shuffled_customers(j);
        demand = nodes(customer_idx, 4);
        
        % 需求拆分：随机决定是否拆分
        if demand > 0 && rand() < 0.4 % 40%概率拆分需求
            split_demand = randi([1, min(demand, vehicle_capacity)]);
        else
            split_demand = demand;
        end
        
        % 尝试将客户添加到现有路线
        added = false;
        for k = 1:vehicle_count
            if loads(k) + split_demand <= vehicle_capacity
                % 添加到现有路线
                routes{k} = [routes{k}, nodes(customer_idx, 1)];
                loads(k) = loads(k) + split_demand;
                added = true;
                break;
            end
        end
        
        % 如果无法添加到现有路线，使用新车
        if ~added && vehicle_count < max_vehicles
            vehicle_count = vehicle_count + 1;
            routes{vehicle_count} = [depot_id, nodes(customer_idx, 1)];
            loads(vehicle_count) = split_demand;
        end
        
        % 更新剩余需求
        remaining_demands(j) = remaining_demands(j) - split_demand;
    end
    
    % 为每条路线添加结束仓库
    for k = 1:vehicle_count
        routes{k} = [routes{k}, depot_id];
    end
    
    % 修复路线以满足电量约束（内联修复代码）
    for k = 1:vehicle_count
        route = routes{k};
        current_battery = battery_capacity;
        new_route = [depot_id]; % 从仓库开始
        
        for i = 2:length(route)
            from_id = route(i-1);
            to_id = route(i);
            
            % 查找节点索引
            from_idx = find(nodes(:,1) == from_id);
            to_idx = find(nodes(:,1) == to_id);
            
            % 计算能耗
            energy_used = dist_matrix(from_idx, to_idx) * energy_consumption;
            
            % 检查电量是否足够
            if energy_used > current_battery
                % 需要充电 - 查找充电站
                charging_stations = find(nodes(:,4) == 0 & nodes(:,1) ~= depot_id);
                
                if ~isempty(charging_stations)
                    % 计算到所有充电站的距离
                    min_dist = inf;
                    best_station_id = -1;
                    for s = 1:length(charging_stations)
                        station_idx = charging_stations(s);
                        dist_to_station = dist_matrix(from_idx, station_idx);
                        if dist_to_station < min_dist
                            min_dist = dist_to_station;
                            best_station_id = nodes(station_idx, 1);
                        end
                    end
                    
                    % 插入充电站
                    new_route = [new_route, best_station_id];
                    current_battery = battery_capacity; % 充满电
                end
            end
            
            % 添加当前节点
            new_route = [new_route, to_id];
            current_battery = current_battery - energy_used;
            
            % 如果是充电站，重置电量
            if to_id ~= depot_id && nodes(to_idx, 4) == 0
                current_battery = battery_capacity;
            end
        end
        
        % 更新路线
        routes{k} = new_route;
    end
    
    % 存储解决方案
    population_routes(sol_idx, 1:max_vehicles) = routes;
    population_loads(sol_idx, :) = loads;
    population_count(sol_idx) = vehicle_count;
end

%% 计算初始适应度
for sol_idx = 1:pop_size
    total_distance = 0;
    energy_violation = 0;
    capacity_violation = 0;
    vehicle_count = population_count(sol_idx);
    
    % 计算总距离和约束违反
    for k = 1:vehicle_count
        route = population_routes{sol_idx, k};
        
        % 计算路线距离
        for i = 2:length(route)
            from_id = route(i-1);
            to_id = route(i);
            from_idx = find(nodes(:,1) == from_id);
            to_idx = find(nodes(:,1) == to_id);
            total_distance = total_distance + dist_matrix(from_idx, to_idx);
        end
        
        % 检查电量约束
        current_battery = battery_capacity;
        for i = 2:length(route)
            from_id = route(i-1);
            to_id = route(i);
            from_idx = find(nodes(:,1) == from_id);
            to_idx = find(nodes(:,1) == to_id);
            
            % 计算能耗
            energy_used = dist_matrix(from_idx, to_idx) * energy_consumption;
            
            if energy_used > current_battery
                energy_violation = energy_violation + (energy_used - current_battery);
            end
            
            % 更新电量
            current_battery = current_battery - energy_used;
            
            % 如果是充电站，重置电量
            if to_id ~= depot_id && nodes(to_idx, 4) == 0
                current_battery = battery_capacity;
            end
        end
        
        % 检查载重约束
        if population_loads(sol_idx, k) > vehicle_capacity
            capacity_violation = capacity_violation + (population_loads(sol_idx, k) - vehicle_capacity);
        end
    end
    
    % 计算总成本
    fitness_values(sol_idx) = total_distance + ...                     % 总距离
                              vehicle_count * 100 + ...               % 车辆使用成本
                              energy_violation * penalty_factor + ... % 电量约束违反惩罚
                              capacity_violation * penalty_factor;    % 载重约束违反惩罚
end

%% 遗传算法主循环
best_fitness = inf;
best_solution_routes = population_routes(1, :);
best_solution_loads = population_loads(1, :);
best_solution_count = population_count(1);
fitness_history = zeros(max_gen, 1);

for gen = 1:max_gen
    % 选择操作 (锦标赛选择)
    new_population_routes = cell(pop_size, max_vehicles);
    new_population_loads = zeros(pop_size, max_vehicles);
    new_population_count = zeros(pop_size, 1);
    
    for i = 1:pop_size
        % 随机选择锦标赛选手
        tournament_indices = randperm(pop_size, tournament_size);
        tournament_fitness = fitness_values(tournament_indices);
        
        % 选择适应度最好的个体
        [~, best_idx] = min(tournament_fitness);
        new_population_routes(i, :) = population_routes(tournament_indices(best_idx), :);
        new_population_loads(i, :) = population_loads(tournament_indices(best_idx), :);
        new_population_count(i) = population_count(tournament_indices(best_idx));
    end
    
    % 交叉操作 (基于路径的交叉)
    for i = 1:2:pop_size-1
        if rand() < crossover_rate
            % 获取父代
            parent1_idx = i;
            parent2_idx = i+1;
            
            parent1_count = new_population_count(parent1_idx);
            parent2_count = new_population_count(parent2_idx);
            
            if parent1_count > 0 && parent2_count > 0
                % 随机选择交叉点
                route_idx1 = randi(parent1_count);
                route_idx2 = randi(parent2_count);
                
                % 交换部分路线
                temp_route = new_population_routes{parent1_idx, route_idx1};
                new_population_routes{parent1_idx, route_idx1} = new_population_routes{parent2_idx, route_idx2};
                new_population_routes{parent2_idx, route_idx2} = temp_route;
                
                % 更新车辆负载
                % 计算新负载
                new_load1 = 0;
                route1 = new_population_routes{parent1_idx, route_idx1};
                for node_id = route1
                    if node_id ~= depot_id
                        node_idx = find(nodes(:,1) == node_id);
                        if nodes(node_idx, 4) > 0
                            new_load1 = new_load1 + nodes(node_idx, 4);
                        end
                    end
                end
                
                new_load2 = 0;
                route2 = new_population_routes{parent2_idx, route_idx2};
                for node_id = route2
                    if node_id ~= depot_id
                        node_idx = find(nodes(:,1) == node_id);
                        if nodes(node_idx, 4) > 0
                            new_load2 = new_load2 + nodes(node_idx, 4);
                        end
                    end
                end
                
                new_population_loads(parent1_idx, route_idx1) = new_load1;
                new_population_loads(parent2_idx, route_idx2) = new_load2;
            end
        end
    end
    
    % 变异操作
    for sol_idx = 1:pop_size
        if rand() < mutation_rate
            % 获取当前解
            routes = new_population_routes(sol_idx, :);
            loads = new_population_loads(sol_idx, :);
            vehicle_count = new_population_count(sol_idx);
            
            % 随机选择一种变异操作
            mutation_type = randi(3);
            
            if vehicle_count > 0
                switch mutation_type
                    case 1 % 交换两个节点
                        route_idx = randi(vehicle_count);
                        route = routes{route_idx};
                        
                        if length(route) > 3 % 至少有两个客户节点
                            % 选择非仓库节点
                            valid_positions = find(route ~= depot_id);
                            if length(valid_positions) >= 2
                                pos = randperm(length(valid_positions), 2);
                                pos1 = valid_positions(pos(1));
                                pos2 = valid_positions(pos(2));
                                
                                % 交换节点
                                temp = route(pos1);
                                route(pos1) = route(pos2);
                                route(pos2) = temp;
                                
                                routes{route_idx} = route;
                            end
                        end
                        
                    case 2 % 移动节点到另一条路线
                        if vehicle_count > 1
                            % 选择源路线
                            src_route_idx = randi(vehicle_count);
                            src_route = routes{src_route_idx};
                            
                            % 选择要移动的节点 (排除仓库)
                            valid_positions = find(src_route ~= depot_id);
                            if ~isempty(valid_positions)
                                pos = valid_positions(randi(length(valid_positions)));
                                node_id = src_route(pos);
                                node_idx = find(nodes(:,1) == node_id);
                                demand = nodes(node_idx, 4);
                                
                                % 从源路线移除节点
                                src_route(pos) = [];
                                routes{src_route_idx} = src_route;
                                loads(src_route_idx) = loads(src_route_idx) - demand;
                                
                                % 选择目标路线
                                tgt_route_idx = randi(vehicle_count);
                                while tgt_route_idx == src_route_idx
                                    tgt_route_idx = randi(vehicle_count);
                                end
                                
                                % 添加到目标路线随机位置
                                tgt_route = routes{tgt_route_idx};
                                if length(tgt_route) > 2
                                    insert_pos = randi([2, length(tgt_route)]);
                                else
                                    insert_pos = 2;
                                end
                                
                                tgt_route = [tgt_route(1:insert_pos-1), node_id, tgt_route(insert_pos:end)];
                                routes{tgt_route_idx} = tgt_route;
                                loads(tgt_route_idx) = loads(tgt_route_idx) + demand;
                            end
                        end
                        
                    case 3 % 需求拆分调整
                        customer_ids = nodes(nodes(:,4) > 0 & nodes(:,1) ~= depot_id, 1)';
                        if ~isempty(customer_ids)
                            customer_id = customer_ids(randi(length(customer_ids)));
                            
                            % 查找所有包含该客户的路线
                            routes_with_customer = [];
                            for k = 1:vehicle_count
                                if ismember(customer_id, routes{k})
                                    routes_with_customer(end+1) = k;
                                end
                            end
                            
                            if length(routes_with_customer) > 1
                                % 随机选择两条路线
                                idx = randperm(length(routes_with_customer), 2);
                                route_idx1 = routes_with_customer(idx(1));
                                route_idx2 = routes_with_customer(idx(2));
                                
                                % 计算可调整的需求量
                                node_idx = find(nodes(:,1) == customer_id);
                                total_demand = nodes(node_idx, 4);
                                
                                max_transfer = min([loads(route_idx1), total_demand - loads(route_idx2), vehicle_capacity]);
                                
                                if max_transfer > 0
                                    transfer_amount = randi([1, max_transfer]);
                                    
                                    % 更新路线需求
                                    loads(route_idx1) = loads(route_idx1) - transfer_amount;
                                    loads(route_idx2) = loads(route_idx2) + transfer_amount;
                                end
                            end
                        end
                end
            end
            
            % 存储变异后的解
            new_population_routes(sol_idx, :) = routes;
            new_population_loads(sol_idx, :) = loads;
            new_population_count(sol_idx) = vehicle_count;
        end
    end
    
    % 精英保留
    elite_count = round(elite_ratio * pop_size);
    if elite_count > 0
        % 排序当前种群
        [sorted_fitness, sorted_idx] = sort(fitness_values);
        elite_indices = sorted_idx(1:elite_count);
        
        % 随机替换新种群中的个体
        replace_indices = randperm(pop_size, elite_count);
        
        for i = 1:elite_count
            new_population_routes(replace_indices(i), :) = population_routes(elite_indices(i), :);
            new_population_loads(replace_indices(i), :) = population_loads(elite_indices(i), :);
            new_population_count(replace_indices(i)) = population_count(elite_indices(i));
        end
    end
    
    % 更新种群
    population_routes = new_population_routes;
    population_loads = new_population_loads;
    population_count = new_population_count;
    
    % 计算新适应度
    for sol_idx = 1:pop_size
        total_distance = 0;
        energy_violation = 0;
        capacity_violation = 0;
        vehicle_count = population_count(sol_idx);
        
        % 计算总距离和约束违反
        for k = 1:vehicle_count
            route = population_routes{sol_idx, k};
            
            % 计算路线距离
            for i = 2:length(route)
                from_id = route(i-1);
                to_id = route(i);
                from_idx = find(nodes(:,1) == from_id);
                to_idx = find(nodes(:,1) == to_id);
                total_distance = total_distance + dist_matrix(from_idx, to_idx);
            end
            
            % 检查电量约束
            current_battery = battery_capacity;
            for i = 2:length(route)
                from_id = route(i-1);
                to_id = route(i);
                from_idx = find(nodes(:,1) == from_id);
                to_idx = find(nodes(:,1) == to_id);
                
                % 计算能耗
                energy_used = dist_matrix(from_idx, to_idx) * energy_consumption;
                
                if energy_used > current_battery
                    energy_violation = energy_violation + (energy_used - current_battery);
                end
                
                % 更新电量
                current_battery = current_battery - energy_used;
                
                % 如果是充电站，重置电量
                if to_id ~= depot_id && nodes(to_idx, 4) == 0
                    current_battery = battery_capacity;
                end
            end
            
            % 检查载重约束
            if population_loads(sol_idx, k) > vehicle_capacity
                capacity_violation = capacity_violation + (population_loads(sol_idx, k) - vehicle_capacity);
            end
        end
        
        % 计算总成本
        fitness_values(sol_idx) = total_distance + ...                     % 总距离
                                  vehicle_count * 100 + ...               % 车辆使用成本
                                  energy_violation * penalty_factor + ... % 电量约束违反惩罚
                                  capacity_violation * penalty_factor;    % 载重约束违反惩罚
    end
    
    % 更新最佳解
    [min_fitness, min_idx] = min(fitness_values);
    if min_fitness < best_fitness
        best_fitness = min_fitness;
        best_solution_routes = population_routes(min_idx, :);
        best_solution_loads = population_loads(min_idx, :);
        best_solution_count = population_count(min_idx);
    end
    
    fitness_history(gen) = best_fitness;
    
    % 显示进度
    if mod(gen, 10) == 0
        fprintf('迭代 %d: 最佳适应度 = %.2f\n', gen, best_fitness);
    end
end

%% 结果显示
fprintf('\n最佳解决方案适应度: %.2f\n', best_fitness);
fprintf('使用车辆数: %d\n', best_solution_count);

% 计算总距离
total_distance = 0;
for k = 1:best_solution_count
    route = best_solution_routes{k};
    route_dist = 0;
    
    % 计算路线距离
    for i = 2:length(route)
        from_id = route(i-1);
        to_id = route(i);
        from_idx = find(nodes(:,1) == from_id);
        to_idx = find(nodes(:,1) == to_id);
        route_dist = route_dist + dist_matrix(from_idx, to_idx);
    end
    total_distance = total_distance + route_dist;
    
    % 计算路线负载
    route_load = best_solution_loads(k);
    
    fprintf('车辆 %d: 路线 = ', k);
    for j = 1:length(route)
        if route(j) == depot_id
            fprintf('D ');
        elseif nodes(find(nodes(:,1) == route(j)), 4) == 0
            fprintf('C%d ', route(j)); % 充电站
        else
            fprintf('%d ', route(j));
        end
    end
    fprintf('| 距离 = %.2f km | 负载 = %d\n', route_dist, route_load);
end
fprintf('总距离: %.2f km\n', total_distance);

%% 可视化解决方案
figure;
hold on;
grid on;
title('EVRP-SDVRP 最佳解决方案');
xlabel('X Coordinate');
ylabel('Y Coordinate');

% 绘制所有节点
depot = nodes(nodes(:,1) == 1, :);
customers = nodes(nodes(:,4) > 0 & nodes(:,1) ~= 1, :);
charging_stations = nodes(nodes(:,4) == 0 & nodes(:,1) ~= 1, :);

% 绘制仓库
plot(depot(2), depot(3), 'ks', 'MarkerSize', 10, 'MarkerFaceColor', 'k');
text(depot(2), depot(3), 'Depot', 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'right');

% 绘制客户
plot(customers(:,2), customers(:,3), 'bo', 'MarkerSize', 8, 'MarkerFaceColor', 'b');
for i = 1:size(customers, 1)
    text(customers(i,2), customers(i,3), num2str(customers(i,1)), ...
        'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'right');
end

% 绘制充电站
if ~isempty(charging_stations)
    plot(charging_stations(:,2), charging_stations(:,3), 'g^', 'MarkerSize', 8, 'MarkerFaceColor', 'g');
    for i = 1:size(charging_stations, 1)
        text(charging_stations(i,2), charging_stations(i,3), ['C' num2str(charging_stations(i,1))], ...
            'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'right');
    end
end

% 定义颜色映射
colors = lines(best_solution_count);

% 绘制路线
for k = 1:best_solution_count
    route = best_solution_routes{k};
    route_coords = zeros(length(route), 2);
    
    for i = 1:length(route)
        node_idx = find(nodes(:,1) == route(i));
        route_coords(i, :) = nodes(node_idx, 2:3);
    end
    
    % 绘制路线
    plot(route_coords(:,1), route_coords(:,2), 'o-', 'Color', colors(k,:), 'LineWidth', 1.5);
    text(mean(route_coords(:,1)), mean(route_coords(:,2)), ['V' num2str(k)], ...
        'BackgroundColor', 'w', 'EdgeColor', colors(k,:));
end

hold off;

%% 绘制收敛曲线
figure;
plot(fitness_history, 'LineWidth', 2);
title('遗传算法收敛曲线');
xlabel('迭代次数');
ylabel('最佳适应度');
grid on;