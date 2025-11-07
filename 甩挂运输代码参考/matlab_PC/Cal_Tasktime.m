%-------------------------------------------------------------------------------------%
%   - Tasktime : 顶点任务时间矩阵
%-------------------------------------------------------------------------------------%
function [Tasktime] = Cal_Tasktime(TaskNum,Task,t_drop) 
Tasktime = zeros(TaskNum,1);               %   - 初始化顶点任务时间为0

%20ft的都是t_drop时间，40ft都是2*t_drop时间

for i = 1:TaskNum
    if ismember(Task(i,3),[1,2,3,4])
        Tasktime(i) = t_drop;           %   - 20ft任务的装卸时间都是t_drop
                                        %       - 装卸一个还是两个都是t_drop
                                        %       -
                                        %       如果不这么假设的话，后续任务安排会改变之前任务的出发时间和车辆状态
    else 
        Tasktime(i) = 2 * t_drop;
    end
end

Tasktime = [0;Tasktime];        %   为了保证时间计算的完整性，起始点任务的时间设为 0 。
