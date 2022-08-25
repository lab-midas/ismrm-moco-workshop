function Cj = nufft1_type2(xj, fk, sign, varargin)
% 
% nufft1_type2
% 
% Description
% -----------
% Non-uniform Fourier transform in 2D
% 
% Synthax
% -------
% Fk = nufft1_type2(xj, fk, -1)
% Fk = nufft1_type2(xj, fk, -1, 'double')
% Fk = nufft1_type2(xj, fk, +1, 1e-6)
%      
% Parameters
% ----------
% xj: 1D-matrix [nj, 1]
%     Location of the non-uniform samples, normalized in [-0.5, 0.5)
% fk: 1D-matrix [ms]
%     Uniformly spaced samples, should be complex valued
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
%     Results of the NUFFT
% 
% Ghislain Vaillant <ghislain.vaillant@kcl.ac.uk> 


%% sanity checks

% dimensionality
Ndims = 1; 

% fk should be 2D...
if ~(size(fk,1) == numel(fk))
    error('Parameter #2 should be a 1D matrix');
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
optargs = {'single', -1};
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
Cj = nufft1d2_mex(xj(:, 1), sign, eps, fk);
