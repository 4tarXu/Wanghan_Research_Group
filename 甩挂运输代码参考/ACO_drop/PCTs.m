%#ok<INUSD,STOUT>
%% 待解决问题
%1 车容量控制
%2 第一类节点选择概率
%3 第二类节点选择概率
%4 第二类节点的2-opt优化





%%
%%%%%%%%%%%%%%%参数说明%%%%%%%%%%%%%%%%%%%%%%
%ACO-PCTS
%vechile1:第一类节点被安排的车辆编号
%vechile2:第二类节点被安排的车辆编号
%M:最大允许车辆数
%m:种群规模
%Tau1:第一类需求点间信息素浓度
%Tau2:第二类需求点beta到第一类需求点信息素浓度
%Alpha1:Tau1控制参数
%Alpha1:Tau2控制参数
%Eta1:第一类需求点间的能见度（取距离的倒数）
%Eta2:第二类需求点到第一类需求点的能见度（取距离的倒数）
%Beta1:Eta1控制参数
%Beta2:Eta2控制参数
%gama1:节约矩阵U的控制参数（第一类点间）
%gama2:节约矩阵U的控制参数（第二类beta到第一类）
%Rho1:信息素浓度更新比例1-Rho（第一类点间）
%Rho2:信息素浓度更新比例1-Rho（第二类beta到第一类）
%NC_max:最大迭代次数
%Q:信息素更新量Q／L（路径长度）
%W：车辆最大载重量
%qq:以一个极低的概率直接选择最大选择概率的节点被选择
%C1：第一类节点坐标
%C2：第二类beta坐标
%t1:每个节点的货物量（第一类）
%t1:每个节点的货物量（第二类beta）
%D1：任意两个节点间的距离矩阵（第一类间）
%D2：任意两个节点间的距离矩阵（第二类beta道第一类）
%%
%%%%%%%%%%%%%%%%%参数初始化%%%%%%%%%%%%%%%%%%%%%%%
clc;
clear all;
close all;%这行删掉时，可以把多次的图放到一次画
m=20;Alpha1=1;Beta1=2;gama1=1;omega1=1;%Beta取2，搜索到了810以下的最优解；gama取2，809
M=5 ;Alpha2=1;Beta2=2;gama2=1;omega2=1;
Rho=0.05;NC_max=50;Q=200;W=100;qq=0.05;
%----------------给出节点信息--------------
C1=[0 0
20 0
25 10
10 20];%各个第一类节点坐标
t1=[0 20 25 15];%各个第一类节点的需求量

C2=[30 20
15 -10
15 -20];%各个第二类beta节点坐标
t2=[10 15 10];%各个第二类节点beta的需求量
%--------------画出节点散点图-------------
scatter(C1(:,1),C1(:,2),'r')%画出个点位置散点图
hold on
scatter(C2(:,1),C2(:,2),'b')
%%
%--------------分别计算距离矩阵和节约矩阵--------
%---第一类点间的距离矩阵
N1=size(C1,1); 
D1=zeros(N1,N1);
for i=1:N1 
for j=1:N1 
if i~=j 
D1(i,j)=((C1(i,1)-C1(j,1))^2+(C1(i,2)-C1(j,2))^2)^0.5; 
else 
D1(i,j)=0; 
end 
D1(j,i)=D1(i,j); 
end 
end 
%------第一类点间节约矩阵
%U：任意两个节点直接相连相对于分别运输的节约量
U1=zeros(N1,N1);
for i=1:N1 
for j=1:N1
if i~=j 
U1(i,j)=D1(i,1)+D1(j,1)-D1(i,j);
else 
U1(i,j)=0; 
end 
U1(j,i)=U1(i,j); 
end 
end 
%对节约矩阵进行修正，防止第一步选择时报错
U1(:,1)=1;
U1(1,:)=1;

%---第二类点beta到第一类点的距离矩阵
N2=size(C2,1); 
D2=zeros(N1,N2);%所有第一类点到第二类点beta的距离， 注意！！！处理中心为第一个第一类点
for i=1:N1 
for j=1:N2 
D2(i,j)=((C1(i,1)-C2(j,1))^2+(C1(i,2)-C2(j,2))^2)^0.5; 
end 
end 

%%
%-------------继续初始化控制参数------
%能见度参数设置为距离的倒数
Eta1=1./D1; 
Eta2=1./D2; 
%初始化各个节点的信息素浓度为1
Tau1=0.01*ones(N1,N1); 
Tau2=0.01*ones(N1,N2); 
%初始化路径集
Tabu1=zeros(m,N1+20);%节点1（处理中心）可以多次访问，其他节点访问一次， 20为可以接受最大车辆数
Tabu2=zeros(m,N2);%第二类需求点beta路径集，对应相应第二类需求点对应的第一类节点编号
%初始化各个代的最佳路径
G_best_route1=zeros(NC_max,N1+20); 
G_best_route2=zeros(NC_max,N2);
%初始化各个代的最短路径为无穷大
G_best_length=inf.*ones(NC_max,1); 
G_best_length2=inf.*ones(NC_max,1); 
%初始化各个代的平均路径长度
length_ave=zeros(NC_max,1);

