  function data = poisson2(xm, varargin)
%|function data = poisson2(xm, [options])
%|
%| in
%|	'xm'		float		
%|
%| option
%|	'seed'		int		seed for 'rand'
%|	'factor'	double		a value < 1 for rejection method
%|
%| Generate Poisson random column vector with mean xm.
%| Uses rejection method - good for large values of xm.
%| See "Numerical Recipes in C", P. 222.

if nargin < 1, help(mfilename), error(mfilename), end
if streq(xm, 'test'), poisson2_test, return, end

arg.seed = [];
%arg.factor = 0.9; % from num rec
arg.factor = 0.85; % seems to work better, but maybe not always

arg = vararg_pair(arg, varargin);

if ~isempty(arg.seed)
	rand('state', arg.seed)
end

if isa(xm, 'double')
	data = zeros(size(xm), 'double');
else
	data = zeros(size(xm), 'single');
end

if any(xm < 0), error 'negative poisson means?', end

data(xm > 0) = poisson2_positive(col(xm(xm > 0)), arg.factor);


%
% poisson2_positive()
%
function data = poisson2_positive(xm, factor)
sx = sqrt(2.0 * xm);
lx = log(xm);
gx = xm .* lx - gammaln(1 + xm);

data = zeros(size(xm));
id = [1:length(xm)]'; % indicates which data left to do

while any(id)
	Tss = sx(id);
	Tll = lx(id);
	Tgg = gx(id);
	Txx = xm(id);

	yy = zeros(size(id));
	em = zeros(size(id));
	ib = true(size(id));

	while ib
		yy(ib) = tan(pi * rand(size(ib)));
		em(ib) = Tss(ib) .* yy(ib) + Txx(ib);
		ib = find(em < 0);
	end

	em = floor(em);
	tt = factor * (1+yy.*yy) .* exp(em .* Tll - gammaln(em+1) - Tgg);
	if any(tt > 1)
		pr xm(tt > 1)
		pr max(tt)
		fail(['sorry: factor %g is too large!\n please rerun using' ...
			' a smaller value for the ''factor'' option'], factor)
	end

	ig = rand(size(id)) < tt;
	data(id(ig(:))) = em(ig);
	id = id(~ig(:));
end


function poisson2_test

xm = linspace(21, 70, 201)';
poisson2(xm);
