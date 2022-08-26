  function ft = bspline_1d_interp(fn, ti, varargin)
%|function ft = bspline_1d_interp(fn, ti, varargin)
%|
%| given f[n], the "unit spaced" samples of a continuous signal f(t),
%| perform b-spline interpolation at sample locations t_i using the model:
%|	f(t) = \sum_{k=0}^{N-1} coef_k b(t - k)
%| where the coefficients are computed internally using bspline_1d_coef.m
%|
%| in
%|	fn	[N (L)]			1d signal(s) samples
%|	ti	[M 1] or [M (L)]	desired sample points (unitless)
%| option
%|	order		default: 3
%|	ending		end / boundary conditions: mirror / periodic / zero
%|	mex		0 to disable mex (default: 1)
%|	ob		1 to create Fatrix object (default: 0)
%| out
%|	ft	[M (L)]			f(t_i) interpolated signal values
%|
%| Copyright 2005-12-7, Jeff Fessler, University of Michigan

if nargin == 1 && streq(fn, 'test'), bspline_1d_interp_test, return, end
if nargin < 2, help(mfilename), error(mfilename), end

arg.order = 3;
arg.ending = 'periodic';
arg.mex = 1; % default is to try mex
arg.ob = false; % 1 to create Fatrix

arg = vararg_pair(arg, varargin);

arg.ti = ti;
arg.N = size(fn,1);

ii = strvcat('mirror', 'periodic', 'zero');
arg.ie = strmatch(arg.ending, ii, 'exact');
if length(arg.ie) ~= 1, error 'unknown end conditions', end

if arg.ob
	ft = bspline_1d_interp_ob(arg);
return
end

ft = bspline_1d_interp_arg(arg, fn);


%
% bspline_1d_interp_ob()
%
function ob = bspline_1d_interp_ob(arg)
if size(arg.ti,2) == 1
	dim = [length(arg.ti) arg.N];
else
	dim = [numel(arg.ti) arg.N*size(arg.ti,2)];
end
ob = Fatrix(dim, arg, 'caller', 'bspline_1d_interp', ...
        'forw', @bspline_1d_interp_arg, 'back', @bspline_1d_interp_adj);


%
% bspline_1d_interp_adj()
%
function fn = bspline_1d_interp_adj(arg, ft)
fn = jf_mex('bspline,interp,adj,1d', ...
	single(ft), single(arg.ti), int32(arg.N), ...
	int32(arg.order), int32(arg.ie));


%
% bspline_1d_interp_arg()
%
function ft = bspline_1d_interp_arg(arg, fn)

if arg.mex
	try
		ft = jf_mex('bspline,interp,1d', single(fn), single(arg.ti), ...
			int32(arg.order), int32(arg.ie));
		return
	catch
		printm 'mex failed; revert to matlab'
	end
end

ck = bspline_1d_coef(fn, 'order', arg.order, 'ending', arg.ending);
ft = bspline_1d_synth(ck, arg.ti, 'order', arg.order, 'ending', arg.ending);


%
% test
%
function bspline_1d_interp_test

N = 12;
ff = inline('t+1', 't');
ff = inline('1+cos(2*pi*t/6)', 't');
n = [0:N-1]';
fn = ff(n);

ti = linspace(-4,N+4,41*(N+8)+1)';
ft = ff(ti);
if 0 % test multi
	ti = [ti flipud(ti)];
	fn = [fn 2+flipud(fn)];
end

%fn = single(fn);
%ti = single(ti);

orders = [1 3];
endings = {'mirror', 'periodic', 'zero'};

fx = cell(2,3);
fm = cell(2,3);
for io = 1:length(orders)
	order = orders(io);
	for ie = 1:length(endings)
		ending = endings{ie};
		arg = {'order', order, 'ending', ending};
		fx{io,ie} = bspline_1d_interp(fn, ti, arg{:}, 'mex', 1);
		fm{io,ie} = bspline_1d_interp(fn, ti, arg{:}, 'mex', 0);
		max_percent_diff(fx{io,ie}, fm{io,ie})
		if 0 & io==1 & ie==1
			plot(n, fn, 'ro', ti, ft, 'y-', ...
				ti, fx{io,ie}, 'g', ti, fm{io,ie}, 'c')
			keyboard
		end
		if has_mex_jf % test adjoint
			A = bspline_1d_interp(single(eye(N)), ti, arg{:});
			B = jf_mex('bspline,interp,adj,1d', ...
				single(eye(length(ti))), ...
				single(ti), int32(N), int32(order), int32(ie));
			if max(col(abs(A-B'))) > 1e-5, error 'adjoint', end

			A = bspline_1d_interp(ones(N,1), ti, arg{:}, 'ob', 1);
			B = A' * eye(length(ti));
			A = A * eye(N);
			if max(col(abs(A-B'))) > 1e-5, error 'adjoint', end
		end
	end
end

if im
	subplot(211)
	plot(n, fn, 'ro', ti, ft, 'b-', ...
		ti, fm{1,1}, 'm-.', ...
		ti, fm{1,2}, 'y--', ...
		ti, fm{1,3}, 'g--')
	legend('sample', 'f(t)', '1m', '1p', '1z', 'location', 'south')
	subplot(212)
	plot(n, fn, 'ro', ti, ft, 'b-', ...
		ti, fm{2,1}, 'm-.', ...
		ti, fm{2,2}, 'y--', ...
		ti, fm{2,3}, 'g--')
	legend('sample', 'f(t)', '3m', '3p', '3z', 'location', 'south')
end

%max_percent_diff(ft, fm{2,2})
