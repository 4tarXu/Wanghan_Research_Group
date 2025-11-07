A =zeros(10,1);
B= zeros(10,1);


for i = 1:10
   run  aco_drop.m
    
   A(i)=Best_solution(iter-1);
   B(i)=Time_Cost;
   
   
end

C=[A;B]';