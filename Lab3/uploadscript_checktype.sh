#!/usr/local/bin/bash
filename=$1
timestamp=`date`
user=`ls -l $filename | awk '{print $3}'`
filetype=`file $filename | awk -F ":" '{print $2}'`

printf "%s: %s has uploaded file %s with type%s\n" "$timestamp" "$user" "$filename" "$filetype" >> /var/log/uploadscript.log