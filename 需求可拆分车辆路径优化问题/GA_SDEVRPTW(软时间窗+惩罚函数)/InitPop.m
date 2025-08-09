function [TSPRoute,Chrom,VehicleNum]=InitPop(NIND,CityNum,Demand,Capacity,Travelcon,Distance,BatteryCap,ChargeStations_index,TravelTime,TimeWindow,ServiceTime)
%% 初始化种群
%输入：
%NIND       种群大小
%CityNum	需求点个数
%Demand      各点需求量
%Capacity   车容量约束

%输出：
%Chrom      初始种群

Chrom=zeros(NIND,CityNum*3+1); %预分配内存，用于存储种群数据
TSPRoute= zeros(NIND,CityNum*2+1); %预分配内存，用于存储种群路径数据
VehicleNum = ones(NIND,1);% 预分配内存，用于存储每条路径使用的车辆数量
for i=1:NIND
    TSProute=[0,randperm(CityNum)]+1; %随机生成一条不包括尾位的TSP路线
    VRProute=ones(1,CityNum*3+1); %初始化VRP路径
    DisTraveled = 0; %初始化汽车已经行驶距离
    CurretBattery = BatteryCap; % 初始化车辆电量
    CurrentTime = 0; % 初始化车辆行驶时间
    delivery=0; % 汽车已经送货量，即已经到达点的需求量之和
    k=1;% k可以理解为一个指针，当前表示VRProute中第一个节点
    for j=2:CityNum+1
        k=k+1;   %对VRP路径下一点进行赋值

         % 检查客户点是否是充电站(如果是充电站，则车辆行驶距离清零)
             if TSProute(j)>= min(ChargeStations_index)
                 DisTraveled = 0;
             end
        
        % 第一步检查里程约束和时间窗约束（保证能到达客户点后又能返回配送中心，同时保证车辆在客户最晚时间窗之前到达客户点）
        if DisTraveled + Distance(VRProute(k-1),TSProute(j)) + Distance(TSProute(j),1) > Travelcon 

        % if DisTraveled + Distance(VRProute(k-1),TSProute(j)) + Distance(TSProute(j),1) > Travelcon || CurrentTime+TravelTime(VRProute(k-1),TSProute(j))>TimeWindow(TSProute(j),2)
            VRProute(k) = 1;
            DisTraveled = Distance(1,TSProute(j));  % 初始化距离为配送中心到此点距离
            CurrentTime = max(TravelTime(1,TSProute(j)),TimeWindow(TSProute(j),1))+ServiceTime(TSProute(j)); % 若车辆到达时间早于客户时间窗，则需等待到时间窗再开始进行服务
            VehicleNum(i) = VehicleNum(i)+1; % 使用车辆数量+1
            delivery = Demand(TSProute(j)); % 新一辆车配送量初始化
            k=k+1;
            VRProute(k) = TSProute(j);

        else % 如果满足里程约束，则检查容量约束
           if delivery+Demand(TSProute(j)) > Capacity %这一点配送完成后车辆可配送量超容量约束
              VRProute(k) = TSProute(j);  % 将当前循环中的客户节点放入路径中
             VRProute(k+1)=1; %将配送中心放入路径中
            % 以下就是本算法最精妙的地方：因为没有像ACO-SDVRP那样的剔除操作，所以本算法只是做了以下的车容量清空。
            delivery=Capacity-delivery - Demand(TSProute(j)); %新一辆车可配送量初始化，数值为客户剩余需求量
            VehicleNum(i) = VehicleNum(i)+1; % 使用车辆数量+1
            k=k+2;% 因为在此if循环中做了两次赋值，所以需要指针k直接跳转2次
            DisTraveled = Distance(1,TSProute(j));  % 初始化距离为配送中心到此点距离
            CurrentTime = max(TravelTime(1,TSProute(j)),TimeWindow(TSProute(j),1))+ServiceTime(TSProute(j)); % 若车辆到达时间早于客户时间窗，则需等待到时间窗再开始进行服务
            VRProute(k)=TSProute(j);  %TSP路线中此点添加到VRP路线
          else %
            delivery=delivery+Demand(TSProute(j)); %累加可配送量
            VRProute(k)=TSProute(j); %TSP路线中此点添加到VRP路线
            DisTraveled = DisTraveled + Distance(VRProute(k-1),TSProute(j));  % 更新距离
            CurrentTime = max(CurrentTime+TravelTime(VRProute(k-1),TSProute(j)),TimeWindow(TSProute(j),1))+ServiceTime(TSProute(j));% 更新车辆已行驶时间,若车辆到达时间早于客户时间窗，则需等待到时间窗再开始进行服务
           end
        end




    end
    Chrom(i,1:length(VRProute))=VRProute;  %此路线加入种群
    TSPRoute(i,1:length(TSProute))=TSProute;
end