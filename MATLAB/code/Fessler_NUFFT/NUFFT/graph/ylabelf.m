 function h = ylabelf(varargin)
%function h = ylabelf(varargin)
% version of ylabel with built-in sprintf

hh = ylabel(sprintf(varargin{:}));
if nargout
	h = hh;
end
