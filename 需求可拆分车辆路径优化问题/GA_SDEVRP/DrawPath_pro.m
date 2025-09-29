function DrawPath_pro(route, City, ChargeStations_index, Instance_Layer, k)
%% 画路径函数
% 输入
% route     待画路径   
% City      各城市坐标位置

subplot(2, Instance_Layer, k + Instance_Layer); % 绘制第k个图

hold on % 保留当前坐标区中的绘图
box on % 在坐标区周围显示框轮廓

% 设置坐标轴范围，增加一些边距
x_margin = (max(City(:,1)) - min(City(:,1))) * 0.1;
y_margin = (max(City(:,2)) - min(City(:,2))) * 0.1;
xlim([min(City(:,1)) - x_margin, max(City(:,1)) + x_margin])
ylim([min(City(:,2)) - y_margin, max(City(:,2)) + y_margin])

% 画配送中心点
plot(City(1,1), City(1,2), 'bp', 'MarkerFaceColor', 'r', 'MarkerSize', 15)

% 画需求点
plot(City(2:end,1), City(2:end,2), 'o', 'color', [0.5,0.5,0.5], 'MarkerFaceColor', 'g')

% 在绘制需求点后，添加充电站标记
charge_idx = ismember(1:size(City,1), ChargeStations_index);
plot(City(charge_idx,1), City(charge_idx,2), 's', 'MarkerFaceColor', 'b', 'MarkerSize', 12);

% 添加点编号
for i = 1:size(City,1)
    text(City(i,1) + 0.002, City(i,2) - 0.002, num2str(i-1));
end

axis equal % 使XY轴的刻度比例一致

% 使用数据坐标绘制箭头（替代annotation方法）
A = City(route + 1, :);
arrcolor = rand(1, 3); % 箭头颜色随机

for i = 2:length(A)
    % 计算线段的方向和长度
    dx = A(i, 1) - A(i-1, 1);
    dy = A(i, 2) - A(i-1, 2);
    
    % 计算箭头头部位置（线段末端向前缩进一点）
    arrow_length = sqrt(dx^2 + dy^2);
    if arrow_length > 0
        shrink_factor = 0.1; % 控制箭头头部与点的距离
        head_x = A(i, 1) - dx * shrink_factor / arrow_length;
        head_y = A(i, 2) - dy * shrink_factor / arrow_length;
        
        % 绘制线段
        plot([A(i-1, 1), head_x], [A(i-1, 2), head_y], 'Color', arrcolor, 'LineWidth', 2);
        
        % 绘制箭头头部
        arrow_size = min(arrow_length * 0.1, 0.02); % 动态箭头大小
        quiver(head_x, head_y, dx * 0.01, dy * 0.01, ...
               'MaxHeadSize', arrow_size * 50, 'Color', arrcolor, ...
               'LineWidth', 2, 'AutoScale', 'off');
    else
        % 如果两点重合，只画一个点
        plot(A(i, 1), A(i, 2), 'o', 'Color', arrcolor, 'MarkerSize', 6);
    end
    
    % 下一个车辆路线换颜色
    if route(i) == 0
        arrcolor = rand(1, 3); % 颜色RGB三元组
    end
end

% 或者使用更简单的箭头绘制方法（取消注释以下代码并注释上面的箭头绘制部分）
% for i = 2:length(A)
%     % 绘制线段
%     plot([A(i-1, 1), A(i, 1)], [A(i-1, 2), A(i, 2)], 'Color', arrcolor, 'LineWidth', 2);
%     
%     % 下一个车辆路线换颜色
%     if route(i) == 0
%         arrcolor = rand(1, 3);
%     end
% end
% 
% % 在线段末端添加箭头标记
% for i = 2:length(A)
%     if i == length(A) || route(i+1) == 0 % 在线段末端或路径终点添加箭头
%         dx = A(i, 1) - A(i-1, 1);
%         dy = A(i, 2) - A(i-1, 2);
%         quiver(A(i, 1), A(i, 2), dx, dy, 0.1, ...
%                'MaxHeadSize', 0.5, 'Color', arrcolor, 'LineWidth', 1);
%     end
% end

set(gca, 'LineWidth', 1)
xlabel('North Latitude')
ylabel('East Longitude')
title('Route Map')

% 确保图形在绘制完成后更新
% drawnow