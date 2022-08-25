  function out = prompt(arg)
%|function out = prompt(arg)
%|
%| in my matlab scripts, there are three possible modes of execution
%| that are controlled by this m-file
%|	pause			tell user to hit enter key to continue
%|				(or user can type 'r' or 'run')
%|	return | stop		force user to re-run to continue
%|	run | continue		just run to end without stopping
%|	draw			'drawnow' then continue
%|	mode			return current prompt mode
%|
%| Copyright 2001-8-30, Jeff Fessler, University of Michigan

persistent Prompt % stores state
if ~isvar('Prompt') || isempty(Prompt)
	Prompt = 'pause';
end

% query mode
if ~nargin & nargout
	out = Prompt;
return
end

% set mode (or give help)
if nargin & ~nargout
	if streq(arg, 'help')
		help(mfilename)
	elseif streq(arg, 'mode')
		if nargout
			out = Prompt;
		else
			printm(Prompt)
		end
		return
	else
		Prompt = arg;
	end
return
end


% 'return' | 'stop'
% fix: we really need a "return all" call here!
% dbquit?
switch Prompt
case {'return', 'stop'}
%	disp ' '
%	disp 'returning'
%	return	% does not work!
%	evalin('base', 'return')
%	evalin('caller', 'return')
	error 'fake error to effect a "return all"'

% 'draw'
case 'draw'
	drawnow	% do nothing, just continue

% 'run'
case {'run', 'continue'}
%	disp ' ' % do nothing, just continue

% 'pause'
case 'pause'
	[name line] = caller_name;
	if isempty(name)
		preface = [];
	else
		preface = sprintf('%s %d: ', name, line);
	end

	what = 'hit enter to continue (or [r]un [d]raw [q]uit [n]odraw): ';
	ans = input([preface  what], 's');
	if streq(ans, 'r', 1)
		Prompt = 'run';
	elseif streq(ans, 'd', 1)
		Prompt = 'draw';
	elseif streq(ans, 'n', 1)
		Prompt = 'run';
		im off
		close all
	elseif streq(ans, 'q', 1)
		fail('quitting')
	elseif ~isempty(ans)
		Prompt = ans;
	end

otherwise
	warn('unknown Prompt mode "%s"; resetting to ''pause''', Prompt)
	Prompt = 'pause';
	prompt
end
