% jf_whos_nan
% script to find variables in work space that have nan values

zzz.st = evalin('caller', 'whos');
for ii=1:length(zzz.st)
	zzz.cl = zzz.st(ii).class;
	zzz.name = zzz.st(ii).name;
	if streq(zzz.cl, 'double') || streq(zzz.cl, 'single')
		try
			zzz.tmp = sprintf('sum(isnan(%s(:)))', zzz.name);
%			disp(zzz.tmp)
			zzz.tmp = eval(zzz.tmp);
			if zzz.tmp
				printm('%d nan in %s', zzz.tmp, zzz.name);
			end
		catch
			printm(['unsure: ' zzz.name])
		end
	end
end
