  function [alphas, beta] = nufft_alpha_kb_fit(N, J, K, varargin)
%|function [alphas, beta] = nufft_alpha_kb_fit(N, J, K, varargin)
%|
%| return the alpha and beta corresponding to LS fit of L components
%| to optimized Kaiser-Bessel scaling factors (m=0, alpha=2.34J).
%| This is the best method I know currently for choosing alpha!
%|
%| option
%|	Nmid	[1]	midpoint: floor(N/2) or default (N-1)/2
%|
%| Copyright 2002-7-16, Jeff Fessler, The University of Michigan

if nargin < 3, help(mfilename), error(mfilename), end

arg.beta = 1;
arg.chat = 0;
arg.Nmid = (N-1)/2;
if N > 40
	arg.L = 13;		% empirically found to be reasonable
else
	arg.L = ceil(N/3);	% a kludge to avoid "rank deficient" complaints
end

arg = vararg_pair(arg, varargin);

%kb_alf = 2.34 * J;	% KB shape parameter
%kb_m = 0;		% KB order

nlist = [0:(N-1)]' - arg.Nmid;

if 0 % old way
	[tmp, sn_kaiser] = nufft1_error(0, N, J, K, 'kaiser', 'ft');
	sn_kaiser = reale(sn_kaiser);
else
	% kaiser-bessel with previously numerically-optimized shape
	[kernel, kb_a, kb_m] = kaiser_bessel('string', J, 'best', 0, K/N);
	kernel_ft = kaiser_bessel_ft('inline', J, kb_a, kb_m, 1);
	sn_kaiser = 1 ./ kernel_ft(nlist/K); % [N]
end


%
% use regression to match NUFFT with BEST kaiser scaling's
%
gam = 2*pi/K;
X = cos(arg.beta*gam*nlist*[0:arg.L]);	% [N,L]
coef = (X \ sn_kaiser)';	% regress(sn_kaiser, X)';
alphas = [reale(coef(1)) coef(2:end)/2];

if arg.chat
	printm('cond # for LS fit to KB scale factors: %g', cond(X))
end

beta = arg.beta;
