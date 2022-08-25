  function data = poisson1(xmean, seed)
%|function data = poisson1(xmean, seed)
%| Generate poisson random column vector with mean xmean
%| by summing exponentials.
%| This is efficient only for small mean values, eg < 20.

if nargin < 1, help(mfilename), error(mfilename), end

if isvar('seed') & ~isempty(seed)
	rand('state', seed)
end

dim = size(xmean);

data = zeros(dim);
i_do = ones(dim);
ee = exp(xmean);

while any(i_do(:))
	i_do = ee >= 1;
	data(i_do) = 1 + data(i_do);
	ee = ee .* rand(dim) .* i_do;
end

data = data - 1;
