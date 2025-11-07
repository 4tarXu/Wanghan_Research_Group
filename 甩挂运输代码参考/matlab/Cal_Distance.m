%-------------------------------------------------------------------------------------%
%   - Distance : ½Úµã¼ä¾àÀë¾ØÕó
%-------------------------------------------------------------------------------------%

function [Distance] = Cal_Distance(Cus,CusNum)

Distance =  zeros(CusNum);
for i = 1:CusNum
    for j = 1:CusNum
        Distance(i,j) =sqrt((Cus(i,1)-Cus(j,1))^2+(Cus(i,2)-Cus(j,2))^2);
    end
end