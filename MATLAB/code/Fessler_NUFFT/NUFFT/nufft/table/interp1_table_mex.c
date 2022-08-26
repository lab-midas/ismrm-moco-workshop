/*
* interp1_table_mex.c
* Mex file for 1D periodic interpolation using table lookup.
*
* forward direction: (for m = 1,...,M)
* f(t_m) = \sum_{k=0}^{K-1} c_k h( (t_m - k) mod K )
*
* The interpolator h is nonzero (and tabulated) for -J/2 <= t <= J/2.
*
* Copyright 2004-3 Yingying Zhang and Jeff Fessler, The University of Michigan
*/
#include "mex.h"
#include "def,table.h"
#include "def,table1.h"


/*
* interp1_table_per_mex()
*/
static int interp1_table_per_mex(
mxArray *plhs[],
const mxArray *mx_ck,
const mxArray *mx_h1,
const mxArray *mx_J,
const mxArray *mx_L,
const mxArray *mx_tm,
const mxArray *mx_order, /* optional: may be NULL */
const mxArray *mx_flips) /* optional: may be NULL */
{
	const int K1 = mxGetM(mx_ck);    /* # of DFT coefficients */
	const int N = mxGetN(mx_ck);    /* # of realizations */
	const int M = mxGetM(mx_tm);    /* # of time samples */

	const int J1 = *((int *) mxGetData(mx_J));
	const int L1 = *((int *) mxGetData(mx_L));

	const double *r_h1 = mxGetPr(mx_h1);
	const double *p_tm = mxGetPr(mx_tm);
	const double *r_ck = mxGetPr(mx_ck);
	const double *i_ck = mxGetPi(mx_ck);

	const int order = mx_order ? *((int *) mxGetData(mx_order)) : 0;
	const int flip1 = mx_flips ? *((int *) mxGetData(mx_flips)) : 0;
	double *r_fm, *i_fm;
	int nn;

	if (N != 1)
		fprintf(stderr, "Caution: multiple columns?");

	Call(mxIsComplexDouble, (mx_ck))
	Call(mxIsRealDouble, (mx_tm))

	/* J, L, must be scalar */
	if (!mxIsScalarInt32(mx_J))
		Fail("J must be scalar int32")
	if (!mxIsScalarInt32(mx_L))
		Fail("L must be scalar int32")
	if (mx_order && !mxIsScalarInt32(mx_order))
		Fail("order must be scalar int32 (0 | 1)")
	if (mx_flips && !mxIsScalarInt32(mx_flips))
		Fail("flips must be scalar int32 (0 | 1)")

	/* check h table size */
	if ((int) mxGetM(mx_h1) != J1*L1+1 || (mxGetN(mx_h1) != 1)) {
		fprintf(stderr, "J=%d L=%d tablelength=%d\n",
			J1, L1, (int) mxGetM(mx_h1));
		Fail("h size problem")
	}

	if (mxGetN(mx_tm) != 1)
		Fail("t_m must be col vector.")

	/* create a new array and set the output pointer to it */
	plhs[0] = mxCreateDoubleMatrix(M, N, mxCOMPLEX);
	r_fm = mxGetPr(plhs[0]);
	i_fm = mxGetPi(plhs[0]);

	/* call the C subroutine N times; once for each realization */
	if (mxIsComplexDouble(mx_h1)) {
		const double *i_h1 = mxGetPi(mx_h1);
		if (order)
			Fail("only 0th order implemented for complex") 
		for (nn=0; nn < N; ++nn) {
			interp1_table0_complex_per(r_ck, i_ck, K1, r_h1, i_h1,
				J1, L1, p_tm, M, r_fm, i_fm);
			r_ck += K1; i_ck += K1;
			r_fm += M; i_fm += M;
		}
	}

	else if (mxIsRealDouble(mx_h1)) {
		interp1_table_real_per_t *fun;
		if (order == 0)		fun = interp1_table0_real_per;
		else if (order == 1)	fun = interp1_table1_real_per;
		else Fail("bad order")

#ifndef Provide_flip
		if (flip1) Fail("flip not compiled")
#endif

		for (nn=0; nn < N; ++nn) {
			fun(r_ck, i_ck, K1, r_h1,
#ifdef Provide_flip
				flip1,
#endif
				J1, L1, p_tm, M, r_fm, i_fm);
			r_ck += K1; i_ck += K1;
			r_fm += M; i_fm += M;
		}
	}

	else
		Fail("h must be real or complex double (preferably real)")

	return 1;
}


/*
* The gateway routine.
* Usage: fm = function(ck, h_table, J, L, tm)
*/
void mexFunction(
int nlhs, mxArray *plhs[],
int nrhs, const mxArray *prhs[])
{
	/* check for the proper number of arguments */
	if (nrhs < 5 || nrhs > 7)
		mexFail("7 inputs needed: (ck, h, J, L, tm, [order, flips])")
	if (nlhs > 1)
		mexFail("Too many output arguments.")

	if (!interp1_table_per_mex(plhs,
		prhs[0], prhs[1], prhs[2], prhs[3], prhs[4],
		nrhs > 5 ? prhs[5] : NULL,
		nrhs > 6 ? prhs[6] : NULL))
		mexFail("interp1_table_mex() failed")

	return;
}
