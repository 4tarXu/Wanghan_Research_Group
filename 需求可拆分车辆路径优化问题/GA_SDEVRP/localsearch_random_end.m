function [Chrom,Chrom_new] = localsearch_random_end(Distance,Demand,Chrom_new,Capacity,Travelcon,VehicleNum,VehicleCost,BatteryCap,ChargeStations_index,Chrom,Subpath,Subroute_start,Subroute_end)

    % 判断子路径的最后一个客户是不是需求拆分点
    if Chrom(i,Subroute_end-1)==Chrom(i,Subroute_end+1) 
    % 如果if条件成立，说明节点是需求拆分点，则需要进行邻域搜索

        % --- 以下是随机路径方法，原理是对存在需求拆分点的子路径进行随机换位，提高解的多样性。速度快，但不保证一定最优 
            Random_Subpath = Subpath(randperm(length(Subpath)));
            Chrom_new(Subroute_start+1:Subroute_end-1) = Random_Subpath;
             % 计算邻域搜索后路径长度
             [ttlDistance1,~]=Fitness(Distance,Demand,Chrom_new,Capacity,Travelcon,VehicleNum,VehicleCost,BatteryCap,ChargeStations_index); %邻域搜索后路径长度
             [ttlDistance2,~]=Fitness(Distance,Demand,Chrom(i,:),Capacity,Travelcon,VehicleNum,VehicleCost,BatteryCap,ChargeStations_index);
      
             % 如果找到更优路径，则进行路径替换
             if ttlDistance1 < ttlDistance2
                 Chrom(i,:)=Chrom_new;
                 return
             else
                 Chrom_new=Chrom(i,:);
             end 
    end