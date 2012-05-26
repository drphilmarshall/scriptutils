/* ======================================================================
 +
  NAME
     timeout
  
  PURPOSE
     Execute a command and terminate it after n seconds.
  
  USAGE
          
     timeout -t seconds [-v verbose] command line
  
  INPUTS
     -t dt               Execution time period dt (seconds)          
     command line        Command to be executed

  OPTIONAL INPUTS
     -v                  Verbose operation        
     
  COMMENTS
    
  
  EXAMPLES
     timeout -t 5 xv ~/Hammerzeit.jpg
  
  OUTPUTS
     Minimal stdout
  
  BUGS
  
  REVISION HISTORY:
    2006-12-21  Rykoff (UCSB)
  
 -
*/
// =============================================================================
#include <stdlib.h>
#include <unistd.h>
#include <stdio.h>
#include <sys/types.h>
#include <signal.h>
#include <netdb.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <string.h>
#include <time.h>
#include <sys/stat.h>
#include <fcntl.h>

#define MAXCMD 5000
#define MAXLEN 100

extern char *optarg;


int main(int argc, char *argv[])
{
  int c;
  int timeout_val = -1;
  int option_count = 0;
  int verbose_flag = 0;


  pid_t cpid,ppid;

  int argc2;
  char **argv2;
  char *tmp;

  int i;
  int retval;


  if (argc < 2) {
    fprintf(stderr,"Usage:\n");
    fprintf(stderr," timeout -t seconds [-v verbose] command line\n");
    return(0);
  }

  while ((c=getopt(argc,argv,"t:v")) != -1) {
    switch(c) {
    case 't':
      timeout_val = (int) strtol(strdup(optarg),NULL,0);
      option_count+=2;
      break;
    case 'v':
      verbose_flag = 1;
      option_count++;
      break;
    }
  }

  if (timeout_val < 1) {
    fprintf(stderr,"timeout must be at least 1 second\n");
    return(-1);
  }

  // generate argv2
  argc2=argc-option_count-1;

  if ((argv2 = (char **) calloc(argc2, sizeof(char *))) == NULL) {
    fprintf(stderr,"error with calloc.\n");
    return(-1);
  }
  for (i=0;i<argc2;i++) {
    if ((tmp = (char *) calloc(MAXLEN, sizeof(char))) == NULL) {
      fprintf(stderr,"error with calloc.\n");
      return(-1);
    }
    argv2[i]=tmp;

    strncpy(argv2[i],argv[i+option_count+1],MAXLEN);

  }


  if (verbose_flag) {
    printf("Running: %s\n",argv2[0]);
    printf("Will kill in %d seconds.\n",timeout_val);
  }

  cpid = fork();
  if (cpid > 0) {
    // parent: fork it
    retval = execvp(argv2[0],argv2);
    if (retval != 0) fprintf(stderr,"exec error:%d (%m)\n", retval);
  } else {
    ppid=getppid();
    sleep(timeout_val);

    if (verbose_flag) printf("Killing %s [pid %d]\n",argv2[0],ppid);

    kill(ppid,SIGTERM);
    return(0);
  }
    


  return(0);

}

