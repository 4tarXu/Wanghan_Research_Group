%-------------------------------------------------------------------------------------%
%   - Linktime : 衔接任务时间矩阵
%-------------------------------------------------------------------------------------%

function [Linktime_1,Linktime_2,Linktime] = Cal_Linktime(TaskNum,Task,Distance,v,t_teu)

Linktime_1 = zeros(TaskNum);    % - 直接服务
Linktime_2 = zeros(TaskNum);    % - 迂回服务


for i = 1: TaskNum
    for j = 1: TaskNum
        
        if Task(i,3) == 1   % - 如果任务i是DF_20ft
            if Task(j,3) == 1
                Linktime_1(i,j) = Distance(Task(i,2),Task(j,2))*v;                                  % - 直接Receiver1前往Receiver2
                Linktime_2(i,j) = Distance(Task(i,2),1)*v + t_teu + Distance(1,Task(j,2))*v;            % - 返回terminal,(交付车上空箱任务在算法迭代过程加入)，提取20ft重箱，前往Receiver2
            elseif Task(j,3) == 2
                Linktime_1(i,j) = Distance(Task(i,2),Task(j,1))*v;
                Linktime_2(i,j) = Distance(Task(i,2),Task(j,1))*v;
            elseif Task(j,3) == 3
                Linktime_1(i,j) = Distance(Task(i,2),Task(j,2))*v;
                Linktime_2(i,j) = Distance(Task(i,2),1)*v + t_teu + Distance(1,Task(j,2))*v;
            elseif Task(j,3) == 4
                Linktime_1(i,j) = Distance(Task(i,2),Task(j,1))*v;
                Linktime_2(i,j) = Distance(Task(i,2),Task(j,1))*v;
            elseif Task(j,3) == 5
                Linktime_1(i,j) = Distance(Task(i,2),1)*v + t_teu*2 + Distance(1,Task(j,2))*v;
                Linktime_2(i,j) = Distance(Task(i,2),1)*v + t_teu*2 + Distance(1,Task(j,2))*v;
            elseif Task(j,3) == 6
                Linktime_1(i,j) = Distance(Task(i,2),Task(j,1))*v;
                Linktime_2(i,j) = Distance(Task(i,2),1)*v + Distance(1,Task(j,1))*v;
            elseif Task(j,3) == 7 
                Linktime_1(i,j) = Distance(Task(i,2),1)*v +t_teu*2 + Distance(1,Task(j,2))*v;
                Linktime_2(i,j) = Distance(Task(i,2),1)*v +t_teu*2 + Distance(1,Task(j,2))*v;
            else
                Linktime_1(i,j) = Distance(Task(i,2),Task(j,1))*v;
                Linktime_2(i,j) = Distance(Task(i,2),1)*v + Distance(1,Task(j,1))*v;
            end
            
        elseif Task(i,3) == 2   % - 如果任务i是PE_20ft
            if Task(j,3) == 1 
                Linktime_1(i,j) = Distance(Task(i,1),Task(j,2))*v;
                Linktime_2(i,j) = Distance(Task(i,1),1)*v + t_teu + Distance(1,Task(j,2))*v;
            elseif Task(j,3) == 2
                Linktime_1(i,j) = Distance(Task(i,1),Task(j,1))*v;
                Linktime_2(i,j) = Distance(Task(i,1),1)*v + Distance(1,Task(j,1))*v;
            elseif Task(j,3) == 3
                Linktime_1(i,j) = Distance(Task(i,1),Task(j,2))*v;
                Linktime_2(i,j) = Distance(Task(i,1),Task(j,2))*v;
            elseif Task(j,3) == 4
                Linktime_1(i,j) = Distance(Task(i,1),Task(j,1))*v;
                Linktime_2(i,j) = Distance(Task(i,1),1)*v + Distance(1,Task(j,1))*v;
            elseif Task(j,3) == 5
                Linktime_1(i,j) = Distance(Task(i,1),1)*v + t_teu*2 + Distance(1,Task(j,2))*v;
                Linktime_2(i,j) = Distance(Task(i,1),1)*v + t_teu*2 + Distance(1,Task(j,2))*v;
            elseif Task(j,3) == 6
                Linktime_1(i,j) = Distance(Task(i,1),1)*v + Distance(1,Task(j,1))*v;
                Linktime_2(i,j) = Distance(Task(i,1),1)*v + Distance(1,Task(j,1))*v;   
            elseif Task(j,3) == 7  
                Linktime_1(i,j) = Distance(Task(i,1),1)*v + t_teu*2 + Distance(1,Task(j,2))*v;
                Linktime_2(i,j) = Distance(Task(i,1),1)*v + t_teu*2 + Distance(1,Task(j,2))*v;
            else
                Linktime_1(i,j) = Distance(Task(i,1),1)*v + Distance(1,Task(j,1))*v;
                Linktime_2(i,j) = Distance(Task(i,1),1)*v + Distance(1,Task(j,1))*v;                  
            end
        elseif Task(i,3) == 3
            if Task(j,3) == 1 
                Linktime_1(i,j) = Distance(Task(i,2),Task(j,2))*v;
                Linktime_2(i,j) = Distance(Task(i,2),1)*v + t_teu + Distance(1,Task(j,2))*v;
            elseif Task(j,3) == 2
                Linktime_1(i,j) = Distance(Task(i,2),Task(j,1))*v;
                Linktime_2(i,j) = Distance(Task(i,2),Task(j,1))*v;
            elseif Task(j,3) == 3
                Linktime_1(i,j) = Distance(Task(i,2),Task(j,2))*v;
                Linktime_2(i,j) = Distance(Task(i,2),1)*v + t_teu + Distance(1,Task(j,2))*v;
            elseif Task(j,3) == 4
                Linktime_1(i,j) = Distance(Task(i,2),Task(j,1))*v;
                Linktime_2(i,j) = Distance(Task(i,2),Task(j,1))*v;
            elseif Task(j,3) == 5
                Linktime_1(i,j) = Distance(Task(i,2),1)*v + t_teu*2 + Distance(1,Task(j,2))*v;
                Linktime_2(i,j) = Distance(Task(i,2),1)*v + t_teu*2 + Distance(1,Task(j,2))*v;
            elseif Task(j,3) == 6
                Linktime_1(i,j) = Distance(Task(i,2),Task(j,1))*v;
                Linktime_2(i,j) = Distance(Task(i,2),1)*v + Distance(1,Task(j,1))*v;
            elseif Task(j,3) == 7  
                Linktime_1(i,j) = Distance(Task(i,2),1)*v + t_teu*2 + Distance(1,Task(j,2))*v;
                Linktime_2(i,j) = Distance(Task(i,2),1)*v + t_teu*2 + Distance(1,Task(j,2))*v;
            else
                Linktime_1(i,j) = Distance(Task(i,2),Task(j,1))*v;
                Linktime_2(i,j) = Distance(Task(i,2),1)*v + Distance(1,Task(j,1))*v;
            end
        elseif Task(i,3) == 4
            if Task(j,3) == 1 
                Linktime_1(i,j) = Distance(Task(i,1),Task(j,2))*v;
                Linktime_2(i,j) = Distance(Task(i,1),1)*v + t_teu + Distance(1,Task(j,2))*v;
            elseif Task(j,3) == 2
                Linktime_1(i,j) = Distance(Task(i,1),Task(j,1))*v;
                Linktime_2(i,j) = Distance(Task(i,1),1)*v + Distance(1,Task(j,1))*v;
            elseif Task(j,3) == 3
                Linktime_1(i,j) = Distance(Task(i,1),Task(j,2))*v;
                Linktime_2(i,j) = Distance(Task(i,1),1)*v + t_teu + Distance(1,Task(j,2))*v;
            elseif Task(j,3) == 4
                Linktime_1(i,j) = Distance(Task(i,1),Task(j,1))*v;
                Linktime_2(i,j) = Distance(Task(i,1),1)*v + Distance(1,Task(j,1))*v;
            elseif Task(j,3) == 5
                Linktime_1(i,j) = Distance(Task(i,1),1)*v + t_teu*2 + Distance(1,Task(j,2))*v;
                Linktime_2(i,j) = Distance(Task(i,1),1)*v + t_teu*2 + Distance(1,Task(j,2))*v;
            elseif Task(j,3) == 6
                Linktime_1(i,j) = Distance(Task(i,1),1)*v + Distance(1,Task(j,1))*v;
                Linktime_2(i,j) = Distance(Task(i,1),1)*v + Distance(1,Task(j,1))*v;
            elseif Task(j,3) == 7  
                Linktime_1(i,j) = Distance(Task(i,1),1)*v + t_teu*2 + Distance(1,Task(j,2))*v;
                Linktime_2(i,j) = Distance(Task(i,1),1)*v + t_teu*2 + Distance(1,Task(j,2))*v;
            else
                Linktime_1(i,j) = Distance(Task(i,1),1)*v + Distance(1,Task(j,1))*v;
                Linktime_2(i,j) = Distance(Task(i,1),1)*v + Distance(1,Task(j,1))*v;                
            end            
        elseif Task(i,3) == 5
            if Task(j,3) == 1 
                Linktime_1(i,j) = Distance(Task(i,2),1)*v + t_teu + Distance(1,Task(j,2))*v;
                Linktime_2(i,j) = Distance(Task(i,2),1)*v + t_teu + Distance(1,Task(j,2))*v;                
            elseif Task(j,3) == 2
                Linktime_1(i,j) = Distance(Task(i,2),Task(j,1))*v;
                Linktime_2(i,j) = Distance(Task(i,2),Task(j,1))*v;
            elseif Task(j,3) == 3
                Linktime_1(i,j) = Distance(Task(i,2),1)*v + t_teu + Distance(1,Task(j,2))*v;
                Linktime_2(i,j) = Distance(Task(i,2),1)*v + t_teu + Distance(1,Task(j,2))*v;                
            elseif Task(j,3) == 4
                Linktime_1(i,j) = Distance(Task(i,2),Task(j,1))*v;
                Linktime_2(i,j) = Distance(Task(i,2),Task(j,1))*v;                
            elseif Task(j,3) == 5
                Linktime_1(i,j) = Distance(Task(i,2),1)*v + t_teu + Distance(1,Task(j,2))*v;
                Linktime_2(i,j) = Distance(Task(i,2),1)*v + t_teu + Distance(1,Task(j,2))*v;
            elseif Task(j,3) == 6
                Linktime_1(i,j) = Distance(Task(i,2),Task(j,1))*v;
                Linktime_2(i,j) = Distance(Task(i,2),Task(j,1))*v;
            elseif Task(j,3) == 7 
                Linktime_1(i,j) = Distance(Task(i,2),1)*v + t_teu*2 + Distance(1,Task(j,2))*v;
                Linktime_2(i,j) = Distance(Task(i,2),1)*v + t_teu*2 + Distance(1,Task(j,2))*v;
            else
                Linktime_1(i,j) = Distance(Task(i,2),Task(j,1))*v;
                Linktime_2(i,j) = Distance(Task(i,2),Task(j,1))*v;
            end        
        elseif Task(i,3) == 6
            if Task(j,3) == 1
                Linktime_1(i,j) = Distance(Task(i,1),1)*v + t_teu + Distance(1,Task(j,2))*v;
                Linktime_2(i,j) = Distance(Task(i,1),1)*v + t_teu + Distance(1,Task(j,2))*v;
            elseif Task(j,3) == 2
                Linktime_1(i,j) = Distance(Task(i,1),1)*v + Distance(1,Task(j,1))*v;
                Linktime_2(i,j) = Distance(Task(i,1),1)*v + Distance(1,Task(j,1))*v;
            elseif Task(j,3) == 3
                Linktime_1(i,j) = Distance(Task(i,1),1)*v + t_teu +Distance(1,Task(j,2))*v;
                Linktime_2(i,j) = Distance(Task(i,1),1)*v + t_teu +Distance(1,Task(j,2))*v;
            elseif Task(j,3) == 4
                Linktime_1(i,j) = Distance(Task(i,1),1)*v + Distance(1,Task(j,1))*v;
                Linktime_2(i,j) = Distance(Task(i,1),1)*v + Distance(1,Task(j,1))*v;
            elseif Task(j,3) == 5
                Linktime_1(i,j) = Distance(Task(i,1),1)*v + t_teu*2 + Distance(1,Task(j,2))*v;
                Linktime_2(i,j) = Distance(Task(i,1),1)*v + t_teu*2 + t_teu*2 + Distance(1,Task(j,2))*v;
            elseif Task(j,3) == 6
                Linktime_1(i,j) = Distance(Task(i,1),1)*v + Distance(1,Task(j,1))*v;
                Linktime_2(i,j) = Distance(Task(i,1),1)*v + Distance(1,Task(j,1))*v;
            elseif Task(j,3) == 7  
                Linktime_1(i,j) = Distance(Task(i,1),Task(j,2))*v;
                Linktime_2(i,j) = Distance(Task(i,1),Task(j,2))*v;
            else
                Linktime_1(i,j) = Distance(Task(i,1),1)*v + Distance(1,Task(j,1))*v;
                Linktime_2(i,j) = Distance(Task(i,1),1)*v + Distance(1,Task(j,1))*v;
            end            
        elseif Task(i,3) == 7
            if Task(j,3) == 1 
                Linktime_1(i,j) = Distance(Task(i,2),1)*v + t_teu + Distance(1,Task(j,2))*v;
                Linktime_2(i,j) = Distance(Task(i,2),1)*v + t_teu + Distance(1,Task(j,2))*v;
            elseif Task(j,3) == 2
                Linktime_1(i,j) = Distance(Task(i,2),Task(j,1))*v;
                Linktime_2(i,j) = Distance(Task(i,2),Task(j,1))*v;
            elseif Task(j,3) == 3
                Linktime_1(i,j) = Distance(Task(i,2),1)*v + t_teu + Distance(1,Task(j,2))*v;
                Linktime_2(i,j) = Distance(Task(i,2),1)*v + t_teu + Distance(1,Task(j,2))*v;
            elseif Task(j,3) == 4
                Linktime_1(i,j) = Distance(Task(i,2),Task(j,1))*v;
                Linktime_2(i,j) = Distance(Task(i,2),Task(j,1))*v;
            elseif Task(j,3) == 5
                Linktime_1(i,j) = Distance(Task(i,2),1)*v + t_teu*2 + Distance(1,Task(j,2))*v;
                Linktime_2(i,j) = Distance(Task(i,2),1)*v + t_teu*2 + Distance(1,Task(j,2))*v; 
            elseif Task(j,3) == 6
                Linktime_1(i,j) = Distance(Task(i,2),Task(j,1))*v;
                Linktime_2(i,j) = Distance(Task(i,2),Task(j,1))*v;
            elseif Task(j,3) == 7  
                Linktime_1(i,j) = Distance(Task(i,2),1)*v + t_teu*2 + Distance(1,Task(j,2))*v;
                Linktime_2(i,j) = Distance(Task(i,2),1)*v + t_teu*2 + Distance(1,Task(j,2))*v;
            else
                Linktime_1(i,j) = Distance(Task(i,2),Task(j,1))*v;
                Linktime_2(i,j) = Distance(Task(i,2),Task(j,1))*v;
            end            
        else
            if Task(j,3) == 1 
                Linktime_1(i,j) = Distance(Task(i,1),1)*v + t_teu + Distance(1,Task(j,2))*v;
                Linktime_2(i,j) = Distance(Task(i,1),1)*v + t_teu + Distance(1,Task(j,2))*v;
            elseif Task(j,3) == 2
                Linktime_1(i,j) = Distance(Task(i,1),1)*v + Distance(1,Task(j,1))*v;
                Linktime_2(i,j) = Distance(Task(i,1),1)*v + Distance(1,Task(j,1))*v;
            elseif Task(j,3) == 3
                Linktime_1(i,j) = Distance(Task(i,1),1)*v + t_teu + Distance(1,Task(j,2))*v;
                Linktime_2(i,j) = Distance(Task(i,1),1)*v + t_teu + Distance(1,Task(j,2))*v;
            elseif Task(j,3) == 4
                Linktime_1(i,j) = Distance(Task(i,1),1)*v + Distance(1,Task(j,1))*v;
                Linktime_2(i,j) = Distance(Task(i,1),1)*v + Distance(1,Task(j,1))*v;                
            elseif Task(j,3) == 5
                Linktime_1(i,j) = Distance(Task(i,1),1)*v + t_teu*2 + Distance(1,Task(j,2))*v;
                Linktime_2(i,j) = Distance(Task(i,1),1)*v + t_teu*2 + Distance(1,Task(j,2))*v;         
            elseif Task(j,3) == 6
                Linktime_1(i,j) = Distance(Task(i,1),1)*v + Distance(1,Task(j,1))*v;
                Linktime_2(i,j) = Distance(Task(i,1),1)*v + Distance(1,Task(j,1))*v;                 
            elseif Task(j,3) == 7  
                Linktime_1(i,j) = Distance(Task(i,1),1)*v + t_teu*2 + Distance(1,Task(j,2))*v;
                Linktime_2(i,j) = Distance(Task(i,1),1)*v + t_teu*2 + Distance(1,Task(j,2))*v;                 
            else
                Linktime_1(i,j) = Distance(Task(i,1),1)*v + Distance(1,Task(j,1))*v;
                Linktime_2(i,j) = Distance(Task(i,1),1)*v + Distance(1,Task(j,1))*v;                 
            end        

        end
    end 
