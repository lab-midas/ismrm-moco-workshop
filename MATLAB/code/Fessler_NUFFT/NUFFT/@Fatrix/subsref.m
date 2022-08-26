 function out = subsref(ob, args)
%function out = subsref(ob, args)
% handle subscript references like ob.ref or ob(ref,:)
% Copyright 2002-2-20, Jeff Fessler, The University of Michigan

%
% handle multiple subscripts, e.g., ob.field()
%
if length(args) > 1
	arg = args(1);
else
	arg = args;
end

%
% ob.?
%
if arg.type == '.'
	out = struct(ob);
	try
		out = out.(arg.subs);
	catch
		out
		error(['No field ' arg.subs])
	end

%
% ob(?)
%
elseif arg.type == '()'
	subs = arg.subs;

	%
	% G(:,:) or G(:,j)
	%
	if length(subs) == 2 & ischar(subs{1}) & streq(subs{1}, ':')
		if ischar(subs{2}) & streq(subs{2}, ':')
			jj = [1:ob.dim(2)]';
		elseif isnumeric(subs{2}) | islogical(subs{2})
			jj = col(subs{2});
		else
			error 'bad G(:,?)'
		end

		if islogical(jj)
			if length(jj) ~= ob.dim(2)
				error 'bad column logical length'
			end
		else
			bad = jj < 1 | jj > ob.dim(2);
			if any(bad)
				printm('bad column indeces:')
				minmax(jj(bad))
				printm('subsref problem')
				keyboard
			end
		end

		%
		% do G(:,?) by matrix multiplication
		%
		out = zeros(ob.dim(1),length(jj));
		for nn=1:length(jj)
			x = zeros(ob.dim(2),1);
			x(jj(nn)) = 1;
			out(:,nn) = ob * x;
		end

	%
	% G(i,:)
	%
	elseif length(subs) == 2 & streq(subs{2}, ':')
		ii = col(subs{1});
		if islogical(ii)
			if length(ii) ~= ob.dim(1)
				error 'bad row logical length'
			end
		elseif any(ii < 1 | ii > ob.dim(1))
			error(sprintf('bad row index %s', num2str(ii)))
		end

		out = zeros(ob.dim(2), length(ii));
		for nn=1:length(ii)
			y = zeros(ob.dim(1), 1);
			y(ii(nn)) = 1;
			out(:,nn) = ob' * y;
		end

	else
		printf('Fatrix subsref of type (%s) called with these args:')
		disp(arg.subs)
		error('That Fatrix subsref type is not done.  Do you mean {1}?')
	end


%
% ob{?} (for ordered-subsets / block methods)
%
elseif arg.type == '{}' & length(arg.subs) == 1
	out = ob;
	if isempty(out.nblock), error 'not a block object', end

	out.iblock = arg.subs{1};
	if out.iblock < 1 | out.iblock > out.nblock
		error 'bad block index'
	end


else
	error(sprintf('type %s notdone', arg.type))
end

if length(args) > 1
	out = subsref(out, args(2:end));
end
