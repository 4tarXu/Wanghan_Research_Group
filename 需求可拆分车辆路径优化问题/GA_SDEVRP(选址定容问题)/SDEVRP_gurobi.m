%% 保持良好的工作空间清空习惯
clc
clear all
close all

%% 加载数据（10个客户点，1个配送中心）
    load('../test_data/City.mat')	      %需求点经纬度，用于画实际路径的XY坐标
    load('../test_data/Distance.mat')	  %距离矩阵
    load('../test_data/Demand.mat')       %需求量
    load('../test_data/Capacity.mat')     %车容量约束
     % load('../test_data/Travelcon.mat')    %车辆行驶约束(电量)

    
     Travelcon = 60;


    % 把测试算例中的后两个节点变成换电站
    ChargeStationNum = 6; % 换电站数量
    ChargeStations_index = [6:11]; % 换电站编号
    ChargeStations_index_Depot = [1 ChargeStations_index];
    Demand(ChargeStations_index) = 0; % 换电站的需求量设置为0
    CityNum = 10;% 总节点数量：配送中心(车场)数量 + 客户点数量 + 换电站数量

%% 参数设置
    % ----------------- 参数设置 ----------------- 
    CityNum = size(City,1); % 总节点数（节点1为仓库）
    CustomerNum = CityNum-ChargeStationNum; % 客户数
    VehicleNum = 2; % 车辆数
    Q = Capacity; % 车辆容量
    B = Travelcon; % 车辆最大行驶距离(电池容量)
%% 决策变量        
    % ----------------- 决策变量 ----------------- 
    % 1)车辆路径相关决策变量
    Xijk = binvar(CityNum, CityNum, VehicleNum, 'full'); % 三维路径变量 x(i,j,k)
    % 2)运输服务量相关决策变量(需求可拆分类问题专用)
    Yik = sdpvar(CityNum,VehicleNum); %车辆离开节点i的电量
    Uik = sdpvar(CityNum,VehicleNum); % 车辆k在节点i的卸货量
    Lik = sdpvar(CityNum,VehicleNum); % 车辆k离开节点i时的载货量
    Aik = sdpvar(CityNum,VehicleNum); % 车辆k到达节点i时的载货量
%% 目标函数    
    %  ----------------- 目标函数：最小化总距离 ----------------- 
    objective = 0;
    for k = 1:VehicleNum
        objective = objective + sum(sum(Distance .* Xijk(:,:,k)));
    end
