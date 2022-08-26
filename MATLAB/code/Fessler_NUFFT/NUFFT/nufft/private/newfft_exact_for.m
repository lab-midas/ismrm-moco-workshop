  function X = newfft_exact_for(st, x, om)
%|function X = newfft_exact_for(st, x, om)
%| exact forward NUFFT

nthread = 1; % todo
useloop = false; % todo

if ~isvar('om') || isempty(om)
	om = st.om;
end
if isempty(om), error 'om or st.om required', end

if exist('dtft_mex') == 3
	X = jf_mex('dtft,forward', double(om'), double(x), int32(nthread));
	if any(st.n_shift)
		error 'n_shift not done'
	end
else
	X = dtft(x, om, st.n_shift, useloop);
end
