#include "fintrf.h"
!==========================================================================
!   
!     nufft3d1_mex.f
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
        mwPointer mxCreateNumericArray
        mwSize mxGetM, mxGetN
        integer mxIsNumeric, mxIsComplex
        integer mxClassIDFromClassName
        mwSize n1, n2, n3, n4, n5, n6, n7, n8, n9
        mwSize m1, m2, m3, m4, m5, m6, m7, m8, m9
        mwSize matdims(3)
        integer ier, classid, complexFlag
        
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
        if(nrhs .ne. 9) then
            call mexErrMsgIdAndTxt('MATLAB:nufft3d1:nInput',
     +          'Function requires 9 input arguments.')
        elseif(nlhs .ne. 1) then
            call mexErrMsgIdAndTxt('MATLAB:nufft3d1:nOutput',
     +          'Function requires 1 output argument.')
        endif

!       Checks inputs are numeric
        if(mxIsNumeric(prhs(1)) .ne. 1) then
            call mexErrMsgIdAndTxt('MATLAB:nufft3d1:NonNumeric',
     +          'Input parameter 1 should be numeric.')
        elseif(mxIsNumeric(prhs(2)) .ne. 1) then
            call mexErrMsgIdAndTxt('MATLAB:nufft3d1:NonNumeric',
     +          'Input parameter 2 should be numeric.')
        elseif(mxIsNumeric(prhs(3)) .ne. 1) then
            call mexErrMsgIdAndTxt('MATLAB:nufft3d1:NonNumeric',
     +          'Input parameter 3 should be numeric.')
        elseif(mxIsComplex(prhs(4)) .ne. 1) then
            call mexErrMsgIdAndTxt('MATLAB:nufft3d1:NonComplex',
     +          'Input parameter 4 should be complex.')
        elseif(mxIsNumeric(prhs(5)) .ne. 1) then
            call mexErrMsgIdAndTxt('MATLAB:nufft3d1:NonNumeric',
     +          'Input parameter 5 should be numeric.')
        elseif(mxIsNumeric(prhs(6)) .ne. 1) then
            call mexErrMsgIdAndTxt('MATLAB:nufft3d1:NonNumeric',
     +          'Input parameter 6 should be numeric.')
        elseif(mxIsNumeric(prhs(7)) .ne. 1) then
            call mexErrMsgIdAndTxt('MATLAB:nufft3d1:NonNumeric',
     +          'Input parameter 7 should be numeric.')
        elseif(mxIsNumeric(prhs(8)) .ne. 1) then
            call mexErrMsgIdAndTxt('MATLAB:nufft3d1:NonNumeric',
     +          'Input parameter 8 should be numeric.')
        elseif(mxIsNumeric(prhs(9)) .ne. 1) then
            call mexErrMsgIdAndTxt('MATLAB:nufft3d1:NonNumeric',
     +          'Input parameter 9 should be numeric.')
        endif

!       Checks inputs are of right dimensions
        m1 = mxGetM(prhs(1))
        n1 = mxGetN(prhs(1))
        if(n1 .ne. 1) then
            call mexErrMsgIdAndTxt('MATLAB:nufft3d1:WrongDims',
     +          'Input parameter 1 should be a 1D matrix.')
        endif
        
        m2 = mxGetM(prhs(2))
        n2 = mxGetN(prhs(2))
        if(n2 .ne. 1) then
            call mexErrMsgIdAndTxt('MATLAB:nufft3d1:WrongDims',
     +          'Input parameter 2 should be a 1D matrix.')
        endif
        
        m3 = mxGetM(prhs(3))
        n3 = mxGetN(prhs(3))
        if(n3 .ne. 1) then
            call mexErrMsgIdAndTxt('MATLAB:nufft3d1:WrongDims',
     +          'Input parameter 3 should be a 1D matrix.')
        endif
        
        m4 = mxGetM(prhs(4))
        n4 = mxGetN(prhs(4))
        if(n4 .ne. 1) then
            call mexErrMsgIdAndTxt('MATLAB:nufft3d1:WrongDims',
     +          'Input parameter 4 should be a 1D matrix.')
        endif
        
        m5 = mxGetM(prhs(5))
        n5 = mxGetN(prhs(5))
        if(m5 .ne. 1 .or. n5 .ne. 1) then
            call mexErrMsgIdAndTxt('MATLAB:nufft3d1:NonScalar',
     +          'Input parameter 5 should be a scalar.')
        endif
        
        m6 = mxGetM(prhs(6))
        n6 = mxGetN(prhs(6))
        if(m6 .ne. 1 .or. n6 .ne. 1) then
            call mexErrMsgIdAndTxt('MATLAB:nufft3d1:NonScalar',
     +          'Input parameter 6 should be a scalar.')
        endif

        m7 = mxGetM(prhs(7))
        n7 = mxGetN(prhs(7))
        if(m7 .ne. 1 .or. n7 .ne. 1) then
            call mexErrMsgIdAndTxt('MATLAB:nufft3d1:NonScalar',
     +          'Input parameter 7 should be a scalar.')
        endif

        m8 = mxGetM(prhs(8))
        n8 = mxGetN(prhs(8))
        if(m8 .ne. 1 .or. n8 .ne. 1) then
            call mexErrMsgIdAndTxt('MATLAB:nufft3d1:NonScalar',
     +          'Input parameter 8 should be a scalar.')
        endif

        m9 = mxGetM(prhs(9))
        n9 = mxGetN(prhs(9))
        if(m9 .ne. 1 .or. n9 .ne. 1) then
            call mexErrMsgIdAndTxt('MATLAB:nufft3d1:NonScalar',
     +          'Input parameter 9 should be a scalar.')
        endif

