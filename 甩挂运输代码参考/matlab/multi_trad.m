
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                    %
%           蚁群算法求解多尺寸集装箱接驳运输问题            %
%                                                    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% - 素质三连
clc
clear all
close all


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                    %
%                   参   数   设   置                 %
%                                                    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

VeiNum = 4;     %   车辆数设置
MMAS = 1;       %   判断信息素更新策略，等于1时表示精英策略
Opt_Vei_Num = 1; %   最优车辆数控制，等于1时表示下一次迭代车辆数必定小于上一台
Stop_iter = 1;  % 提前终止策略，算法如果在Stop_iter_Num没有找到新的最优解，那么停止迭代
Stop_iter_Num = 50;
Remainder_vol = 2*ones(VeiNum,1);


No_better_Num = 0;                        %      - 记录算法已经 No_better_Num 次没找到新的最优解

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                    %
%                  数   据   导   入                   %
%                                                    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% - 尝试写成函数：
%   - Input：数据规模，进出口任务数量等等
%   - Output:Cus,Task等等




% - 客户坐标数据
%   - 散点图时需要调用，所以这个可以放入其他.m文件中
%   - 本次问题设定terminal作用：车辆出发起点、空重箱堆场
Cus = [0,0
    1,1
    2,2
    3,3
    4,4
    ];

% - 任务类型编号说明
%  (1) - DF_20ft
%  (2) - PE_20ft
%  (3) - DE_20ft
%  (4) - PF_20ft
%  (5) - DF_40ft
%  (6) - PE_40ft
%  (7) - DE_40ft
%  (8) - PF_40ft

% Task = 任务起点 & 任务终点 & 任务类型 & 前置任务 & 装卸时间 & 任务占用车容量
Task = [ 1,2,1,0,1,1
    2,1,2,1,0,1
    1,3,3,0,1,1
    3,1,4,3,0,1
    1,4,5,0,2,2
    4,1,6,5,0,2
    1,5,7,0,2,2
    5,1,8,7,0,2];

CusNum = length(Cus);       %   - 节点数量
TaskNum = size(Task,1);     %   - 任务数量


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                    %
%              参   数   设   置   (模型)              %
%                                                    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% - 时间相关数据 -

v = 1;                      %   - 单位距离行驶时间
t_teu = 0.5;                %   - 单个集装箱的提箱、交箱时间(假设40尺箱和两个20尺箱都是2*t_teu的时间)
t_drop = 0.2;               %   - 甩箱时间(提取40ft是2倍，但提取2个20ft也是t_drop)

% - 车辆相关数据 -

Time_Max = 30;              %   - 牵引车最长工作时间
%VeiNum = 3;                 %   - 最大车了调用数量

% - 成本相关数据 -
Cost_F = 10;                %   - 单车固定成本
Cost_T = 1;                 %   - 单位时间运输成本
Cost_W = 500;                 %   - 单位时间等待成本

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                    %
%               数   据   预   处    理                %
%                                                    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%   - 调取Distance.m函数计算节点间距离
[Distance] = Cal_Distance(Cus,CusNum);
%   - 调取Tasktime.m函数计算任务节点时间
[Tasktime] = Cal_Tasktime(TaskNum,Task,t_drop);
%   - 调取Linktime.m函数计算两种情况的衔接时间
[Linktime_1,Linktime_2,Linktime] = Cal_Linktime(TaskNum,Task,Distance,v,t_teu);

%%%%%%%%%%%%%%%%%%
%   运算开始计时   %
%%%%%%%%%%%%%%%%%%

t0 = clock;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                    %
%              参   数   设   置   (算法)              %
%                                                    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

AntNum = 20;                              %      - 种群中蚂蚁数量
alpha = 1 ;                               %      - 轨迹强度Tau(i,j)的权重参数
beta = 1;                                 %      - 能见度Eta(i,j)的权重参数
rho = 0.1;                                %      - 信息素蒸发系数
Q_ant = 50;                               %      - 信息素的更新量参数(根据目标函数修改，通常为百分之10到百分之20)

Tau_min = 0.5;                          %      - 信息素浓度下界
Tau_max = 3;                              %      - 信息素浓度上界

iter = 1;                                 %      - 初始化迭代次数
iter_max = 100;                           %      - 算法最大迭代次数



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                  %
%     蚁  群  算  法  存  储  器     %
%                                  %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%   - 信息素浓度记录矩阵
Tau = ones(TaskNum + 1,TaskNum + 1);        %      - Tau : 信息素浓度矩阵，初始化时浓度均为1

