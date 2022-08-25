function [A] = K2Image (a_complex)

% K2Image does the inverse operations of Image2K, i.e., fourier transforms
% from K-space to image-space.

A = fftshift(ifft2(ifftshift(a_complex)));

end

