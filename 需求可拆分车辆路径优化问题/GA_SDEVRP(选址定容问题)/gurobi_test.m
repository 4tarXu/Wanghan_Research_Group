clear
clc
%% 小规模数据
d=[0,120,170,150,140,170,140,120,190];          %需求量
a=[0,912,825,65,727,15,621,170,255];            %左时间窗
b=[1236,967,870,146,782,67,702,225,324];        %右时间窗
E=a(1);                                         %配送中心左时间窗
L=b(1);                                         %配送中心右时间窗
s=[0,90,90,90,90,90,90,90,90];                  %服务时间
x=[81.5,87,75,85,89,77,76,87,73];               %横坐标
y=[41.5,37,53,52,41,58,45,53,38];               %纵坐标

d=[d,d(1)];                                     %体现出数学模型中的第n+1个节点，也就是配送中心
a=[a,a(1)];                                     %体现出数学模型中的第n+1个节点，也就是配送中心
b=[b,b(1)];                                     %体现出数学模型中的第n+1个节点，也就是配送中心
s=[s,s(1)];                                     %体现出数学模型中的第n+1个节点，也就是配送中心
x=[x,x(1)];                                     %体现出数学模型中的第n+1个节点，也就是配送中心
y=[y,y(1)];                                     %体现出数学模型中的第n+1个节点，也就是配送中心

axis=[x' y'];                                   %顾客坐标
h=pdist(axis);
Dij=squareform(h);                              %距离矩阵
%% 配送车辆和顾客数据
vNum=5;                                         %车数量
nodeNum=numel(a);                               %总节点数量
C=600;                                          %单车容量
%% 决策变量
Xijk=binvar(nodeNum,nodeNum,vNum,'full');       %i、j节点之间是否由第k辆车进行配送
Wik=sdpvar(nodeNum,vNum,'full');                %表示车辆k对i点的开始服务时间
M=1e7;                                          %足够大的数，对应公式（6）中的Mij
tol=1e-7;                                       %决策变量精确度
%% 目标函数，对应公式（1）
obj=0;
for i=1:nodeNum
    for j=1:nodeNum
        for k=1:vNum
            obj=obj+Dij(i,j)*Xijk(i,j,k);
        end
    end
end
f=obj;
%% 约束条件
F=[];
%每个需求点i都会被一辆车经过，对应公式（2）
for i=2:nodeNum-1
    F=[F;sum(Xijk(i,1,:))==0;sum(Xijk(i,i,:))==0;sum(sum(Xijk(i,:,:)))==1];
end
%每条配送路线从配送中心出发只能前往一个顾客点，对应公式（3）
for k=1:vNum
    F=[F;Xijk(1,1,k)==0;sum(Xijk(1,:,k))==1];
end
%流量平衡，对应公式（4）
for j=2:nodeNum-1
    for k=1:vNum
        F=[F;sum(Xijk(j,:,k))==sum(Xijk(:,j,k))];
    end
end
%每条配送路线都必须返回配送中心，对应公式（5）
for k=1:vNum
    F=[F;Xijk(nodeNum,nodeNum,k)==0;sum(Xijk(:,nodeNum,k))==1];
end
%时间连续不等式，对应公式（6）
for k=1:vNum
    for i=1:nodeNum
        for j=1:nodeNum
            F=[F;Wik(i,k)+s(i)+Dij(i,j)-Wik(j,k)<=(1-Xijk(i,j,k))*M];
        end
    end
end
%顾客时间窗约束，对应公式（7）
for k=1:vNum
    for i=2:nodeNum-1
        F=[F;a(i)*sum(Xijk(i,:,k))<=Wik(i,k)];
        F=[F;Wik(i,k)<=b(i)*sum(Xijk(i,:,k))];
    end
end
%配送中心时间窗约束，对应公式（8）
for k=1:vNum
    for i=[1,nodeNum]
        F=[F;E<=Wik(i,k)];
        F=[F;Wik(i,k)<=L];
    end
end
%装载量约束，对应公式（9）
for k=1:vNum
    load=0;
    for i=2:nodeNum-1
        load=load+d(i)*sum(Xijk(i,:,k));
    end
    F=[F;load<=C]; %每个回路上的需求量之和小于车的容量
end
%% 参数配置 'solver','cplex'  'verbose',0,'solver','cplex'
ops=sdpsettings();
%% 求解问题
sol=solvesdp(F,f,ops);
f=double(f);
Xijk=double(Xijk);
Wik=double(Wik);
%% 画出配送路线图
plot(axis(2:nodeNum-1,1),axis(2:nodeNum-1,2),'ro');hold on;
plot(axis(1,1),axis(1,2),'pm');hold on;
%在各个节点上标出对应的节点编号
for i=1:nodeNum
    if i~=nodeNum
        text(axis(i,1)-0.1,axis(i,2)+0.5,num2str(i-1));
    else
        text(axis(i,1)-0.1,axis(i,2)-0.5,num2str(i-1));
    end
end
%根据Xijk的值，将对应节点连接
color=hsv(vNum);
for i=1:nodeNum
    for j=1:nodeNum
        for k=1:vNum
            if abs(Xijk(i,j,k)-1)<1e-5
                plot([axis(i,1),axis(j,1)],[axis(i,2),axis(j,2)],'-','color',color(k,:),'linewidth',1);
            end
        end
    end
end
%% 将最终的决策变量Xijk转换为具体的配送方案
VC=cell(vNum,1);                    %配送方案
for k=1:vNum
    [row,col]=find(abs(Xijk(:,:,k)-1)<tol);
    n=numel(row);
    route=zeros(1,n+1);
    route(1)=0;                     %起点为配送中心
    route(end)=0;           %终点为配送中心
    for i=1:n
        if i==1
            next_index=find(row==1);
        else
            next=col(next_index);
            next_index=find(row==next);
            route(i)=next-1;
        end
    end
    VC{k,1}=route;
    disp(['车辆',num2str(k),'的路径如下：']);
    disp(route)
end