C_best_length=10e9;%目前为止的最优解
C_best_length2=10e9;%目前为止的最优解

%初始化迭代次数
NC=1; 
%初始化当前自营物流车辆载重为0
load_w=zeros(M,1);
%%
%开始迭代寻优
while NC<=NC_max%当迭代次数不超过最大迭代次数
    Tabu1=zeros(m,N1); 
    Tabu2=zeros(m,N2);
    load_w=zeros(M,1);
    %设置所有路径的起点均为1（配送中心）
    Tabu1(:,1)=ones(m,1);
    %每只蚂蚁的迭代循环
    for i=1:m
        %%
        ii=1;%标记当前使用车辆编号
        vehicle1=zeros(N1,1);
        vehicle2=zeros(N2,1);
     %------------第一类点的路径安排----------
     %---初始化路径集等信息
     visited1=Tabu1(i,:);%根据Tabu输出当前蚂蚁的已访问节点的集合
    visited1=visited1(visited1>0);%已访问节点集合的过滤操作
    to_visit1=setdiff(1:N1,visited1);%根据已访问节点集合筛选出未访问节点集合
    j=1;%j代表决策次数
          while j<=N1+10%次数加的这个10未最大利用车辆数目
                  if ~isempty(to_visit1)%当未访问节点集合不为空集时
  %-----------------                    
        TTabu1=visited1;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%需要改进，要求选择概率跟第二类节点相关
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if TTabu1(end)==1%如果最后一个节点是1，则仍采用节约矩阵进行选择
%概率选择操作
    for k=1:length(to_visit1)%对于所有的未访问节点集合
        %计算每个未访问节点，计算吸引价值
  x1(k)=(Tau1(visited1(end),to_visit1(k))^Alpha1)*(U1(visited1(end),to_visit1(k))^gama1);
    end   
else %如果不为1，则计算NU，并引入计算
    
  for k=1:length(to_visit1)%对于所有的未访问节点集合
 NU1=D1(TTabu1(end-1),TTabu1(end))+D1(TTabu1(end-1),to_visit1(k))-D1(TTabu1(end),to_visit1(k));
  x1(k)=(Tau1(visited1(end),to_visit1(k))^Alpha1)*(U1(visited1(end),to_visit1(k))^gama1)*(NU1^omega1);
    end   
end
        ww=rand;
if ww<qq
    Select1=find(max(x1));%以一个极低的概率选择最大适应度点为被选择点
    %Tabu(i,length(visited(visited>0))+1)=to_visit(Select(1)); 
else
x1=x1/(sum(x1)); %计算每个节点的转移概率
xcum1=cumsum(x1); %每个节点转移概率的累加和
Select1=find(xcum1>=rand);%通过轮盘赌的方法确定被选择节点
%Tabu(i,length(visited(visited>0))+1)=to_visi(Select(1)); 
end
%节点选择后的车容更新
if isempty(Select1)%被选择集合为空集(测试中未出现这种情况)
    Select1=1;
    fprintf(' ！！！!');
   load_w(ii)=load_w(ii)+t1(Select1);%更新当前车容量
else
load_w(ii)=load_w(ii)+t1(to_visit1(Select1(1)));%更新当前车容量
st1=t1(to_visit1(Select1(1)));%记录一下增加量
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%需要改进，不能等到车容满了才重制车辆%%%%%%%%%%%%%%%%%%%
%%%%%%可以更改为估计容量%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if load_w(ii)>W %如果车辆载重量待遇最大载重量
    Select1=1;%车辆开回车场
       j=j-1;%决策次数减1
      load_w(ii)=load_w(ii)-st1;
    ii=ii+1;%初始化车辆载重量
   Tabu1(i,length(visited1)+1)=1;%更新路径集中下一个节点为配送中心1
