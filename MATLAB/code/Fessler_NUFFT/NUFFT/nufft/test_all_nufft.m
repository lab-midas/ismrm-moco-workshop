% test_all_nufft.m

list = {
	'dtft test'
	'fftn_fast test'
	'ifftn_fast test'
	'interp_table_test'
	'kaiser_bessel_xray test'
%	'my_fftn'
%	'newfft'
	'nufft1_build test'
	'nufft_init test'
	'nufft_scale test'
	'nufft_sinc test'
	'nufft_table_test'
	'nufft test'
};

run_mfile_local(list)
%run_mfile_local(list, 'draw', 1, 'pause', 1)
