#!/bin/sh

BIN="$( cd "$( dirname "$0" )" && pwd )"   # https://stackoverflow.com/a/20434740

echo -e "\n\n+ Load environment variables..."
source $BIN/setenv   # https://stackoverflow.com/a/13360474
cat $BIN/setenv      # for logging

# Wait trigger of backup script
while [ ! -f $S3_TRIGGER ]; do sleep 2s; done
if [ 'ERROR' = "$(cat $S3_TRIGGER)" ]; then
	echo -e '\n\n+ ERROR :: Fail when backup stage.'
	exit 1
fi
rm $S3_TRIGGER

aws --endpoint-url $S3_ENDPOINT s3 ls $S3_BUCKET

echo -e "\n\n+ Upload backup files..."
time aws --dryrun --endpoint-url $S3_ENDPOINT s3 cp $BACKUP_DIR s3://$S3_BUCKET --recursive
