 function axisx(arg1, arg2)
%function axisx(vals)
%function axisx(val1, val2)
% set x range of plot axis

if nargin < 1, help axisx, error args, end
if nargin == 1, vals = arg1; end
if nargin == 2, vals = [arg1 arg2]; end

if ischar(arg1) & streq(arg1, 'tight')
	ylim = get(gca, 'ylim');
	axis tight
	set(gca, 'ylim', ylim)
return
end

t = axis;
if length(vals) == 1
	t(1) = vals;
elseif length(vals) == 2
	t(1:2) = vals;
else
	error 'length of val'
end
axis(t)
