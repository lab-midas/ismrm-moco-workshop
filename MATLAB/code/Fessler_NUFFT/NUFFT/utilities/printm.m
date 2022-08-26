  function printm(varargin)
%|function printm(varargin)
%| like printf except that it puts the mfilename in front of it
%| so that you know where the message originated.

[caller line] = caller_name;
if ~isempty(line) && line ~= 0
	caller = [caller sprintf(' %d', line)];
end
if length(varargin)
	disp([caller ': ' sprintf(varargin{:})])
else
	disp([caller ': '])
end
