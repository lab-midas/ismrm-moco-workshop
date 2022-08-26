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
        mwPointer mxCreateDoubleMatrix
        mwSize mxGetM, mxGetN
        integer mxIsNumeric, mxIsComplex
        mwSize n1, n2, n3, n4, n5, n6, n7
        mwSize m1, m2, m3, m4, m5, m6, m7
        mwSize matsize
        integer ier
        
!       NUFFT subroutine arguments
        integer nj, iflag, ms, mt
        real*8 eps
        real*8, allocatable :: xj(:), yj(:)
        complex*16, allocatable :: cj(:), fk(:,:)

!       For debugging
        character to_print*80
        integer mexPrintf, nchar

!--------------------------------------------------------------------------

!       Sanity checks

!       Checks for proper number of arguments
        if(nrhs .ne. 5) then
            call mexErrMsgIdAndTxt('MATLAB:nufft2d2:nInput',
     +          'Function requires 5 input arguments.')
        elseif(nlhs .ne. 1) then
            call mexErrMsgIdAndTxt('MATLAB:nufft2d2:nOutput',
     +          'Function requires 1 output argument.')
        endif

!       Checks inputs are numeric
        if(mxIsNumeric(prhs(1)) .ne. 1) then
            call mexErrMsgIdAndTxt('MATLAB:nufft2d2:NonNumeric',
     +          'Input parameter 1 should be numeric.')
        elseif(mxIsNumeric(prhs(2)) .ne. 1) then
            call mexErrMsgIdAndTxt('MATLAB:nufft2d2:NonNumeric',
     +          'Input parameter 2 should be numeric.')
        elseif(mxIsNumeric(prhs(3)) .ne. 1) then
            call mexErrMsgIdAndTxt('MATLAB:nufft2d2:NonNumeric',
     +          'Input parameter 3 should be numeric.')
        elseif(mxIsNumeric(prhs(4)) .ne. 1) then
            call mexErrMsgIdAndTxt('MATLAB:nufft2d2:NonNumeric',
     +          'Input parameter 4 should be numeric.')
        elseif(mxIsComplex(prhs(5)) .ne. 1) then
            call mexErrMsgIdAndTxt('MATLAB:nufft2d2:NonComplex',
     +          'Input parameter 5 should be complex.')
        endif

!       Checks inputs are of right dimensions
        m1 = mxGetM(prhs(1))
        n1 = mxGetN(prhs(1))
        if(n1 .ne. 1) then
            call mexErrMsgIdAndTxt('MATLAB:nufft2d2:WrongDims',
     +          'Input parameter 1 should be a 1D matrix.')
        endif
        
        m2 = mxGetM(prhs(2))
        n2 = mxGetN(prhs(2))
        if(n2 .ne. 1) then
            call mexErrMsgIdAndTxt('MATLAB:nufft2d2:WrongDims',
     +          'Input parameter 2 should be a 1D matrix.')
        endif
        
        m3 = mxGetM(prhs(3))
        n3 = mxGetN(prhs(3))
        if(m3 .ne. 1 .or. n3 .ne. 1) then
            call mexErrMsgIdAndTxt('MATLAB:nufft2d2:NonScalar',
     +          'Input parameter 3 should be a scalar.')
        endif
        
        m4 = mxGetM(prhs(4))
        n4 = mxGetN(prhs(4))
        if(m4 .ne. 1 .or. n4 .ne. 1) then
            call mexErrMsgIdAndTxt('MATLAB:nufft2d2:NonScalar',
     +          'Input parameter 4 should be a scalar.')
        endif
        
        m5 = mxGetM(prhs(5))
        n5 = mxGetN(prhs(5))
        if (.not.(m5 .gt. 1 .and. n5 .gt. 1)) then
            call mexErrMsgIdAndTxt('MATLAB:nufft2d2:WrongDims',
     +          'Input parameter 5 should be a 2D matrix.')
        endif

!       checks xj, yj have compatible dimensions
        if(m1 .ne. m2) then
            call mexErrMsgIdAndTxt('MATLAB:nufft2d2:WrongDims',
     +          'Input parameter 1 and 2 should be of same length.')
        endif

