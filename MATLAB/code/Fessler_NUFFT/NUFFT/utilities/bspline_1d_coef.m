  function coef = bspline_1d_coef(fn, varargin)
%|function coef = bspline_1d_coef(fn, varargin)
%|
%| Given f[n], uniformly spaced samples of a 1D signal f(t),
%| compute the bspline coefficients so that the following model interpolates:
%| f(t) = \sum_{k=0}^{N-1} coef[k] b(t - k)
%|
%| in
%|	fn	[N,(L)]	1d signal(s) of length N (columns)
%| option
%|	order	default: 3
%|	ending	end / boundary conditions: mirror / periodic / zero
%| out
%|	coef	[N,(L)]	bspline coefficients, for use in bspline_1d_interp()
%|
%| Caution: the 'zero' end conditions do not quite interpolate the edge samples.
%| That would require returning more coefficients than signal samples, which is
%| not worth the trouble since 'mirror' and 'periodic' are more common.
%|
%| Copyright 2005-12-7, Jeff Fessler, University of Michigan

if nargin < 1, help(mfilename), error(mfilename), end
if streq(fn, 'test'), bspline_1d_coef_test, return, end

arg.order = 3;
arg.ending = 'periodic';
arg.n0 = 10; % boundary conditions, more than enough for single precision.
arg.mex = 1; % default is to try mex version

arg = vararg_pair(arg, varargin);

if arg.mex
	ii = strvcat('mirror', 'periodic', 'zero');
	ii = strmatch(arg.ending, ii, 'exact');
	if length(ii) ~= 1, error 'unknown end conditions', end
	try
		coef = jf_mex('bspline,coef,1d', single(fn), ...
			int32(arg.order), int32(ii));
		return
	catch
		printm 'Warn: mex version failed; reverting to matlab version'
	end
end

dims = size(fn);
N = dims(1);
fn = reshapee(fn, N, []); % [N,*L]

if arg.order == 1
	coef = fn;
elseif arg.order == 3
	coef = bspline3_1d_coef(fn, arg.n0, arg.ending);
else
	error 'order not done'
end

coef = reshape(coef, dims); % [N,(L)]


%
% 1d cubic bspline, various end conditions
% fn and coef are [N,L]
%
function coef = bspline3_1d_coef(fn, n0, ending)

p = -2 + sqrt(3); % pole location

N = size(fn,1);
fn = 6 * fn;
coef = zeros(size(fn));

n0 = min(n0, N);
ps = p .^ [1:n0];

% initial condition for forward
if streq(ending, 'mirror')
	coef(1,:) = ps/p * fn(1:n0,:);
elseif streq(ending, 'periodic')
	coef(1,:) = fn(1,:) + fliplr(ps) * fn([(N-n0+1):N],:);
elseif streq(ending, 'zero')
	coef(1,:) = fn(1,:);
else
	error 'unknown end conditions'
end

% causal iir filter
for n=2:N
	coef(n,:) = fn(n,:) + p * coef(n-1,:);
end

% initial condition for anti-causal
if streq(ending, 'mirror')
%	coef(N,:) = -fliplr(ps) * coef([(N-n0+1):N],:); % my way, not good
	coef(N,:) = -p/(1-p^2) * ( coef(N,:) + p * coef(N-1,:) ); % unser way
elseif streq(ending, 'periodic')
	coef(N,:) = -p * coef(N,:) - p * ps * coef(1:n0,:);
else % zero
	coef(N,:) = -p * coef(N,:);
end

% anti-causal iir filter
for n=N-1:-1:1
	coef(n,:) = p * ( coef(n+1,:) - coef(n,:) );
end


%
% fft approach, for validating periodic and mirror cases
%
function coef = bspline3_1d_coef_fft(fn, ending)
N = size(fn,1);

if streq(ending, 'mirror')
	hn = zeros(2*N-2,1);
	hn([1 2 2*N-2]) = [4 1 1]'/6;
	coef = ifft(fft([fn; flipud(fn(2:N-1,:))]) ./ ...
		repmat(fft(hn), [1 ncol(fn)]));
	coef = reale(coef(1:N,:));
elseif streq(ending, 'periodic')
	hn = zeros(N,1);
	hn([1 2 N]) = [4 1 1]'/6;
	coef = ifft(fft(fn) ./ repmat(fft(hn), [1 ncol(fn)]));
	coef = reale(coef);
elseif streq(ending, 'zero')
	coef = zeros(size(fn)); % fake
end


%
% exact matrix approach based on cbanal.m from kybic, for validating
%
function coef = bspline3_1d_coef_exact(y, ending)
N = size(y,1);
A = zeros(N,N);

if N == 1
	coef = 1.5 * y; % 6/4
	return
end

if streq(ending, 'mirror')
	coef = bspline3_1d_coef_exact([y; flipud(y(2:N-1,:))], 'periodic');
	coef = coef(1:N,:);
	return
end

A(1,1:2) = [4 1]/6;
A(N,N-1:N) = [1 4]/6;
if streq(ending, 'mirror')
	A(1,2) = 2/6;
	A(N,N-1) = 2/6;
elseif streq(ending, 'periodic')
	A(1,N) = 1/6;
	A(N,1) = 1/6;
end
for i=2:N-1,
	A(i,i-1:i+1) = [1 4 1]/6;
end
coef = A \ y;


%
% test periodic case by comparing to fft and to matrix "exact" method
%
function bspline_1d_coef_test

N = 2^5;
%fn = zeros(N,1); fn(3) = 1;
fn = eye(N);

orders = [1 3];
endings = {'mirror', 'periodic', 'zero'};
for io=1:length(orders)
	order = orders(io);

	for ie=1:length(endings)
		ending = endings{ie};
		printm([ending ' ' num2str(order)])

		arg = {'order', order, 'ending', ending};
		if 1 % check mex version
%			cpu etic
			coef = bspline_1d_coef(fn, arg{:}, 'mex', 0);
%			cpu etoc 'matlab'
%			cpu etic
			cmex = bspline_1d_coef(fn, arg{:}, 'mex', 1);
%			cpu etoc 'mex'
			max_percent_diff(coef, cmex)
			im clf, im pl 1 3
			im(1, coef)
			im(2, cmex)
			im(3, cmex-coef)
		end

		if has_mex_jf % check adjoint
			A = bspline_1d_coef(eye(N), arg{:}, 'mex', 1);
			B = jf_mex('bspline,coef,adj,1d', single(eye(N)), ...
				int32(order), int32(ie));
			if max(col(abs(A-B'))) > 1e-5, error 'adjoint', end
		end

		if order ~= 3, continue, end

		cfft = bspline3_1d_coef_fft(fn, ending);
		exact = bspline3_1d_coef_exact(fn, ending);

		max_percent_diff(exact, cfft)
		max_percent_diff(exact, coef)

		im clf, im pl 2 3
		im(1, fn, 'f[n]'), cbar
		im(4, exact, 'exact'), cbar
		im(2, coef, 'coef'), cbar
		im(5, coef-exact, 'error'), cbar
		im(3, cfft, 'coef fft'), cbar
		im(6, cfft-exact, 'error'), cbar
	end
end
