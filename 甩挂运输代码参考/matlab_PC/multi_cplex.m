%-----------------------------
%   多尺寸集装箱cplex
%-----------------------------
clc
clear


%   导入算例
load(['Solution/','4-4(2(1-1)-2(1-1))/Drop/','instance.mat'])

%   设定结果保存路径
Save_path = ['Solution/','4-4(2(0-2)-2(2-0))/Trad/cplex/'];

VeiNum=2;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                    %
%              参   数   设   置   (静态)              %
%              （与aco设定一致）                       %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% - 时间相关数据 -

v = 1/10;                      %   - 单位距离行驶时间
t_teu = 0.5;                %   - 单个集装箱的提箱、交箱时间(假设40尺箱和两个20尺箱都是2*t_teu的时间)
t_drop = 0.2;               %   - 甩箱时间(提取40ft是2倍，但提取2个20ft也是t_drop)

% - 车辆相关数据 -

Time_Max = 500;              %   - 牵引车最长工作时间

% - 成本相关数据 -
Cost_F = 10;                %   - 单车固定成本
Cost_T = 1;                 %   - 单位时间运输成本
Cost_W = 3;                 %   - 单位时间等待成本

CusNum = length(Cus);       %   - 节点数量
TaskNum = size(Task,1);     %   - 任务数量

% - 充分大正数写约束用
M = 100000;

%   - 调取Distance.m函数计算节点间距离
[Distance] = Cal_Distance(Cus,CusNum);
%   - 调取Tasktime.m函数计算任务节点时间
[Tasktime] = Cal_Tasktime(TaskNum,Task,t_drop);
%   - 调取Linktime.m函数计算两种情况的衔接时间
[Linktime_1,Linktime_2,Linktime] = Cal_Linktime(TaskNum,Task,Distance,v,t_teu);

Linktime_3 = Linktime_2 + 1;


%------------------------------------------------------------------------------------------------------------------------
%%%%%%%%%%%%%%%
%   决策变量   %
%%%%%%%%%%%%%%%
Xijk = binvar(TaskNum+1,TaskNum+1,VeiNum,'full'); % - 车辆k以direct mode 连续服务任务i和任务j
Zijk = binvar(TaskNum+1,TaskNum+1,VeiNum,'full'); % - 车辆k以detour mode 连续服务任务i和任务j


Yik = binvar(TaskNum+1,VeiNum,'full');            % - 任务i由车辆k完成

yi = sdpvar(TaskNum+1,1,'full');                  % - 任务i的开始服务时间

alpha = intvar(TaskNum+1,TaskNum+1,VeiNum,'full');  % - 车辆k从任务i到任务j后的离港车容
beta = intvar(TaskNum+1,TaskNum+1,VeiNum,'full');   % - 车辆k从任务i到任务j后的当前车容
gama = intvar(TaskNum+1,TaskNum+1,VeiNum,'full');   % - 车辆k从任务i到任务j后20ft的资源情况
gamma = intvar(TaskNum+1,TaskNum+1,VeiNum,'full');   % - 车辆k从任务i到任务j后40ft的资源情况

alpha1 = intvar(TaskNum+1,VeiNum,'full');               % - 服务完任务i后车辆k 离港车容，取值{0,1,2}
beta1 = intvar(TaskNum+1,VeiNum,'full');                % - 服务完任务i后车辆k 当前车容，取值{0,1,2}
gama1 = intvar(TaskNum+1,VeiNum,'full');                % - 服务完任务i后车辆k 车上20ft空箱情况，取值{0,1,2,3}
gama2 = intvar(TaskNum+1,VeiNum,'full');                % - 服务完任务i后车辆k 车上20ft空箱情况，取值{0,1}

%%%%%%%%%%%%%%%
%   目标函数   %
%%%%%%%%%%%%%%%
obj=0;
% - 车辆固定成本
for j = 2:TaskNum+1
    for k = 1:VeiNum
   obj = obj + Cost_F * (Xijk(1,j,k) + Zijk(1,j,k)) ;  
    end
end

