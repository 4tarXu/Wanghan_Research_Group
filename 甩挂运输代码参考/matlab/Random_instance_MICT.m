


function [Cus_select,Task_Cus,Cus,Task] = Random_instance_MICT(Cus_size,Task_size,Task_20ft_size,Task_40ft_size,Task_20ft_inbound_size,Task_20ft_outbound_size,Task_40ft_inbound_size,Task_40ft_outbound_size)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                          % 
%             主要功能 : VRP标准测试算例生成MICT算例            %  
%                                                          % 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% - 素质三连
%clc
%clear all
%close all

%----------------------------------------------------------
%           - 原   始   数   据   导   入   区               
%----------------------------------------------------------

%------------------------------------------------------------------------%
%       - Solomon标准测试算例说明
%           - 客户规模 : 100
%           - 最大车辆数 : 12
%           - 最大车容量 : 200
%           - 行指标 : 
%               - 第 1 行 : 车辆中心信息(编号为0)
%               - 第 2 ~ 101 行 : 客户节点信息
%           - 列指标 : 
%               - 第一列 : 节点编号(CUST NO.)
%               - 第二列 : 横坐标(XCOORD)
%               - 第三列 : 纵坐标(YCOORD)
%               - 第四列 : 客户需求(DEMAND)
%               - 第五列 : 开始时间窗(READY_TIME)
%               - 第六列 : 结束时间窗(DUE_TIME)
%               - 第七列 : 服务时间(SERVICE_TIME)
%------------------------------------------------------------------------%

%       - 导入Solomon测试算例 - 
c101=importdata('./instance/RC/RC101.txt');
Size_instance = size(c101,1) - 1 ;  % 减1因为第一行作为terminal，不作为customer生成                                        


%----------------------------------------------------------
%           - 生   成   规   则   设   定   区                
%----------------------------------------------------------



% - 设定算例生成规则
rand_rule = 0;   %       - 生成规则，取1时表示所有任务节点均匀分布给客户，取2时表示完全随机(但需要保证所有客户点有任务)  

% - 设定集装箱装卸时间
load_20ft_time = 1; 
load_40ft_time = 2;


%  - 创建空矩阵用于保存算例

Cus = zeros(Cus_size + 1,2);       %      客户点横纵坐标。加1是因为要增加terminal位置 
Task = zeros(Task_size*2,6);       %      每个任务需求被拆分成两项任务。  Task = 任务起点 & 任务终点 & 任务类型 & 前置任务 & 装卸时间 & 任务占用车容量  

%%%%%%%%%%%%%%%%%%
%     Cus生成     %
%%%%%%%%%%%%%%%%%%

%  (1) 抽取Cus_size个客户节点
Cus_select =  randperm(Size_instance,Cus_size);

%  (2) 插入terminal坐标

Cus(1,1) = c101(1,2);
Cus(1,2) = c101(1,3);

%   (4)插入被选择的客户节点
for i = 1:Cus_size
    Cus(i+1,1) = c101(Cus_select(i)+1,2);
    Cus(i+1,2) = c101(Cus_select(i)+1,3);
end

%%%%%%%%%%%%%%%%%%
%    Task生成     %
%%%%%%%%%%%%%%%%%%

%  -(1)客户任务均匀分布时
if rand_rule ==1
%   - 生成所有任务对应客户点编号 ： Task_Cus

Task_Cus = [];          %       - 前Cus_size个任务对应的客户节点编号，保证每一个客户至少有一个任务         

cycle = ceil(Task_size/Cus_size);   %   Cus_select重复次数

for i=1:cycle
Task_Cus = [Task_Cus Cus_select ] ;              
end

Task_Cus = Task_Cus(1:Task_size);                     %       - 至此，所有任务对应的客户点完成            


%  -(1)客户任务随机分布时
else 
    
    Task_Cus = []; 
    Task_Cus = [Task_Cus Cus_select];%  把被选择客户插入进来，保证每个客户至少有一个任务
    
    for i =1:Task_size-Cus_size     %剩余客户插入任务
    se = randperm(Cus_size,1);
    Task_Cus = [Task_Cus Cus_select(se)];
    end
end


% - 按照不同任务的数量生成数组，其中1表示20尺进港集装箱，2表示20尺出港集装箱，3表示40尺进港集装箱，4表示40尺出港集装箱
Task_IO24 = [ones(Task_20ft_inbound_size,1); 2*ones(Task_20ft_outbound_size,1); 3*ones(Task_40ft_inbound_size,1);4*ones(Task_40ft_outbound_size,1)];
% - 对Task_IO24重新排列，给每项任务安排一个任务类型
Task_IO24 = Task_IO24(randperm(length(Task_IO24)));

