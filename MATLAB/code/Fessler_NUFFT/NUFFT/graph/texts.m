 function ho = texts(x, y, str, varargin)
%function ho = texts(x, y, str [, center], options)
% put text on current plot using screen coordinates 
% user can supply optional name/value object properties.
% for horizontalalign, only the value is needed (e.g., 'center')
% if it is the first option.

if nargin == 1 && streq(x, 'test'), texts_test, return, end
if nargin < 3, help(mfilename), error(mfilename), end

xlim = get(gca, 'xlim');
ylim = get(gca, 'ylim');
xscale = get(gca, 'xscale');
yscale = get(gca, 'yscale');

if streq(xscale, 'log')
	xlim = log10(xlim);
end
if streq(yscale, 'log')
	ylim = log10(ylim);
end

x = xlim(1) + x * (xlim(2)-xlim(1));
y = ylim(1) + y * (ylim(2)-ylim(1));

if streq(xscale, 'log')
	x = 10 ^ x;
end
if streq(yscale, 'log')
	y = 10 ^ y;
end

if isfreemat
	args = {};
else
	args = {'buttondownfcn', 'textmove'};
end

if length(varargin)
	arg1 = varargin{1};
	if streq(arg1, 'left') | streq(arg1, 'center') | streq(arg1, 'right')
		args = {args{:}, 'horizontalalign', varargin{:}};
	else
		args = {args{:}, varargin{:}};
	end
end

h = text(x, y, str, args{:});

if nargout > 0
	ho = h;
end

function texts_test
if im
	plot(rand(3))
	texts(0.5, 0.5, 'test', 'center', 'color', 'blue')
end
