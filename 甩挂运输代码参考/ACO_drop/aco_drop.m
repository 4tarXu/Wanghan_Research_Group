%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                    %
%           蚁群算法求解港口集装箱甩挂运输问题              %
%                                                    %   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc
clear all
close all
%t0 = clock;     %   - 获取当前系统时间 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                    %
%                  数   据   导   入                   %
%                                                    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%   导入客户节点坐标信息。第一行为挂车中心坐标，第二行是重箱堆场坐标，第三行是空箱堆场坐标

%Cus = xlsread('case1.xlsx','cus','B2:C6','basic');  

Cus = [40,50;40,50;40,50;85,25;48,30;0,40;87,30;25,35;8,45;63,58;75,55;25,30;40,15;44,5;15,80;23,52;35,32;30,50;53,30;18,75;65,82;22,85;72,55];
%   导入任务信息。第一列表示任务起点，第二列表示任务重点，第三列表示任务类型，第四列表示前置任务
%       - 任务类型分为以下四种：
%           - DF ： 送重箱
%           - PE ： 取空箱
%           - DE ： 送空箱
%           - PF ： 取重箱
%       - 前置任务采用任务编号表示
%           - DF和DE分别为PE和PF的前置任务
%           - DF和DE没有前置任务，用0表示。

%Task = xlsread('case1.xlsx','task','B2:F9','basic');   
Task= [3,1,3,0,10;1,2,4,1,0;3,2,3,0,10;2,2,4,3,0;2,3,1,0,10;3,3,2,5,0;3,4,3,0,10;4,2,4,7,0;3,5,3,0,10;5,2,4,9,0;3,6,3,0,10;6,2,4,11,0;3,7,3,0,10;7,2,4,13,0;2,8,1,0,10;8,3,2,15,0;3,9,3,0,10;9,2,4,17,0;3,10,3,0,10;10,2,4,19,0;3,11,3,0,10;11,2,4,21,0;2,12,1,0,10;12,3,2,23,0;2,13,1,0,10;13,3,2,25,0;3,14,3,0,10;14,2,4,27,0;3,15,3,0,10;15,2,4,29,0;3,16,3,0,10;16,2,4,31,0;3,17,3,0,10;17,2,4,33,0;3,18,3,0,10;18,2,4,35,0;2,19,1,0,10;19,3,2,37,0;3,20,3,0,10;20,2,4,39,0];

CusNum = length(Cus);   %   - 节点数量
TaskNum = size(Task,1); %   - 任务数量

%   - 时间相关数据 - 
v = 1 ;                 %   - 单位距离行驶时间
t_teu =  0.5 ;          %   - 提箱、交箱时间
t_drop = 1 ;            %   - 甩箱时间(甩箱模式下，这个时间更长)（甩挂时间设为0.1）
t_pack = 2 ;            %   - 装、卸货时间

%   - 车辆相关数据 -  

Time_Max = 500;          %   - 牵引车最长工作时间
VeiNum = 3;             %   - 车辆数量              (车辆数量目前不能设置为1，设置后出现bug，并且我懒得调)

%   - 成本相关数据 - 
Cost_F = 100;           %   - 单车调用固定成本
Cost_T = 10;            %   - 单位时间运输成本
Cost_W = 10;            %   - 单位时间等待成本


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                    %
%               数   据   预   处    理                %
%                                                    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%-------------------------------------------------------------------------------------%
%   - Distance : 节点间距离矩阵 
%-------------------------------------------------------------------------------------%
Distance =  zeros(CusNum);    
for i = 1:CusNum
    for j = 1:CusNum
        Distance(i,j) =sqrt((Cus(i,1)-Cus(j,1))^2+(Cus(i,2)-Cus(j,2))^2);
    end
end