%   - 车辆记录相关矩阵
Route = zeros(VeiNum,TaskNum + 1);          %      - Route : 路径记录矩阵，用于记录各辆车的运行路线
Route_mode = zeros(VeiNum,TaskNum + 1);     %      - Route_mode : 用于记录任务选择时采用的路径模式  
Route_time = zeros(VeiNum,1);               %      - Route_time : 路径时间矩阵，用于记录任务完成时间
End_Task = zeros(VeiNum,1);                 %      - End_Task : 每辆车的最后一个任务

Origin_vol = 2*ones(VeiNum,1);              %      - Origin_vol : 车辆上一次离开terminal时车辆剩余容量
Remainder_vol = 2*ones(VeiNum,1);           %      - Remainder_vol : 当前车辆剩余车容
Ori_Remainder_vol = Remainder_vol;          %      - Ori_Remainder_vol : 设置初始车容量，对于初始为1的，任务不能安排给这辆车
Resource = zeros(VeiNum,2);                 %      - Resource : 记录车上空箱资源数量，第一列表示20ft箱个数，第二列表示40ft箱个数(其实也可以用一列表示，别问，问就是我懒的写调用函数。)
Container_Vei = zeros(VeiNum,1);             %      - 当前车上集装箱数量为0，如果为1，需要付出一个t_teu进行装卸，如果为2，则需要两个t_tue装卸（不过这个数值应该也可以通过Remainder_vol计算）

%   - 任务记录相关矩阵
Task_start_time = 1./zeros(TaskNum,1);      %      -  所有任务的开始时间，相当于数学模型里的y(i)

%   - 蚂蚁记录相关矩阵(因为要记录多只蚂蚁，所以采用cell变量)
Ant_route = cell(AntNum,1);                 %      - 记录各代中每只蚂蚁的路径(Route)
Ant_route_mode = cell(AntNum,1);            %      - 记录各代中每只蚂蚁的路径模式(Route_mode)
Ant_task_start_time = cell(AntNum,1);       %      - 记录各代每只蚂蚁的任务开始时间(Task_start_time)
Ant_objective = zeros(AntNum,1);            %      - 记录各代中每只蚂蚁的目标值
Ant_arc = cell(AntNum,TaskNum);             %      - 记录每只蚂蚁的弧

%   - 最优解记录相关矩阵
Best_route = zeros(VeiNum,TaskNum);         %      - Best_route : 最优解路径矩阵，记录各代的最优解的车辆路径
Best_route_mode = zeros(VeiNum,TaskNum);    %      - Best_route_mode : 最优解路径模式
Best_solution = zeros(iter_max,1);          %      - Best_solution : 最优解矩阵，记录各带最优解值
Ave_solution = zeros(iter_max,1);           %      - Ave_solution : 平均解矩阵，记录每次迭代中解的平均值
Best_Ant_arc = cell(1,TaskNum);             %      - Best_Ant_arc : 记录当前最优解的弧

%--------------------------------------------------------------------------------------------------------------------------------------------------------------------%
%-----------------------------------------------------      主    要   工   作   内   容      -------------------------------------------------------------------------%
%--------------------------------------------------------------------------------------------------------------------------------------------------------------------%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                    %
%         蚁    群    算   法   主   体   部   分       %
%                                                    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%




while iter <= iter_max
    fprintf(' 开始第%d次迭代!!! \n',iter)         %      - 输出迭代次数
    Ant_arc = cell(AntNum,TaskNum);             %      - 初始化蚂蚁选择弧
    ant = 1;                                    %      - 从第一只蚂蚁开始迭代
    
    while ant <= AntNum
        %----------------------------------    初   始   化   ----------------------------------
        % - 初始化解的可行性
        infeasible = 0 ;
        % - 初始化车辆记录相关矩阵
        Route = zeros(VeiNum,TaskNum + 1);
        Route_mode = zeros(VeiNum,TaskNum + 1);
        Route_time = zeros(VeiNum,1);
        End_Task = zeros(VeiNum,1);
        % - 初始化任务记录相关矩阵
        Task_start_time = 1./zeros(TaskNum,1);
        % - 初始化车辆状态
        Origin_vol = 2*ones(VeiNum,1);
        Remainder_vol = Ori_Remainder_vol;
        Resource = zeros(VeiNum,2);
        % - 初始化目标函数构成元素
        Use_vehicle = 0 ;
        Transport_time = 0 ;
        Waiting_time = 0 ;
        % - 初始化蚁群参数
        Visited_Task = Route(Route>0);
        Visited_Task = [Visited_Task;0];
        Unvisited_Task = setdiff(1:TaskNum,Visited_Task);
        
        % - 对每项任务进行一次决策
        for Tas = 1:TaskNum