!--------------------------------------------------------------------------

!       I/O arguments management

!       get nufft parameters
        nj = int(m1 * n1)
        call mxCopyPtrToInteger4(mxGetPr(prhs(3)), iflag, 1)
        call mxCopyPtrToReal8(mxGetPr(prhs(4)), eps, 1)
        ms = int(m5)
        mt = int(n5)

!       check their validity...
!       Precision should be a positive scalar in the allowable range
!       (1.0e-13, 1.0e-1)
        if (.not.(eps .gt. 1d-13 .and. eps .lt. 1d-1)) then
            call mexErrMsgIdAndTxt('MATLAB:nufft2d2:WrongValue',
     +          'Input parameter 5 should be in [1e-13, 1e-1].')
        endif

!--------------------------------------------------------------------------

!       Memory allocation

        allocate(xj(nj), stat=ier)
        if(ier .ne. 0) then
            call mexErrMsgIdAndTxt('MATLAB:nufft2d2:MemoryError',
     +          'Memory allocation failed.')
        endif
        call mxCopyPtrToReal8(mxGetPr(prhs(1)), xj, nj)
        
        allocate(yj(nj), stat=ier)
        if(ier .ne. 0) then
            call mexErrMsgIdAndTxt('MATLAB:nufft2d2:MemoryError',
     +          'Memory allocation failed.')
        endif
        call mxCopyPtrToReal8(mxGetPr(prhs(2)), yj, nj)

        allocate(fk(ms, mt), stat=ier)
        if(ier .ne. 0) then
            call mexErrMsgIdAndTxt('MATLAB:nufft2d2:MemoryError',
     +          'Memory allocation failed.')
        endif
        call mxCopyPtrToComplex16(mxGetPr(prhs(5)), mxGetPi(prhs(5)),
     +          fk, ms*mt)

        allocate(cj(nj), stat=ier)
        if(ier .ne. 0) then
            call mexErrMsgIdAndTxt('MATLAB:nufft2d2:MemoryError',
     +          'Memory allocation failed.')
        endif

!--------------------------------------------------------------------------

!       Some debugging

!        write(to_print,*) 'eps = ', eps
!        nchar = mexPrintf(to_print//achar(10))
!        write(to_print,*) 'ms = ', ms
!        nchar = mexPrintf(to_print//achar(10))
!        write(to_print,*) 'mt = ', mt
!        nchar = mexPrintf(to_print//achar(10))
!        write(to_print,*) 'iflag = ', iflag
!        nchar = mexPrintf(to_print//achar(10))

!--------------------------------------------------------------------------

!       Call computational routine
        call nufft2d2f90(nj, xj, yj, cj, iflag, eps, ms, mt, fk, ier)

!--------------------------------------------------------------------------

!       Post-computation treatments

!       Treat returned error code from computational function
        if(ier .ne. 0) then 
                call mexErrMsgIdAndTxt('MATLAB:nufft2d2:ErrorCode',
     +          'Error occured in computational routine')
        endif

!       Copy back results
        plhs(1) = mxCreateDoubleMatrix(nj, 1, 1)
        call mxCopyComplex16ToPtr(cj, mxGetPr(plhs(1)), 
     +          mxGetPi(plhs(1)), nj)

!       Clean dynamicaly allocated variables
        deallocate(xj, stat=ier)
        if(ier .ne. 0) then
            call mexErrMsgIdAndTxt('MATLAB:nufft2d2:MemoryError',
     +          'Memory release failed.')
        endif
        deallocate(yj, stat=ier)
        if(ier .ne. 0) then
            call mexErrMsgIdAndTxt('MATLAB:nufft2d2:MemoryError',
     +          'Memory release failed.')
        endif
        deallocate(cj, stat=ier)
        if(ier .ne. 0) then
            call mexErrMsgIdAndTxt('MATLAB:nufft2d2:MemoryError',
     +          'Memory release failed.')
        endif
        deallocate(fk, stat=ier)
        if(ier .ne. 0) then
            call mexErrMsgIdAndTxt('MATLAB:nufft2d2:MemoryError',
     +          'Memory release failed.')
        endif

        return
        end
