%% 保持良好的工作空间清空习惯
clc
clear all
close all

%% 加载数据
load('../test_data/City.mat')	      %需求点经纬度，用于画实际路径的XY坐标
load('../test_data/Distance.mat')	  %距离矩阵
load('../test_data/Demand.mat')       %需求量
load('../test_data/Capacity.mat')     %车容量约束

    % 参数设置
    CustomerNum = size(City,1)-1; % 客户数
    CityNum = size(City,1); % 总节点数（节点1为仓库）
    VehicleNum = 8; % 车辆数
    Q = Capacity; % 车辆容量
    demands = Demand; % 需求量（仓库为0）
    
    % 距离矩阵（示例数据）
    dist = Distance;
    % dist = dist + dist'; % 确保对称
    % for i = 1:N
    %     dist(i,i) = 0;
    % end
    
    % 决策变量
    x = binvar(CityNum, CityNum, VehicleNum, 'full'); % 三维路径变量 x(i,j,k)
    u = sdpvar(CustomerNum, VehicleNum); % MTZ辅助变量 u(i,k) - 针对每个客户和每辆车
    
    % 目标函数：最小化总距离
    objective = 0;
    for k = 1:VehicleNum
        objective = objective + sum(sum(dist .* x(:,:,k)));
    end
    
    constraints = [];
    
    % 1. 每个客户只能被一辆车访问一次
    for j = 2:CityNum
        constraints = [constraints, sum(sum(x(:, j, :))) == 1];
    end
    
    % 2. 流量守恒约束
    for k = 1:VehicleNum
        for i = 1:CityNum
            constraints = [constraints, sum(x(i, :, k)) == sum(x(:, i, k))];
        end
    end
    
    % 3. 仓库约束：每辆车从仓库出发并返回
    for k = 1:VehicleNum
        constraints = [constraints, sum(x(1, :, k)) <= 1]; % 最多从仓库出发一次
        constraints = [constraints, sum(x(:, 1, k)) <= 1]; % 最多返回仓库一次
    end
    
    % 4. 消除自环
    for k = 1:VehicleNum
        for i = 1:CityNum
            constraints = [constraints, x(i, i, k) == 0];
        end
    end
    
    % 5. MTZ子回路消除约束（针对每辆车）
    for k = 1:VehicleNum
        for i = 1:CustomerNum
            for j = 1:CustomerNum
                if i ~= j
                    % MTZ核心约束：u(i,k) - u(j,k) + n*x(i+1,j+1,k) <= n - 1
                    constraints = [constraints, 
                        u(i,k) - u(j,k) + CustomerNum * x(i+1, j+1, k) <= CustomerNum - 1];
                end
            end
        end
    end
    
    % 6. u变量范围约束
    for k = 1:VehicleNum
        for i = 1:CustomerNum
            constraints = [constraints, u(i,k) >= 1];
            constraints = [constraints, u(i,k) <= CustomerNum];
        end
    end
    
    % 7. 容量约束
    for k = 1:VehicleNum
        capacity_constraint = 0;
        for i = 1:CityNum
            for j = 1:CityNum
                if i ~= j
                    capacity_constraint = capacity_constraint + demands(j) * x(i,j,k);
                end
            end
        end
        constraints = [constraints, capacity_constraint <= Q];
    end
    
    % 8. 确保如果车辆k不访问客户i，则对应的u(i,k)不受影响
    % 通过big-M方法实现
    M = CustomerNum + 1;
    for k = 1:VehicleNum
        for i = 1:CustomerNum
            % 如果车辆k访问客户i+1，则u(i,k)在有效范围内
            visited = 0;
            for j = 1:CityNum
                if j ~= i+1
                    visited = visited + x(j, i+1, k);
                end
            end
            constraints = [constraints, u(i,k) <= 1 + (CustomerNum-1) * visited];
            constraints = [constraints, u(i,k) >= visited];
        end
    end
    
    % 求解设置
    ops = sdpsettings('verbose', 1, 'solver', 'gurobi');
    
    % 求解
    sol = optimize(constraints, objective, ops);
    
    if sol.problem == 0
        % 提取解
        x_val = value(x);
        u_val = value(u);
        
        % 输出结果
        disp('求解成功！');
        disp(['总距离：', num2str(value(objective))]);
        
        % 显示每辆车的路径
        for k = 1:VehicleNum
            fprintf('车辆%d的路径：', k);
            path = find_path(x_val(:,:,k), CityNum);
            if ~isempty(path)
                fprintf('%s\n', mat2str(path));
            else
                fprintf('未使用\n');
            end
        end
    else
        disp('求解失败');
        disp(sol.info);
    end

% 辅助函数：从x矩阵中提取路径
function path = find_path(x_matrix, N)
    path = [];
    current = 1; % 从仓库开始
    visited = zeros(1, N);
    
    while true
        path = [path, current];
        visited(current) = 1;
        
        next_nodes = find(x_matrix(current, :) > 0.5);
        if isempty(next_nodes) || next_nodes(1) == 1
            break;
        end
        
        % 选择未访问的节点
        found = false;
        for i = 1:length(next_nodes)
            if ~visited(next_nodes(i))
                current = next_nodes(i);
                found = true;
                break;
            end
        end
        
        if ~found
            break;
        end
    end
    
    % 如果最后没有回到仓库，添加仓库
    if path(end) ~= 1 && ~isempty(path)
        path = [path, 1];
    end
end