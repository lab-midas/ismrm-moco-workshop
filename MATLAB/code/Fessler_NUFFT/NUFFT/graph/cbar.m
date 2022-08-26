  function hh = cbar(varargin)
%|function hh = cbar(varargin)
%|
%| colorbar with options
%|	'h' 'horiz'	horizontal
%|	'v' 'vert'	vertical
%|	'below'		horizontal colorbar below current plot (jf)
%|	'hide'		make room for it, but hide it (invisible)
%|	'fSIZE'		font size
%|	1d-array	ytick
%|	'notick'	disable tick marks
%|
%| Copyright 2007, Jeff Fessler, University of Michigan

if nargin == 1 && streq(varargin{1}, 'test'), cbar_test, return, end

if isfreemat
	return % freemat 3.6 colorbar does not work with subplot
end

if ~im('ison')
%	disp 'im disabled'
return
end


%
% handle state of display or not
%
persistent Display
if ~isvar('Display') || isempty(Display)
	Display = true;
end

st.dotick = 1;
st.ytick = [];
st.orient = [];
st.fontsize = [];
st.new = 0;
st.label = '';

while length(varargin)
	arg = varargin{1};

	if streq(arg, 'on')
		Display = true;
		printm 'enabling cbar'
		return

	elseif streq(arg, 'off')
		Display = false;
		printm 'disabling cbar'
		return

	%
	% new
	%
	elseif streq(arg, 'new')
		st.new = 1;

	%
	% notick
	%
	elseif streq(arg, 'notick')
		st.dotick = 0;

	%
	% ytick
	%
	elseif isa(arg, 'double')
		st.ytick = arg;

	%
	% 'h' or 'horiz' for horizontal
	%
	elseif ischar(arg) & streq(arg, 'h') | streq(arg, 'horiz')
		if (is_pre_v7)
			st.orient = 'horiz';
		else
			st.orient = 'horiz';
%			colorbar horiz; return % fixed
		end

	%
	% 'v' or 'vert' for vertical
	%
	elseif ischar(arg) & streq(arg, 'v') | streq(arg, 'vert')
		st.orient = [];

	%
	% 'below'
	%
	elseif ischar(arg) & streq(arg, 'below')
		st.orient = 'below';

	%
	% 'hide'
	%
	elseif ischar(arg) & streq(arg, 'hide')
		set(colorbar, 'ytick', [], 'visible', 'off')
		return

	%
	% 'fSIZE'
	%
	elseif ischar(arg) & streq(arg, 'f', 1)
		st.fontsize = sscanf(arg, 'f%d');

	else
		if ischar(arg) && isempty(st.label)
			st.label = arg;
		else
			error 'arg'
		end
	end

	varargin = {varargin{2:end}};
end
clear arg

if ~Display
	return
end

if isempty(get(gcf, 'children'))
	warn 'no figure children?'
	help(mfilename)
return
end

% explore new way
if st.new
	ha = gca;
%	get(ha)
	hi = get(ha, 'children');
	hi = hi(end); % for pre_v7
%	get(hi)
	dat = get(hi, 'cdata');
	clim = get(ha, 'clim');
	[nv nh] = size(dat);
	if streq(st.orient, 'below')
		error 'not done'
	else
		arg.npad = ceil(0.08*nh);
		arg.nramp = ceil(0.1*nh);
		arg.padv = 0;
		ramp = linspace(clim(1), clim(2), nv)';
		ramp = flipud(ramp);
		dat(:,end+[1:arg.npad]) = arg.padv;
		dat(:,end+[1:arg.nramp]) = repmat(ramp, 1, arg.nramp);
	end
	set(hi, 'cdata', dat)
%	get(hi)
	nh = size(dat,2);
	set(ha, 'xlim', [0.5 nh+0.5])
	xlim = get(ha, 'xlim');
	ylim = get(ha, 'ylim');
	text(1.05*xlim(2), ylim(2), sprintf('%g', clim(1)))
	text(1.05*xlim(2), ylim(1), sprintf('%g', clim(2)))
%	set(ha, 'xlim', [0.5 size(dat,2)+0.5+arg.npad+arg.nramp])
%	minmax(dat)
%	axis off

	if ~isempty(st.label)
		text(1.05*xlim(2), mean(ylim(1:2)), st.label)
	end
return
end

if isempty(st.orient)
	h = colorbar;
elseif ~streq(st.orient, 'below')
	h = colorbar(st.orient);
else
	h = cbar_below;
	st.orient = 'horiz';
end

if streq(st.orient, 'horiz')
	xtick = st.ytick;
	if isempty(xtick)
		xtick = get(gca, 'clim');
		if xtick(2) > 100
			xtick(2) = floor(xtick(2));
		end
	end

else
	if isempty(st.ytick)
	%	st.ytick = get(h, 'ytick');
	%	st.ytick = st.ytick([1 end]);
		clim0 = get(gca, 'clim');
		clim1 = clim0;
		if clim1(2) > 100
			clim1(2) = floor(clim1(2));
		end

		% truncate to 3 digits of precision:
		st.ytick = truncate_precision(clim1, 3);
	% todo: this loses the bottom label sometimes, by rounding down ...
	end
end

if st.dotick
	if streq(st.orient, 'horiz')
		set(h, 'xtick', xtick)
	else
		if is_pre_v7
			set(h, 'ytick', st.ytick)
		elseif 0 % disabled because not working
			% trick: for v7, move ticks in slightly
			yticks = num2str(st.ytick');
			ytick = st.ytick + [1 -1] * 0.005 * diff(st.ytick);
			if 0 && length(ytick) == 2 % kludge:
				tmp1 = get(h, 'yticklabel');
				tmp2 = strvcat(yticks, tmp1);
				yticks = tmp2([1 4:end-1 2], :);
				yticks(2:end-1,:) = ' ';
				set(h, 'yticklabel', yticks)
			else % this way should work but has had problems:
%				set(h, 'fontsize', 7)
				set(h, ...
					'YTickMode', 'manual', ...
					'Ytick', ytick, ...
					'YTickLabelMode', 'manual', ...
					'YtickLabel', yticks)
			end
		end
	end
else
	set(h, 'ytick', [])
end

if ~isempty(st.fontsize)
	set(h, 'fontsize', st.fontsize)
end

if ~isempty(st.label)
	xlim = get(h, 'xlim'); % [-0.5 1.5]
	ylim = get(h, 'ylim');
	htmp = gca;
	axes(h)
	text(2.2, mean(ylim), st.label, ...
		'rotation', 90, ...
		'verticalalign', 'top', ...
		'horizontalalign', 'center')
%	ylabel(label)
%	[x y] = ginput(1)
	axes(htmp) % return current axis to image
end

if nargout
	hh = h;
end


function h = cbar_below(vfrac)
pos = get(gca, 'position');
clim = get(gca, 'clim');
h = pos(4);
pos(2) = pos(2) - 0.11 * h;
pos(4) = 0.1 * h;
axes('position', pos)
x = linspace(clim(1),clim(2),101);
y = 1:10;
im(x, y, x'*ones(size(y)), clim, ' ');
h = gca;
ytick off
axis normal


function cbar_test
im clf, im pl 2 3
clim = [5 20];
x = 10 * eye(9);
im(4, x, clim)
cbar %notick
prompt
im(6, x, clim)
cbar new
prompt
im(1, x, clim)
cbar 'label'
prompt
