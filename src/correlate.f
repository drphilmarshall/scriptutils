c ======================================================================
c+
c NAME
c         correlate
c 
c PURPOSE
c         Read in two catalogs and compute their correlation function.
c 
c USAGE
c         correlate.exe
c 
c INPUTS
c    A.txt          
c    B.txt          2 x 4 column (x,y,e1,e2) ascii text catalogues
c    nbin           no. of bins in binning grid
c    rmax           maximum radius for binning grid
c    q              quiet operation
c    
c COMMENTS
c   Best to have x and y (and so rmax) in arcsec.
c 
c EXAMPLES
c   echo "stars.txt\ngalaxies.txt\n50\n100.0" |  correlate.exe
c 
c OUTPUTS
c   outfiles:       3 column ascii text catalogues (r, corr, error)
c     tt.txt
c     tx.txt
c     xx.txt
c     Xiplus.txt
c     Ximinus.txt
c     Xicross.txt
c 
c BUGS
c 
c REVISION HISTORY:
c   2006-06-13 Marshall (KIPAC)
c 
c-
c ==============================================================================

      program correlate
      
      implicit none

	integer nbin,nA,nB,vb
      real rmax
      character*200 catA,catB
      
      call options(catA,catB,nbin,rmax,vb)
      call nlines(catA,catB,nA,nB,vb)
	call driver(catA,catB,nA,nB,nbin,rmax,vb)

      end

c ==============================================================================

	subroutine options(catA,catB,nbin,rmax,vb)

      implicit none

	integer nbin,vb
      real rmax
      character*200 catA,catB
      
c ------------------------------------------------------------------------------
      
      write(*,'(a,)') 'Enter catalogue A: '
      read(*,*) catA 
      write(*,'(a,)') 'Enter catalogue B: '
      read(*,*) catB 
      write(*,'(a,)') 'Enter no. of bins: '
      read(*,*) nbin 
      write(*,'(a,)') 'Enter maximimum radius of binning grid: '
      read(*,*) rmax 
      write(*,'(a,)') 'Enter verbosity (1 or 0): '
      read(*,*) vb 
      
	return
      end

c ==============================================================================

	subroutine nlines(catA,catB,nA,nB,vb)

      implicit none

	integer nA,nB,vb,i,j
      character*200 catA,catB
      character*80 record
      
c ------------------------------------------------------------------------------
      
      open(unit=9,file=catA,form='formatted',status='old')
      nA = 0
      do i=1,100000000
        read(9,'(a)',end=10) record
        nA = nA + 1
      enddo
 10   close(9)
      if (vb.eq.1) write(*,*) 'Read in ',nA,' lines from ',catA
     
      open(unit=9,file=catB,form='formatted',status='old')
      nB = 0
      do i=1,100000000
        read(9,'(a)',end=20) record
        nB = nB + 1
      enddo
 20   close(9)
      if (vb.eq.1) write(*,*) 'Read in ',nB,' lines from ',catB
     
	return
      end

c ==============================================================================

	subroutine driver(catA,catB,nA,nB,nbin,rmax,vb)

      implicit none

	integer nbin,nA,nB,vb
      real rmax
      character*200 catA,catB
      
      integer i,j,k,ohmygod,count,percent
      real xA(nA),yA(nA),e1A(nA),e2A(nA) 
      real xB(nB),yB(nB),e1B(nB),e2B(nB) 
      real dr,rbin(nbin)
      real r,dx,dy,cosphi,sinphi,cosphisq,sinphisq
      real cos2phi,sin2phi,cos2phisq,sin2phisq,cos2phisin2phi
      real tt,tx,xx
      real sumtt(nbin),sumsqtt(nbin)
      real meantt(nbin),errtt(nbin),errsqtt(nbin)
      real sumtx(nbin),sumsqtx(nbin)
      real meantx(nbin),errtx(nbin),errsqtx(nbin)
      real sumxx(nbin),sumsqxx(nbin)
      real meanxx(nbin),errxx(nbin),errsqxx(nbin)
      real meanXiplus(nbin),errXiplus(nbin)
      real meanXiminus(nbin),errXiminus(nbin)      
      real meanXicross(nbin),errXicross(nbin)
      real totalNum(nbin)

c ------------------------------------------------------------------------------
      
c Set up binning grid:

c The length of each bin (dr) = total length / number of bins

      dr = rmax / float(nbin)

c rbin contains midpoints of bins, stats need zeroing

      do k=1,nbin
        rbin(k) = dr*(k - 0.5)
        sumtt(k) = 0.0
        sumsqtt(k) = 0.0
        sumtx(k) = 0.0
        sumsqtx(k) = 0.0
        sumxx(k) = 0.0
        sumsqxx(k) = 0.0
        totalNum(k) = 0.0
      enddo

c Open up files and read in data:
      
      open(unit=9,file=catA,form='formatted',status='old')
      do i=1,nA
        read(9,*) xA(i),yA(i),e1A(i),e2A(i) 
      enddo
      close(9)
      open(unit=9,file=catB,form='formatted',status='old')
      do j=1,nB
        read(9,*) xB(j),yB(j),e1B(j),e2B(j) 
      enddo
      close(9)

c ------------------------------------------------------------------------------
      
