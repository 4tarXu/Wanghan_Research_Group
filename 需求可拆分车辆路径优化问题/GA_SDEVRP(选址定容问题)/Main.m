clc %清空命令行窗口
clear %从当前工作区中删除所有变量，并将它们从系统内存中释放
close all %删除其句柄未隐藏的所有图窗
tic % 保存当前时间(算法执行时间开始时刻标记)

%% 代码改进空间：
% 1. 装载率计算问题
% 2. 更改Fitness中换电站，如果访问则增加对应的行驶里程
% 3. 换电站固定建设成本与换电成本

%% 代码改进工作
% 单个充电站位置设置多个充电站，实现换电定容操作，已经可以保证一个充电站被多个客户访问。（同时可以保证一辆车访问一个充电站多次）
% （待修改：）Best Route中，充电站编号与ChargeStations_index中的序号相差1
% 生成3次不同算例，充电站使用相同的内容

%% 算例设置区域

% --------基于Solomon benchmark生成测试算例
 % 导入测试算例：solomon标准测试算例(详见课题组门户网站关于Solomon算例的讲解，终点关注 C、R、RC的区别)
       instance=importdata('./instance/C/C101.txt');
 % 
 % % 设置算例规模(客户点数量)
       Instance_Layer = 3; % 设置算例层数为3，即生成3次算例，但要求充电站位置相同
       CustomerNum = 100; % 设置客户点数量为
       ChargeStationNum = 10; % 设置充电站位置数量，每个位置设置多个"重合"充电站，用于表示需要电池数量。最后根据选择情况定容。   
       ChargeStationBatteryNum = 10;% 设置电池数量：
       [Sturct_instances,City,Demand,Distance,ChargeStations_index,CityNum]=sdvrp_instance(instance,CustomerNum,ChargeStationNum,ChargeStationBatteryNum,Instance_Layer);

% --------代码自带测试算例
% 以下是问题规模为10(10个客户点)的测试算例、同时包含3个充电站
    % load('../test_data/City.mat')	      %需求点经纬度，用于画实际路径的XY坐标
    % load('../test_data/Distance.mat')	  %距离矩阵
    % load('../test_data/Demand.mat')       %需求量
    % load('../test_data/Capacity.mat')     %车容量约束
    % % load('../test_data/Travelcon.mat')    %车辆行驶约束(电量)
    % Travelcon = 60;
    % Instance_Layer = 1;% 设置算例层数
    % Sturct_instances(Instance_Layer) = struct('City', [], 'Demand', [],'Distance',[],'ChargeStations_index',[],'CityNum',[]);% 预分配结构体数组
    % % 把测试算例中的后两个节点变成换电站
    % ChargeStationNum = 6; % 换电站数量为3
    % ChargeStationBatteryNum = 1; % 每个换电站的电池数量
    % ChargeStations_index = [6:11]; % 换电站编号
    % Demand(ChargeStations_index) = 0; % 换电站的需求量设置为0
    % CityNum = 10;% 总节点数量：配送中心(车场)数量 + 客户点数量 + 换电站数量
    % % 数据存入结构体
    % Sturct_instances.City = City; % 城市数据
    % Sturct_instances.Demand = Demand; % 需求数据
    % Sturct_instances.ChargeStations_index = ChargeStations_index; % 换电站坐标
    % Sturct_instances.CityNum = CityNum; % 节点总数量
    % Sturct_instances.Distance = Distance; % 距离矩阵

%% 算例相关参数设置

% % 车辆相关参数设置：
 Capacity = 200; % 设置车容量 原参数：12
 VehicleCost = 0;% 设置车辆成本参数，用于控制与平衡车辆使用的数量与车辆行驶距离的关系
 Travelcon = 150;  % 车辆最大行驶里程

% 车辆电力相关参数(目前均没有使用，因为算法逻辑是如何客户访问充电站，则行驶距离清零，只要满足里程约束即可)
%   - 未使用的主要原因：目前算法没有考虑时间相关约束，即不考虑充电时间和访问时间
BatteryCap = 50;       % 电池最大容量（kWh）
EnergyConsump = 0.2;    % 单位距离能耗（kWh/km）
ChargeRate = 10;        % 充电速率（kWh/h）
MaxRange = BatteryCap / EnergyConsump; % 最大续航里程（km）= 电池容量/单位能耗

%% 遗传算法相关参数设置
NIND=30;      %种群大小
MAXGEN=1000;     %最大遗传代数
GGAP=0.8;       %代沟概率
Pc=0.8;         %交叉概率
Pm=0.05;        %变异概率

% 创建绘图
% figure;

parfor k = 1:Instance_Layer


%% 为预分配内存而初始化的0矩阵
mindis = zeros(1,MAXGEN);
bestind = zeros(1,Sturct_instances(k).CityNum*2+1);

%% 初始化种群(注意，本算法框架的遗传操作都是基于TSP架构进行)
[TSPRoute,Chrom,VehicleNum]=InitPop(NIND,Sturct_instances(k).CityNum,Sturct_instances(k).Demand,Capacity,Travelcon,Sturct_instances(k).Distance,BatteryCap,Sturct_instances(k).ChargeStations_index);

%% 迭代
gen=1;
while gen <= MAXGEN
    %% 遗传算法封包运行
 [mindis,bestind,Chrom,VehicleNum,TSPRoute,mindisbygen] = GA_SDEVRP(Sturct_instances(k).Distance,Sturct_instances(k).Demand,Chrom,Capacity,Travelcon,VehicleNum,VehicleCost,GGAP,Pc,Pm,gen,TSPRoute,Sturct_instances(k).CityNum,mindis,bestind,BatteryCap,Sturct_instances(k).ChargeStations_index,ChargeStationNum,ChargeStationBatteryNum);

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
TextOutput(Sturct_instances(k).Distance,Sturct_instances(k).Demand,bestroute,Capacity,bestind,Sturct_instances(k).ChargeStations_index,ChargeStationNum,ChargeStationBatteryNum)  %显示最优路径
disp('-------------------------------------------------------------')


%% 迭代图
   % subplot(2, Instance_Layer, k); %绘制第k个图
   % plot(mindis,'LineWidth',2) %展示目标函数值历史变化
   % xlim([1 gen-1]) %设置 x 坐标轴范围
   % set(gca, 'LineWidth',1)
   % xlabel('Iterations')
   % ylabel('Min Distance(km)')
   % title('GA Optimization Process')
   % grid on;
    %% 绘制实际路线
   % DrawPath_pro(bestroute,Sturct_instances(k).City,Sturct_instances(k).ChargeStations_index,Instance_Layer,k)
end
   
 

