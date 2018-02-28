#!/bin/bash

if [  ! -f $HOME/crontab.sha256 ]; then
	shasum -a 256 /etc/crontab > $HOME/crontab.sha256
	exit 0
fi
cronSHA256cur=`cat $HOME/crontab.sha256`
cronSHA256=`shasum -a 256 /etc/crontab`
if [[ "$cronSHA256cur" != "$cronSHA256" ]]; then
   echo "/etc/crontab has been modified" | mail -s "Alert" root
   echo $cronSHA256 > $HOME/crontab.sha256
fi
## chmod 744 $HOME/04.sh
## /etc/crontab schedule rule should be like this, 0 0 * * * root $HOME/04.sh
