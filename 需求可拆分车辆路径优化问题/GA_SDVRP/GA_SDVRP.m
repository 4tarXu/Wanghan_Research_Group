function [mindis,bestind,Chrom,VehicleNum,TSPRoute,mindisbygen] = GA_SDVRP(Distance,Demand,Chrom,Capacity,Travelcon,VehicleNum,VehicleCost,GGAP,Pc,Pm,gen,TSPRoute,CityNum,mindis,bestind)

    %% 计算适应度(注意，本算法框架的遗传操作都是基于TSP架构进行)
    [TotalCost,FitnV]=Fitness(Distance,Demand,Chrom,Capacity,Travelcon,VehicleNum,VehicleCost);  %计算路径长度
    [mindisbygen,bestindex] = min(TotalCost);
    mindis(gen) = mindisbygen; % 最小适应值fit的集
	bestind = Chrom(bestindex,:); % 最优个体集
    bestind = bestind(bestind>0); %剔除最优个体中非零元素
    
    %% 选择（允许一个染色体被选择多次）(注意，本算法框架的遗传操作都是基于TSP架构进行)
    SelCh=Select(TSPRoute,FitnV,GGAP);

    %% 交叉操作(注意，本算法框架的遗传操作都是基于TSP架构进行)
    SelCh=Crossover(SelCh,Pc);
 
    %% 变异(注意，本算法框架的遗传操作都是基于TSP架构进行)
     % fprintf('变异操作后')
     SelCh=Mutate(SelCh,Pm,CityNum);
    %% 逆转操作(注意，本算法框架的遗传操作都是基于TSP架构进行)

    TSPRoute_sel = SelCh;   % 保存经过遗传操作的TSP路径，与Chrom对应

    %% (注意，本算法框架的遗传操作都是基于TSP架构进行)TSP路径转SDVRP路径,即把TSPRoute转化为符合要求的Chrom数组  

    [Chrom_sel,VehicleNum_sel] = TSPtoChrom(TSPRoute_sel,CityNum,Distance,Travelcon,Demand,Capacity);

    %% 亲代重插入子代
    [TSPRoute,Chrom,VehicleNum]=Reins(Chrom,Chrom_sel,TSPRoute,TSPRoute_sel,FitnV,VehicleNum_sel,VehicleNum);

    %% 邻域搜索操作
    Chrom = localsearch(Chrom,Distance,Demand,Capacity,Travelcon,VehicleNum,VehicleCost);