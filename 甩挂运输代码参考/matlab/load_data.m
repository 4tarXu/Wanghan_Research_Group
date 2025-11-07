clc
clear all 
close all

load('Solution/instance.mat')

disp(['抽取的客户节点编号为']);
Cus_select
disp(['各任务对应的的客户节点编号为']);
Task_Cus
disp(['输出到主程序的算例数据(1):']);
Cus 
disp(['输出到主程序的算例数据(2):']);
Task


load(['Solution/',num2str(3),'.mat'])   %   这里的数字表示读区编号

disp(['最优解为:' num2str(Best_solution(end))]);
disp(['最优解路径:' ]);Best_route
disp(['最优解路径模式:' ]);Best_route_mode
disp(['本次运算用时:' num2str(Time_Cost) '秒']);
disp(['算法在第' num2str(Best_iter) '代时收敛']);