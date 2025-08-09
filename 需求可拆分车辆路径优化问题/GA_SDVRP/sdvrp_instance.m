function  [City,Demand,Distance]=read_sdvrp_instance(instance,CustomerNum)
    % 读取算例实例文件并生成City.mat、Demand.mat和Distance.mat
    
    
    %% 以下是根据CustomerNum生成算例测试的代码 
    InstanceNum = CustomerNum+1; 
    Size_instance = size(instance,1)-1;   % 获取算例规模(不含0点，即Depot节点)

    % 随机抽取CustomerNum个客户点
    Customer_select = randperm(Size_instance,CustomerNum);

    % 获取城市坐标(含Depot节点)
    City = [instance(1,2:3); instance(Customer_select,2:3)];
    % 获取客户需求量
    Demand = [instance(1,4); instance(Customer_select,4)];
    
    % 计算距离矩阵(欧氏距离)
    Distance = zeros(InstanceNum,InstanceNum);
         for i = 1:InstanceNum
               for j = 1:InstanceNum
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