else
Tabu1(i,length(visited1)+1)=to_visit1(Select1(1)); %更新路径集
vehicle1(to_visit1(Select1(1)))=ii;%记录各个节点安排车辆编号
end
      
        
  %--------------      
      
                  end%是否还存在未访问节点的end
                  
    visited1=Tabu1(i,:);%更新已访问节点集合
    visited1=visited1(visited1>0);%过滤已访问节点集合
    to_visit1=setdiff(1:N1,visited1);%更新未访问节点集合
    x1=[];%初始化节点选择概率
            if visited1(end)~=1%如果最后一个节点不为1，则手动更新为1
   Tabu1(i,1:(length(visited1)+1))=[visited1,1];
            end
            TTabu1=visited1;
        j=j+1;%决策次数+1
          end%决策次数j的end

          %----------第一类点安排结束
          %% ---------第二类点路径选择
          visited2=Tabu2(i,:);%对应二类节点编号
          visited2=visited2(visited2>0);%输出当前已访问节点
          to_visit2=setdiff(1:N2,visited2);%筛选出未访问节点
          j=1;
           while j<=N2%未完成一条路径的决策
          if ~isempty(to_visit2)%如果未访问集合不为空
              %计算第一个未访问第二类点到所有第一类点的选择概率
              T_visited=visited1(visited1>1);%筛选所有可访问第一类点
              for k=1:length(T_visited)
                 x2(k)=(Tau2(T_visited(k)^Alpha2,to_visit2(1)))*(Eta2(T_visited(k),to_visit2(1))^Beta2);%信息素*启发因子*节约矩阵  
              end
               ww=rand;
     if ww<qq
    Select2=find(max(x2));%以一个非常小的概率直接采用选择概率最高的节点进行下一节点选择
    %Tabu(i,length(visited(visited>0))+1)=to_visit(Select(1)); 
else
x2=x2/(sum(x2));
%按概率原则选取下一个城市 
xcum=cumsum(x2); 
Select2=find(xcum>=rand);%%%%%%%%%轮盘赌方法进行选择下一个选择节点
%Tabu(i,length(visited(visited>0))+1)=to_visi(Select(1)); 
     end 
     
     
load_w(vehicle1(Select2(1)+1))=load_w(vehicle1(Select2(1)+1))+t2(j);%更新第二类点选择的第一类点所在车辆的车容量
     while load_w(vehicle1(Select2(1)+1))>W %如果车容量超过限制
         
         load_w(vehicle1(Select2(1)+1))=load_w(vehicle1(Select2(1)+1))-t2(j);%还原车容量
     x2(Select2(1))=0;%设被选择点的转移概率为0
     %--------进行新一轮的轮盘赌--------
     ww=rand;
     if ww<qq
    Select2=find(max(x2));%以一个非常小的概率直接采用选择概率最高的节点进行下一节点选择
    %Tabu(i,length(visited(visited>0))+1)=to_visit(Select(1)); 
else
x2=x2/(sum(x2)); 
%按概率原则选取下一个城市 
xcum=cumsum(x2); 
Select2=find(xcum>=rand);%%%%%%%%%轮盘赌方法进行选择下一个选择节点
%Tabu(i,length(visited(visited>0))+1)=to_visi(Select(1)); 
     end 
     load_w(vehicle1(Select2(1)+1))=load_w(vehicle1(Select2(1)+1))+t2(j);%重新选择后的载重量
     end
     vehicle2(j)=Select2(1)+1;
       Tabu2(i,length(visited2)+1)=T_visited(Select2(1));
      visited2=[visited2 j];%访问集合加入i
    to_visit2=setdiff(1:N2,abs(visited2));%未访问集合中除去点i        
     
   
     
     
     
     
     
%    if isempty(Select2)
%     X_visited=x2(x2>0);%所有选择概率大于0的点
% Tabu2(i,length(visited2)+1)=T_visited(X_visited(end));%如果没有点被选择，则选择已访问集合当中的倒数第一个选择概率不为0的节点。
% visited2=[visited2 j];%访问集合加入i
% to_visit2=setdiff(1:n,abs(visited2));%未访问集合中除去点i
%    else     
%     Tabu2(i,length(visited2)+1)=T_visited(Select2(1));
%      visited2=[visited2 j];%访问集合加入i
%    to_visit2=setdiff(1:N2,abs(visited2));%未访问集合中除去点i
%    end           
  
 
    
    
    
    
    
    
              
              
          end
          j=j+1;
           end
           
           
       load_w=zeros(M,1);%初始化车容量      
    end%蚂蚁编号m的end
    
    
    %% 第一类点局部更新策略
L1=zeros(m,1); 
for i=1:m 
MM=Tabu1(i,:); 
R=MM(MM>0);
for j=1:(length(R)-1)
L1(i)=L1(i)+D1(R(j),R(j+1)); 
end 
end 