%---------------------------------------------------------------    提   取   可   行   弧   ------------------------------------------------------------------------------------%            

            EL = length(End_Task);                                  %   - End_Task 的元素个数
            UL = length(Unvisited_Task);                            %   - Unvisited_Task 的元素个数
            
            % - 潜在运输弧
            Potential_arc = cell(EL,UL);  
            % - 新增内容：用于记录如果弧被选择时，采用的运输模式
            Potential_arc_linkmode = zeros(EL,UL);
            % - 新增内容，弧的所需额外时间，用于记录清空车上集装箱的时间（因为之前Linktime计算时，无法判断车上集装箱数量，所以无法确定）
            Additional_arc_time = zeros(EL,UL);
            for i = 1:EL                                            %   - 这里 i 代表车辆编号
                for j = 1:UL                                        %   - 这里 j 代表任务编号
                    
                    % - 判断任务应采用那个Linktime进行运算
                    %   - 如果j是DE类任务，需要考察一下当前车上任务Resource(20ft读取第一列，40ft读取第二列)，如果有，则linktime_1；如果没有考察离港车容量Origin_vol
                    %   - 对于DF：直接考察离港车容量Origin_vol，需要有足够的车容
                    %   - 对于PE、PF，需要判断当前车容Remainder_vol
                    
   
                    if End_Task(i) == 0  % - 如果这是车辆i首次调用
                        Potential_arc_linkmode(i,j) = 1;
                    else
                        if Task(Unvisited_Task(j),3) == 1   % - 如果任务j是DF_20ft
                            
                            % - 考察离港车容量
                            if Origin_vol(i) >= 1 
                                Potential_arc_linkmode(i,j) = 1;
                            else
                                Potential_arc_linkmode(i,j) = 2;
                                Additional_arc_time(i,j) = t_teu*(2-Remainder_vol(i));   % - 附加清空车上集装箱时间为。(2-Remainder_vol(i))表示车辆i上当前装载的集装箱数量
                            end
                            
                        elseif Task(Unvisited_Task(j),3) == 2               % - 如果任务是PE_20ft
                            
                            % - 考察当前车容量
                            if Remainder_vol(i) >=1
                                Potential_arc_linkmode(i,j) = 1;
                            else
                                Potential_arc_linkmode(i,j) = 2;
                                Additional_arc_time(i,j) = t_teu*(2-Remainder_vol(i));   % - 附加清空车上集装箱时间为。(2-Remainder_vol(i))表示车辆i上当前装载的集装箱数量
                            end
                            
                        elseif Task(Unvisited_Task(j),3) == 3              % - 如果任务是DE_20ft
                            
                             % - 先考察车上资源量
                            if Resource(i,1) >= 1       % - 20ft考察第一列
                                Potential_arc_linkmode(i,j) = 1;
                            else
                                % - 车上资源不够时，考察离港车容量
                                if Origin_vol(i) >= 1 
                                     Potential_arc_linkmode(i,j) = 1;
                                else
                                     Potential_arc_linkmode(i,j) = 2;
                                     Additional_arc_time(i,j) = t_teu*(2-Remainder_vol(i));   % - 附加清空车上集装箱时间为。(2-Remainder_vol(i))表示车辆i上当前装载的集装箱数量
                                end
                            end
                            
                        elseif Task(Unvisited_Task(j),3) == 4              % - 如果任务是PF_20ft
                            
                            % - 考察当前车容量
                            if Remainder_vol(i) >=1
                                Potential_arc_linkmode(i,j) = 1;
                            else
                                Potential_arc_linkmode(i,j) = 2;
                                Additional_arc_time(i,j) = t_teu*(2-Remainder_vol(i));   % - 附加清空车上集装箱时间为。(2-Remainder_vol(i))表示车辆i上当前装载的集装箱数量
                            end     
                            
                        elseif Task(Unvisited_Task(j),3) == 5              % - 如果任务是DF_40ft
                            
                            
                            % - 考察离港车容量
                            if Origin_vol(i) >= 2 
                                Potential_arc_linkmode(i,j) = 1;
                            else
                                Potential_arc_linkmode(i,j) = 2;
                                Additional_arc_time(i,j) = t_teu*(2-Remainder_vol(i));   % - 附加清空车上集装箱时间为。(2-Remainder_vol(i))表示车辆i上当前装载的集装箱数量
                            end                            
                            
                        elseif Task(Unvisited_Task(j),3) == 6              % - 如果任务是PE_40ft
                            
                            % - 考察当前车容量
                            if Remainder_vol(i) >=2
                                Potential_arc_linkmode(i,j) = 1;
                            else
                                Potential_arc_linkmode(i,j) = 2;
                                Additional_arc_time(i,j) = t_teu*(2-Remainder_vol(i));   % - 附加清空车上集装箱时间为。(2-Remainder_vol(i))表示车辆i上当前装载的集装箱数量
                            end             
                            
                            
                        elseif Task(Unvisited_Task(j),3) == 7              % - 如果任务是DE_40ft
                            
                             % - 先考察车上资源量
                            if Resource(i,2) >= 1   % - 40ft考察第二列
                                Potential_arc_linkmode(i,j) = 1;
                            else
                                % - 车上资源不够时，考察离港车容量
                                if Origin_vol(i) >= 2 
                                     Potential_arc_linkmode(i,j) = 1;
                                else
                                     Potential_arc_linkmode(i,j) = 2;
                                     Additional_arc_time(i,j) = t_teu*(2-Remainder_vol(i));   % - 附加清空车上集装箱时间为。(2-Remainder_vol(i))表示车辆i上当前装载的集装箱数量
                                end
                            end     
                            
                        else                                               % - 如果任务是PF_40ft
                            
                            % - 考察当前车容量
                            if Remainder_vol(i) >=2
                                Potential_arc_linkmode(i,j) = 1;
                            else
                                Potential_arc_linkmode(i,j) = 2;
                                Additional_arc_time(i,j) = t_teu*(2-Remainder_vol(i));   % - 附加清空车上集装箱时间为。(2-Remainder_vol(i))表示车辆i上当前装载的集装箱数量
                            end
                             
                        end
                          
                    end
                    

                    % - 潜在运输弧更新遵从如下准则：
                    %  - (1)前置任务已访问
                    if ismember(Task(Unvisited_Task(j),4),Visited_Task)
                        %  - (2) 加入任务后有足够时间返回挂车中心
                        %       - 最后一项直接采用了模式1因为车辆返回堆场时，两种模式的Linktime相同
                    
                        % - 只有车辆车容量能够满足任务所需空间时，才会被选择
                       if  Task(Unvisited_Task(j),6) <= Ori_Remainder_vol(i)
                        
                        
                        if Route_time(i) + Linktime(End_Task(i)+1,Unvisited_Task(j)+1,Potential_arc_linkmode(i,j)) + Additional_arc_time(i,j)  + Tasktime(Unvisited_Task(j)+1) + Linktime(Unvisited_Task(j)+1,1,1) <= Time_Max
                          
                           %   改写：如果某个非零的End_Task(i)是某一个Unvisited_Task(j)的前置任务，那么只更新前置任务，否则，不更新。
                      %出现问题：车辆1是基数，车辆2是偶数，车辆1的后置任务被车辆2访问了     
               if mod(End_Task(i),2) == 1         %   如果车辆最后一个任务是奇数，则需要立刻访问下一个任务
                         if End_Task(i) == Task(Unvisited_Task(j),4)
                             Potential_arc{i,j} = [End_Task(i),Unvisited_Task(j)];
                         end
                   
               else  
                   %如果Unvisited_Task(j)的前置任务不在End_Task集合中
                   if Task(Unvisited_Task(j),4) == 0
                        Potential_arc{i,j} = [End_Task(i),Unvisited_Task(j)] ;                  
                  % else
                 %      if ~ismember(Task(Unvisited_Task(j),4),End_Task)     
                   
                  %  Potential_arc{i,j} = [End_Task(i),Unvisited_Task(j)];
                   %    end
                   end
               end  
                            
                  %      Potential_arc{i,j} = [End_Task(i),Unvisited_Task(j)];   %如果需要，可以在这个弧后面增加一个这条弧选择的linkmode 
                        
                        end
                  
                        
                       end
                        
                        
                    end
                end
            end
  
  %-------------------------------------------------------------     计   算   弧   选   择   概   率     -----------------------------------------------------------------------------------%        
       
          %   - 计算每条弧的选择概率
        Probabilistic_arc = ones(EL,UL);  
  
        for i = 1:EL 
            for j = 1:UL

                if isempty(Potential_arc{i,j})                             % - 如果弧中元素为空集，则选择概率为0
                    
                    Probabilistic_arc(i,j) = 0;
                
                else 
                
                % - 计算车辆数变化量 
                    if Potential_arc{i,j}(1) == 0
                            Delta_F = 1;
                    else
                            Delta_F = 0;
                    end
                
                % - 计算里程(时间)变化量    
                            
                            Delta_T = Linktime(Potential_arc{i,j}(1)+1,Potential_arc{i,j}(2)+1,1) + Additional_arc_time(i,j) ;  % - 时间已经附加上了清空时间
                            
                % - 计算等待时间变化量(等待时间由前置任务产生)
                    if Task(Potential_arc{i,j}(2),4) == 0
                            Delta_W = 0;
                    else 
                        % - 等待时间等于前置任务完成时间 - 该任务到达时间Route_time(i) +Linktime()
                        %   - 前置任务完成时间 = 前置任务开始时间 + 前置任务执行时间(甩挂) + 前置任务装卸时间
                        Delta_W = (Task_start_time(Task(Potential_arc{i,j}(2),4)) + Tasktime(Task(Potential_arc{i,j}(2),4)+1) + Task(Task(Potential_arc{i,j}(2),4)+1,5)) - (Route_time(i) + Linktime(Potential_arc{i,j}(1)+1,Potential_arc{i,j}(2)+1) + Additional_arc_time(i,j) ) ;
                        
                        if Delta_W < 0 
                            Delta_W =0;
                        end
                        
                    end

                %       - 计算能见度
                        Eta = 1/(Cost_F * Delta_F + Cost_T * Delta_T + Cost_W * Delta_W);
                        Eta = min(Eta,2);%如果最优解一直无法出现，适当改大改小
                
                %   - 计算各节点的转移系数
                                                                           %      - 由轨迹强度Tau和能见度Eta两部分组成
                       Probabilistic_arc(i,j) = (Tau(Potential_arc{i,j}(1)+1,Potential_arc{i,j}(2)+1)^alpha)*(Eta^beta);  
                    
                end
            end
        end
  
        %   - 如果所有节点都无法插入路径中，则判定为不可行解
        %       - 不可行解的产生是由于最长行驶时间T_max导致的，即所有车辆都无法完成任务
        %       - 若要搜索过程中不出现不可行解，则应 : (1)延长T_max取值; (2) 增加可调用车辆数 VeiNum
        %           - 延长T_max可能会导致问题的最优解变化，但增加VeiNum不会改变
        
        if ~any(Probabilistic_arc)          
             %disp(['出现不可行解，跳出循环']);
             infeasible =1;         %   - 当前循环标记为不可行解(跳出的是Tas的循环)                                                        
           break 
        end
        
