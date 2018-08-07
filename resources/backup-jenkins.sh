#!/bin/sh
BIN="$( cd "$( dirname "$0" )" && pwd )"   # https://stackoverflow.com/a/20434740

# Inject through pod environment variables
#echo -e "\n\n+ Load environment variables..."
#source $BIN/setenv   # https://stackoverflow.com/a/13360474
#cat $BIN/setenv      # for logging

BACKUP=$BACKUP_DIR/jenkins-home-$(TZ='' date +%Y%m%d-%H%M)
mkdir -p $BACKUP

POD=$(kubectl get pods --no-headers=true -o custom-columns=:.metadata.name | grep -- $JENKINS_DEPLOY)
if [ -z "$POD" ]; then
	echo -e '\n\n+ ERROR :: There is no jenkins pod.'
	kubectl get pods
	echo 'ERROR' > $S3_TRIGGER
	exit 1
fi

echo -e "\n\n+ Copy... [pod/$POD -> $BACKUP]"
# https://github.com/kubernetes/charts/blob/master/stable/jenkins/templates/jenkins-master-deployment.yaml#L64
#if [ -z $(which rsync) ]; then
#	echo -e '\n\n+ Install rsync'
#	apk update
#	apk add rsync
#fi
#time rsync -av -e './rsh.sh' --blocking-io $POD:/var/jenkins_home $BACKUP
time kubectl cp $POD:/var/jenkins_home $BACKUP
ls -l $BACKUP

echo -e '\n\n+ Compress...'
time tar -zcvf $BACKUP.tgz $BACKUP > $BACKUP.log
rm -rf $BACKUP

ls -l $BACKUP_DIR

# Trigger s3 upload
echo 'START' > $S3_TRIGGER