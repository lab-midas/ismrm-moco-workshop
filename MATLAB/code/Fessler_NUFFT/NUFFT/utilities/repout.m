 function varargout = repout(in)
%function varargout = repout(in)
% extension of "deal" to take a single input to multiple outputs, e.g.,
% [a b c] = repout(in)

if nargin < 1, help(mfilename), error(mfilename), end
for ii=1:nargout
	varargout{ii} = in;
end