%-----------------------------------------------------------------进   行   路   径   选   择-----------------------------------------------------------------------------------------%
       %   - 根据转移概率进行路径选择 
       %        两种选择策略 : (1) 选择最大转移概率的弧; (2) 随机选择一条可行弧
       
            %   - 产生两个随机数
              r0 = rand;
              q0 = rand;
              
            %   - 确定选择策略
              if r0 < q0                                                                        %   - 如果r0<q0， 采用最大选择策略
                   [x y] = find(Probabilistic_arc==max(max(Probabilistic_arc)));                %   - 最大转移概率所在位置   
                         s0 = randperm(size(x,1),1);                                                       %   - 随机选择一个位置
              else                                                                              %   - 如果r0>=q0，采用随机选择策略  
                   [x y] = find(Probabilistic_arc~=0);                                          %   - 所有非0概率所在位置      
                   
                   %    改成轮盘赌选择
                   Sum_Pro_arc = sum(sum(Probabilistic_arc)) ;            %     - 计算所有转移系数之和
                   Probabilistic_arc = Probabilistic_arc/Sum_Pro_arc;
                   Cum_Pro = zeros(size(x,1),1);
                for i = 1:size(x,1)
                    Cum_Pro (i:size(x,1)) = Cum_Pro (i) + Probabilistic_arc(x(i),y(i));     %   转移概率累加和  
                end
                   sr = rand;
                   s0 = find(Cum_Pro>=sr,1);
              end
  
            %   - 选择插入节点        
        
              Select_arc = Potential_arc{x(s0),y(s0)};                                          %   - 选择的是(x(s0),y(s0))位置的弧
              Ant_arc{ant,Tas} = Select_arc;
              Transport_time = Transport_time + Linktime(Select_arc(1)+1,Select_arc(2)+1) + Additional_arc_time(x(s0),y(s0)) ;      %   - 记录车辆行驶时间,(增加了清空时间)
              Insert = find(Route(x(s0),:)~=0);                                                 %   - 找到x(s0)车辆路径中非0节点位置
        
            %   - 判断插入位置
              if isempty(Insert)                                                                %   - 如果Insert为空集，则插入到第一个任务位置 
                    Route(x(s0),1) = Select_arc(2);
                    Route_mode(x(s0),1) = Potential_arc_linkmode(x(s0),y(s0));
                    Use_vehicle = Use_vehicle +1;
              else                                                                              %   - 如果Insert非空集，则插入Insert后第一个位置  
                    Route(x(s0),Insert(end)+1) = Select_arc(2);
                    Route_mode(x(s0),Insert(end)+1) = Potential_arc_linkmode(x(s0),y(s0));
              end         
 
            %  - 更新车辆状态集合 
            %       -
            %       首先：被插入的弧是第x(s0)辆车，被插入的任务Potential_arc{x(s0),y(s0)}(2),选择这个弧所使用的模式是：Potential_arc_linkmode(x(s0),y(s0))
            
            % - 如果采用的是direct mode
            if Potential_arc_linkmode(x(s0),y(s0)) == 1
                if Task(Potential_arc{x(s0),y(s0)}(2),3) == 1           % - 如果被插入的任务是DF_20ft
                    
                    Origin_vol(x(s0)) = Origin_vol(x(s0)) - 1; 
                    
                elseif Task(Potential_arc{x(s0),y(s0)}(2),3) == 2       % - 如果被插入的任务是PE_20ft
                    
                    Remainder_vol(x(s0)) = Remainder_vol(x(s0)) -1;
                    Resource(x(s0),1) = Resource(x(s0),1)+1;
                    
                elseif Task(Potential_arc{x(s0),y(s0)}(2),3) == 3       % - 如果被插入的任务是DE_20ft
                    
                    if Resource(x(s0),1) >= 1              
                        % - 如果当前车上有对应空箱，那么调用一个
                        Resource(x(s0),1) = Resource(x(s0),1) - 1;
                    else 
                        % - 如果车上没有对应空箱，那么出港车容减1
                        Origin_vol(x(s0)) = Origin_vol(x(s0)) - 1; 
                    end
  
                elseif Task(Potential_arc{x(s0),y(s0)}(2),3) == 4       % - 如果被插入的任务是PF_20ft
                    
                    Remainder_vol(x(s0)) = Remainder_vol(x(s0)) -1;   
                    
                elseif Task(Potential_arc{x(s0),y(s0)}(2),3) == 5       % - 如果被插入的任务是DF_40ft
                    
                    Origin_vol(x(s0)) = Origin_vol(x(s0)) - 2; 
                    
                elseif Task(Potential_arc{x(s0),y(s0)}(2),3) == 6       % - 如果被插入的任务是PE_40ft
                    
                    Remainder_vol(x(s0)) = Remainder_vol(x(s0)) -2;
                    Resource(x(s0),1) = Resource(x(s0),2)+1;
                    
                elseif Task(Potential_arc{x(s0),y(s0)}(2),3) == 7       % - 如果被插入的任务是DE_40ft
                    
                    if Resource(x(s0),2) >= 1              
                        % - 如果当前车上有对应空箱，那么调用一个
                        Resource(x(s0),2) = Resource(x(s0),2) - 1;
                    else 
                        % - 如果车上没有对应空箱，那么出港车容减1
                        Origin_vol(x(s0)) = Origin_vol(x(s0)) - 2; 
                    end

                else                                                    % - 如果被插入的任务是PF_40ft
                
                    Remainder_vol(x(s0)) = Remainder_vol(x(s0)) -2;   
                                        
                end
                
            % - 如果采用的是detour mode    
            else
                
               if Task(Potential_arc{x(s0),y(s0)}(2),3) == 1            % - 如果被插入的任务是DF_20ft
                   
                   Origin_vol(x(s0)) = 1;
                   Remainder_vol(x(s0)) = 2;
                   Resource(x(s0),:) =[0,0];
                   
               elseif Task(Potential_arc{x(s0),y(s0)}(2),3) == 2        % - 如果被插入的任务是PE_20ft
                   
                   Origin_vol(x(s0)) = 2;
                   Remainder_vol(x(s0)) = 1;
                   Resource(x(s0),:) =[1,0];
                   
               elseif Task(Potential_arc{x(s0),y(s0)}(2),3) == 3        % - 如果被插入的任务是DE_20ft
                   
                   Origin_vol(x(s0)) = 1;
                   Remainder_vol(x(s0)) = 2;
                   Resource(x(s0),:) =[0,0];
                   
               elseif Task(Potential_arc{x(s0),y(s0)}(2),3) == 4        % - 如果被插入的任务是PF_20ft
                   
                   Origin_vol(x(s0)) = 2;
                   Remainder_vol(x(s0)) = 1;
                   Resource(x(s0),:) =[0,0];                   
                   
               elseif Task(Potential_arc{x(s0),y(s0)}(2),3) == 5        % - 如果被插入的任务是DF_40ft
                   
                   Origin_vol(x(s0)) = 0;
                   Remainder_vol(x(s0)) = 2;
                   Resource(x(s0),:) =[0,0];                   
                   
               elseif Task(Potential_arc{x(s0),y(s0)}(2),3) == 6        % - 如果被插入的任务是PE_40ft
                   
                   Origin_vol(x(s0)) = 2;
                   Remainder_vol(x(s0)) = 0;
                   Resource(x(s0),:) =[0,1];                       
                   
               elseif Task(Potential_arc{x(s0),y(s0)}(2),3) == 7        % - 如果被插入的任务是DE_40ft
                   
                   Origin_vol(x(s0)) = 0;
                   Remainder_vol(x(s0)) = 2;
                   Resource(x(s0),:) =[0,0];                 
                   
               else                                                     % - 如果被插入的任务是PF_40ft
                   
                   Origin_vol(x(s0)) = 2;
                   Remainder_vol(x(s0)) = 0;
                   Resource(x(s0),:) =[0,0];                  
                   
               end
                
                
                
                
            end
            
            %   - 相关集合更新          
              if Task(Select_arc(2),4) == 0                                                     %       - 新加入任务如果无前置任务
                            Task_start_time(Select_arc(2)) = Route_time(x(s0)) + Linktime(Select_arc(1)+1,Select_arc(2)+1) + Additional_arc_time(x(s0),y(s0)) ; 
              else                                                                              %       - 新加入任务如果有前置任务
                            Task_start_time(Select_arc(2)) = max(Task_start_time(Task(Select_arc(2),4)) + Tasktime(Task(Select_arc(2),4)) + Task(Task(Select_arc(2),4),5) , Route_time(x(s0)) + Linktime(Select_arc(1)+1,Select_arc(2)+1) + Additional_arc_time(x(s0),y(s0)) );
                            
                            wait = (Task_start_time(Task(Select_arc(2),4)) + Tasktime(Task(Select_arc(2),4)) + Task(Task(Select_arc(2),4),5)) - (Route_time(x(s0)) + Linktime(Select_arc(1)+1,Select_arc(2)+1) + Additional_arc_time(x(s0),y(s0)));
                            if wait < 0
                               wait = 0 ;
                            end
                            
                            Waiting_time = Waiting_time + wait;
                            
                            
              end        