end

linktime0 = zeros(TaskNum,1);   % - add第一列
linktime1 = zeros(1,TaskNum+1); % - add第一行

for i = 1:TaskNum
    if Task(i,3) == 1
        linktime0(i) = Distance(Task(i,2),1)*v;
        linktime1(i+1) = t_teu + Distance(1,Task(i,2))*v;
    elseif Task(i,3) == 2
        linktime0(i) = Distance(Task(i,1),1)*v + t_teu;
        linktime1(i+1) = Distance(1,Task(i,1))*v;
    elseif Task(i,3) == 3
        linktime0(i) = Distance(Task(i,2),1)*v;
        linktime1(i+1) = t_teu + Distance(1,Task(i,2))*v;
    elseif Task(i,3) == 4
        linktime0(i) = Distance(Task(i,1),1) + t_teu;
        linktime1(i+1) = Distance(1,Task(i,1))*v;
    elseif Task(i,3) == 5
        linktime0(i) = Distance(Task(i,2),1)*v;
        linktime1(i+1) = t_teu*2 + Distance(1,Task(i,2))*v;
    elseif Task(i,3) == 6
        linktime0(i) = Distance(Task(i,1),1)*v + t_teu*2;
        linktime1(i+1) = Distance(1,Task(i,1))*v;
    elseif Task(i,3) == 7
        linktime0(i) = Distance(Task(i,2),1)*v;
        linktime1(i+1) = t_teu*2 + Distance(1,Task(i,2))*v;
    else
        linktime0(i) = Distance(Task(i,1),1)*v +t_teu*2;
        linktime1(i+1) = Distance(1,Task(i,1))*v;
               
    end
end

Linktime_1 = [linktime0 Linktime_1];                                
Linktime_1 = [linktime1;Linktime_1];

Linktime_2 = [linktime0 Linktime_2];                                
Linktime_2 = [linktime1;Linktime_2];

Linktime = zeros(TaskNum+1,TaskNum+1,2);
Linktime(:,:,1) = Linktime_1;
Linktime(:,:,2) = Linktime_2;




