function [a_complex] = Image2K (A)

% Image2K: Takes the 2-FFT of image A, followed by fftshift 
% to put small frequencies in the center. Returns this fourier transform in 
% absolute values (a_abs) and in its complete complex form (a_complex).

a_complex = fftshift(fft2(ifftshift(A)));

end

