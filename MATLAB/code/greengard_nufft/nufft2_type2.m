function Cj = nufft2_type2(xj, fk, sign, varargin)
% 
% nufft2_type2
% 
% Description
% -----------
% Non-uniform Fourier transform in 2D
% 
% Synthax
% -------
% Fk = nufft2_type2(xj, fk, -1)
% Fk = nufft2_type2(xj, fk, -1, 'double')
% Fk = nufft2_type2(xj, fk, +1, 1e-6)
%      
% Parameters
% ----------
% xj: 2D-matrix [nj, 2]
%     Location of the non-uniform samples, normalized in [-0.5, 0.5)
% fk: 2D-matrix [ms, mt]
%     Uniformly spaced samples, should be complex valued. Assumes that first
%     dimension is x and second dimension is y.
% sign: integer 
% 	  specifies the use of forward (-1) or inverse (+1) Fourier transform
% precision: string or value (optional) 
%     Desired precision for the convolution. Default is 'single' (fastest), 
%     choose 'double' for more accurate results or specify your own in
%     range [1e-13, 1e-1]
%  
% Return
% ------
% Cj: 1D-vector [nj]
%     Fourier transform of the uniform samples at the specified non-uniform 
%     locations.
% 
% Ghislain Vaillant <ghislain.vaillant@kcl.ac.uk> 



%% sanity checks

% constants
Ndims = 2; 

% fk should be 2D...
if ~(ndims(fk) == Ndims && all(size(fk) > 1))
    error('Parameter #2 should be a 2D matrix');
end

% ...and in complex format
if isreal(fk)
    fk = complex(fk);
end

% trajectory should be shaped as [nj, Ndims]
% and convert it to [-pi; pi) convention
try
	xj = double(reshape(xj, [], Ndims)) * 2 * pi;
catch
	error('Unable to reshape trajectory');
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
Cj = nufft2d2_mex(xj(:, 1), xj(:, 2), sign, eps, fk);