%-------------------------------------------------------------------------------------%
%   - Tasktime : 顶点任务时间矩阵
%-------------------------------------------------------------------------------------%
Tasktime = zeros(TaskNum,1);    %   - 顶点任务时间矩阵
for i = 1:TaskNum
    if Task(i,3) == 1           %   - 如果任务 i 是 DF
                                %       - 顶点任务执行时间为 : 提箱时间 + 运输时间 + 甩挂时间  
        Tasktime(i) = t_teu + Distance(Task(i,1),Task(i,2))*v + t_drop;
    elseif Task(i,3) == 2       %   - 如果任务 i 是 PE
                                %       - 顶点任务时间为装挂时间
        Tasktime(i) = t_drop;
    elseif Task(i,3) == 3       %   - 如果任务 i 是 DE
                                %       - 顶点任务时间为甩挂时间
        Tasktime(i) = t_drop;
    else                        %   - 如果任务 i 是 PF
                                %       - 顶点任务时间为 : 装挂时间 + 运输时间 + 交箱时间
        Tasktime(i) = t_drop + Distance(Task(i,1),Task(i,2))*v + t_teu;
    end
end
Tasktime = [0;Tasktime];        %   为了保证时间计算的完整性，起始点任务的时间设为 0 。

%-------------------------------------------------------------------------------------%
%   - Linktime : 衔接任务时间矩阵
%-------------------------------------------------------------------------------------%
Linktime = zeros(TaskNum)  ;                     %      - 衔接任务时间矩阵

