c  /asl/opt/absoft/absoft10.0/bin/af77 -w -W -s -C -N109 get_diurnal_sst_sergioC.f
c  same as get_diurnal_sst_sergio.f except all the eg cosd routines have been changes to cosdx
c  so that g77 can handle this

c same as get_diurnal_sst_sergioB.f except this is in array form and everything is in
c real*8 so I don;t need to worry about the input/output interface with Matlab
c same as get_diurnal_sst_sergioC.f except this contains only routines relevent for MEX file
         
c%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
c	subroutine get_diurnal_sst_seviri2(lyr,idyjl,xhour,xlat,xlon,wind,nlen,dsst)
	subroutine get_diurnal_sst_sergioD(xlyr,xidyjl,xhour,xlat,xlon,
     $                                      wind,nlen,dsst)

        implicit none 

      include 'max.inc'
c      integer MaxLen
c      parameter(MaxLen = 10000)

c	c.gentemann 4.2008
c	inputs:
c	lyr=year
c	idyjl=ordinal day
c	xhour = LOCAL TIME IN HOURS
c	xlat=latitude in deg
c	wind = wind speed in m/s

c	output:
c	dsst = diurnal amplitude in deg

	integer nlen,lyr(MaxLen),idyjl(MaxLen)
	real*8 xlyr(MaxLen),xidyjl(MaxLen)
	real*8 xhour(MaxLen),xlat(MaxLen),xlon(MaxLen)
        real*8 wind(MaxLen),dsst(MaxLen)

c       local variables
c	real*8 a0,a1,a2,a3,a4,a5,b1,b2,b3,b4,b5
	real*8 w,rsol(MaxLen)
        real*8 pi
	real*8 xpar(11)
	real*8 diurnal_cos,rhr(MaxLen)
        integer iI

        pi = 3.141592654

	xpar(1)=0.90779440686153
	xpar(2)=-5.654018322117584E-001 
	xpar(3)=-9.109286437084861E-001
	xpar(4)=4.938677367379611E-002
	xpar(5)=2.921478004135862E-001  
	xpar(6)=-8.767453446309354E-004 
	xpar(7)= -6.803299659334103E-002  
	xpar(8)=-4.456366487917374E-003   
	xpar(9)=2.214046984740299E-003
	xpar(10)=2.166914823201959E-002  
	xpar(11)=-2.116565831620519E-003

c	a0=4.118;a1=-4.132;b1=-5.093;a2=.8746;b2=2.583;
c	a3=-.246;b3=-.5143;a4=.2762;b4=-.3355;a5=-.0609;b5=.2269;
	w=2.*pi/24.0

        DO iI = 1,nlen
          lyr(iI)   = int(xlyr(iI))
          idyjl(iI) = int(xidyjl(iI))
  	  rhr(iI) = xhour(iI) + xlon(iI)/360.0*24.0
          if(rhr(iI) .GT. 24.) rhr(iI) = rhr(iI) - 24.0
          if(rhr(iI) .EQ. 0) rhr(iI) = 24.0
        END DO

	call fd_insolation(lyr,idyjl,43200,xlat,rsol,nlen)  !!! ??????????

        DO iI = 1,nlen
  	  dsst(iI)=0.0
          if (rsol(iI) .GT. 97.0) then
            diurnal_cos=xpar(1)+
     $			xpar(2)*cos(rhr(iI)*w)+xpar(3)*sin(rhr(iI)*w)+
     $			xpar(4)*cos(2*rhr(iI)*w)+xpar(5)*sin(2*rhr(iI)*w)+
     $			xpar(6)*cos(3*rhr(iI)*w)+xpar(7)*sin(3*rhr(iI)*w)+
     $			xpar(8)*cos(4*rhr(iI)*w)+xpar(9)*sin(4*rhr(iI)*w)+
     $			xpar(10)*cos(5*rhr(iI)*w)+xpar(11)*sin(5*rhr(iI)*w)

	    dsst(iI) =((0.00224946*(rsol(iI)-97.))*exp(-0.27*wind(iI))+
     $             (2.01422e-6*(rsol(iI)-97.)**2)*exp(-0.27*wind(iI)))*
     $                diurnal_cos
     	  endif
  	  if(dsst(iI) .LT. 0) dsst(iI)=0.0

