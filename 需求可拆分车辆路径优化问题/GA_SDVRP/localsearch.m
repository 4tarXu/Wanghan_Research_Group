function [Chrom] = localsearch(Chrom,Distance,Demand,Capacity,Travelcon,VehicleNum,VehicleCost)
% 对需求拆分路径Chrom进行局部搜索的邻域操作，目标：1)需求拆分点可以出现在路径中间；2)去交叉化
%   此处显示详细说明


% -- 功能1:需求点可以出现在路径中间
% - 需求：提取拆分点(路径中)、拆分点换位、评价新路径fitness、决策是否替换路径
% - 

% 提取Chrom的维度，用于for函数索引
[NIND_size Route_size] = size(Chrom); 

% 对每一个染色体执行操作
for i = 1:NIND_size
    
    % 设置临时染色体Chrom_new,如果邻域搜索更优则替换Chrom
    Chrom_new = Chrom(i,:);
% 查找所有1元素的位置，用于确定子路径
Subroute_index= find(Chrom(i,:)==1);


%% 对第一个子路径单独操作(因为第一条子路径起始点-1后索引不可行)


    %提取出子路径的起点和终点(数字1的位置序号)
    Subroute_start = Subroute_index(1);
    Subroute_end = Subroute_index(2);
    Subpath = Chrom(i,Subroute_start+1:Subroute_end-1);


    % 判断子路径的最后一个客户是不是需求拆分点
    if Chrom(i,Subroute_end-1)==Chrom(i,Subroute_end+1) 
    % 如果if条件成立，说明节点是需求拆分点，则需要进行邻域搜索
        
        % --- 以下是随机路径方法，原理是对存在需求拆分点的子路径进行随机换位，提高解的多样性。速度快，但不保证一定最优 
            Random_Subpath = Subpath(randperm(length(Subpath)));
            Chrom_new(Subroute_start+1:Subroute_end-1) = Random_Subpath;
             % 计算邻域搜索后路径长度
             [ttlDistance1,~]=Fitness(Distance,Demand,Chrom_new,Capacity,Travelcon,VehicleNum,VehicleCost); %邻域搜索后路径长度
             [ttlDistance2,~]=Fitness(Distance,Demand,Chrom(i,:),Capacity,Travelcon,VehicleNum,VehicleCost);
      
             % 如果找到更优路径，则进行路径替换
             if ttlDistance1 < ttlDistance2
                 Chrom(i,:)=Chrom_new;
                 break
             else
                 Chrom_new=Chrom(i,:);
             end 
    end

% (第二条子路径开始)对每一个子路径执行操作
for j =2:length(Subroute_index)
    % 设立终止规则，提前跳出for循环，因为在设置Chrom时候是节点数量的三倍，路径中一定存在非常多的1用作占位符
    if Subroute_index(j)== Subroute_index(j+1)-1 % 如果存在两个连续的1，则子路径为空，种植对于j的for循环，直接进入下一个i染色体搜索

        break;
    end

    %提取出子路径的起点和终点(数字1的位置序号)
    Subroute_start = Subroute_index(j);
    Subroute_end = Subroute_index(j+1);
    Subpath = Chrom(i,Subroute_start+1:Subroute_end-1);


    % 判断子路径的最后一个客户是不是需求拆分点
    if Chrom(i,Subroute_end-1)==Chrom(i,Subroute_end+1) 
    % 如果if条件成立，说明节点是需求拆分点，则需要进行邻域搜索
        
        % --- 以下是随机路径方法，原理是对存在需求拆分点的子路径进行随机换位，提高解的多样性。速度快，但不保证一定最优 
            Random_Subpath = Subpath(randperm(length(Subpath)));
            Chrom_new(Subroute_start+1:Subroute_end-1) = Random_Subpath;
             % 计算邻域搜索后路径长度
             [ttlDistance1,~]=Fitness(Distance,Demand,Chrom_new,Capacity,Travelcon,VehicleNum,VehicleCost); %邻域搜索后路径长度
             [ttlDistance2,~]=Fitness(Distance,Demand,Chrom(i,:),Capacity,Travelcon,VehicleNum,VehicleCost);
      
             % 如果找到更优路径，则进行路径替换
             if ttlDistance1 < ttlDistance2
                 Chrom(i,:)=Chrom_new;
                 break
             else
                 Chrom_new=Chrom(i,:);
             end 

        % --- 以下是换位操作方法，原理是对每一个需求拆分点和前边的节点换位，并对比适应度(精度高但速度慢)    
     % SplitNode_index = Subroute_end-1; %确定需求拆分点编号
     % SplitNode = Chrom(i,SplitNode_index);
     % SwapNum = Subroute_end - Subroute_start - 2; %换位交换检验次数
     % 
     %    % 执行换位操作，换位次数等于 Subroute_end - Subroute_start - 2
     %    for k = 1:SwapNum
     %        %重构Chrom_new路径
     %        Chrom_new(i,SplitNode_index) = Chrom(i,SplitNode_index-k);
     %        Chrom_new(i,SplitNode_index-k) = SplitNode;
     % 
     %        % 计算邻域搜索后路径长度
     %        [ttlDistance1,~]=Fitness(Distance,Demand,Chrom_new,Capacity,Travelcon); %邻域搜索后路径长度
     %        [ttlDistance2,~]=Fitness(Distance,Demand,Chrom(i,:),Capacity,Travelcon);
     % 
     %        % 如果找到更优路径，则进行路径替换
     %        if ttlDistance1 < ttlDistance2
     %            Chrom(i,:)=Chrom_new;
     %            break
     %        else
     %            Chrom_new=Chrom(i,:);
     %        end 
     % 
     %    end

    end

     % 判断子路径的第一个一个客户是不是需求拆分点
     if Chrom(i,Subroute_start+1)==Chrom(i,Subroute_start-1) && j>1
         % 如果if条件成立，说明节点是需求拆分点，则需要进行邻域搜索
        
        % --- 以下是随机路径方法，原理是对存在需求拆分点的子路径进行随机换位，提高解的多样性。速度快，但不保证一定最优 
            Random_Subpath = Subpath(randperm(length(Subpath)));
            Chrom_new(Subroute_start+1:Subroute_end-1) = Random_Subpath;
             % 计算邻域搜索后路径长度
             [ttlDistance1,~]=Fitness(Distance,Demand,Chrom_new,Capacity,Travelcon,VehicleNum,VehicleCost); %邻域搜索后路径长度
             [ttlDistance2,~]=Fitness(Distance,Demand,Chrom(i,:),Capacity,Travelcon,VehicleNum,VehicleCost);
      
             % 如果找到更优路径，则进行路径替换
             if ttlDistance1 < ttlDistance2
                 Chrom(i,:)=Chrom_new;
                 break
             else
                 Chrom_new=Chrom(i,:);
             end 
     
     
     end


end




end