G_best_length(NC)=min(L1); 
pos=find(L1==G_best_length(NC)); 
G_best_route1(NC,1:length(Tabu1(pos(1),:)))=Tabu1(pos(1),:);
%%2-opt局部搜索策略
select=find(G_best_route1(NC,:)==1);
FF=[];
LM=0;
for a=1:(length(select)-1)
   y_G_best_route1=G_best_route1(NC,select(a):select(a+1));
   al=length(y_G_best_route1);
   T=zeros((length(select)-1),1);
   for d=1:(al-1)
       T(a)=T(a)+D1(y_G_best_route1(d),y_G_best_route1(d+1));
   end
   for b=2:(al-1)
       for c=(b+1):(al-1)
           DD=y_G_best_route1;
           temp1=DD(b);
           temp2=DD(c);
           DD(b)=temp2;
           DD(c)=temp1;
           TT=zeros(1);
           for d=1:(al-1)
       TT=TT+D1(DD(d),DD(d+1));
           end
           if TT<T(a)
               T(a)=TT;
            y_G_best_route1=DD;
           end
       end
   end
   if a>=2
       y_G_best_route1=y_G_best_route1(2:al);
   end
   FF=[FF,y_G_best_route1];
   LM=LM+T(a);
end
   G_best_length(NC)=LM;
   G_best_route1(NC,1:length(FF))=FF;
   FF=[];
   LM=0;
   %%2-opt????????
length_ave(NC)=mean(L1); 

if (G_best_length(NC) < C_best_length);
            C_best_length=G_best_length(NC);
            C_best_route1=G_best_route1(NC,:);
            C_best_route1=C_best_route1(C_best_route1>0);
            %有更优解产生,设置标志
            FoundBetter=1; 
end
%-----------输出第二类点的最优距离
L2=zeros(m,1); 
for i=1:m 
MM=Tabu2(i,:); 
R=MM(MM>0);
for j=1:(length(R))
L2(i)=L2(i)+D2(R(j),j); %第一类点到对应第二类点的距离
end 
end 

G_best_length2(NC)=min(L2); 
pos=find(L2==G_best_length2(NC)); 
G_best_route2(NC,1:length(Tabu2(pos(1),:)))=Tabu2(pos(1),:);

if (G_best_length2(NC) < C_best_length2);
            C_best_length2=G_best_length2(NC);
            C_best_route2=G_best_route2(NC,:);
            C_best_route2=C_best_route2(C_best_route2>0);
            %有更优解产生,设置标志
            FoundBetter=1; 
end



NC=NC+1
  %% 信息素更新策略 
  %--------------第一类点间
    Delta_Tau1=zeros(N1,N1); 
 MM=G_best_route1(NC-1,:);
R=MM(MM>0);
dbQ1=1/G_best_length(NC-1,:);  
cbQ1=1/C_best_length;   
 %g更新当前最优解
for j=1:(length(C_best_route1)-1) 
Delta_Tau1(C_best_route1(j),C_best_route1(j+1))=Delta_Tau1(C_best_route1(j),C_best_route1(j+1))+cbQ1; %更新当前最优解
Delta_Tau1(C_best_route1(j+1),C_best_route1(j))=Delta_Tau1(C_best_route1(j),C_best_route1(j+1));
end 

for j=1:(length(R)-1) 
Delta_Tau1(R(j),R(j+1))=Delta_Tau1(R(j),R(j+1))+dbQ1; %只更新最优解
Delta_Tau1(R(j+1),R(j))=Delta_Tau1(R(j),R(j+1));
end     
    Tau1=(1-Rho).*Tau1+Delta_Tau1;
 %--------------  第二类点信息素的更新   
   Delta_Tau2=zeros(N1,N2); 
  MM=G_best_route2(NC-1,:);
R=MM(MM>0);
dbQ2=1/G_best_length2(NC-1,:);  
cbQ2=1/C_best_length2;  
 
 for j=1:(length(R)) 
Delta_Tau2(R(j),j)=Delta_Tau2(R(j),j)+dbQ2; %只更新最优解
end     
    Tau2=(1-Rho).*Tau2+Delta_Tau2;
 
 
 
 
end%迭代次数的end

  
    
    
    
    
    
    
    
    
    
    
    
    
    
%输出结果
Pos=find(G_best_length==min(G_best_length)); 
best_route1=G_best_route1(Pos(1),:);
best_length=G_best_length(Pos(1))
best_route1=best_route1(best_route1>0)

Pos=find(G_best_length2==min(G_best_length2)); 
best_route2=G_best_route2(Pos(1),:);
best_length2=G_best_length2(Pos(1))
best_route2=best_route2(best_route2>0)
%画图
subplot(1,2,1) %????????1*2????????????????1??
plot([C1(best_route1,1)],[C1(best_route1,2)],'-*')
hold on 
for i=1:N2
x=[C1(best_route2(i),1) C2(i,1)];
y=[C1(best_route2(i),2) C2(i,2)];
plot(x,y,'r-');
hold on
end


subplot(1,2,2) 
plot(G_best_length) 
hold on 
plot(length_ave) 