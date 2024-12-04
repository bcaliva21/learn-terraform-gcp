#! /bin/bash
{
echo "starting startup script"
apt-get update
apt-get install -y nginx
service nginx start
echo "completed startup script"
} &>> /var/log/startup-script.log