% - 车辆运输成本
for i = 1:TaskNum+1
    for j = 1:TaskNum+1
        for k = 1:VeiNum

            obj = obj + Cost_T * ( Xijk(i,j,k)*Linktime_1(i,j) + Zijk(i,j,k)*Linktime_2(i,j));%缺少清空时间成本，清空时间等于采用detour时，上一个任务后的当前车容量
            
        end
    end
end

% - 增加清空时间所产生的成本

for i = 1:TaskNum+1
    for j = 2:TaskNum+1
        for k = 1:VeiNum
            obj = obj + Cost_T * Zijk(i,j,k) * t_teu * (2 - beta1(i,k));
        end
    end
end

for j = 2:TaskNum+1
   
    obj = obj + Cost_W * yi(j);
    
end


for i = 1:TaskNum+1 
    for j = 2:TaskNum+1
        for k = 1:VeiNum
            
     obj = obj - Cost_W *( Xijk(i,j,k) * (yi(i) + Tasktime(i) +  Linktime_1(i,j)) + Zijk(i,j,k) * (yi(i) + Tasktime(i) + Linktime_2(i,j) + t_teu*(2-beta1(i,k)))    )        ;
            
        end
    end
end





f= obj;
%%%%%%%%%%%%%%%
%   约束条件   %
%%%%%%%%%%%%%%%
F=[];

% - 所有任务都有唯一的车车辆进行服务
for i=2:TaskNum+1   
    F=[F;sum(Yik(i,:))==1]; 
end

% - 调用车辆数不超过最大车辆数
for i=1
    F=[F;sum(Yik(i,:))<=VeiNum];
end

% - 若车辆有任务，则车辆必须服务起始点
for k=1:VeiNum
    F = [F;sum(Yik(1,k)) >= sum(Yik(:,k))/(TaskNum+1)]; 
end

% - 自回路消除
for i=1:TaskNum+1
    for j=1:TaskNum+1
        for k=1:VeiNum
            if i==j
                F=[F;Xijk(i,j,k) + Zijk(i,j,k) ==0];           %不可能存在从该点出发又回到该点的情况
            end
        end
    end
end

% - 变量关系约束(如果任务被选择，必然有一辆车以一种的状态访问这个任务，并且离开这个任务)
for j=1:TaskNum+1
    for k=1:VeiNum
        F=[F;sum(Xijk(:,j,k)) + sum(Zijk(:,j,k))==Yik(j,k)];
    end
end

for i=1:TaskNum+1
    for k=1:VeiNum
        F=[F;sum(Xijk(i,:,k)) + sum(Zijk(i,:,k)) ==Yik(i,k)];%
    end
end

% - 车辆不能够立刻返回之前任务
for k = 1:VeiNum
    for i = 2:TaskNum+1
        for j = 2:TaskNum+1
           F = [F;Xijk(i,j,k) + Xijk(j,i,k) + Zijk(j,i,k) <= 1 ];
           F = [F;Zijk(i,j,k) + Zijk(j,i,k) + Xijk(j,i,k) <= 1 ];
        end
    end
end

% - 车辆节点流量守恒
for i=1:TaskNum+1
    for k=1:VeiNum
       F=[F;sum(Xijk(i,:,k)) + sum(Zijk(i,:,k)) == sum(Xijk(:,i,k)) + sum(Zijk(:,i,k))];
    end
end


% - 回路消除约束(基于子集合内路径数量)
Task_check = 2:TaskNum+1;
for sub_size = 2:TaskNum %定义子集合长度，最短为2，最长为除了1点之外的长度
    select_set = combntns(Task_check,sub_size);     % - 输出包含sub_size个元素的所有组合
    select_set_size = size(select_set,1);           % - 确定组合包含元素个数 
    for i = 1:select_set_size           % - 子集合判断次数 

                    for k = 1:VeiNum
                                     
                       F = [F;sum(sum(Xijk(select_set(i,:),select_set(i,:),k))) + sum(sum(Zijk(select_set(i,:),select_set(i,:),k)))   <= sub_size - 1];      
                        
                    end

    end
end

% - 任务开始时间约束
for i = 1:TaskNum+1

    F = [F;yi(i) >= Linktime_1(1,i)]; % - 不早于直指到达时间
    F = [F;yi(i) + Tasktime(i) + Linktime_1(i,1) <= Time_Max];%这里的linktime不需要修改(因为这里肯定是1)
    
