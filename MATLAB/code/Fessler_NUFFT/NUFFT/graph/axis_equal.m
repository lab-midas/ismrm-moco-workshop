 function axis_equal
% my version of "axis equal"

set(gca, 'DataAspectRatio', [1 1 1])
return

use_y = 1;

pos = get(gca, 'pos')
xlim = get(gca, 'xlim')
ylim = get(gca, 'ylim')

% adjust x so that it matches y

if use_y
	xwidth = pos(4) * abs(diff(xlim)) / abs(diff(ylim));
	pos(1) = pos(1) + (pos(3) - xwidth)/2;
	pos(3) = xwidth
else
	error 'not done'
end

%set(gca, 'DataAspectRatioMode', 'manual')
%set(gca, 'pos', pos)
