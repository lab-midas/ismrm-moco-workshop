function Fk = nufft1_type1(xj, cj, ms, sign, varargin)
% 
% nufft1_type1
% 
% Description
% -----------
% Non-uniform Fourier transform in 1D
% 
% Synthax
% -------
% Fk = nufft1_type1(xj, cj, ms, -1)
% Fk = nufft1_type1(xj, cj, ms, -1, 'double')
% Fk = nufft1_type1(xj, cj, ms, +1, 1e-6)
%      
% Parameters
% ----------
% xj: 1D-vector [nj]
%     Location of the non-uniform samples, normalized in [-0.5, 0.5)
% cj: 1D-vector [nj]
%     Non-uniform samples
% ms: integer
%     Size of the uniform grid in number of grid points.
% sign: integer 
% 	  specifies the use of forward (-1) or inverse (+1) Fourier transform
% precision: string or value (optional) 
%     Desired precision for the convolution. Default is 'single' (fastest), 
%     choose 'double' for more accurate results or specify your own in
%     range [1e-13, 1e-1]
%  
% Return
% ------
% Fk: 1D-vector [ms]
%     NUFFT result
% 
% Ghislain Vaillant <ghislain.vaillant@kcl.ac.uk> 


%% sanity checks

% dimensionality
Ndims = 1; 

% ravel non-uniform data matrix 
cj = cj(:);

% convert to complex format if required
if isreal(cj)
    cj = complex(cj);
end

% get number of elements from raveled data matrix
nj = numel(cj);

% check compatibility with provided trajectory
% and convert it to [-pi; pi) convention
try
	xj = double(reshape(xj, nj, Ndims)) * 2 * pi;
catch
	error('Unable to reshape trajectory to size [%d, %d]', nj, Ndims);
end

% check gridsize parameter is compatible with NUFFT dimension
if size(ms) ~= [1, Ndims]
	error('Gridsize should be of size [1, %d]', Ndims)
end

% check gridsize parameter only contains integers 
if ~all(ms == fix(ms))
	error('Gridsize should only contain integer values')
end

% then convert them to integer-type
ms = int32(ms);

% and check they are all positive 
if ~all((ms > 0))
	error('Grid parameters should be all strictly positive')
end

% sign of the FT
if isnumeric(sign)
	sign = int32(sign);
else
    error('Invalid sign parameter, should be -1 for forward FT, +1 for reverse FT')
end

% optional precision parameter
optargs = {'single'};
nempty  = cellfun(@(x) ~isempty(x), varargin);
optargs(nempty) = varargin(nempty);
[precision] = optargs{:};

% check validity of optional parameters
if strcmp(precision, 'single')
	eps = double(1e-6);
elseif(strcmp(precision, 'double'))
    eps = double(1e-12);
elseif(isnumeric(precision))
    eps = double(precision);
else
    error('Invalid precision parameter, should be ''single'', ''double'' or a numeric value')
end

%% call NUFFT
Fk = nufft1d1_mex(xj, cj, sign, eps, ms);