for i = 1:TaskNum
    for j = 1:TaskNum    
        %-----------------------------------------------------------------------------------------------------------------------------------------------------%
        if Task(i,3) == 1                        %      - 任务 i 为 DF，结束时车辆状态为 : 单牵引车头
        %-----------------------------------------------------------------------------------------------------------------------------------------------------%    
           if Task(j,3) == 1                     %          - 任务 j 为 DF                                                       
                                                 %              - 衔接任务时间为 : 前往挂车中心时间 + 提取挂车时间 + 运输到重箱堆场时间                        
               Linktime(i,j) = Distance(Task(i,2),1)*v + t_drop + Distance(1,2)*v ;         
               
           elseif Task(j,3) == 2                 %          - 任务 j 为 PE
                                                 %              - 衔接任务时间为 : 当前节点行驶到目标节点时间    
               Linktime(i,j) = Distance(Task(i,2),Task(j,1));                               
               
           elseif Task(j,3) == 3                 %          - 任务 j 为 DE
                                                 %              - 衔接任务时间为 : 前往挂车中心时间 + 提取挂车时间 + 运输到空箱堆场时间 + 提取空箱时间 + 运输到客户节点时间               
               Linktime(i,j) = Distance(Task(i,2),1)*v + t_drop + Distance(1,3)+ t_teu +Distance(3,Task(j,2))*v;  
                                            
           else                                  %          - 任务 j 为 PF            
                                                 %              - 衔接任务时间为 : 当前节点行驶到目标节点时间   
               Linktime(i,j) = Distance(Task(i,2),Task(j,1))*v;                                           
               
           end                                                                                              

        %-----------------------------------------------------------------------------------------------------------------------------------------------------%                                                                                                    
        elseif Task(i,3) == 2                    %      - 任务 i 为 PE，结束时车辆状态为 : 牵引车头 + 挂车 + 空箱
        %-----------------------------------------------------------------------------------------------------------------------------------------------------%
          if Task(j,3) == 1                      %          - 任务 j 为 DF
                                                 %              - 衔接任务时间为 : 行驶到空箱堆场时间 + 交付空箱时间 + 行驶到重箱堆场时间    
              Linktime(i,j) = Distance(Task(i,1),3)*v  + t_teu + Distance(3,2)*v;     
                    
          elseif Task(j,3) == 2                  %          - 任务 j 为 PE
                                                 %              - 衔接任务时间为 : 行驶到空箱堆场时间 + 交付空箱时间 + 行驶到挂车中心时间 + 甩挂时间 + 行驶到客户节点时间             
              Linktime(i,j) = Distance(Task(i,1),3)*v + t_teu + Distance(3,1)*v + t_drop + Distance(1,Task(j,1))*v;      
              
          elseif Task(j,3) == 3                  %          - 任务 j 为 DE
                                                 %              - 衔接任务时间为 : 当前节点行驶到目标节点时间       
              Linktime(i,j) = Distance(Task(i,1),Task(j,2))*v;                                          
              
          else                                   %          - 任务 j 为 PF
                                                 %              - 衔接任务时间为 : 行驶到空箱堆场时间 + 交付空箱时间 + 行驶到挂车中心时间 + 甩挂时间 + 行驶到客户节点时间     
              Linktime(i,j) = Distance(Task(i,1),3)*v + t_teu + Distance(3,1)*v + t_drop + Distance(1,Task(j,1))*v;                           
              
          end                                                                                                
          
        %-----------------------------------------------------------------------------------------------------------------------------------------------------%                                                                                                        
        elseif Task(i,3) == 3                    %      - 任务 i 为 DE，结束时车辆状态为 : 单独牵引车头 
        %-----------------------------------------------------------------------------------------------------------------------------------------------------%
          if Task(j,3) == 1                      %          - 任务 j 为 DF                                                       
                                                 %              - 衔接任务时间为 : 行驶到挂车中心时间 + 提取挂车时间 + 行驶到空箱堆场时间        
              Linktime(i,j) = Distance(Task(i,2),1)*v + t_drop + Distance(1,2)*v;     
              
          elseif Task(j,3) == 2                  %          - 任务 j 为 PE
                                                 %              - 衔接任务时间为 : 当前节点行驶到目标节点时间               
              Linktime(i,j) = Distance(Task(i,2),Task(j,1))*v;     
              
          elseif Task(j,3) == 3                  %          ? 任务 j 为 DE
                                                 %              - 衔接任务时间为 : 行驶到挂车中心时间 + 提取挂车时间 + 行驶到空箱堆场时间 + 提取空箱时间 + 行驶到客户节点时间   
              Linktime(i,j) = Distance(Task(i,2),1)*v + t_drop + Distance(1,3)*v+ t_teu +Distance(3,Task(j,2))*v;                          
              
          else                                   %          - 任务 j 为 PF
                                                 %              - 衔接任务时间为 : 当前节点行驶到目标节点时间   
              Linktime(i,j) = Distance(Task(i,2),Task(j,1))*v;                                          
              
          end                                                                                             
          
        %-----------------------------------------------------------------------------------------------------------------------------------------------------%                                                                                                    
        else                                     %      - 任务 i 为 PF，结束时车辆状态为 : 牵引车头 + 挂车                                                                    
        %-----------------------------------------------------------------------------------------------------------------------------------------------------%    
            if Task(j,3) == 1                    %          - 任务 j 为 DF                                                     
                                                 %              - 衔接任务时间为 : 0 （在重箱堆场等待）    
                Linktime(i,j) = 0 ;            
                
            elseif Task(j,3) == 2                %          - 任务 j 为 PE
                                                 %              - 衔接任务时间为 : 行驶到挂车中心时间 + 甩挂时间 + 行驶到客户节点时间    
                Linktime(i,j) = Distance(2,1)*v + t_drop + Distance(1,Task(j,1))*v;                                       
                
            elseif Task(j,3) == 3                %          - 任务 j 为 DE
                                                 %              - 衔接任务时间为 : 行驶到空箱堆场时间 + 提取空箱时间 + 行驶到客户节点时间    
                Linktime(i,j) = Distance(2,3)*v + t_teu +Distance(3,Task(j,2))*v;                                 
                
            else                                 %          - 任务 j 为 PF
                                                 %              - 衔接任务时间为 : 行驶到挂车中心时间 + 甩挂时间 + 行驶到客户节点时间    
                Linktime(i,j) = Distance(2,1)*v + t_drop + Distance(1,Task(j,1))*v;                                                  
                
            end                                                                                         
        end
    end
end


 %-----------------------------------------------------------------------------------------------------------------------------------------------------%
 %   - 补全挂车中心到各节点的任务时间
linktime0 = zeros(TaskNum,1);                    %          - 从各个任务到终点的时间
linktime1 = zeros(1,TaskNum+1);                  %          - 从起点到各个任务的时间
 %-----------------------------------------------------------------------------------------------------------------------------------------------------%
