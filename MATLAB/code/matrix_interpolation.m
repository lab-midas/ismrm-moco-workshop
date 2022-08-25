function new = matrix_interpolation(old,interpolationMatrix)
%matrix_interpolation does exactly what it says. "old" is a NxN image,
%"interpolationMatrix" is a N^2xN^2 matrix that will perform a
%transformation and interpolation simply by matrix multiplication.

old = double(old);
interpolationMatrix = double(interpolationMatrix);
new = interpolationMatrix*old(:);

ndims = numel(size(old));
if ndims == 2
    [ymax,xmax] = size(old);
    new = reshape(new,ymax,xmax);
elseif ndims == 3
    [ymax,xmax,zmax] = size(old);
    new = reshape(new,ymax,xmax,zmax);
end

end

