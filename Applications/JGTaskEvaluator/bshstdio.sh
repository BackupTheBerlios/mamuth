#!/bin/sh
# this is an example of using jgrunwithfifo.
# it assumes, that there is a bsh (beanshell) interpreter installed, that takes a bsh-scriptfile as an argument. 
jgrunwithfifo bsh `jgmktemp`

# this could be the contents of bsh:
##!/bin/sh
#/Library/Java/home/bin/java -cp ~/Developer/Java/BeanShell/bsh-1.2b6.jar bsh.Interpreter $@