for i = 1:TaskNum
    if Task(i,3) == 1                                                       %          - 任务类型为 DF
        linktime0(i) = Distance(Task(i,2),1)*v;                             %              - 直接返回终点                                                        
        linktime1(i+1) = Distance(1,2)*v;                                   %              - 从起点前往重箱堆场
        
    elseif Task(i,3) == 2                                                   %          - 任务类型为 PE
        linktime0(i) = Distance(Task(i,1),3)*v + t_teu + Distance(3,1)*v;   %              - 返回空箱堆场 + 交付空箱 + 返回终点                                   
        linktime1(i+1) = Distance(1,Task(i,1))*v;                           %              - 从起点前往客户节点
        
    elseif Task(i,3) == 3                                                   %          - 任务类型为 DE
        linktime0(i) = Distance(Task(i,2),1)*v;                             %              - 直接返回终点                             
        linktime1(i+1) = Distance(1,3)*v + t_teu +Distance(3,Task(i,2))*v;  %              - 前往空箱堆场 + 提取空箱 + 前往客户节点 
        
    else                                                                    %          - 任务类型为 PF
        linktime0(i) = Distance(2,1)*v;                                     %              - 直接返回终点                              
        linktime1(i+1) = Distance(1,Task(i,1))*v;                           %              - 从起点前往客户节点 
    end
end

%   - 将起止点和各任务之间距离加入
Linktime = [linktime0 Linktime];                                
Linktime = [linktime1;Linktime];

%   - 至此，衔接时间矩阵 Linktime 预处理工作结束
 %-----------------------------------------------------------------------------------------------------------------------------------------------------%
 
 t0 = clock;     %   - 获取当前系统时间
 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                    %
%         蚁  群   算   法   相   关   参   数          %
%                                                    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

AntNum = 20 ;                             %      - 种群中蚂蚁数量
alpha = 1 ;                                %      - 轨迹强度Tau(i,j)的权重参数
beta = 1;                                 %      - 能见度Eta(i,j)的权重参数
rho = 0.1;                                %      - 信息素蒸发系数
Q_ant = 800;                               %      - 信息素的更新量参数

Tau_min = 0.005;                            %      - 信息素浓度下界 
Tau_max = 3;                              %      - 信息素浓度上界

iter = 1;                                 %      - 初始化迭代次数
iter_max = 500;                            %      - 算法最大迭代次数

MMAS = 1 ;                                %      - 信息素更新策略，MMAS = 1时表示采用最大最小信息素更新策略


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                    %
%      ICT   问   题   相   关   变   量   设   置      %
%                                                    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Eta = 1./Distance;                         %      - Eta : 能见度矩阵，此处设置为节点间距离的倒数
Tau = ones(TaskNum + 1,TaskNum + 1);        %      - Tau : 信息素浓度矩阵，初始化时浓度均为1

Route = zeros(VeiNum,TaskNum + 1);          %      - Route : 路径记录矩阵，用于记录各辆车的运行路线     
Route_time = zeros(VeiNum,1);               %      - Route_time : 路径时间矩阵，用于记录任务完成时间
End_Task = zeros(VeiNum,1);                 %      - End_Task : 每辆车的最后一个任务 
Task_start_time = 1./zeros(TaskNum,1);      %      - Task_start_time = 所有任务的开始时间 

Ant_route = cell(AntNum,1);                 %      - 记录各代中每只蚂蚁的路径(Route)
Ant_task_start_time = cell(AntNum,1);       %      - 记录各代每只蚂蚁的任务开始时间(Task_start_time)
Ant_objective = zeros(AntNum,1);            %      - 记录各代中每只蚂蚁的目标值
Ant_arc = cell(AntNum,TaskNum);             %      - 记录每只蚂蚁的弧

Best_route = zeros(VeiNum,TaskNum);         %      - Best_route : 最优解路径矩阵，记录各代的最优解的车辆路径
Best_solution = zeros(iter_max,1);          %      - Best_solution : 最优解矩阵，记录各带最优解值
Ave_solution = zeros(iter_max,1);           %      - Ave_solution : 平均解矩阵，记录每次迭代中解的平均值
Best_Ant_arc = cell(1,TaskNum); 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                    %
%         不  确  定  用  不  用  参  数  变  量         %
%                                                    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%




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


    %   - 对每只蚂蚁进行搜索
    ant = 1;                                    %      - 初始化蚂蚁编号 
    while ant <= AntNum
        infeasible = 0;                         %      - 初始化解的可行性 