%--------------------------------------------------------------更    新   相   关   集   合--------------------------------------------------------------------------------%      
            Route_time(x(s0)) = Task_start_time(Select_arc(2)) + Tasktime(Select_arc(2));                       %   - 车辆时间等于 : 最终任务的开始时间 + 任务执行时间
            End_Task(x(s0)) = Select_arc(2);                                                                    %   - 更新每辆车最后一个任务
            Visited_Task = Route(Route>0);                                                                      %   - 已访问任务节点集合，初始时为空集。
            Visited_Task = [Visited_Task;0];                                                                    %   - 把0加入，为了处理前置任务
            Unvisited_Task = setdiff(1:TaskNum,Visited_Task);                                                   %   - 未访问任务节点集合，初始时为所有任务。                
              
                    
        end % 对应任务决策次数Tas
        
%-------------------------------------------------------------记   录   蚂   蚁   搜   索   结   果--------------------------------------------------------------------------------%
        %       - (1) 记录蚂蚁搜索出的路径、任务开始时间、目标函数
        %         - 记录路径
                 Ant_route{ant} = Route;
                 Ant_route_mode{ant} = Route_mode; 
        %         - 记录任务开始时间
                 Ant_task_start_time{ant} = Task_start_time;            
        %         - 记录目标函数 
                 Ant_objective(ant) = Use_vehicle * Cost_F + Transport_time * Cost_T + Waiting_time * Cost_W ;                                
                    
        %         - 更新蚂蚁编号         
                 ant = ant +1;
               
        %         - 如果出现不可行解，则这只蚂蚁进行重新搜索          
              if infeasible == 1
                  %disp(['当前蚂蚁进行重新搜索！！！'])
                  ant = ant -1;
              end        
        
    end % - 对应蚂蚁ant编号
    
