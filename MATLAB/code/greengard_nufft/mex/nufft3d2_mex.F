#include "fintrf.h"
!==========================================================================
!   
!     nufft2d2_mex.f
!
!     Fortran wrapper for NUFFT 2 function from original Greengard's code
!      
!     @Author: Ghislain Vaillant <ghislain.vaillant@kcl.ac.uk>
!==========================================================================
!       Gateway routine
        subroutine mexFunction(nlhs, plhs, nrhs, prhs)
        implicit none

!       mexFunction arguments
        mwPointer plhs(*), prhs(*)
        integer nlhs, nrhs
        
!       Declarations
        mwPointer mxGetPr, mxGetPi
        mwPointer mxCreateDoubleMatrix, mxGetDimensions
        mwSize mxGetM, mxGetN, mxGetNumberOfDimensions
        integer mxIsNumeric, mxIsComplex
        integer mxClassIDFromClassName
        mwSize n1, n2, n3, n4, n5, n6
        mwSize m1, m2, m3, m4, m5, m6
        mwSize p6, nd6
        mwSize matdims(3)
        integer ier, complexFlag
        
!       NUFFT subroutine arguments
        integer nj, iflag, ms, mt, mu
        real*8 eps
        real*8, allocatable :: xj(:), yj(:), zj(:)
        complex*16, allocatable :: cj(:), fk(:,:,:)

!       For debugging
!       character to_print*80
!       integer mexPrintf, nchar

!--------------------------------------------------------------------------

!       Sanity checks

!       Checks for proper number of arguments
        if(nrhs .ne. 6) then
            call mexErrMsgIdAndTxt('MATLAB:nufft3d2:nInput',
     +          'Function requires 6 input arguments.')
        elseif(nlhs .ne. 1) then
            call mexErrMsgIdAndTxt('MATLAB:nufft3d2:nOutput',
     +          'Function requires 1 output argument.')
        endif

!       Checks inputs are numeric
        if(mxIsNumeric(prhs(1)) .ne. 1) then
            call mexErrMsgIdAndTxt('MATLAB:nufft3d2:NonNumeric',
     +          'Input parameter 1 should be numeric.')
        elseif(mxIsNumeric(prhs(2)) .ne. 1) then
            call mexErrMsgIdAndTxt('MATLAB:nufft3d2:NonNumeric',
     +          'Input parameter 2 should be numeric.')
        elseif(mxIsNumeric(prhs(3)) .ne. 1) then
            call mexErrMsgIdAndTxt('MATLAB:nufft3d2:NonNumeric',
     +          'Input parameter 3 should be numeric.')
        elseif(mxIsNumeric(prhs(4)) .ne. 1) then
            call mexErrMsgIdAndTxt('MATLAB:nufft3d2:NonNumeric',
     +          'Input parameter 4 should be numeric.')
        elseif(mxIsNumeric(prhs(5)) .ne. 1) then
            call mexErrMsgIdAndTxt('MATLAB:nufft3d2:NonNumeric',
     +          'Input parameter 5 should be numeric.')
        elseif(mxIsComplex(prhs(6)) .ne. 1) then
            call mexErrMsgIdAndTxt('MATLAB:nufft3d2:NonComplex',
     +          'Input parameter 6 should be complex.')
        endif

!       Checks inputs are of right dimensions
        m1 = mxGetM(prhs(1))
        n1 = mxGetN(prhs(1))
        if(n1 .ne. 1) then
            call mexErrMsgIdAndTxt('MATLAB:nufft3d2:WrongDims',
     +          'Input parameter 1 should be a 1D matrix.')
        endif
        
        m2 = mxGetM(prhs(2))
        n2 = mxGetN(prhs(2))
        if(n2 .ne. 1) then
            call mexErrMsgIdAndTxt('MATLAB:nufft3d2:WrongDims',
     +          'Input parameter 2 should be a 1D matrix.')
        endif

        m3 = mxGetM(prhs(3))
        n3 = mxGetN(prhs(3))
        if(n3 .ne. 1) then
            call mexErrMsgIdAndTxt('MATLAB:nufft3d2:WrongDims',
     +          'Input parameter 3 should be a 1D matrix.')
        endif
        
        m4 = mxGetM(prhs(4))
        n4 = mxGetN(prhs(4))
        if(m4 .ne. 1 .or. n4 .ne. 1) then
            call mexErrMsgIdAndTxt('MATLAB:nufft3d2:NonScalar',
     +          'Input parameter 4 should be a scalar.')
        endif

        m5 = mxGetM(prhs(5))
        n5 = mxGetN(prhs(5))
        if(m5 .ne. 1 .or. n5 .ne. 1) then
            call mexErrMsgIdAndTxt('MATLAB:nufft3d2:NonScalar',
     +          'Input parameter 5 should be a scalar.')
        endif
        
!	handling of multi-dimensional array is more complex
!	first, get the dimensionality and check it is indeed 3 
        nd6 = mxGetNumberOfDimensions(prhs(6))
        if (nd6 .ne. 3) then
            call mexErrMsgIdAndTxt('MATLAB:nufft3d2:WrongDims',
     +          'Input parameter 6 should be a 3D matrix.')
	endif
!	second, use Ptr to Ptr copy to translate mwPointer to the
!	Fortran array containing each dimension
        call mxCopyPtrToPtrArray(mxGetDimensions(prhs(6)),
     +		matdims, nd6)
