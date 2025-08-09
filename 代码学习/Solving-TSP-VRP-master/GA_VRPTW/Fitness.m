function [ttlDistance,FitnV]=Fitness(Chrom,Distance,TravelTime,Demand,TimeWindow,Travelcon,Capacity)
%% 计算各个体的路径长度 适应度函数  
% 输入：
% Chrom         种群矩阵
% Distance      两两城市之间的距离
% TravelTime    行驶时间矩阵
% Demand        各点需求量
% TimeWindow    早晚时间窗
% Travelcon     行程约束
% Capacity      容量约束

% 输出：
% ttlDistance	种群个体路径距离组成的向量
% FitnV         个体的适应度值组成的列向量

[NIND,len] = size(Chrom); %行列
ttlDistance = zeros(1,NIND); %分配矩阵内存

for i=1:NIND
    %相关数据初始化
    Dis=0; %此方案所有车辆的总距离置零
    DisTraveled=0;  % 所有车辆已经行驶的距离置零
    CurrentTime=0; % 所有车辆行驶时间置零
    delivery=0; % 所有车辆已经送货量，即已经到达点的需求量之和
    
    route=Chrom(i,:);  %取出一条路径

    for j=2:len
        DisTraveled = DisTraveled+Distance(route(j-1),route(j)); %每两点间距离累加
        if route(j) == 1  %若此点是配送中心
            
            if DisTraveled > Travelcon
                Dis = Inf;  %对非可行解进行惩罚
                break
            else
                Dis=Dis+DisTraveled; %累加已行驶距离
                DisTraveled=0; %已行驶距离置零
                CurrentTime=0; %时间置零TimeWindow(1,2)
                delivery=0; %可配送量置零
            end
        else %若此点非配送中心
            if DisTraveled > Travelcon
                Dis = Inf;  %对非可行解进行惩罚
                break
            else
                delivery = delivery+Demand(route(j)); %累加可配送量
                if delivery > Capacity
                    Dis = Inf; %对非可行解进行惩罚
                    break
                else
                    CurrentTime = CurrentTime + TravelTime(route(j-1),route(j));

                    % 改进：也可以设置惩罚成本。需要调整后变的ttdistance
                    if CurrentTime > TimeWindow(route(j),2) %将晚时间窗是否超约束放到route(j)是否=1外判断，防止route(j)=1时TW=0始终超约束的错误判断，这一步也是为什么要将route(j)是否为1分开判断的原因
                        Dis = Inf;  %对非可行解进行惩罚
                        break
                    else
                        CurrentTime = max(CurrentTime,TimeWindow(route(j),1));%若到达时间早于早时间窗，等待至早时间窗
                        % 如果设置惩罚成本，这里也可以计算并加上等待成本
                    end
                end
            end
        end
    end
    ttlDistance(i)=Dis; %存储此VRP路径总距离
end

FitnV=1./ttlDistance; %适应度函数设为距离倒数  对向量进行点运算