%-------------------------------------------------------------信   息   素   更   新----------------------------------------------------------------------------%
    %   - 蚁群信息素更新
       [min_obj min_ant] = min(Ant_objective);         %   - 找到本次迭代的最优解和蚂蚁

    if MMAS == 1                                       %   - 采用最大最小信息素更新策略
        
       % disp(['蚂蚁',num2str(min_ant),'找到了本代最优解为：',num2str(min_obj)])
        %disp(['最优解路线为:'])
        %Ant_route{min_ant}
        
        Delta_Tau = zeros(TaskNum + 1,TaskNum + 1);    %   - 初始化信息素增加量
        
        for i = 1:TaskNum
        
            Delta_Tau(Ant_arc{min_ant,i}(1)+1,Ant_arc{min_ant,i}(2)+1) = Q_ant/min_obj; 
            
        end
        
        Tau = (1-rho) * Tau + Delta_Tau;               %   - 信息素挥发后更新
        
        for i = 1:TaskNum + 1                          %   - 按照最大最小更新策略
            for j = 1:TaskNum +1
                if Tau(i,j) <= Tau_min
                    Tau(i,j) = Tau_min;
                elseif Tau(i,j) >= Tau_max
                    Tau(i,j) = Tau_max;
                end
            end
        end
        
    else                                               %   - 采用所有蚂蚁都更新策略
        Delta_Tau = zeros(TaskNum + 1,TaskNum + 1); 
        for i = 1:AntNum
            for j = 1:TaskNum
                                                       %   - 计算信息素增加量
            Delta_Tau(Ant_arc{i,j}(1)+1,Ant_arc{i,j}(2)+1) = Q_ant/Ant_objective(i); 

            end

        end
        
                Tau = (1-rho) * Tau + Delta_Tau;       %   - 信息素挥发后更新
                
            
    end