%% 约束条件    
    constraints = [];
    
     % 1. (客户点)每个客户至少被一辆车服务一次，最多被2辆车服务
    for i = 2:CustomerNum
        constraints = [constraints, sum(sum(Xijk(i, :, :))) >= 1];
        constraints = [constraints, sum(sum(Xijk(i, :, :))) <= 2];
    end
 
    % 2. (车辆)同一辆车对同一客户点最多访问一次
    for k = 1:VehicleNum
        for i = 2:CustomerNum
            constraints = [constraints,sum(Xijk(i,:,k)) <= 1];
        end
    end

    % 3. (车辆)流量守恒约束
    for k = 1:VehicleNum
        for j = 1:CityNum
            constraints = [constraints, sum(Xijk(:,j,k)) == sum(Xijk(j,:,k))];
        end
    end
    
    % 4. (车辆)每辆车从Depot出发并返回
    for k = 1:VehicleNum
        constraints = [constraints, sum(Xijk(1, :, k)) <= 1]; % 最多从仓库出发一次
        constraints = [constraints, sum(Xijk(:, 1, k)) <= 1]; % 最多返回仓库一次
    end
    
    % 5.(车辆)运输服务量取值约束(只有车辆访问客户点时才生效)
    for k = 1:VehicleNum
        for i = 2:CityNum
            constraints = [constraints, sum(Uik(i,k)) >= 0];
            constraints = [constraints, sum(Uik(i,k)) <= Q * sum(Xijk(i,:,k))]; % 当车辆不服务于客户点时，Uik=0
        end
    end

    % 6.(车辆)车辆容量约束
    for k = 1:VehicleNum
        constraints = [constraints, sum(Uik(2:CustomerNum,k)) <= Q];
    end

    % 7.(客户)客户点需求必须被满足(可以是一辆车或者多辆车)
    for i = 2:CityNum
        constraints = [constraints, sum(Uik(i,:)) == Demand(i)];
    end

    % 8.(车辆)回路消除约束组，参考东北大学——苏强(导师：张瑞友)学位论文————考虑是否添加if i~=j
    % Lik取值约束(只有车辆访问客户点时才生效)
    for k = 1:VehicleNum
        for i = 1:CityNum
            constraints = [constraints, sum(Lik(i,k)) >= 0];
            constraints = [constraints, sum(Lik(i,k)) <= Q * sum(Xijk(i,:,k))]; % 当车辆不服务于客户点时，Uik=0
        end
    end
    % Aik取值约束(只有车辆访问客户点时才生效)
    for k = 1:VehicleNum
        for i = 1:CityNum
            constraints = [constraints, sum(Aik(i,k)) >= 0];
            constraints = [constraints, sum(Aik(i,k)) <= Q * sum(Xijk(i,:,k))]; % 当车辆不服务于客户点时，Uik=0
        end
    end
    % 运输弧(Xijk)上载重量不产生变化
    for k = 1:VehicleNum
        for i = 1:CityNum
            for j = 1:CityNum
                constraints = [constraints, - Q * (1 - Xijk(i,j,k)) <= Lik(i,k) - Aik(j,k)];
                constraints = [constraints, Lik(i,k) - Aik(j,k) <= Q * (1 - Xijk(i,j,k))];
            end
        end
    end

    % 9. (客户)货物量守恒约束组
    for k = 1:VehicleNum
        for i = 2:CityNum
             constraints = [constraints, Aik(i,k) - Uik(i,k) == Lik(i,k)];
        end
    end

    % (电池) 电量消耗计算("客户-客户"之间电量依据行驶距离减少)
     for k = 1:VehicleNum
         for i = 2:CustomerNum
            for j =1:CustomerNum
                   constraints = [constraints, 0 <= Yik(j,k)];
                   constraints = [constraints, Yik(j,k) <= Yik(i,k) - Distance(i,j) * Xijk(i,j,k) + B *(1 - Xijk(i,j,k))]; %如果车辆k从i到j，则j点电量必须小于i点电量减去路径(i,j)的电量消耗
             end
         end
     end

    % (电池) 电量消耗计算("换电站-客户"之间电量依据行驶距离减少)
     for k = 1:VehicleNum
         for i = ChargeStations_index_Depot
             for j =2:CustomerNum
                   constraints = [constraints, 0 <= Yik(j,k)];
                   constraints = [constraints, Yik(j,k) <= B - Distance(i,j) * Xijk(i,j,k) + B *(1 - Xijk(i,j,k))]; %如果车辆k从i到j，则j点电量必须小于i点电量减去路径(i,j)的电量消耗
             end
         end
     end

    % （电池）如果客户到换电站/配送中心，则必须有充足的电量
    % 
       for k = 1:VehicleNum
             for i = 2:CustomerNum
                 for j = ChargeStations_index_Depot
                     constraints = [constraints, Yik(i,k) - Distance(i,j) * Xijk(i,j,k)  >= 0];
                 end
             end
         end
      
     % (极端情况)车辆有足够电量行驶到所有换电站
      for k = 1:VehicleNum
          for i = ChargeStations_index
              for j = ChargeStations_index
                   constraints = [constraints, B -Distance(i,j) * Xijk(i,j,k) >= 0];
              end
         end
      end
     
      % 11.(客户-电池)换电站的载货量守恒
      for k = 1:VehicleNum
          for i = ChargeStations_index
               constraints = [constraints, Aik(i,k) == Lik(i,k)];
          end
      end
          
 %% 求解器参数   
    % 求解设置
    ops = sdpsettings('verbose', 1, 'solver', 'gurobi','debug',1,'savesolveroutput',1);
    ops.gurobi.TuneTimeLimit = 300;    % 设置5分钟调参时间
    % ops.gurobi.WriteToFile = 'model_1.lp';
    % 其他必要设置
     ops.gurobi.TimeLimit = 600;       % 求解时间限制
% ops.gurobi.OutputFlag = 1;
% ops.gurobi.ResultFile = 'model.ilp';  % 保存IIS结果
% ops.gurobi.LogFile = 'gurobi.log';

    % 求解
    sol = optimize(constraints, objective, ops);


 %% 结果输出   
    % if sol.problem ~= 0
        % 提取解
        x_val = value(Xijk);
        u_val = value(Uik);
        y_val = value(Yik);
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
    % else
    %     disp('求解失败');
    %     disp(sol.info);
    % end

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