!       checks xj, yj, zj and cj have compatible dimensions
        if(m1 .ne. m2 .or. m1 .ne. m3 .or. m1 .ne. m4) then
            call mexErrMsgIdAndTxt('MATLAB:nufft3d1:WrongDims',
     +      'Input parameter 1, 2, 3, and 4 should be of same length.')
        endif

!--------------------------------------------------------------------------

!       I/O arguments management

!       Get nufft parameters
        nj = int(m1 * n1)
        call mxCopyPtrToInteger4(mxGetPr(prhs(5)), iflag, 1)
        call mxCopyPtrToReal8(mxGetPr(prhs(6)), eps, 1)
        call mxCopyPtrToInteger4(mxGetPr(prhs(7)), ms, 1)
        call mxCopyPtrToInteger4(mxGetPr(prhs(8)), mt, 1)
        call mxCopyPtrToInteger4(mxGetPr(prhs(9)), mu, 1)

!       Check their validity...
!       Precision should be a positive scalar in the allowable range
!       (1.0e-13, 1.0e-1)
        if (eps .lt. 1d-13 .or. eps .gt. 1d-1) then
            call mexErrMsgIdAndTxt('MATLAB:nufft3d1:WrongValue',
     +          'Input parameter 6 should be in [1e-13, 1e-1].')
        endif
!       Uniform grid dimensions should be > 1 
        if (.not.(ms .gt. 1 .and. mt .gt. 1 .and. mu .gt. 1)) then
            call mexErrMsgIdAndTxt('MATLAB:nufft3d1:WrongValue',
     +          'Input parameter 7, 8 and 9 should be > 1.')
        endif

!--------------------------------------------------------------------------

!       Memory allocation

        allocate(xj(nj), stat=ier)
        if(ier .ne. 0) then
            call mexErrMsgIdAndTxt('MATLAB:nufft3d1:MemoryError',
     +          'Memory allocation failed.')
        endif
        call mxCopyPtrToReal8(mxGetPr(prhs(1)), xj, nj)
        
        allocate(yj(nj), stat=ier)
        if(ier .ne. 0) then
            call mexErrMsgIdAndTxt('MATLAB:nufft3d1:MemoryError',
     +          'Memory allocation failed.')
        endif
        call mxCopyPtrToReal8(mxGetPr(prhs(2)), yj, nj)

        allocate(zj(nj), stat=ier)
        if(ier .ne. 0) then
            call mexErrMsgIdAndTxt('MATLAB:nufft3d1:MemoryError',
     +          'Memory allocation failed.')
        endif
        call mxCopyPtrToReal8(mxGetPr(prhs(3)), zj, nj)

        allocate(cj(nj), stat=ier)
        if(ier .ne. 0) then
            call mexErrMsgIdAndTxt('MATLAB:nufft3d1:MemoryError',
     +          'Memory allocation failed.')
        endif
        call mxCopyPtrToComplex16(mxGetPr(prhs(4)), mxGetPi(prhs(4)),
     +          cj, nj)

        allocate(fk(ms, mt, mu), stat=ier)
        if(ier .ne. 0) then
            call mexErrMsgIdAndTxt('MATLAB:nufft3d1:MemoryError',
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
        call nufft3d1f90(nj, xj, yj, zj, cj, iflag, eps, ms, mt, mu, 
     +          fk, ier)

!--------------------------------------------------------------------------

!       Post-computation treatments

!       Treat returned error code from computational function
        if(ier .ne. 0) then 
                call mexErrMsgIdAndTxt('MATLAB:nufft3d1:ErrorCode',
     +          'Error occured in computational routine')
        endif

!       Copy back results
        classid = mxClassIDFromClassName('double')
        complexFlag = 1
        matdims(1) = ms
        matdims(2) = mt
        matdims(3) = mu
        plhs(1) = mxCreateNumericArray(3, matdims, classid,
     +                  complexFlag)
        call mxCopyComplex16ToPtr(fk, mxGetPr(plhs(1)), 
     +          mxGetPi(plhs(1)), ms*mt*mu)

!       Clean dynamicaly allocated variables
        deallocate(xj, stat=ier)
        if(ier .ne. 0) then
            call mexErrMsgIdAndTxt('MATLAB:nufft3d1:MemoryError',
     +          'Memory release failed.')
        endif
        deallocate(yj, stat=ier)
        if(ier .ne. 0) then
            call mexErrMsgIdAndTxt('MATLAB:nufft3d1:MemoryError',
     +          'Memory release failed.')
        endif
        deallocate(zj, stat=ier)
        if(ier .ne. 0) then
            call mexErrMsgIdAndTxt('MATLAB:nufft3d1:MemoryError',
     +          'Memory release failed.')
        endif
        deallocate(cj, stat=ier)
        if(ier .ne. 0) then
            call mexErrMsgIdAndTxt('MATLAB:nufft3d1:MemoryError',
     +          'Memory release failed.')
        endif
        deallocate(fk, stat=ier)
        if(ier .ne. 0) then
            call mexErrMsgIdAndTxt('MATLAB:nufft3d1:MemoryError',
     +          'Memory release failed.')
        endif

        return
        end
