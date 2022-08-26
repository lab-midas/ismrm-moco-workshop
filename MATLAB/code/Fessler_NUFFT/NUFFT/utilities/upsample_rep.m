 function y = upsample_rep(x, m)
%function y = upsample_rep(x, m)
% upsample a 2D image a factor of m by simple replication

if nargin == 1 && streq(x, 'test'), upsample_rep_test, return, end
if nargin < 1, help(mfilename), error(mfilename), end
if nargin < 2, m = [2 2]; end

y = upsample1_rep(x, m(1));
y = upsample1_rep(y', m(end))';


% 1d upsampling of each column
function y = upsample1_rep(x, m)
[n1 n2] = size(x);
y = zeros(m*n1,n2);
for ii=1:m
	y(ii+m*[0:n1-1],:) = x;
end


function upsample_rep_test
x = reshape(1:24, [4 6]);
y = upsample_rep(x, 2);
for i1=1:2
	for i2=1:2
		jf_equal(x, y(i1:2:end,i2:2:end))
	end
end
