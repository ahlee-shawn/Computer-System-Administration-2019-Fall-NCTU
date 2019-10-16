#!/bin/sh
ls -A -R -ll | grep ^[d-] | awk '{print $1 " " $5 " " $9}' | sort -k 2,2 -r -n | awk 'BEGIN {dir=0; file=0; total=0; count=1} {if(count <= 5 && $1 ~ /-/) {print count ":" $2 " " $3; count+=1}if($1 ~ /d/) {dir+=1} else {file+=1; total+=$2}} END{print "Dir num: " dir; print "File num: " file; print "Total: " total}'
