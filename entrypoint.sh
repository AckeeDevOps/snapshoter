#!/bin/bash
: ${CRON_SCHEDULE:="0 2 * * *"}

echo "CRON_SCHEDULE is $CRON_SCHEDULE"

if [ -z "$SNAPSHOT_DEVICE_NAME" -o -z "$SNAPSHOT_INSTANCE_ZONE" ]; then
        err "You need to specify both SNAPSHOT_DEVICE_NAME and SNAPSHOT_INSTANCE_ZONE."
        exit 1
fi

echo Snapshotting device $SNAPSHOT_DEVICE_NAME in zone $SNAPSHOT_INSTANCE_ZONE.

touch /var/log/cron.log

# add a cron job
echo "$CRON_SCHEDULE /opt/backuper.sh > /var/log/cron.log 2>&1" >> /tmp/crontab
crontab /tmp/crontab
rm /tmp/crontab

/usr/sbin/cron
tail -f /var/log/cron.log
# For any weird case when this ^ fails
sleep 30d