end


% - 任务衔接时间约束
for i = 1:TaskNum+1
    for j = 2:TaskNum+1
        for k = 1:VeiNum
                                                                                                 %如果xijk和zijk都等于0，则恒成立，如果有一个等于0，那么小于yi(j)
                                                                                                 % - 根据其他约束，xiji和zijk不可能都等于1
           F = [F;yi(i) + Tasktime(i) +  Linktime_1(i,j) <= (M * (1-Xijk(i,j,k)) + yi(j))];
           F = [F;yi(i) + Tasktime(i) +  Linktime_2(i,j) +  t_teu*(2-beta1(i,k))  <= (M * (1-Zijk(i,j,k)) + yi(j))];
           
            
        end
    end
end



% - 前置任务时间约束

for i = 2:TaskNum+1

    F = [F;yi(Task(i-1,4)+1) + Tasktime(Task(i-1,4)+1) + Task(Task(i-1,4)+1,5) <= yi(i)];

end

% - 初始化起始点状态
for i = 1
    for k =1:VeiNum
  F = [F;alpha1(i,k) == 2] ;
  F = [F;beta1(i,k) == 2] ;
  F = [F;gama1(i,k) == 0] ;
  F = [F;gama2(i,k) == 0] ;
    end
    
end

% - 车辆状态取值范围设定
for i = 2:TaskNum+1
    for k = 1:VeiNum
    F = [F; 0 <= alpha1(i,k) <= 2];
    F = [F; 0 <= beta1(i,k) <= 2];
    F = [F; 0 <= gama1(i,k) <= 2];
    F = [F; 0 <= gama2(i,k) <= 1];
    end
end

for i = 1 :TaskNum+1

    F = [F;0<=yi(i)<=Time_Max];
    
end

for i = 1:TaskNum+1
    for j = 2:TaskNum+1
        for k = 1:VeiNum
            
           F = [F; -2 <= alpha(i,j,k) <= 2];
           F = [F; -2 <= beta(i,j,k) <= 2];
           F = [F; -2 <= gama(i,j,k) <= 2];
           F = [F; -2 <= gamma(i,j,k) <= 2];
            
        end
    end
end
%--------------   修改分割线     --------------------

% - 第二次尝试写车辆状态变量关系(失败)

% - 第三次尝试：把决策变量改为当前车容量，并拓展Task确定各个人物所需要的离港车荣，当前车容，以及所需空箱资源(失败)

% - 第四次尝试：设定决策变量：从任务i到任务j的状态变化量

% - 第五次尝试：把xijk写成xijk==0的等式形式，避免implies左右都是binvay

% - 第六次尝试：给40ft箱增加一个新的决策变量gama2
for i = 1:TaskNum+1
for j = 2:TaskNum+1
   for k = 1:VeiNum 
    
       switch Task(j-1,3)
