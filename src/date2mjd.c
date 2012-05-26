#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <math.h>
#include <string.h>


extern char *optarg;

void printusage(void);
/* these functions were "borrowed" from Patrick Wallace's slalib */
void slaCldj(int iy, int im, int id, double *djm, int *j);
void slaCtf2d(int ihour, int imin, float sec, float *days, int *j);



int main(int argc, char *argv[])
{
  int c = 0;
  long year = -1, month = -1, day = -1, hour = -1, minute = -1;
  double second = -1.0;

  double djm,mjd;
  float days;
  int k;

  while ((c=getopt(argc,argv,"y:m:d:h:i:s:")) != -1) {
    switch (c) {
    case 'y':
      year = strtol(strdup(optarg), NULL, 10);
      break;
    case 'm':
      month = strtol(strdup(optarg), NULL, 10);
      break;
    case 'd':
      day = strtol(strdup(optarg), NULL, 10);
      break;
    case 'h':
      hour = strtol(strdup(optarg), NULL, 10);
      break;
    case 'i':
      minute = strtol(strdup(optarg), NULL, 10);
      break;
    case 's':
      second = strtod(strdup(optarg), NULL);
      break;
    }
  }
  if (year < 0 || month < 0 || day < 0 || hour < 0 || minute < 0 || second < 0) {
    printusage();
    return(-1);
  }

  slaCldj(year, month, day, &djm, &k);
  slaCtf2d(hour, minute, second, &days, &k);

  mjd = djm + (double) days;

  printf("%.8f\n", mjd);

  return(0);
}

void printusage(void)
{
  fprintf(stderr,"Usage: \n");
  fprintf(stderr,"  date2mjd -y year -m month -d day -h hour -i minute -s second\n");

}

void slaCldj(int iy, int im, int id, double *djm, int *j)
/*
   **  - - - - - - - -
   **   s l a C l d j
   **  - - - - - - - -
   **
   **  Gregorian calendar to Modified Julian Date.
   **
   **  Given:
   **     iy,im,id     int    year, month, day in Gregorian calendar
   **
   **  Returned:
   **     *djm         double Modified Julian Date (JD-2400000.5) for 0 hrs
   **     *j           int    status:
   **                           0 = OK
   **                           1 = bad year   (MJD not computed)
   **                           2 = bad month  (MJD not computed)
   **                           3 = bad day    (MJD computed)
   **
   **  The year must be -4699 (i.e. 4700BC) or later.
   **
   **  The algorithm is derived from that of Hatcher 1984 (QJRAS 25, 53-55).
   **
   **  Last revision:   29 August 1994
   **
   **  Copyright P.T.Wallace.  All rights reserved.
 */
{
   long iyL, imL;

/* Month lengths in days */
   static int mtab[12] =
   {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31};



/* Validate year */
   if (iy < -4699) {
      *j = 1;
      return;
   }
/* Validate month */
   if ((im < 1) || (im > 12)) {
      *j = 2;
      return;
   }
/* Allow for leap year */
   mtab[1] = (((iy % 4) == 0) &&
              (((iy % 100) != 0) || ((iy % 400) == 0))) ?
       29 : 28;

/* Validate day */
   *j = (id < 1 || id > mtab[im - 1]) ? 3 : 0;

/* Lengthen year and month numbers to avoid overflow */
   iyL = (long) iy;
   imL = (long) im;

/* Perform the conversion */
   *djm = (double)
       ((1461L * (iyL - (12L - imL) / 10L + 4712L)) / 4L
        + (306L * ((imL + 9L) % 12L) + 5L) / 10L
        - (3L * ((iyL - (12L - imL) / 10L + 4900L) / 100L)) / 4L
        + (long) id - 2399904L);
}


void slaCtf2d(int ihour, int imin, float sec, float *days, int *j)
/*
   **  - - - - - - - - -
   **   s l a C t f 2 d
   **  - - - - - - - - -
   **
   **  Convert hours, minutes, seconds to days.
   **
   **  (single precision)
   **
   **  Given:
   **     ihour       int       hours
   **     imin        int       minutes
   **     sec         float     seconds
   **
   **  Returned:
   **     *days       float     interval in days
   **     *j          int       status:  0 = OK
   **                                    1 = ihour outside range 0-23
   **                                    2 = imin outside range 0-59
   **                                    3 = sec outside range 0-59.999...
   **
   **  Notes:
   **
   **     1)  The result is computed even if any of the range checks fail.
   **
   **     2)  The sign must be dealt with outside this routine.
   **
   **  Last revision:   31 October 1993
   **
   **  Copyright P.T.Wallace.  All rights reserved.
 */

#define D2S 86400.0             /* Seconds per day */

{
/* Preset status */
   *j = 0;

/* Validate sec, min, hour */
   if ((sec < 0.0f) || (sec >= 60.0f)) {
      *j = 3;
      return;
   }
   if ((imin < 0) || (imin > 59)) {
      *j = 2;
      return;
   }
   if ((ihour < 0) || (ihour > 23)) {
      *j = 1;
      return;
   }
/* Compute interval */
   *days = (60.0f * (60.0f * (float) ihour + (float) imin) + sec) / D2S;
}
