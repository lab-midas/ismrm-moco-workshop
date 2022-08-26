 function axisy(arg1, arg2)
%function axisy(vals)
%function axisy(val1, val2)
% set x range of plot axis

if nargin < 1, help axisy, error args, end
if nargin == 1, vals = arg1; end
if nargin == 2, vals = [arg1 arg2]; end

if ischar(arg1) & streq(arg1, 'tight')
	xlim = get(gca, 'xlim');
	axis tight
	set(gca, 'xlim', xlim)
return
end

t = axis;
if length(vals) == 1
	t(3) = vals;
elseif length(vals) == 2
	t(3:4) = vals;
else
	error 'length of val'
end
axis(t)
