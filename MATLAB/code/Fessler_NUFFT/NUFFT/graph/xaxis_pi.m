 function xaxis_pi(varargin)
%function xaxis_pi(varargin)
% label x axis with various forms of "pi"
% the argument can be a string with p's in it, or fractions of pi:
% [0 1/2 1] or '0 p/2 p' -> [0 pi/2 pi]
% [-1 0 1] or '-p 0 p' -> [-pi 0 pi]
% etc.
%
% There is one catch: this changes the axes font, so subsequent
% calls to title or xlabel or ylabel will have the wrong font.
% so title, xlabel, ylabel should be done *before* calling this routine.
%
% Jeff Fessler

if length(varargin) == 0
	ticks = '0 p';
elseif length(varargin) == 1
	ticks = varargin{1};
else
	error 'only one arg allowed'
end

if ischar(ticks)
	str = ticks;
	str = strrep(str, ' ', ' | ');
	str = strrep(str, '*', '');	% we don't need the "*" in label
	ticks = strrep(ticks, '2p', '2*p');
	ticks = strrep(ticks, '4p', '4*p');
	ticks = strrep(ticks, 'p', 'pi');
	ticks = eval(['[' ticks ']']);

else

	if same(ticks, [0])
		str = '0';
	elseif same(ticks, [0 1])
		str = '0 | p';
	elseif same(ticks, [0 1/2 1])
		str = '0 | p/2 | p';
	elseif same(ticks, [-1 0 1])
		str = '-p | 0 | p';
	elseif same(ticks, [0 1 2])
		str = '0 | p | 2p';
	else
		error 'this ticks not done'
	end

end

% here is the main part
axisx(min(ticks), max(ticks))
xtick(ticks)
set(gca, 'xticklabel', str)
set_gca_fontname('symbol')


%
% set_gca_fontname()
%
function set_gca_fontname(type)

% ideally the following line would just work:
%set(gca, 'fontname', type)

% but at least in version 7.5 matlab has a bug where
% it sets the font not only of the current axis, but
% also of the legend.  so get all the current font
% names first and then fix them up.

ax = get(gcf, 'children');
for ii=1:length(ax)
	name{ii} = get(ax(ii), 'fontname');
end
set(gca, 'fontname', type)
for ii=1:length(ax)
	if ax(ii) ~= gca
		if ~streq(name{ii}, get(ax(ii), 'fontname'))
			warn 'fixing matlab font bug, hopefully!'
			set(ax(ii), 'fontname', name{ii})
		end
	end
end


function is = same(x,y)
if length(x) ~= length(y)
	is = 0;
	return
end
is = all(x == y);