c Do calculations:

      ohmygod = nA*nB
      count = 0

      if (vb.eq.1) write(*,*) 'Correlating ',ohmygod,' pairs...'

	do i=1,nA
        do 10 j=1,nB

          count = count + 1

c         Compute r:

          dx = abs(xA(i) - xB(j))
          dy = abs(yA(i) - yB(j))
          r = sqrt(dx*dx + dy*dy);

          if (r.eq.0.0.or.r.gt.rmax) goto 10

c         Which bin do they go into?

          k = int(r/dr) + 1

c         Inner products: E-mode and B-mode with angles involved:

          cosphi = dx / r
          sinphi = dy / r

          cosphisq = cosphi*cosphi
          sinphisq = sinphi*sinphi
          cos2phi = cosphisq - sinphisq
          sin2phi = 2 * sinphi * cosphi
          cos2phisq = cos2phi*cos2phi
          sin2phisq = sin2phi*sin2phi
          cos2phisin2phi = cos2phi*sin2phi

c         Correlation functions from Schneider's notes - 
c         build up averages as we go:

          tt =   (cos2phisq * (e1A(i)*e1B(j)))
     &         + (sin2phisq * (e2A(i)*e2B(j)))
     &         + (cos2phisin2phi * (e2A(i)*e1B(j) + e1A(i)*e2B(j)))
          sumtt(k) = sumtt(k) + tt
          sumsqtt(k) = sumsqtt(k) + tt*tt
          
          xx =   (cos2phisq * (e2A(i)*e2B(j)))
     &         + (sin2phisq * (e1A(i)*e1B(j)))
     &         - (cos2phisin2phi * (e1A(i)*e2B(j) + e2A(i)*e1B(j)))
          sumxx(k) = sumxx(k) + xx
          sumsqxx(k) = sumsqxx(k) + xx*xx
      
          tx =   (cos2phisq * (e1A(i)*e2B(j)))
     &         - (sin2phisq * (e2A(i)*e1B(j)))
     &         - (cos2phisin2phi * (e1A(i)*e1B(j) - e2A(i)*e2B(j)))
          sumtx(k) = sumtx(k) + tx
          sumsqtx(k) = sumsqtx(k) + tx*tx

          totalNum(k) = totalNum(k) + 1

  10    continue
        
        percent = int(100*count/ohmygod)
        if (vb.eq.1) write(*,*) percent,'% completed'
      
      enddo
      
c ------------------------------------------------------------------------------

c Open output for writing binned correlation function:
        
      open(unit=9,file='tt.txt',form='formatted',status='unknown')
      open(unit=10,file='tx.txt',form='formatted',status='unknown')
      open(unit=11,file='xx.txt',form='formatted',status='unknown')
      open(unit=12,file='Xiplus.txt',form='formatted',status='unknown')
      open(unit=13,file='Ximinus.txt',form='formatted',status='unknown')
      open(unit=14,file='Xicross.txt',form='formatted',status='unknown')

C Write out stats:
      
      do k=1,nbin

        if (totalNum(k).gt.1) then

c         Calculate mean and squared error on mean, for tt, tx, xx:
          meantt(k)  = sumtt(k) / totalNum(k)
          errsqtt(k) = (sumsqtt(k)/totalNum(k) - meantt(k)*meantt(k)) /
     &                                (totalNum(k)-1.0)
          errtt(k) = sqrt(errsqtt(k))
          
          meantx(k)  = sumtx(k) / totalNum(k)
          errsqtx(k) = (sumsqtx(k)/totalNum(k) - meantx(k)*meantx(k)) /
     &                                (totalNum(k)-1.0)
          errtx(k) = sqrt(errsqtx(k))
          
          meanxx(k)  = sumxx(k) / totalNum(k)
          errsqxx(k) = (sumsqxx(k)/totalNum(k) - meanxx(k)*meanxx(k)) /
     &                                (totalNum(k)-1.0)
          errxx(k) = sqrt(errsqxx(k))

c         Now form three correlation functions:

          meanXiplus(k) = meantt(k) + meanxx(k)
          errXiplus(k) = sqrt(errsqtt(k) + errsqxx(k))
          meanXiminus(k) = meantt(k) - meanxx(k)
          errXiminus(k) = sqrt(errsqtt(k) + errsqxx(k))
          meanXicross(k) = meantx(k)
          errXicross(k) = errtx(k)

c         Append to file:

          r = rbin(k)

          write(9,'(f10.1,3x,e13.6,3x,e13.6)')  r,meantt(k),errtt(k)
          write(10,'(f10.1,3x,e13.6,3x,e13.6)') r,meantx(k),errtx(k)
          write(11,'(f10.1,3x,e13.6,3x,e13.6)') r,meanxx(k),errxx(k)
          write(12,'(f10.1,3x,e13.6,3x,e13.6)') r,meanXiplus(k),errXiplus(k)
          write(13,'(f10.1,3x,e13.6,3x,e13.6)') r,meanXiminus(k),errXiminus(k)
          write(14,'(f10.1,3x,e13.6,3x,e13.6)') r,meanXicross(k),errXicross(k)

        endif
      
      enddo

c Shut up shop:

      close(9)
      close(10)
      close(11)
      close(12)
      close(13)
      close(14)
      
c ------------------------------------------------------------------------------

      return
      end

c ==============================================================================
