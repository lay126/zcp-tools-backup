#!/bin/sh
BIN="$( cd "$( dirname "$0" )" && pwd )"   # https://stackoverflow.com/a/20434740

# Inject through pod environment variables
#echo -e "\n\n+ Load environment variables..."
#source $BIN/setenv   # https://stackoverflow.com/a/13360474
#cat $BIN/setenv      # for logging

BACKUP_NAME=jenkins-home-$(date +%Y%m%d-%H%M)
BACKUP=$BACKUP_DIR/$BACKUP_NAME
mkdir -p $BACKUP

POD=$(kubectl get pods --no-headers=true -o custom-columns=:.metadata.name | grep -- $JENKINS_DEPLOY)
if [ -z "$POD" ]; then
	echo -e '\n\n+ ERROR :: There is no jenkins pod.'
	kubectl get pods
	echo 'ERROR' > $S3_TRIGGER
	exit 1
fi

time kubectl exec -it $POD mkdir appdata

echo -e '\n\n+ [backup] start Compress...'
time kubectl exec -it $POD -- tar -zcf /appdata/$BACKUP_NAME.tgz /var/jenkins_home || echo 'tar done' > /appdata/.$BACKUP_NAME 
#> /appdata/$BACKUP_NAME.log
echo -e '\n\n+ [backup] end Compress...'

while [ ! -f $POD:/appdata/.$BACKUP_NAME  ]; do sleep 2s; done

echo -e "\n\n+ [backup] start Copy... [pod/$POD -> $BACKUP]"
time kubectl cp $POD:/appdata/$BACKUP_NAME.tgz $BACKUP.tgz
echo -e "\n\n+ [backup] end Copy... [pod/$POD -> $BACKUP]"

ls -l $BACKUP_DIR

# Trigger s3 upload
echo -e "\n\n+ [backup] Trigger Upload..."
echo 'START' > $S3_TRIGGER

#time kubectl exec -it $POD -- rm -rf appdata/$BACKUP_NAME.tgz 