%-------------------------------  20 ft  -------------------------------           
           case 1   % - DF_20ft
                    F = [F;implies(alpha1(i,k)<=0,Xijk(i,j,k)==0)];
                    F = [F;implies(beta1(i,k)<=0,Xijk(i,j,k)==0)];
                    
                    F = [F;implies(Xijk(i,j,k),alpha(i,j,k) == -1 )];
                    F = [F;implies(Xijk(i,j,k),beta(i,j,k) == 0 )];
                    F = [F;implies(Xijk(i,j,k),gama(i,j,k) == 0 )];
                    F = [F;implies(Xijk(i,j,k),gamma(i,j,k) == 0 )];
                    
                    F = [F;implies(Zijk(i,j,k),alpha1(j,k)==1)];
                    F = [F;implies(Zijk(i,j,k),beta1(j,k)==2)];
                    F = [F;implies(Zijk(i,j,k),gama1(j,k)==0)];
                    F = [F;implies(Zijk(i,j,k),gama2(j,k)==0)];
                                        
                    F = [F;alpha1(j,k) == alpha1(i,k) + alpha(i,j,k)];
                    F = [F;beta1(j,k) == beta1(i,k) + beta(i,j,k)];
                    F = [F;gama1(j,k) == gama1(i,k) + gama(i,j,k)];
                    F = [F;gama2(j,k) == gama2(i,k) + gamma(i,j,k)];
                      
           case 2   % - PE_20ft 
                    F = [F;implies(beta1(i,k)<=0,Xijk(i,j,k)==0)];  % 当车容不满足任务要求时，只可能采用detour模式

                    F = [F;implies(Xijk(i,j,k),alpha(i,j,k) == 0 )];
                    F = [F;implies(Xijk(i,j,k),beta(i,j,k) == -1 )];
                    F = [F;implies(Xijk(i,j,k),gama(i,j,k) == 1 )];
                    F = [F;implies(Xijk(i,j,k),gamma(i,j,k) == 0 )];

                    F = [F;implies(Zijk(i,j,k),alpha1(j,k)==2)];
                    F = [F;implies(Zijk(i,j,k),beta1(j,k)==1)];
                    F = [F;implies(Zijk(i,j,k),gama1(j,k)==1)];
                    F = [F;implies(Zijk(i,j,k),gama2(j,k)==0)];
                    
                    F = [F;alpha1(j,k) == alpha1(i,k) + alpha(i,j,k)];
                    F = [F;beta1(j,k) == beta1(i,k) + beta(i,j,k)];
                    F = [F;gama1(j,k) == gama1(i,k) + gama(i,j,k)];
                    F = [F;gama2(j,k) == gama2(i,k) + gamma(i,j,k)];                   
               
           case 3   % - DE_20ft 
               
                    F = [F;implies(gama1(i,k)>=1,Zijk(i,j,k)==0)];  % 当车容不满足任务要求时，只可能采用detour模式
                    F = [F;implies(alpha1(i,k)>=1,Zijk(i,j,k)==0)];                                       
    
                   % xijk==1,并且gama1>=1;alpha(i,j,k) == 0 gama(i,j,k) == -1
                   % xijk ==1 ,alpha1(i,k)>=1,alpha(i,j,k) ==-1,gama(i,j,k)
                   % ==0
                    
                    
               %     F = [F;implies(Xijk(i,j,k)*gama1(i,k)>=1,alpha(i,j,k) == 0 )];
               %     F = [F;implies(Xijk(i,j,k)*gama1(i,k)>=1,gama(i,j,k) == -1 )];
               %     F = [F;implies(Xijk(i,j,k)*alpha1(i,k)>=1,alpha(i,j,k) == -1 )];
               %     F = [F;implies(Xijk(i,j,k)*alpha1(i,k)>=1,gama(i,j,k) == 0 )];               
               

                    F = [F;implies(Xijk(i,j,k),alpha(i,j,k)+gama(i,j,k)==-1)];
                    
                    F = [F;implies(Xijk(i,j,k),beta(i,j,k) == 0 )];                  
                    F = [F;implies(Xijk(i,j,k),gamma(i,j,k) == 0 )];                    
                    
                    
                    F = [F;implies(Zijk(i,j,k),alpha1(j,k)==1)];
                    F = [F;implies(Zijk(i,j,k),beta1(j,k)==2)];
                    F = [F;implies(Zijk(i,j,k),gama1(j,k)==0)];
                    F = [F;implies(Zijk(i,j,k),gama2(j,k)==0)];
                                        
                    F = [F;alpha1(j,k) == alpha1(i,k) + alpha(i,j,k)];
                    F = [F;beta1(j,k) == beta1(i,k) + beta(i,j,k)];
                    F = [F;gama1(j,k) == gama1(i,k) + gama(i,j,k)];
                    F = [F;gama2(j,k) == gama2(i,k) + gamma(i,j,k)];
               
               
                  
           case 4   % - PF_20ft 
                    F = [F;implies(beta1(i,k)<=0,Xijk(i,j,k)==0)];  % 当车容不满足任务要求时，只可能采用detour模式

                    F = [F;implies(Xijk(i,j,k),alpha(i,j,k) == 0 )];
                    F = [F;implies(Xijk(i,j,k),beta(i,j,k) == -1 )];
                    F = [F;implies(Xijk(i,j,k),gama(i,j,k) == 0 )];
                    F = [F;implies(Xijk(i,j,k),gamma(i,j,k) == 0 )];

                    F = [F;implies(Zijk(i,j,k),alpha1(j,k)==2)];
                    F = [F;implies(Zijk(i,j,k),beta1(j,k)==1)];
                    F = [F;implies(Zijk(i,j,k),gama1(j,k)==0)];
                    F = [F;implies(Zijk(i,j,k),gama2(j,k)==0)];
                    
                    F = [F;alpha1(j,k) == alpha1(i,k) + alpha(i,j,k)];
                    F = [F;beta1(j,k) == beta1(i,k) + beta(i,j,k)];
                    F = [F;gama1(j,k) == gama1(i,k) + gama(i,j,k)];
                    F = [F;gama2(j,k) == gama2(i,k) + gamma(i,j,k)];                   
