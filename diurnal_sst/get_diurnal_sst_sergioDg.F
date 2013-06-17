c http://www.mathworks.com/matlabcentral/fileexchange/25934-fortran-95-interface-to-matlab-api-with-extras
c change      *.f                  to      *.F
c change      integer m_in,n_in    to      mwSize m_in,n_in
c change      integer nlhs,nrhs    to      integer*2 nlhs,nrhs
c change      mxCreateFull         to      mxCreateDoubleMatrix
c include     fintrf.h

#include "fintrf.h"

      subroutine mexFunction(nlhs,plhs,nrhs,prhs)

c fmex5 get_diurnal_sst_sergioD.F get_diurnal_sst_sergioDg.F FFLAGS='$FFLAGS -u -64 -mips4' 
c LDFLAGS='$LDFLAGS -64 -mips4'
c
c /asl/opt/matlab/R2009a/bin/mex get_diurnal_sst_sergioD.F get_diurnal_sst_sergioDg.F FFLAGS='$FFLAGS -u -64 '
c  LDFLAGS='$LDFLAGS -mips4'

c ALL THE INPUTS SHOULD BE DOUBLE!!!!
c call this with dsst = get_diurnal_sst_sergioD(lyr,idyjl,xhour,xlat,xlon,wind)
c ALL THE INPUTS SHOULD BE DOUBLE!!!!

      implicit none 

      include 'max.inc'

      integer plhs(*),prhs(*)
      integer*2 nlhs,nrhs

      integer mxGetM,mxGetN
      integer mxGetPr,mxCreateDoubleMatrix

      integer ilyrp,idyjlp,xhourp,xlatp,xlonp,windp,sstp
      real*8 raLyr(MaxLen),raIdyjl(MaxLen),raXhour(MaxLen)
      real*8 raXlat(MaxLen),raXlon(MaxLen),raWind(MaxLen)
      real*8 raDSST(MaxLen)

      integer ii
      mwSize m_in,n_in,mx
             
c check for proper number of arguments
c want to call the function as shown above
      if (nrhs .ne. 6) then
        print *,nrhs
        call mexErrMsgTxt('6 input args required')
        endif
      if (nlhs .ne. 1) then
        call mexErrMsgTxt('1 output arg required')
        endif

c want to check sizes of input wavevector array "y"
      m_in = mxGetM(prhs(1)) 
      n_in = mxGetN(prhs(1))
      if ((m_in .gt. MaxLen) .or. (n_in .gt. MaxLen)) then
        call mexErrMsgTxt('array y has to be smaller than MaxLen')
        endif        
      if ((m_in .ne. 1)  .and.  (n_in .ne. 1)) then
        call mexErrMsgTxt('array y needs to be (1,ylen) or (ylen,1)')
        endif
      mx = max(m_in,n_in)
c      print *,'sent in ',mx,' entries'      

      if (int(mx) .GT. MaxLen) then
        call mexErrMsgTxt('int(mx) > Maxlen : ouch!')
        endif

      ilyrp  = mxGetPr(prhs(1))
      idyjlp = mxGetPr(prhs(2))
      xhourp = mxGetPr(prhs(3))
      xlatp  = mxGetPr(prhs(4))
      xlonp  = mxGetPr(prhs(5))
      windp  = mxGetPr(prhs(6))

c copy right hand arguments to local arrays or variables       
      call mxCopyPtrToReal8(ilyrp,raLyr,int(mx))
      call mxCopyPtrToReal8(idyjlp,raIdyjl,int(mx))
      call mxCopyPtrToReal8(xhourp,raXhour,int(mx))
      call mxCopyPtrToReal8(xlatp,raXlat,int(mx))
      call mxCopyPtrToReal8(xlonp,raXlon,int(mx))
      call mxCopyPtrToReal8(windp,raWind,int(mx))

c      do ii = 1,5
c        print *,ii,raLyr(ii),raIdyjl(ii),raXhour(ii),
c     $             raXlat(ii),raXlon(ii),raWind(ii),raDsst(ii)
c      end do

c create a matrix for return argument and assign pointers to the 
c output parameter z
      plhs(1) = mxCreateDoubleMatrix(m_in,n_in,0)
      sstp    = mxGetPr(plhs(1))

c     do the actual computations in a subroutine
      call get_diurnal_sst_sergioD(raLyr,raIdyjl,raXhour,raXlat,raXlon,
     $                             raWind,int(mx),raDSST)

c      do ii = 1,5
c        print *,ii,raLyr(ii),raIdyjl(ii),raXhour(ii),
c     $             raXlat(ii),raXlon(ii),raWind(ii),raDsst(ii)
c      end do

c copy output which is stored in local array to matrix output
      call mxCopyReal8ToPtr(raDSST, sstp, int(mx))

      return
      end


