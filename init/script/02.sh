#!/bin/bash

echo "Current time is" $(date) >> /var/log/update_script.log
apt-get update &>> /var/log/update_script.log
apt-get upgrade -y &>> /var/log/update_script.log
echo "Finished updating at" $(date) >> /var/log/update_script.log
## to add scheduled task
## do echo "0 4    * * 1    root    $HOME/auto_update.sh" >> /etc/crontab
