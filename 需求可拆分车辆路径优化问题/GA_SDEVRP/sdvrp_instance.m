function  [Sturct_instances,City,Demand,Distance,ChargeStations_index,CityNum]=read_sdvrp_instance(instance,CustomerNum,ChargeStationNum,ChargeStationBatteryNum,Instance_Layer)

    
%% 以下是根据CustomerNum生成算例测试的代码 
    % 一、提取原始案例客户数据
    InstanceNum = CustomerNum+1;          % 问题规模(不含换电站)
    Size_instance = size(instance,1)-1;   % 获取算例规模(不含0点，即Depot节点)
    Sturct_instances(Instance_Layer) = struct('City', [], 'Demand', [],'Distance',[],'ChargeStations_index',[],'CityNum',[]);% 预分配结构体数组

%% 换电站生成部分(不同案例使用相同的换电站)
    % 1) 获取客户点覆盖区域（从原始案例数据获取）
       X_left  = min(instance(:,1)-0.01);
       X_right = max(instance(:,1)+0.01);
       X_up    = max(instance(:,2)+0.01);
       X_down  = min(instance(:,2)-0.01);

    % 初始化充电站索引编号   
    ChargeStations_index = [InstanceNum+1:InstanceNum+ChargeStationNum*ChargeStationBatteryNum];

    % 生成充电站位置(错误待修正：每次都生成了要求数量的充电站位置，而不是相同位置重复生成)
    ChargeStation_coordinite = zeros(ChargeStationNum,2); % 预分配内存，储存充电站位置信息
         for i = 1:ChargeStationNum
              ChargeStation_coordinite(i,:) = [(X_left + (X_right-X_left)*rand()),(X_down + (X_up-X_down)*rand())];
         end
    % 生成充电站需求量(默认为0，即充电站没有配送任务)
    ChargeStations_demand = zeros(ChargeStationNum*ChargeStationBatteryNum,1);
    ChargeStations_XY = []; % 初始化换电站坐标存储器

    for i = 1:ChargeStationBatteryNum
    % 充电站坐标加入存储器
        ChargeStations_XY = [ChargeStations_XY;ChargeStation_coordinite]; 

    end


%% 生成Instance_Layer组数据

for k = 1:Instance_Layer
    City = []; %初始化城市数据 
    Demand = []; %初始化需求数据

    % ----------------  客户点数据生成  ----------------
    % 随机抽取CustomerNum个客户点
      Customer_select = randperm(Size_instance,CustomerNum);

    % 获取城市坐标(含Depot节点)
      City = [instance(1,2:3); instance(Customer_select,2:3)];
    % 获取客户需求量
      Demand = [instance(1,4); instance(Customer_select,4)]; 
    % 充电站坐标加入城市变量
      City = [City;ChargeStations_XY];    
    % 充电站需求加入需求变量
      Demand = [Demand;ChargeStations_demand];
    % 计算问题规模(结果为算例规模减1，即不包含Depot)
      CityNum=size(City,1)-1;    %需求点个数
    % 计算距离矩阵
      Distance = zeros(CityNum+1,CityNum+1);
         for i = 1:CityNum+1
               for j = 1:CityNum+1
                     if i ~= j
                        % 计算欧式距离
                            dx = City(i, 1) - City(j, 1);
                            dy = City(i, 2) - City(j, 2);
                            Distance(i, j) = sqrt(dx^2 + dy^2);
                    end
                end
        end

    % 数据合并并存储到结构体数组
    Sturct_instances(k).City = City; % 城市数据
    Sturct_instances(k).Demand = Demand; % 需求数据
    Sturct_instances(k).ChargeStations_index = ChargeStations_index;
    Sturct_instances(k).CityNum = CityNum;
    Sturct_instances(k).Distance = Distance;
   
end




