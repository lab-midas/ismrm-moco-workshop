 function printv(arg)
%function printv(arg)
% print a scalar variable
% todo: add 'off' and 'on'
if nargin < 1, help(mfilename), error(mfilename), end

printf('"%s" = %g', inputname(1), arg)
