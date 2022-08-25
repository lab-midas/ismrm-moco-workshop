  function h = xlabelf(varargin)
%|function h = xlabelf(varargin)
%| version of xlabel with built-in sprintf

if im
	hh = xlabel(sprintf(varargin{:}));
else
	hh = [];
end

if nargout
	h = hh;
end
