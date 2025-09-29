function Chrom = RemoveRedundantChargers(Distance,Demand,Chrom,Capacity,Travelcon,VehicleNum,VehicleCost,BatteryCap,ChargeStations_index,ChargeStationNum,ChargeStationBatteryNum)
% 剔除子路径中多余的充电站：
% 剔除原理：检查子路径中敲除充电站，子路径是否扔满足电量约束/距离约束

% 提取Chrom的维度，用于for函数索引
[NIND_size Route_size] = size(Chrom); 


% 对每一个染色体都执行操作
for i = 1:NIND_size
        % 设置临时染色体Chrom_new,如果可剔除多余充电站更优则替换Chrom
             Chrom_new = Chrom(i,:);

        % 对所有充电站执行剔除筛选操作
        for j = 1:(ChargeStationNum*ChargeStationBatteryNum)
            % 查找充电站j位置的
            Charge_index= find(Chrom_new==ChargeStations_index(j));

            % 剔除充电站
            Chrom_new_save = Chrom_new; %保存未删除的结果
            Chrom_new(Charge_index) = []; 

             % 计算邻域搜索后路径长度
             [ttlDistance1,~]=Fitness(Distance,Demand,Chrom_new,Capacity,Travelcon,VehicleNum,VehicleCost,BatteryCap,ChargeStations_index); %邻域搜索后路径长度
             [ttlDistance2,~]=Fitness(Distance,Demand,Chrom_new_save,Capacity,Travelcon,VehicleNum,VehicleCost,BatteryCap,ChargeStations_index);
      
             % 如果找到剔除充电站后更优，则进行路径替换(如果剔除充电站后不满足里程约束，则根据Fitness函数计算规则，会输出为Inf)
             if ttlDistance1 <= ttlDistance2 % 这里必须是小于等于，否则充电站无法剔除
                  Chrom(i,1:length(Chrom_new))=Chrom_new; % 代码潜在风险：如果Chrom后边的数字1占位符不足，可能导致部分客户点被删除
                 % break
             else
                 Chrom_new=Chrom_new_save; % 
             end     

        end




        % % 对所有充电站执行剔除筛选操作
        % for j = 1:(ChargeStationNum*ChargeStationBatteryNum)
        %     % 查找充电站j位置的
        %     Charge_index= find(Chrom(i,:)==ChargeStations_index(j));
        % 
        %     % 剔除充电站
        %     Chrom_new(Charge_index) = []; 
        % 
        %      % 计算邻域搜索后路径长度
        %      [ttlDistance1,~]=Fitness(Distance,Demand,Chrom_new,Capacity,Travelcon,VehicleNum,VehicleCost,BatteryCap,ChargeStations_index); %邻域搜索后路径长度
        %      [ttlDistance2,~]=Fitness(Distance,Demand,Chrom(i,:),Capacity,Travelcon,VehicleNum,VehicleCost,BatteryCap,ChargeStations_index);
        % 
        %      % 如果找到剔除充电站后更优，则进行路径替换(如果剔除充电站后不满足里程约束，则根据Fitness函数计算规则，会输出为Inf)
        %      if ttlDistance1 < ttlDistance2
        %           Chrom(i,1:length(Chrom_new))=Chrom_new; % 代码潜在风险：如果Chrom后边的数字1占位符不足，可能导致部分客户点被删除
        %          % break
        %      else
        %          Chrom_new=Chrom(i,:); % 错误：会被替换成原始路径
        %      end     
        %                    % fprintf('执行充电站筛选剔除操作  %d \n',j)
        % 
        % end
end








