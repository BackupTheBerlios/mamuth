//  jgdostdio_main.c Copyright (c) 2002 Joerg Garbers.
//  This software is open source. See the license.

// The use of this program is to make mktemp() available to the shell.
// This program produces for each argument a mktemp() (adding .XXXXXX if argument does not end in X)
// If no argument is given, uses $MKTEMP_DIR/mktemp.XXXXXX or TMP/mktemp.XXXXXX

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>

#define MAXBUF 1000

char template[MAXBUF+1];

void jgmktmp() {
  char *tempFileName;
  if ((template[0]==0) || (template[strlen(template)-1]!='X'))
    strncat(template,".XXXXXX",MAXBUF-strlen(template));
  tempFileName=mktemp(template);
  if (!tempFileName) 
    exit(1);
  puts(tempFileName);
}

int main(int argc, const char *argv[])
{
  if (argc>1) {
    int i;
    for (i=1;i<argc;i++) {
      strncpy(template,argv[i],MAXBUF);
      jgmktmp();
    }
 } else {
    const char *defaultName="mktemp.XXXXXX";
    char *tempdir=getenv("MKTEMP_DIR");
    if (!tempdir)
      tempdir=getenv("TMP");
    if (tempdir) 
      snprintf(template,MAXBUF-strlen(tempdir)-1,"%s/%s",tempdir,defaultName);
    else
      strncpy(template,defaultName,MAXBUF);
    jgmktmp();
  }
  exit(0);
  return 0;
}
