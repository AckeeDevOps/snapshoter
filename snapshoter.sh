#!/usr/bin/env bash
# inspired by https://github.com/jacksegal/google-compute-snapshot/blob/master/snapshot.sh

function err() {
  escapedText=$(echo $@ | sed 's/"/\"/g' | sed "s/'/\'/g" )
  json="{\"text\": \"$escapedText\"}"

  echo $-
  case "$-" in
    *i*) echo $@
       ;;
    *) if [ ! -z "$SLACK_HOOK" ]; then
           curl -s -d "payload=$json" $SLACK_HOOK
       else
           echo "You will never see this message. Guess why?"
       fi
       ;;
  esac
  exit 1
}

# keep 7 days by default

: ${SNAPSHOT_KEEP_DAYS:=7}

. /etc/snapshoter

if [ -z "$SNAPSHOT_DEVICE_NAME" -o -z "$SNAPSHOT_INSTANCE_ZONE" ]; then
    err "You need to specify both SNAPSHOT_DEVICE_NAME ($SNAPSHOT_DEVICE_NAME) and SNAPSHOT_INSTANCE_ZONE ($SNAPSHOT_INSTANCE_ZONE)."
fi

# CREATE DAILY SNAPSHOT
#
# get the device name for this vm
DEVICE_NAME=$SNAPSHOT_DEVICE_NAME

# trim very long device names
SHORT_DEVICE_NAME=$(echo $DEVICE_NAME | head -c 40)

# get the zone that this vm is in
INSTANCE_ZONE=$SNAPSHOT_INSTANCE_ZONE

# create a datetime stamp for filename
DATE_TIME="$(date +%Y%m%d%H%M)"

# create the snapshot
echo -e "$(gcloud compute disks snapshot ${DEVICE_NAME} --snapshot-names backup-${SHORT_DEVICE_NAME}-${DATE_TIME} --zone ${INSTANCE_ZONE})"
if [ $? -ne 0 ]; then
    err "Creation of snapshot named backup-${SHORT_DEVICE_NAME}-${DATE_TIME} failed. Examine the logs."
fi

#
# DELETE OLD SNAPSHOTS (OLDER THAN 7 DAYS)
#

# get a list of existing snapshots, that were created by this process (gcs-), for this vm disk (DEVICE_NAME)
SNAPSHOT_LIST="$(gcloud compute snapshots list --regexp "(backup-${SHORT_DEVICE_NAME}-.*)" --uri)"

# loop through the snapshots
echo "${SNAPSHOT_LIST}" | while read line ; do

   # get the snapshot name from full URL that google returns
   SNAPSHOT_NAME="${line##*/}"

   # get the date that the snapshot was created
   SNAPSHOT_DATETIME="$(gcloud compute snapshots describe ${SNAPSHOT_NAME} | grep "creationTimestamp" | cut -d " " -f 2 | tr -d \')"
   echo $SNAPSHOT_DATETIME
   # format the date
   SNAPSHOT_DATETIME="$(date -d ${SNAPSHOT_DATETIME} +%Y%m%d)"
   echo $SNAPSHOT_DATETIME

   # get the expiry date for snapshot deletion (currently 7 days)
   SNAPSHOT_EXPIRY="$(date -d "-${SNAPSHOT_KEEP_DAYS} days" +"%Y%m%d")"

   # check if the snapshot is older than expiry date
    if [ $SNAPSHOT_EXPIRY -ge $SNAPSHOT_DATETIME ];then
      # delete the snapshot
      echo -e "[$(date -Iseconds)] \c"
      echo "$(gcloud compute snapshots delete ${SNAPSHOT_NAME})"
      if [ $? -ne 0 ]; then
         err "Deletion of snapshot named ${SNAPSHOT_NAME} failed. Examine the logs."
      fi
    fi
done
