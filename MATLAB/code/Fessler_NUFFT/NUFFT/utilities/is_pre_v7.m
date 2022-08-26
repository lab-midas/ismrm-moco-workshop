 function y = is_pre_v7
%function y = is_pre_v7
% return 1 if version is before 7, i.e., before release 14.
if isfreemat
	y = false;
return
end

y = str2num(version('-release')) < 14;
