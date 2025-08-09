function [TotalCost,FitnV]=Fitness(Distance,Demand,Chrom,Capacity,Travelcon,VehicleNum,VehicleCost,BatteryCap,ChargeStations_index,TravelTime,TimeWindow,ServiceTime)
%% 计算各个体的路径长度 适应度函数  
% 输入：
% Distance      两两城市之间的距离
% Demand        各点需求量
% Chrom         种群矩阵
% Capacity      容量约束
% 输出：
% ttlDistance	种群个体路径距离组成的向量
% FitnV         个体的适应度值组成的列向量

[NIND,len]=size(Chrom); %行列
TotalCost=zeros(1,NIND); %分配矩阵内存

for i=1:NIND
    %相关数据初始化
    DisTraveled=0;  % 汽车已经行驶的距离
    CurrentTime=0; % 所有车辆行驶时间置零
    delivery=0; % 汽车已经送货量，即已经到达点的需求量之和置零
    Dis=0; %此方案所有车辆的总距离
    Penalty_TimeWindow = 0 ; % 初始化时间窗惩罚成本
    route=Chrom(i,:);  %取出一条路径
    route=route(route>0);%剔除路径中的零元素
    Splitdelivery=0;%需求拆分剩余量
    SplitNode=666;%需求拆分节点编号(666没啥特殊含义，与客户节点编号区别开就行)
    for j=2:length(route)

        DisTraveled = DisTraveled+Distance(route(j-1),route(j)); %每两点间距离累加
        CurrentTime = max(CurrentTime+TravelTime(route(j-1),route(j)),TimeWindow(route(j),1))+ServiceTime(route(j)); % 更新车辆已行驶时间,若车辆到达时间早于客户时间窗，则需等待到时间窗再开始进行服务

        delivery = delivery+Demand(route(j)); %累加可配送量

         % 检查客户点是否是充电站(如果是充电站，则车辆行驶距离清零)
             if route(j)>= min(ChargeStations_index)
                  Dis=Dis+DisTraveled; %累加已行驶距离（这行代码必须在清零之前添加，否则总成本没有计算清零之前）
                 DisTraveled = 0;
             end

        if delivery>Capacity %如果需求量超过车容量，则计算剩余客户需求量
            SplitNode =j;   % 记录需求拆分点
            Splitdelivery=delivery-Capacity;% 计算拆分剩余客户需求量(即下一车辆的初始装载量)
        end

        if route(j-1)==1 && j==SplitNode    % 如果客户前一节点是配送中心，则需要判断客户点是否是需求拆分点
            delivery = delivery - Demand(route(j)) + Splitdelivery;
        end

        % %如果不满足里程约束,加入Inf值作为惩罚函数                
         if DisTraveled > Travelcon 
             Dis=Inf;
             break
         end
        
        if CurrentTime -  ServiceTime(route(j)) > TimeWindow(route(j),2)

            Penalty_TimeWindow = Penalty_TimeWindow + (CurrentTime -  ServiceTime(route(j)) - TimeWindow(route(j),2));

        end




% || CurrentTime -  ServiceTime(route(j)) > TimeWindow(route(j),2) % 注意这里需要减去服务时间

        if route(j)==1 %若此位是配送中心
            Dis=Dis+DisTraveled; %累加已行驶距离
            DisTraveled=0; %已行驶距离置零
            CurrentTime=0; % 所有车辆行驶时间置零
            delivery=0; %已配送置零
        end

        % %如果不满足里程约束,加入Inf值作为惩罚函数                
         % if DisTraveled > Travelcon
         %     Dis=Inf;
         %     break
         % end


    end
    TotalCost(i)=10*Penalty_TimeWindow + Dis + VehicleNum(i) * VehicleCost;%存储此方案总距离
end

FitnV=1./TotalCost; %适应度函数设为距离倒数  对向量进行点运算