for i = 1:Task_size
        if Task_IO24(i) == 1            % - 20ft进港集装箱   

        % - 更新DF_20ft任务
            Task(2*i-1,1) = 1;                                     %  - 起始点为terminal  
            Task(2*i-1,2) = find(Task_Cus(i)==Cus_select)+1;       %  - 终止点为客户节点
            Task(2*i-1,3) = 1;                                     %  - 标记为DF_20ft任务
            Task(2*i-1,4) = 0;                                     %  - 无前置任务
            Task(2*i-1,5) = load_20ft_time;                        %  - 有装卸时间
            Task(2*i-1,6) = 1;                                     %  - 占用一个车容空间        
        % - 更新PE_20ft任务
            Task(2*i,1) = find(Task_Cus(i)==Cus_select)+1;         %  - 起始点为客户节点  
            Task(2*i,2) = 1;                                       %  - 终止点为terminal
            Task(2*i,3) = 2;                                       %  - 标记为PE_20ft任务
            Task(2*i,4) = 2*i-1;                                   %  - 前置任务为DF_20ft
            Task(2*i,5) = 0;                                       %  - 无装卸时间
            Task(2*i,6) = 1;                                       %  - 占用一个车容空间          
        
        elseif Task_IO24(i) == 2        % - 20ft出港集装箱

        % - 更新DE_20ft任务
            Task(2*i-1,1) = 1;                                     %  - 起始点为terminal  
            Task(2*i-1,2) = find(Task_Cus(i)==Cus_select)+1;       %  - 终止点为客户节点
            Task(2*i-1,3) = 3;                                     %  - 标记为DE_20ft任务
            Task(2*i-1,4) = 0;                                     %  - 无前置任务
            Task(2*i-1,5) = load_20ft_time;                        %  - 有装卸时间
            Task(2*i-1,6) = 1;                                     %  - 占用一个车容空间         
        % - 更新PF_20ft任务            
            Task(2*i,1) = find(Task_Cus(i)==Cus_select)+1;         %  - 起始点为客户节点  
            Task(2*i,2) = 1;                                       %  - 终止点为terminal
            Task(2*i,3) = 4;                                       %  - 标记为PF_20ft任务
            Task(2*i,4) = 2*i-1;                                   %  - 前置任务为DF_20ft
            Task(2*i,5) = 0;                                       %  - 无装卸时间
            Task(2*i,6) = 1;                                       %  - 占用一个车容空间 
            
        elseif Task_IO24(i) == 3        % - 40ft进港集装箱
            
        % - 更新DF_40ft任务
            Task(2*i-1,1) = 1;                                     %  - 起始点为terminal  
            Task(2*i-1,2) = find(Task_Cus(i)==Cus_select)+1;       %  - 终止点为客户节点
            Task(2*i-1,3) = 5;                                     %  - 标记为DF_40ft任务
            Task(2*i-1,4) = 0;                                     %  - 无前置任务
            Task(2*i-1,5) = load_40ft_time;                        %  - 有装卸时间
            Task(2*i-1,6) = 2;                                     %  - 占用两个车容空间         
        % - 更新PE_40ft任务       
            Task(2*i,1) = find(Task_Cus(i)==Cus_select)+1;         %  - 起始点为客户节点  
            Task(2*i,2) = 1;                                       %  - 终止点为terminal
            Task(2*i,3) = 6;                                       %  - 标记为PE_20ft任务
            Task(2*i,4) = 2*i-1;                                   %  - 前置任务为DF_20ft
            Task(2*i,5) = 0;                                       %  - 无装卸时间
            Task(2*i,6) = 2;                                       %  - 占用两个车容空间     
        else                            % - 40ft进港集装箱

        % - 更新DE_40ft任务
            Task(2*i-1,1) = 1;                                     %  - 起始点为terminal  
            Task(2*i-1,2) = find(Task_Cus(i)==Cus_select)+1;       %  - 终止点为客户节点
            Task(2*i-1,3) = 7;                                     %  - 标记为DE_40ft任务
            Task(2*i-1,4) = 0;                                     %  - 无前置任务
            Task(2*i-1,5) = load_40ft_time;                        %  - 有装卸时间
            Task(2*i-1,6) = 2;                                     %  - 占用两个车容空间          
        % - 更新PF_40ft任务 
            Task(2*i,1) = find(Task_Cus(i)==Cus_select)+1;         %  - 起始点为客户节点  
            Task(2*i,2) = 1;                                       %  - 终止点为terminal
            Task(2*i,3) = 8;                                       %  - 标记为PF_24ft任务
            Task(2*i,4) = 2*i-1;                                   %  - 前置任务为DF_40ft
            Task(2*i,5) = 0;                                       %  - 无装卸时间
            Task(2*i,6) = 2;                                       %  - 占用一个车容空间         
        end
end


disp(['抽取的客户节点编号为']);
Cus_select
disp(['各任务对应的的客户节点编号为']);
Task_Cus

disp(['输出到主程序的算例数据(1):']);
Cus 
disp(['输出到主程序的算例数据(2):']);
Task

