function [Chrom_sel,VehicleNum_sel] = TSPtoChrom(TSPRoute_sel,CityNum,Distance,Travelcon,Demand,Capacity,ChargeStations_index,TravelTime,TimeWindow,ServiceTime)

TSP_size=size(TSPRoute_sel,1);
    Chrom_sel=zeros(TSP_size,CityNum*3+1); %预分配内存，用于存储种群数据
    VehicleNum_sel = ones(TSP_size,1); % 初始化车辆使用数量
    for i=1:TSP_size
        VRProute=ones(1,CityNum*3+1); %初始化VRP路径
        DisTraveled = 0; %初始化汽车已经行驶距离
        CurrentTime = 0; % 初始化车辆行驶时间
        delivery=0; % 汽车已经送货量，即已经到达点的需求量之和
        k=1;% k可以理解为一个指针，当前表示VRProute中第一个节点

        for j=2:CityNum+1
            k=k+1;   %对VRP路径下一点进行赋值
                    % 第一步检查里程约束
         
             if TSPRoute_sel(i,j)>= min(ChargeStations_index)
                 DisTraveled = 0;
             end


        if DisTraveled + Distance(VRProute(k-1),TSPRoute_sel(i,j)) + Distance(TSPRoute_sel(i,j),1) > Travelcon || CurrentTime+TravelTime(VRProute(k-1),TSPRoute_sel(i,j))>TimeWindow(TSPRoute_sel(i,j),2)
            VRProute(k) = 1;
            DisTraveled = Distance(1,TSPRoute_sel(i,j));  % 初始化距离为配送中心到此点距离
            CurrentTime = max(TravelTime(1,TSPRoute_sel(i,j)),TimeWindow(TSPRoute_sel(i,j),1))+ServiceTime(TSPRoute_sel(i,j));
            VehicleNum_sel(i) = VehicleNum_sel(i)+1; % 使用车辆数量+1
            delivery = Demand(TSPRoute_sel(i,j)); % 新一辆车配送量初始化
            k=k+1;
            VRProute(k) = TSPRoute_sel(i,j);

        else % 如果满足里程约束，则检查容量约束
           if delivery+Demand(TSPRoute_sel(i,j)) > Capacity %这一点配送完成后车辆可配送量超容量约束
              VRProute(k) = TSPRoute_sel(i,j);  % 将当前循环中的客户节点放入路径中
             VRProute(k+1)=1; %将配送中心放入路径中
            % 以下就是本算法最精妙的地方：因为没有像ACO-SDVRP那样的剔除操作，所以本算法只是做了以下的车容量清空。
            delivery=Capacity-delivery - Demand(TSPRoute_sel(i,j)); %新一辆车可配送量初始化，数值为客户剩余需求量
            VehicleNum_sel(i) = VehicleNum_sel(i)+1; % 使用车辆数量+1
            k=k+2;% 因为在此if循环中做了两次赋值，所以需要指针k直接跳转2次
            DisTraveled = Distance(1,TSPRoute_sel(i,j));  % 初始化距离为配送中心到此点距离
            CurrentTime = max(TravelTime(1,TSPRoute_sel(i,j)),TimeWindow(TSPRoute_sel(i,j),1))+ServiceTime(TSPRoute_sel(i,j)); % 若车辆到达时间早于客户时间窗，则需等待到时间窗再开始进行服务
            VRProute(k)=TSPRoute_sel(i,j);  %TSP路线中此点添加到VRP路线
          else %
            delivery=delivery+Demand(TSPRoute_sel(i,j)); %累加可配送量
            VRProute(k)=TSPRoute_sel(i,j); %TSP路线中此点添加到VRP路线
            DisTraveled = DisTraveled + Distance(VRProute(k-1),TSPRoute_sel(i,j));  % 初始化距离为配送中心到此点距离
            CurrentTime = max(CurrentTime+TravelTime(VRProute(k-1),TSPRoute_sel(i,j)),TimeWindow(TSPRoute_sel(i,j),1))+ServiceTime(TSPRoute_sel(i,j));% 更新车辆已行驶时间,若车辆到达时间早于客户时间窗，则需等待到时间窗再开始进行服务

              end

        end
            % if delivery+Demand(TSPRoute_sel(i,j)) > Capacity %这一点配送完成后车辆可配送量超容量约束
            %     VRProute(k) = TSPRoute_sel(i,j);  % 将当前循环中的客户节点放入路径中
            %     VRProute(k+1)=1; %将配送中心放入路径中
            %     % 以下就是本算法最精妙的地方：因为没有像ACO-SDVRP那样的剔除操作，所以本算法只是做了以下的车容量清空。
            %      delivery=Capacity-delivery - Demand(TSPRoute_sel(i,j)); %新一辆车可配送量初始化，数值为客户剩余需求量
            %      k=k+2;% 因为在此if循环中做了两次赋值，所以需要指针k直接跳转2次
            %      VRProute(k)=TSPRoute_sel(i,j);  %TSP路线中此点添加到VRP路线
            % else
            %     delivery=delivery+Demand(TSPRoute_sel(i,j)); %累加可配送量
            %     VRProute(k)=TSPRoute_sel(i,j); %TSP路线中此点添加到VRP路线
            % end
        end
        Chrom_sel(i,1:length(VRProute))=VRProute;  %此路线加入种群    
     end