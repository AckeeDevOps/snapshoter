# snapshoter 

Run cron with the only job - regularly export and delete GCE snapshots of a chosen disk

Prerequisities:
* Pod needs to have compute engine admin scope 

Mandatory env parameters:

* `SNAPSHOT_DEVICE_NAME` - disk name (has to be unique in the cluster)
* `SNAPSHOT_INSTANCE_ZONE` - zone where the disk is defined

Optional env parameters:
* `SLACK_HOOK` - if you want to report errors to Slack ("incoming webhook")
* `SNAPSHOT_KEEP_DAYS` - how long to keep the snapshots. Defaults to 7.

Sample deployment:
    kubectl run snapshoter --image ackee/snapshoter:latest --env="SNAPSHOT_DEVICE_NAME=nginxress" --env="SNAPSHOT_INSTANCE_ZONE=europe-west1-d"

