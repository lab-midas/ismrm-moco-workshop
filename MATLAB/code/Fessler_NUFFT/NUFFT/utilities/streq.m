 function tf = streq(a,b,n)
%function tf = streq(a, b [,n])
% return 1 if two strings are equal (optionally only up to 1st n chars)
if nargin == 1 && strcmp(a, 'test'), streq_test, return, end
if nargin < 2, help(mfilename), error(mfilename), end

if ~ischar(a) | ~ischar(b), tf = 0; return, end
if nargin == 2
	tf = strcmp(a,b);
elseif nargin == 3
	tf = strncmp(a,b,n);
else
	error(mfilename)
end
