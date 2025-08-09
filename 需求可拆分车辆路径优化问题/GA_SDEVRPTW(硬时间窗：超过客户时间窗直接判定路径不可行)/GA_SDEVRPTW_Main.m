clc %清空命令行窗口
clear %从当前工作区中删除所有变量，并将它们从系统内存中释放
close all %删除其句柄未隐藏的所有图窗
tic % 保存当前时间(算法执行时间开始时刻标记)

%% 代码改进空间：


%% 算例设置区域

% --------基于Solomon benchmark生成测试算例
% % 导入测试算例：solomon标准测试算例(详见课题组门户网站关于Solomon算例的讲解，终点关注 C、R、RC的区别)
      instance=importdata('./instance/C/C101.txt');
% 
% % 设置算例规模(客户点数量)
      CustomerNum = 100; % 设置客户点数量为
      ChargeStationNum = 60; % 设置充电站数量
% % 生成算例
      [City,Demand,Distance,ChargeStations_index,CityNum,TimeWindow,ServiceTime,TravelTime]=sdvrp_instance(instance,CustomerNum,ChargeStationNum);

% --------代码自带测试算例
% 以下是问题规模为10的测试算例
   % load('../test_data/City.mat')	      % 需求点经纬度，用于画实际路径的XY坐标
   % load('../test_data/Distance.mat')	  % 距离矩阵
   % load('../test_data/Demand.mat')        % 需求量

%% 算例相关参数设置

% 车辆相关参数设置：
Capacity = 200; % 设置车容量 原参数：12
VehicleCost = 300;% 设置车辆成本参数，用于控制与平衡车辆使用的数量与车辆行驶距离的关系
Travelcon = 200;  % 车辆最大行驶里程

% 车辆电力相关参数(目前均没有使用，因为算法逻辑是如何客户访问充电站，则行驶距离清零，只要满足里程约束即可)
%   - 未使用的主要原因：目前算法没有考虑时间相关约束，即不考虑充电时间和访问时间
BatteryCap = 50;       % 电池最大容量（kWh）
EnergyConsump = 0.2;    % 单位距离能耗（kWh/km）
ChargeRate = 10;        % 充电速率（kWh/h）
MaxRange = BatteryCap / EnergyConsump; % 最大续航里程（km）= 电池容量/单位能耗


%% 遗传算法相关参数设置
NIND=80;      %种群大小
MAXGEN=500;     %最大遗传代数
GGAP=0.9;       %代沟概率
Pc=0.9;         %交叉概率
Pm=0.5;        %变异概率

%% 为预分配内存而初始化的0矩阵
mindis = zeros(1,MAXGEN);
bestind = zeros(1,CityNum*2+1);

%% 初始化种群(注意，本算法框架的遗传操作都是基于TSP架构进行)
[TSPRoute,Chrom,VehicleNum]=InitPop(NIND,CityNum,Demand,Capacity,Travelcon,Distance,BatteryCap,ChargeStations_index,TravelTime,TimeWindow,ServiceTime);

%% 迭代
gen=1;
while gen <= MAXGEN
    %% 遗传算法测试封包（冻结：封包无法找到算法问题）
% [mindis,bestind,Chrom,VehicleNum,TSPRoute,mindisbygen] = GA_SDVRP(Distance,Demand,Chrom,Capacity,Travelcon,VehicleNum,VehicleCost,GGAP,Pc,Pm,gen,TSPRoute,CityNum,mindis,bestind,BatteryCap,ChargeStations_index)

% 代码测试：如通过则修正封包
[TotalCost,FitnV]=Fitness(Distance,Demand,Chrom,Capacity,Travelcon,VehicleNum,VehicleCost,BatteryCap,ChargeStations_index,TravelTime,TimeWindow,ServiceTime);  %计算路径长度
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

    [Chrom_sel,VehicleNum_sel] = TSPtoChrom(TSPRoute_sel,CityNum,Distance,Travelcon,Demand,Capacity,ChargeStations_index,TravelTime,TimeWindow,ServiceTime);

    %% 亲代重插入子代
    [TSPRoute,Chrom,VehicleNum]=Reins(Chrom,Chrom_sel,TSPRoute,TSPRoute_sel,FitnV,VehicleNum_sel,VehicleNum);

    %% 邻域搜索操作（注意：邻域搜索操作和剔除冗余充电站操作顺序可以互换，实验阶段检测一下先后顺序对时间的影响）
    
    Chrom = localsearch(Chrom,Distance,Demand,Capacity,Travelcon,VehicleNum,VehicleCost,BatteryCap,ChargeStations_index,TravelTime,TimeWindow,ServiceTime);

    %% 剔除冗余充电站（注意：邻域搜索操作和剔除冗余充电站操作顺序可以互换，实验阶段检测一下先后顺序对时间的影响）
    Chrom = RemoveRedundantChargers(Distance,Demand,Chrom,Capacity,Travelcon,VehicleNum,VehicleCost,BatteryCap,ChargeStations_index,ChargeStationNum,TravelTime,TimeWindow,ServiceTime);

    %% 显示此代信息
    fprintf('Iteration = %d, Min Distance = %.2f km  \n',gen,mindisbygen)
    %% 更新迭代次数
    gen=gen+1;
end

%% 找出历史最短距离和对应路径
mindisever=mindis(MAXGEN);  % 取最优适应值的位置、最优目标函数值
bestroute=bestind; % 取最优个体

%删去路径中多余1
for i=1:length(bestroute)-1
    if bestroute(i)==bestroute(i+1)
        bestroute(i)=0;  %相邻位都为1时前一个置零
    end
end
bestroute(bestroute==0)=[];  %删去多余零元素
bestroute=bestroute-1;  % 编码各减1，与文中的编码一致

%% 计算结果数据输出到命令行
disp('-------------------------------------------------------------')
toc %显示运行时间
fprintf('Total Cost = %s km \n',num2str(mindisever))
TextOutput(Distance,Demand,bestroute,Capacity,bestind,ChargeStations_index,ChargeStationNum)  %显示最优路径
disp('-------------------------------------------------------------')

%% 迭代图
 figure
  plot(mindis,'LineWidth',2) %展示目标函数值历史变化
  xlim([1 gen-1]) %设置 x 坐标轴范围
  set(gca, 'LineWidth',1)
  xlabel('Iterations')
  ylabel('Min Distance(km)')
  title('GA Optimization Process')

%% 绘制实际路线
       DrawPath(bestroute,City,ChargeStations_index)
