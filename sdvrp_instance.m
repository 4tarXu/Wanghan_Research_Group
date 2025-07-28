function  [City,Demand,Distance,ChargeStations_index,CityNum]=read_sdvrp_instance(instance,CustomerNum,ChargeStationNum)
    % 读取算例实例文件并生成City.mat、Demand.mat和Distance.mat
    
    
    %% 以下是根据CustomerNum生成算例测试的代码 
    % 一、生成客户数据
    InstanceNum = CustomerNum+1; 
    Size_instance = size(instance,1)-1;   % 获取算例规模(不含0点，即Depot节点)

    % 随机抽取CustomerNum个客户点
    Customer_select = randperm(Size_instance,CustomerNum);

    % 获取城市坐标(含Depot节点)
    City = [instance(1,2:3); instance(Customer_select,2:3)];
    % 获取客户需求量
    Demand = [instance(1,4); instance(Customer_select,4)];
    
    % 二、生成充电站数据
    % 1) 获取客户覆盖区域
      X_left  = min(City(:,1)-0.01);
       X_right = max(City(:,1)+0.01);
       X_up    = max(City(:,2)+0.01);
       X_down  = min(City(:,2)-0.01);

    % 充电节点索引编号
    ChargeStations_index = [size(City,1)+1:size(City,1)+ChargeStationNum];

    % 生成充电站位置
    ChargeStation_coordinite = zeros(ChargeStationNum,2); % 预分配内存，储存充电站位置信息
         for i = 1:ChargeStationNum
              ChargeStation_coordinite(i,:) = [(X_left + (X_right-X_left)*rand()),(X_down + (X_up-X_down)*rand())];
         end
   
    % 生成充电站需求量(默认为0，即充电站没有配送任务)
    ChargeStations_demand = zeros(ChargeStationNum,1);

    % 三、客户与充电站数据合并：
    % 充电站坐标加入城市变量
    City = [City;ChargeStation_coordinite]; 

    % 充电站需求加入需求变量
    Demand = [Demand;ChargeStations_demand];

    % 四、计算距离矩阵(欧氏距离)
    % 节点个数
        CityNum=size(City,1)-1;    %需求点个数

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




    %% 以下是采用原始算例进行算法测试的代码，不改变客户点顺序
   
    % % 获取城市坐标和需求量
    % City= instance(:,2:3);
    % Demand = instance(:,4);
    % 
    % % 计算距离矩阵(欧式距离)
    % Distance = zeros(Size_instance, Size_instance);
    % for i = 1:Size_instance
    %     for j = 1:Size_instance
    %         if i ~= j
    %             % 计算欧式距离
    %             dx = City(i, 1) - City(j, 1);
    %             dy = City(i, 2) - City(j, 2);
    %             Distance(i, j) = sqrt(dx^2 + dy^2);
    %         end
    %     end
    % end
