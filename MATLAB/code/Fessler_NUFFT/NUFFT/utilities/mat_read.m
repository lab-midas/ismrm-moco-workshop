 function x = mat_read(file, pick)
%function x = mat_read(file, pick)
% read a matlab matrix from file, e.g., 'data.mat'
% if pick is an integer, it indexes which field in the file is desired.
% Jeff Fessler, The University of Michigan

if nargin < 1, help(mfilename), error args, end
if ~isvar('pick') | isempty(pick), pick = 0; end

s = load(file);
names = fieldnames(s);
name = names{1};
if length(names) > 1
	if ~isa(pick, 'numeric')
		error 'only numeric picking done now'
	end
	if pick < 1
		disp(names)
		warning(sprintf('using default first array: %s', name))
	elseif pick > length(names)
		error 'pick too large'
	else
		name = names{pick};
		printf('Using array %s', name)
	end
end
x = s.(name);
