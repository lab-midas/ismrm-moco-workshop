 function [rhat, s] = rms(x)
%function [rhat, s] = rms(x)
% function [r, s] = rms(err)
% in:
%	x: NxM	error vectors
% out:
%	r: Mx1		estimate of rms error
%	s: Mx1		estimate of std. dev. of that estimate
if streq(x, 'test'), rms_test, return, end

N = nrow(x);	if (N==1), error('ERROR: use column vector'), end
bs = mean(x);
st = std(x);
rhat = sqrt(mean(abs(x).^2, 1));

var_mse = (2*st.^4 + 4*st.^2 .* bs.^2)/N;
if rhat > 0
	s = sqrt( var_mse / 4 ./ rhat.^2 );
else
	s = 0;
	if nargout > 1
		warning 's meaningless'
	end
end

if ~nargout
	base = '';
	fprintf('%srms(%s) =', base, inputname(1))
	fprintf(' %g', rhat)
	fprintf('\n')
	clear rhat
end


function rms_test
rand('state', 7)
r = (rand(10^4,3)-0.5) * sqrt(12);
rms(r)