%---------------------------------------------------------------    初   始   化   ---------------------------------------------------------------------------------------%        
        %   - 相关集合初始化
        Route = zeros(VeiNum,TaskNum + 1);                      %    - 初始化路径集合    
        Route_time = zeros(VeiNum,1);                           %    - 初始化路径时间
        End_Task = zeros(VeiNum,1);                             %    - 初始化末端任务
        Task_start_time = 1./zeros(TaskNum,1);                  %    - 初始化任务开始时间
        Use_vehicle = 0;                                        %    - 初始化调用车辆数
        Transport_time = 0;                                     %    - 初始化运输时间
        Waiting_time = 0;                                       %    - 初始化等待时间
       
        
        Visited_Task = Route(Route>0);                          %    - 初始化已访问任务集合
        Visited_Task = [Visited_Task;0];                        %    
        Unvisited_Task = setdiff(1:TaskNum,Visited_Task);       %    - 初始化未访问任务集合

        
        %   - 对每项任务进行决策(因为是TaskNum个任务，所以进行TaskNum次决策)    
        for Tas = 1:TaskNum         %   - 注意这个 j 表示的实际是决策次数

%---------------------------------------------------------------    提   取   可   行   弧   ------------------------------------------------------------------------------------%            
        %   - 提取所有可行路径，采用元细胞组表示
        EL = length(End_Task);                                  %   - End_Task 的元素个数
        UL = length(Unvisited_Task);                            %   - Unvisited_Task 的元素个数
            
        Potential_arc = cell(EL,UL);                             
        for i = 1:EL                                            %   - 这里 i 代表车辆编号
           for j = 1:UL                                         %   - 这里 j 代表任务编号
               %   - 如果前置任务已经在已访问任务集合中
               if ismember(Task(Unvisited_Task(j),4),Visited_Task) 
               %   - 如果添加任务后，所在车辆完成该任务后，有充足的时间返回挂车中心 
                   if Route_time(i) + Linktime(End_Task(i)+1,Unvisited_Task(j)+1) + Tasktime(Unvisited_Task(j)+1) + Linktime(Unvisited_Task(j)+1,1) <= Time_Max  
               %   - 只有同时满足上两条，才能够说加入备选路径集合中                   
                   Potential_arc{i,j} = [End_Task(i),Unvisited_Task(j)];
                   end
               end
           end
        end   