!	finally, recover each dimension into individual variables
!	for further checking           
        m6 = matdims(1)
        n6 = matdims(2)
        p6 = matdims(3)
        if (.not.(m6 .gt. 1 .and. n6 .gt. 1 .and. p6 .gt. 1)) then
            call mexErrMsgIdAndTxt('MATLAB:nufft3d2:WrongDims',
     +          'Input parameter 6 should be a 3D matrix.')
        endif

!       checks xj, yj, zj have compatible dimensions
        if (.not.(m1 .eq. m2 .and. m1 .eq. m3)) then
            call mexErrMsgIdAndTxt('MATLAB:nufft3d2:WrongDims',
     +          'Input parameter 1, 2 and 3 should be of same length.')
        endif

!--------------------------------------------------------------------------

!       I/O arguments management

!       get nufft parameters
        nj = int(m1 * n1)
        call mxCopyPtrToInteger4(mxGetPr(prhs(4)), iflag, 1)
        call mxCopyPtrToReal8(mxGetPr(prhs(5)), eps, 1)
        ms = int(m6)
        mt = int(n6)
        mu = int(p6)

!       check their validity...
!       Precision should be a positive scalar in the allowable range
!       (1.0e-13, 1.0e-1)
        if (.not.(eps .gt. 1d-13 .and. eps .lt. 1d-1)) then
            call mexErrMsgIdAndTxt('MATLAB:nufft3d2:WrongValue',
     +          'Input parameter 5 should be in [1e-13, 1e-1].')
        endif


!--------------------------------------------------------------------------

!       Some debugging

!        write(to_print,*) 'eps = ', eps
!        nchar = mexPrintf(to_print//achar(10))
!        write(to_print,*) 'ndims = ', nd6
!        nchar = mexPrintf(to_print//achar(10))
!        write(to_print,*) 'ms = ', matdims(1)
!        nchar = mexPrintf(to_print//achar(10))
!        write(to_print,*) 'mt = ', matdims(2)
!        nchar = mexPrintf(to_print//achar(10))
!        write(to_print,*) 'mu = ', matdims(3)
!        nchar = mexPrintf(to_print//achar(10))

!--------------------------------------------------------------------------

!       Memory allocation

        allocate(xj(nj), stat=ier)
        if(ier .ne. 0) then
            call mexErrMsgIdAndTxt('MATLAB:nufft3d2:MemoryError',
     +          'Memory allocation failed.')
        endif
        call mxCopyPtrToReal8(mxGetPr(prhs(1)), xj, nj)
        
        allocate(yj(nj), stat=ier)
        if(ier .ne. 0) then
            call mexErrMsgIdAndTxt('MATLAB:nufft3d2:MemoryError',
     +          'Memory allocation failed.')
        endif
        call mxCopyPtrToReal8(mxGetPr(prhs(2)), yj, nj)
        
        allocate(zj(nj), stat=ier)
        if(ier .ne. 0) then
            call mexErrMsgIdAndTxt('MATLAB:nufft3d2:MemoryError',
     +          'Memory allocation failed.')
        endif
        call mxCopyPtrToReal8(mxGetPr(prhs(3)), zj, nj)

        allocate(fk(ms, mt, mu), stat=ier)
        if(ier .ne. 0) then
            call mexErrMsgIdAndTxt('MATLAB:nufft3d2:MemoryError',
     +          'Memory allocation failed.')
        endif
        call mxCopyPtrToComplex16(mxGetPr(prhs(6)), mxGetPi(prhs(6)),
     +          fk, ms*mt*mu)

        allocate(cj(nj), stat=ier)
        if(ier .ne. 0) then
            call mexErrMsgIdAndTxt('MATLAB:nufft3d2:MemoryError',
     +          'Memory allocation failed.')
        endif

!       Call computational routine
        call nufft3d2f90(nj, xj, yj, zj, cj, iflag, eps, ms, mt, mu, 
     +          fk, ier)

!--------------------------------------------------------------------------

!       Post-computation treatments

!       Treat returned error code from computational function
        if(ier .ne. 0) then 
                call mexErrMsgIdAndTxt('MATLAB:nufft3d2:ErrorCode',
     +          'Error occured in computational routine')
        endif

!       Copy back results
        complexFlag = 1
        plhs(1) = mxCreateDoubleMatrix(nj, 1, complexFlag)
        call mxCopyComplex16ToPtr(cj, mxGetPr(plhs(1)), 
     +          mxGetPi(plhs(1)), nj)

!       Clean dynamicaly allocated variables
        deallocate(xj, stat=ier)
        if(ier .ne. 0) then
            call mexErrMsgIdAndTxt('MATLAB:nufft3d2:MemoryError',
     +          'Memory release failed.')
        endif
        deallocate(yj, stat=ier)
        if(ier .ne. 0) then
            call mexErrMsgIdAndTxt('MATLAB:nufft3d2:MemoryError',
     +          'Memory release failed.')
        endif
        deallocate(zj, stat=ier)
        if(ier .ne. 0) then
            call mexErrMsgIdAndTxt('MATLAB:nufft3d2:MemoryError',
     +          'Memory release failed.')
        endif
        deallocate(cj, stat=ier)
        if(ier .ne. 0) then
            call mexErrMsgIdAndTxt('MATLAB:nufft3d2:MemoryError',
     +          'Memory release failed.')
        endif
        deallocate(fk, stat=ier)
        if(ier .ne. 0) then
            call mexErrMsgIdAndTxt('MATLAB:nufft3d2:MemoryError',
     +          'Memory release failed.')
        endif

        return
        end
