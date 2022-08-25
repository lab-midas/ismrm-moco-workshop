 function h = zlabelf(varargin)
%function h = zlabelf(varargin)
% version of zlabel with built-in sprintf

hh = zlabel(sprintf(varargin{:}));
if nargout
	h = hh;
end