%------------------------------------------------------------记   录   各   代   最   优   解--------------------------------------------------------------------------------%    
    if iter == 1                                       %   - 如果迭代次数为1，直接记录最优解和路径
        Best_solution(iter) = min_obj;
        Best_route = Ant_route{min_ant};
        Best_route_mode = Ant_route_mode{min_ant};
        for i = 1:TaskNum
        Best_Ant_arc{i} = Ant_arc{min_ant,i};
        end
         Best_iter = iter;
        disp(['初代最优解为：',num2str(Best_solution(iter))])

    else                                               %   - 如果迭代次数>1，    
        if min_obj < Best_solution(iter-1)             %   - 如果本代最优解小雨当前最优解
            Best_solution(iter) = min_obj;
            Best_route = Ant_route{min_ant};
            Best_route_mode = Ant_route_mode{min_ant};
            for i = 1:TaskNum
                Best_Ant_arc{i} = Ant_arc{min_ant,i};
            end
            disp(['搜索到新的最优解：',num2str(Best_solution(iter))])
            Best_iter = iter;
            No_better_Num = 0;
        else
            Best_solution(iter) = Best_solution(iter-1);
            No_better_Num = No_better_Num + 1;
            disp(['算法已经连续：',num2str(No_better_Num),'代找到新的最优解！'])
            
        end
            
    
    end
    
        Ave_solution(iter) = mean(Ant_objective);      %   - 记录当前代数平均值
    
        % - 判断是否采用最优车辆数策略
        if Opt_Vei_Num == 1

            VeiNum  = sum(any(Best_route,2));
            
        end
        
        if Stop_iter == 1
        
            if No_better_Num >= Stop_iter_Num
                plot_iter = iter;       %   - 用于记录画图长度
                 disp(['满足终止准则，停止迭代！'])
                break
            end
        else 
            plot_iter = iter_max;
        end
        
        iter = iter + 1;                               %   - 迭代次数加 1
