  function x = flipdims(x)
%|function x = flipdims(x)
%| generalization of flipdim() and flips all dimensions.
%| this is useful for the adjoint of convolution operator.

for ii = 1:ndims(x)
	x = flipdim(x, ii);
end
