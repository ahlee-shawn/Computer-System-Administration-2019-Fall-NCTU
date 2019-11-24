#!/usr/local/bin/bash
filename=$1
timestamp=`date`
user=`ls -l $filename | awk '{print $3}'`
filesize=`ls -l $filename | awk '{print $5}'`

printf "%s: %s has uploaded file %s with size %s\n" "$timestamp" "$user" "$filename" "$filesize" >> /var/log/uploadscript.log