%-------------------------------------------------------------     计  算   弧   选   择   概   率     -----------------------------------------------------------------------------------%        
        %   - 计算每条弧的选择概率
        Probabilistic_arc = ones(EL,UL);       
        for i = 1:EL
            for j = 1:UL
               
                if isempty(Potential_arc{i,j})                             %    - 如果弧中元素是空集，则概率为0
                    Probabilistic_arc(i,j) = 0 ;
               
                else                                                       %    - 若非空，则计算弧的选择概率
                   
               %        - 计算车辆数变化量  
                     if Potential_arc{i,j}(1) == 0                         %    - 如果弧起点为0,则增加一辆车 
                              Delta_F = 1;
                     else
                              Delta_F = 0; 
                     end     
               %        - 计算运行里程变化量
                        Delta_T = Linktime(Potential_arc{i,j}(1)+1,Potential_arc{i,j}(2)+1);  
               %        - 计算等待时间变化量(等待时间只由前置任务产生)
                        if Task(Potential_arc{i,j}(2),4) == 0              %       - 如果被选择的任务没有前置任务
                            Delta_W = 0;
                        else                                               %       - 计算等待时间(前置任务开始+前置任务执行+装卸)
                            %   - 等待时间等于前置任务完成时间 - 该任务到达时间Route_time(i) +Linktime()      m
                            Delta_W = (Task_start_time(Task(Potential_arc{i,j}(2),4)) + Tasktime(Task(Potential_arc{i,j}(2),4)+1) +Task(Task(Potential_arc{i,j}(2),4)+1,5)) - (Route_time(i) + Linktime(Potential_arc{i,j}(1)+1,Potential_arc{i,j}(2)+1) ) ;
                            %   - 等待时间不可以为负值，最小为0
                            if Delta_W < 0 
                                Delta_W = 0;
                            end
                        end
                %       - 计算能见度
                        Eta = 1/(Cost_F * Delta_F + Cost_T * Delta_T + Cost_W * Delta_W);
                        Eta = min(Eta,10);
                        
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
             disp(['出现不可行解，跳出循环']);
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
                   Sum_Pro_arc = sum(sum(Probabilistic_arc)) ;            %     - 计算所有转移系数只和
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
              Transport_time = Transport_time + Linktime(Select_arc(1)+1,Select_arc(2)+1);      %   - 记录车辆行驶时间
              Insert = find(Route(x(s0),:)~=0);                                                 %   - 找到x(s0)车辆路径中非0节点位置
            
            %   - 判断插入位置
              if isempty(Insert)                                                                %   - 如果Insert为空集，则插入到第一个任务位置 
                    Route(x(s0),1) = Select_arc(2);
                    Use_vehicle = Use_vehicle +1;
              else                                                                              %   - 如果Insert非空集，则插入Insert后第一个位置  
                    Route(x(s0),Insert(end)+1) = Select_arc(2);    
              end   
                
      %   - 相关集合更新  
              if Task(Select_arc(2),4) == 0                                                     %       - 新加入任务如果无前置任务
                            Task_start_time(Select_arc(2)) = Route_time(x(s0)) + Linktime(Select_arc(1)+1,Select_arc(2)+1); 
              else                                                                              %       - 新加入任务如果有前置任务
                            Task_start_time(Select_arc(2)) = max(Task_start_time(Task(Select_arc(2),4)) + Tasktime(Task(Select_arc(2),4)) + Task(Task(Select_arc(2),4),5) , Route_time(x(s0)) + Linktime(Select_arc(1)+1,Select_arc(2)+1) );
                            
                            wait = (Task_start_time(Task(Select_arc(2),4)) + Tasktime(Task(Select_arc(2),4)) + Task(Task(Select_arc(2),4),5)) - (Route_time(x(s0)) + Linktime(Select_arc(1)+1,Select_arc(2)+1));
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
      
        end                 %   - 这个 end 对应路径决策  
     
%-------------------------------------------------------------记   录   蚂   蚁   搜   索   结   果--------------------------------------------------------------------------------%
        %       - (1) 记录蚂蚁搜索出的路径、任务开始时间、目标函数
        %         - 记录路径
                 Ant_route{ant} = Route;   
        %         - 记录任务开始时间
                 Ant_task_start_time{ant} = Task_start_time;            
        %         - 记录目标函数 
                 Ant_objective(ant) = Use_vehicle * Cost_F + Transport_time * Cost_T + Waiting_time * Cost_W ;                                
                    
        %         - 更新蚂蚁编号         
                 ant = ant +1;
               
        %         - 如果出现不可行解，则这只蚂蚁进行重新搜索          
              if infeasible == 1
                  disp(['当前蚂蚁进行重新搜索！！！'])
                  ant = ant -1;
              end
                 
    end                     %   - 这个 end 对应蚂蚁编号

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
        for i = 1:TaskNum
        Best_Ant_arc{i} = Ant_arc{min_ant,i};
        end
         Best_iter = iter;
        disp(['初代最优解为：',num2str(Best_solution(iter))])

    else                                               %   - 如果迭代次数>1，    
        if min_obj < Best_solution(iter-1)             %   - 如果本代最优解小雨当前最优解
            Best_solution(iter) = min_obj;
            Best_route = Ant_route{min_ant};
            for i = 1:TaskNum
                Best_Ant_arc{i} = Ant_arc{min_ant,i};
            end
            disp(['搜索到新的最优解：',num2str(Best_solution(iter))])
            Best_iter = iter;
        else
            Best_solution(iter) = Best_solution(iter-1);
        end
            
    
    end
    
        Ave_solution(iter) = mean(Ant_objective);      %   - 记录当前代数平均值
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
disp(['本次运算用时:' num2str(Time_Cost) '秒']);
disp(['算法在第' num2str(Best_iter) '代时收敛']);

figure(1)
plot(1:iter_max,Best_solution,'b','linewidth',1.2)
xlabel('迭代次数')
ylabel('目标函数')
hold on 
plot(1:iter_max,Ave_solution,'r','linewidth',1.2) 
legend('最优解','平均值')
