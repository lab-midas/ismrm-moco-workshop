 function index = subv2ind(dim, sub)
%function index = subv2ind(dim, sub)
% version of matlab's sub2ind that allows a vector version of the subscripts
if nargin < 2, help(mfilename), error(mfilename), end
sub = num2cell(sub);
index = sub2ind(dim, sub{:});
