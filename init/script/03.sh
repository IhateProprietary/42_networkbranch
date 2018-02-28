#!/bin/bash

if [[ $# -lt 1 ]] ; then
	exit 1
fi
file $1 | grep directory >/dev/null
if [[ $? -eq 1 ]] ; then
   echo file $1 is not a directory
else
	ls -1S $1
fi
