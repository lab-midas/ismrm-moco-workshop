  function [fw, hr, hl] = fwhm1(psfs, varargin)
%|function [fw, hr, hl] = fwhm1(psfs, options)
%| compute fwhm of point-spread function centered at pixel imid
%| and half-right width and half-left width (fw = hr + hl)
%| in
%|	psfs	[np nc]	column psf(s)
%| option
%|	imid	[1]	which pixel is the middle (default: peak)
%|	chat	0|1	if 1, then plot
%|	dx	[1]	pixel size (default: 1)
%| out
%|	fw	[nc]	fwhm of each psf column

if ~nargin, help(mfilename), error(mfilename), end
if streq(psfs, 'test'), fwhm1_test, return, end

arg.chat = 0;
arg.dx = 1;
arg.imid = [];
arg = vararg_pair(arg, varargin);

psfs = squeeze(psfs); % in case [1 1 np]
[np nc] = size(psfs);
if (np == 1) % single row
	psfs = psfs';
	[np nc] = size(psfs);
end

warned = false;
for ic = 1:nc
	psf = psfs(:,ic);
	if isempty(arg.imid)
		imid = imax(psf);
	else
		imid = arg.imid;
	end

	% normalize
	psf = psf / psf(imid);
	if ~warned & (1 ~= max(psf))
		warn 'peak not at center'
		warned = true;
	end

	% right
	ir = sum(cumprod(double6(psf((imid+1):np) >= 0.5)));
	if (imid + ir == np)
		hr(ic,1) = ir;
	else
		high	= psf(imid + ir);
		low	= psf(imid + ir + 1);
		hr(ic,1) = ir + (high - 1/2) / (high-low);
	end

	% left
	il = sum(cumprod(double6(psf((imid-1):-1:1) >= 0.5)));
	if (il == imid-1)
		hl(ic,1) = il;
	else
		high	= psf(imid - il);
		low	= psf(imid - il - 1);
		hl(ic,1) = il + (high - 1/2) / (high-low);
	end
end

hr = hr * arg.dx;
hl = hl * arg.dx;
fw = hr + hl;

if arg.chat && im
	plot(([1:np]-imid)*arg.dx, psf, '-o', ...
	[-hl hr], [0.5 0.5], '-')
	xlabel 'x', ylabel 'psf(x)'
	title(sprintf('fwhm=%g', fw))
end


%
% fwhm1_test
%
function fwhm1_test
dx = 3;
nx = 100;
xx = [-nx/2:nx/2-1]' * dx;
fx = 30;
sx = fx / sqrt(log(256));
psf = exp(-((xx/sx).^2)/2);
fw = fwhm1(psf, 'dx', dx, 'chat', 1);
