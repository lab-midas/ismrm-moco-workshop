 function fail(varargin)
%|function fail(varargin)
%|
%| fail with concise but informative error message.
%| the motivation for this routine is that sometimes matlab's error command
%| annoyingly does not tell the file/line where the error occured.
%| this call ensures that the file/line is always displayed.

[name line] = caller_name(1);
if length(varargin)
	printf(['Fail: %s %d: ' varargin{1}], name, line, varargin{2:end})
else
	printf(['Fail: %s %d'], name, line)
end
%error fail
evalin('caller', 'error(''!'')')
