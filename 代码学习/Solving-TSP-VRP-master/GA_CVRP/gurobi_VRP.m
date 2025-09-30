%% 保持良好的工作空间清空习惯
clc
clear all
close all

%% 加载数据
load('../test_data/City.mat')	      %需求点经纬度，用于画实际路径的XY坐标
load('../test_data/Distance.mat')	  %距离矩阵
load('../test_data/Demand.mat')       %需求量
load('../test_data/Capacity.mat')     %车容量约束

%% 输入建模参数
M=1e7; % 充分大正数M，构建约束条件用

%% 处理并获得数据中所需的参数索引

CityNum = size(City,1); % 节点总数量(包含Depot)
CustomerNum = CityNum-1; % 客户点总数量
VehicleNum = 5; %设置车辆最大可用数量

%% 定义决策变量
Xijk=binvar(CityNum,CityNum,VehicleNum,'full');       %i、j节点之间是否由第k辆车进行配送
u = sdpvar(CityNum,VehicleNum,'full'); 

%% 定义目标函数：VRP问题中目标函数 = 决策变量 * 距离矩阵 
 obj=0;
 for i=1:CityNum
     for j=1:CityNum
         for k=1:VehicleNum
             obj=obj+Distance(i,j)*Xijk(i,j,k);
         end
     end
 end
 ObjectFuntion = obj;

 %% 定义约束条件
    Subject_To = []; %初始化约束条件集合

    % (1)客户点访问约束(每个客户点有且仅有一辆车提供服务)
    for j = 2:CityNum
         Subject_To = [Subject_To;sum(sum(Xijk(:,j,:))) <= 1];
    end

    % (2)车辆出发约束(每辆车必须从仓库出发，前往某个客户点）
    for k = 1:VehicleNum
         Subject_To = [Subject_To;sum(Xijk(1,2:CityNum,k)) <= 1]; %注意这里":"可能需要修改为从客户点开始
    end

    % (3)车辆返回约束(每辆车必须最终必须返回仓库)
    for k = 1:VehicleNum
        Subject_To = [Subject_To;sum(Xijk(2:CityNum,1,k))]; %注意这里":"可能需要修改为从客户点开始
    end

    % (4)流量守恒约束(每辆车在每个客户点进入流量守恒)
    for k = 1:VehicleNum
        for j = 2:CityNum
            Subject_To = [Subject_To;sum(Xijk(:,j,k)) == sum(Xijk(j,:,k))];
        end
    end

    % (5)载重量约束(每个客户点服务总量不能够超过最大载重量)
    for k = 1:VehicleNum
        Load = 0;
        for i = 2:CityNum
            Load = Load + Demand(i) * sum(Xijk(i,:,k));
        end
        Subject_To = [Subject_To; Load <= Capacity];
    end

    % (6)子回路消除约束(MTZ法)
    for i = 2:CityNum
        for j = 2:CityNum
            if i ~=j
                for k = 1:VehicleNum
                   Subject_To = [Subject_To;u(i,k) - u(j,k) + M * Xijk(i,j,k) <= M-1];
                end
            end
        end
    end

%% 求解器参数配置
ops=sdpsettings();

%% 调用求解器求解

Solution = solvesdp(Subject_To,ObjectFuntion,ops);
ObjectFuntion = double(ObjectFuntion);
Xijk = double(Xijk);
u = double(u);

% 求解结果可视化






% %% 画出配送路线图
% plot(axis(2:nodeNum-1,1),axis(2:nodeNum-1,2),'ro');hold on;
% plot(axis(1,1),axis(1,2),'pm');hold on;
% %在各个节点上标出对应的节点编号
% for i=1:nodeNum
%     if i~=nodeNum
%         text(axis(i,1)-0.1,axis(i,2)+0.5,num2str(i-1));
%     else
%         text(axis(i,1)-0.1,axis(i,2)-0.5,num2str(i-1));
%     end
% end
% %根据Xijk的值，将对应节点连接
% color=hsv(vNum);
% for i=1:nodeNum
%     for j=1:nodeNum
%         for k=1:vNum
%             if abs(Xijk(i,j,k)-1)<1e-5
%                 plot([axis(i,1),axis(j,1)],[axis(i,2),axis(j,2)],'-','color',color(k,:),'linewidth',1);
%             end
%         end
%     end
% end
% %% 将最终的决策变量Xijk转换为具体的配送方案
% VC=cell(vNum,1);                    %配送方案
% for k=1:vNum
%     [row,col]=find(abs(Xijk(:,:,k)-1)<tol);
%     n=numel(row);
%     route=zeros(1,n+1);
%     route(1)=0;                     %起点为配送中心
%     route(end)=0;           %终点为配送中心
%     for i=1:n
%         if i==1
%             next_index=find(row==1);
%         else
%             next=col(next_index);
%             next_index=find(row==next);
%             route(i)=next-1;
%         end
%     end
%     VC{k,1}=route;
%     disp(['车辆',num2str(k),'的路径如下：']);
%     disp(route)
% end





% ----
% %% 小规模数据
% d=[0,120,170,150,140,170,140,120,190];          %需求量
% a=[0,912,825,65,727,15,621,170,255];            %左时间窗
% b=[1236,967,870,146,782,67,702,225,324];        %右时间窗
% E=a(1);                                         %配送中心左时间窗
% L=b(1);                                         %配送中心右时间窗
% s=[0,90,90,90,90,90,90,90,90];                  %服务时间
% x=[81.5,87,75,85,89,77,76,87,73];               %横坐标
% y=[41.5,37,53,52,41,58,45,53,38];               %纵坐标
% 
% d=[d,d(1)];                                     %体现出数学模型中的第n+1个节点，也就是配送中心
% a=[a,a(1)];                                     %体现出数学模型中的第n+1个节点，也就是配送中心
% b=[b,b(1)];                                     %体现出数学模型中的第n+1个节点，也就是配送中心
% s=[s,s(1)];                                     %体现出数学模型中的第n+1个节点，也就是配送中心
% x=[x,x(1)];                                     %体现出数学模型中的第n+1个节点，也就是配送中心
% y=[y,y(1)];                                     %体现出数学模型中的第n+1个节点，也就是配送中心
% 
% axis=[x' y'];                                   %顾客坐标
% h=pdist(axis);
% Dij=squareform(h);                              %距离矩阵
% %% 配送车辆和顾客数据
% vNum=5;                                         %车数量
% nodeNum=numel(a);                               %总节点数量
% C=600;                                          %单车容量


% %% 决策变量
% Xijk=binvar(nodeNum,nodeNum,vNum,'full');       %i、j节点之间是否由第k辆车进行配送
% Wik=sdpvar(nodeNum,vNum,'full');                %表示车辆k对i点的开始服务时间
% M=1e7;                                          %足够大的数，对应公式（6）中的Mij
% tol=1e-7;                                       %决策变量精确度
