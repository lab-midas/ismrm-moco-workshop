 function xpad = pad_into_center(x, npad)
%function xpad = pad_into_center(x, npad)
% Zero pad an input signal x symmetrically around "0" (image center).
% Useful for DFT/FFT of PSF.
% todo: replace with matlab's padarray.m
% Originally by A. Yendiki, modified by Jeff Fessler, 2005-7-26.

if nargin < 1, help(mfilename), error(mfilename), end
if nargin == 1 && streq(x, 'test'), pad_into_center_test, return, end

if length(npad) == 1
	if min(size(x)) == 1 % 1d.  kludge: wrong if size(x) = [nx,1,nz]
		if size(x,1) == 1
			npad = [1 npad];
		else
			npad = [npad 1];
		end
	else % n-dimensional; pad all dimensions the same amount
		npad = repmat(npad, [1 ndims(x)]);
	end
end


ndim = ndims(x);
if ndim ~= length(npad)
	error 'Incorrect number of dimensions'
end

args = cell(ndim,1);
for id = 1:ndim
	nold = size(x,id);
	nnew = npad(id);
	if nold > nnew
		error(sprintf('Padding[%d]=%d too small cf %d', id, nnew, nold))
	end
	args{id} = [1:nold] + ceil((nnew - nold)/2);
end
xpad = zeros(npad);
xpad(args{:}) = x;


function pad_into_center_test
pad_into_center([1 2 1], [7])
pad_into_center([1 2 1]', [7])'
pad_into_center([1 2 1], [7 3])
pad_into_center([1 2 1]', [7 3])
pad_into_center(ones(3), [5 7])
