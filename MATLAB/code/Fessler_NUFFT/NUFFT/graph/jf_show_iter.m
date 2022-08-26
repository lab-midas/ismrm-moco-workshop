  function out = jf_show_iter(varargin)
%|function out = jf_show_iter([options])
%| function handle to serve as 'userfun' in iterative algorithms
%| to show current iterate
%| call it first to initialize with options:
%|	'mask'	support mask for embed()
%|	'name'	variable name.  default: 'x'
%|	'clim'	color limits for im().  default: []
%|	'draw'	call drawnow()?  default: true
%|	'pause'	call pause() after each display?
%|
%| Copyright 2010-03-10, Jeff Fessler, University of Michigan

persistent arg
if ~isvar('arg') || isempty(arg)
	arg.mask = [];
	arg.name = 'x';
	arg.clim = [];
	arg.draw = true;
	arg.pause = false;
end

if length(varargin)
	printm 'setup'
	arg = vararg_pair(arg, varargin);
	out = 0;
return
end

x = evalin('caller', arg.name);
if isempty(arg.clim)
	im(embed(x, arg.mask))
else
	im(embed(x, arg.mask), arg.clim)
end

if arg.draw
	drawnow
end
if arg.pause
	pause
end
out = 0;
