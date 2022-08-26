 function sn = nufft_scale(Nd, Jd, Kd, kb_alf, kb_m)
%function sn = nufft_scale(Nd, Jd, Kd, kb_alf, kb_m)
% Compute KB scaling factors for NUFFT
% in:
%	N,J,K
%	kb_alf	[d]
%	kb_m	[d]
% out:
%	sn	[[Nd]]		scaling factors
%
% Copyright 2004-7-8, Jeff Fessler, The University of Michigan

if nargin < 5, help(mfilename), error(mfilename), end

%
% scaling factors: "outer product" of 1D vectors
%
sn = 1;
dd = length(Nd);
for id=1:dd
	nc = [0:Nd(id)-1]'-(Nd(id)-1)/2;
	tmp = 1 ./ kaiser_bessel_ft(nc/Kd(id), Jd(id), kb_alf(id), kb_m(id), 1);
	sn = sn(:) * tmp';
end
if length(Nd) > 1
	sn = reshape(sn, Nd);	% [(Nd)]
else
	sn = sn(:);	% [(Nd)]
end