c          print *,'main : ',iI,lyr(iI),idyjl(iI),xhour(iI),
c     $           xlat(iI),xlon(iI),wind(iI),dsst(iI)

        END DO

        return
	end


c%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      subroutine fd_insolation(lyear,idayjl,isecdy,xlat, rsol,nlen)

      implicit none

c Now, during the time period of 1978 through 1998, 
c the mean value of daily averages for the solar constant from six different satellites 
c yielded a solar constant of 1366.1 Wm2. This same source offers a minimum - maximum range of 
c the readings for 1363 - 1368 Wm2. Adjustments yielded "a solar constant" calculated to 1366.22 Wm2. 
c [Royal Meteorological Institute of Belgium: Department of Aerology; 
c http://remotesensing.oma.be/RadiometryPapers/article2.html.]. 
c	c.gentemann gentemann@remss.com
c	6/2009

c      real(4), parameter :: solar_constant=1366.2   !watts/m**2
c      real(4), parameter :: pi=3.141592654

      include 'max.inc'
c      integer MaxLen
c      parameter(MaxLen = 10000)

      real*8 solar_constant,pi
      real*8 sindx,cosdx,tandx
      real*8 sindxd,cosdxd,tandxd

c     inputs and outputs
        integer nlen,iI
	integer lyear(MaxLen),idayjl(MaxLen),isecdy  ! year, julian day, seconds in day
	real*8    xlat(MaxLen)                 ! latitude of observation
	real*8    rsol(MaxLen)                 ! average insolation watts/m**2   
	real*8 sunlat(MaxLen),sunlon(MaxLen),sundis(MaxLen),rr,H,sinh,Q
       
       solar_constant = 1366.2   !watts/m**2
       pi = 3.141592654

      call sunloc1(lyear,idayjl,isecdy, sunlat,sunlon,sundis,nlen)	  
      !sundis is radius/(mean radius)

      do iI = 1,nlen
        rr = -tandx(xlat(iI))*tandx(sunlat(iI))
        if (rr .GT.  1) rr= 1.
        if (rr .LT. -1) rr=-1.

        H = acos(rr)	 
        sinH = sqrt(1 - rr**2)                      !sqrt(1-cos(h)**2) =sin(h)
        Q = sindx(xlat(iI))*sindx(sunlat(iI)) + 
     $      cosdx(xlat(iI))*cosdx(sunlat(iI))*sinH    !! seen in www
        Q = sindx(xlat(iI))*sindx(sunlat(iI))*H + 
     $      cosdx(xlat(iI))*cosdx(sunlat(iI))*sinH  !! orig
        rsol(iI) = (solar_constant/pi)*Q/sundis(iI)**2
      end do

      return
      end

c%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
C     12/12/2003 VERSION CHANGED ON AUG 26 2005.  IMPLICIT NONE WAS ADDED.
C     Same as SUNLOC August 01, 1998, 01:04:31 PM, except this also returns R.
	SUBROUTINE SUNLOC1(LYEAR,IDAYJL,ISECDY,SUNLAT,SUNLON,R,nlen)
	IMPLICIT NONE

        integer nlen
	REAL*8 XDAY,TX
        real*8 Z(3),X(3),TOSUN(3),PROJECT(3)
	real*8 D01,D11,S11,C11,S21,C21
	real*8 D02,D12,S12,C12,S22,C22
	real*8 slope,period,ecc,xinc,rad,xfac,alpha,t0,t,ang
	real*8 amag,xphi,eot,hang,sinang,cosang,sinhang
        real*8 coshang,corrlat,corrlon
	real*8 phi
	integer istart,lyear(nlen),idayjl(nlen),isecdy
	real*8 sunlat(nlen),sunlon(nlen),r(nlen)

        real*8 dot_productx,cosinc
        real*8 sindx,cosdx,tandx
        real*8 sindxd,cosdxd,tandxd,dot_productdx
        integer iI

	DATA D01,D11,S11,C11,S21,C21/ -1.15538E-3, -6.86302E-8, 
     $        -8.48082E-1, -1.29184E-1, -3.18681E-2, -5.59290E-4/
	DATA D02,D12,S12,C12,S22,C22/ -1.57115E-3, -3.82973E-5, 
     $    -9.91281E-4, -2.75336E-2,  1.83422E-2,  1.09567E-3/
	DATA SLOPE/1.81818E-5/ !=0.2/11000.0
	DATA PERIOD,ECC,XINC/365.2422,0.016708617,23.43929111/
        DATA RAD/0.01745329252/
	DATA ISTART/1/

	IF(ISTART.EQ.1) THEN
          XFAC=360./PERIOD                 
          ALPHA=XFAC*(355.5674 - 0.3210) 
          !WINTER SOLSTICES DEC 21 13:37, 2000; ADDITION OFFSET OF .321 TO COMPENSTATE FOR ECC
          T0 = XFAC*2.2083 !PERIHELION JAN 3, 5 HOURS, 2000
	  Z(1) = SINDXD(XINC)*COSDXD(ALPHA)
	  Z(2) = SINDXD(XINC)*SINDXD(ALPHA)
	  Z(3) = COSDXD(XINC)
	  X(1) = COSDXD(XINC)*COSDXD(ALPHA+180)
	  X(2) = COSDXD(XINC)*SINDXD(ALPHA+180)
	  X(3) = SINDXD(XINC)
	ENDIF

      do iI = 1, nlen
	IF(LYEAR(II) .LT.1950 .OR. LYEAR(iI) .GT.2099) THEN
          print *,II,LYEAR(II),IDAYJL(iI)
          STOP 'ERROR IN LYEAR'
        END IF
	XDAY=365.D0*(LYEAR(iI)-1950) + (IDAYJL(iI)-1) + ISECDY/86400.D0 + 
     $       INT((LYEAR(iI)-1949)/4) - 18262.D0   !TDAY=0 FOR JAN 1 0Z, 2000 
        TX = XFAC*XDAY
        T = MOD(TX*1.0D0,360.D0)
        IF(T.LT.0) T=T+360. 
                                                 
        ANG = T+2.*ECC*(SINDXD(T-T0)+SINDXD(T0))/RAD                    
                       
        R(iI)=1.-ECC*COSDXD(T-T0)

        TOSUN(1)=-COSDXD(ANG)  
        TOSUN(2)=-SINDXD(ANG)   
        TOSUN(3)=0
        COSINC=DOT_PRODUCTDX(TOSUN,Z) 

c      SUNLAT=90-ACOSD(COSINC)        huuuuuuuuuuhhhhhhhhhhhh????????
        SUNLAT(II)=90-ACOS(COSINC)*1/RAD

        PROJECT(1)=TOSUN(1) - COSINC*Z(1) 
        PROJECT(2)=TOSUN(2) - COSINC*Z(2) 
        PROJECT(3)=TOSUN(3) - COSINC*Z(3) 

        AMAG=SQRT(PROJECT(1)**2 + PROJECT(2)**2 + PROJECT(3)**2)
        PROJECT(1)=PROJECT(1)/AMAG
        PROJECT(2)=PROJECT(2)/AMAG
        PROJECT(3)=PROJECT(3)/AMAG

        CALL FINDANG(X,PROJECT,Z, PHI)                             
        XPHI=PHI-9.6 -0.326
	EOT=T-XPHI
	IF(EOT.LT.-180) EOT=EOT+360
	IF(EOT.GT. 180) EOT=EOT-360

	SUNLON(II)=180-360*ISECDY/86400. - EOT
	IF(SUNLON(II).LT.0) SUNLON(II)=SUNLON(II)+360.

	ANG=XFAC*XDAY
	HANG=0.5*ANG
	SINANG=SINDXD(ANG)
	COSANG=COSDXD(ANG)
	SINHANG=SINDXD(HANG)
	COSHANG=COSDXD(HANG)
	CORRLAT = D01 + D11*XDAY + SLOPE*XDAY*(S11*SINANG + C11*COSANG + 
     $            S21*SINHANG + C21*COSHANG)
	CORRLON = D02 + D12*XDAY +             S12*SINANG + C12*COSANG + 
     $            S22*SINHANG + C22*COSHANG

	SUNLAT(II)=SUNLAT(iI) + CORRLAT
	SUNLON(iI)=SUNLON(iI) + CORRLON
	IF(SUNLON(iI).LT.  0) SUNLON(iI)=SUNLON(iI)+360
	IF(SUNLON(iI).GE.360) SUNLON(iI)=SUNLON(iI)-360

      end do

      RETURN
      END 


c************************************************************************
                                                           
      SUBROUTINE FINDANG(X,Y,Z, ANG) 
	implicit none       
       
	REAL*8 X(3),Y(3),Z(3),D(3), dot_productdx
	real*8 sinang,cosang,ang,atan2dx

      D(1)=X(2)*Y(3)-X(3)*Y(2)                                                    
      D(2)=X(3)*Y(1)-X(1)*Y(3)                                                    
      D(3)=X(1)*Y(2)-X(2)*Y(1)                                                    
      SINANG=SQRT(D(1)**2+D(2)**2+D(3)**2) 
	IF(DOT_PRODUCTDX(D,Z).LT.0) SINANG=-SINANG 
      COSANG=DOT_PRODUCTDX(X,Y) 
	ANG=ATAN2DX(SINANG,COSANG)
	IF(ANG.LT.0) ANG=ANG+360.
      RETURN                                                            
      END                                                           

c************************************************************************

      real*8 function dot_productx(x,y)

      implicit none

      real*8 x(3),y(3),z
      integer iI

      z = 0.0
      do iI = 1,3
        Z = Z + x(iI)*y(iI)
      end do

      dot_productx = Z

      return
      end
 
c************************************************************************
      real*8 function dot_productdx(x,y)

      implicit none

      real*8 x(3),y(3),z
      integer iI

      z = 0.0
      do iI = 1,3
        Z = Z + x(iI)*y(iI)
      end do

      dot_productdx = Z

      return
      end
 
c************************************************************************

      real*8 function atan2dx(x,y)

      implicit none

      real*8 x,y,z,pi

      pi = 3.141592654     
      z = atan2(x,y) * 180/pi
      atan2dx = z

      return
      end
c************************************************************************

      real*8 function acosdx(x)

      implicit none

      real*8 x,y,pi

      pi = 3.141592654     
      y = acos(x) * 180.00/pi

      acosdx = y

      RETURN
      END

c************************************************************************

      real*8 function cosdx(x)

      implicit none

      real*8 x,y,pi

      pi = 3.141592654     
      y = cos(x * pi/180.00)

      cosdx = y

      RETURN
      END
c************************************************************************

      real*8 function sindx(x)

      implicit none

      real*8 x,y,pi

      pi = 3.141592654     
      y = sin(x * pi/180.00)

      sindx = y

      RETURN
      END

c************************************************************************

      real*8 function tandx(x)

      implicit none

      real*8 x,y,pi

      pi = 3.141592654     
      y = tan(x * pi/180.00)

      tandx = y

      RETURN
      END

c************************************************************************

      real*8 function cosdxd(x)

      implicit none

      real*8 x,y,pi

      pi = 3.141592654     
      y = cos(x * pi/180.00)

      cosdxd = y

      RETURN
      END
c************************************************************************

      real*8 function sindxd(x)

      implicit none

      real*8 x,y,pi

      pi = 3.141592654     
      y = sin(x * pi/180.00)

      sindxd = y

      RETURN
      END

c************************************************************************

      real*8 function tandxd(x)

      implicit none

      real*8 x,y,pi

      pi = 3.141592654     
      y = tan(x * pi/180.00)

      tandxd = y

      RETURN
      END

c************************************************************************
