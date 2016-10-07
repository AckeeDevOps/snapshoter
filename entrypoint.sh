#!/bin/bash
: ${CRON_SCHEDULE:="0 2 * * *"}

echo "CRON_SCHEDULE is $CRON_SCHEDULE"

# add a cron job
touch /var/log/cron.log

echo "$CRON_SCHEDULE /opt/backuper.sh > /var/log/cron.log 2>&1" >> /tmp/crontab
crontab /tmp/crontab
rm /tmp/crontab

/usr/sbin/cron
tail -f /var/log/cron.log
sleep 30d