end                                                    %   - 这个 end 对应迭代次数
Time_Cost = etime(clock,t0); 
%--------------------------------------------------------------------------------------------------------------------------------------------------------------------%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                    %
%           结    果   输   出   与   绘   图           %
%                                                    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

disp(['搜索结束:' ]);
disp(['最优解为:' num2str(Best_solution(iter-1))]);
disp(['最优解路径:' ]);Best_route
disp(['最优解路径模式:' ]);Best_route_mode
disp(['本次运算用时:' num2str(Time_Cost) '秒']);
disp(['算法在第' num2str(Best_iter) '代时收敛']);

if Stop_iter == 1

   plot(1:plot_iter,Best_solution(1:plot_iter),'b','linewidth',1.2)
   xlabel('迭代次数')
   ylabel('目标函数')
   hold on 
   plot(1:plot_iter,Ave_solution(1:plot_iter),'r','linewidth',1.2) 
   legend('最优解','平均值')    
    
else
  
   plot(1:iter_max,Best_solution,'b','linewidth',1.2)
   xlabel('迭代次数')
   ylabel('目标函数')
   hold on 
   plot(1:iter_max,Ave_solution,'r','linewidth',1.2) 
   legend('最优解','平均值') 
    
end




%figure(1)



%figure(2)
%scatter(Cus(1,1),Cus(1,2),'r','filled')
%hold on 
%scatter(Cus(4:CusNum,1),Cus(4:CusNum,2),'b','filled')