%-------------------------------  40 ft  -------------------------------
           case 5   % - DF_40ft 
                    F = [F;Xijk(i,j,k)==0];
                    F = [F;alpha1(j,k)==0];
                    F = [F;beta1(j,k)==2];
                    F = [F;gama1(j,k)==0];
                    F = [F;gama2(j,k)==0];
                    
               
           case 6   % - PE_40ft
                    F = [F;implies(beta1(i,k)<=1,Xijk(i,j,k)==0)];  % 当车容不满足任务要求时，只可能采用detour模式
                    F = [F;alpha1(j,k)==0];
                    F = [F;beta1(j,k)==0];
                    F = [F;gama1(j,k)==0];
                    F = [F;gama2(j,k)==1];
                    
                 
           case 7   % - DE_40ft
                    F = [F;implies(gama2(i,k)>=1,Zijk(i,j,k)==0)];  % 当车容不满足任务要求时，只可能采用detour模式
                    F = [F;implies(alpha1(i,k)>=2,Zijk(i,j,k)==0)];
                    F = [F;alpha1(j,k)==0];
                    F = [F;beta1(j,k)==2];
                    F = [F;gama1(j,k)==0];
                    F = [F;gama2(j,k)==0];

           case 8   % - PF_40ft
                    F = [F;implies(beta1(i,k)<=1,Xijk(i,j,k)==0)];  % 当车容不满足任务要求时，只可能采用detour模式
                    F = [F;alpha1(j,k)==0];
                    F = [F;beta1(j,k)==0];
                    F = [F;gama1(j,k)==0];
                    F = [F;gama2(j,k)==0];
                    
%-------------------------------         -------------------------------
       end
   end
end
end


%------------------------

%%%%%%%%%%%%%%%
%   cplex求解  %
%%%%%%%%%%%%%%%
ops = sdpsettings( 'solver','cplex');%参数设置
ops.cplex.display='on';
%ops.cplex.timelimit=3600;
disp('开始求解')

sol=optimize(F,f,ops);% 设置求解

if sol.problem==0
    disp('Solver thinks it is feasible')
elseif sol.problem == 1
    disp('Solver thinks it is infeasible')
    pause();
else
    disp('Timeout, Display the current optimal solution')
end


f=double(f);      % 目标函数
Xijk = double(Xijk) % 决策变量
Zijk = double(Zijk) % 决策变量
Yik = double(Yik)  % 决策变量
yi = double(yi)
alpha1 = double(alpha1)
alpha = double(alpha)
beta1 = double(beta1)
beta = double(beta)
gama1 = double(gama1)
gama2 = double(gama2)
gama = double(gama)
%Uik=double(Uik);   % 决策变量

%for k=1:VeiNum
%    [a,b]=find(Xijk(:,:,k)); %非零元素索引值
%    sqe=[a,b];
%    sqe1=zeros(1,0);
%    sqe1(1)=1;
%    [a,b]=find(sqe(:,1)==1);
%    for i=2:length(sqe)+1
%        [a,b]=find(sqe(:,1)==sqe1(i-1));
%        sqe1(i)=sqe(a,b+1);
%    end
%    disp(['车辆',num2str(k),'的路径如下：']);
%    disp(sqe1)
%end


