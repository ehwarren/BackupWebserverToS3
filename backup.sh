#!/bin/sh

LOG_DIR="/home/austin/backuplogs/"
LOG_FILE="`date`.log"

LOCAL_STORAGE_DIR="/home/austin/backups"
REMOTE_S3_BUCKET="morbackup"

WWW_DIR="/var/www/"

DB_BACKUP_NAME="backup"
WWW_BACKUP_NAME="www_backup"

SQL_PASSWORD="password"
SQL_USER="username"
###################################################
#########   NO CONFIG BELOW THIS LINE   ###########
###################################################
SQL_HAS_CHANGED=0
WWW_HAS_CHANGED=0
LOG_PATH="$LOG_DIR/$LOG_FILE"

echo "Backing up sql database.." >> $LOG_PATH
mysqldump -A -u$SQL_USER -p$SQL_PASSWORD  >$LOCAL_STORAGE_DIR/current_dump.sql 2>/dev/null
#remove the last line for compares because they contain a timestamp
sed '$ d' $LOCAL_STORAGE_DIR/current_dump.sql > $LOCAL_STORAGE_DIR/current_dump
sed '$ d' $LOCAL_STORAGE_DIR/$DB_BACKUP_NAME.sql > $LOCAL_STORAGE_DIR/backup
#compare the md5 checksums
NEW_SQL_CHECKSUM=`md5sum $LOCAL_STORAGE_DIR/current_dump | awk '{ print $1 }'`
OLD_SQL_CHECKSUM=`md5sum $LOCAL_STORAGE_DIR/backup | awk '{ print $1 }'`
#remove temporary files
rm $LOCAL_STORAGE_DIR/current_dump
rm $LOCAL_STORAGE_DIR/backup
if test "$NEW_SQL_CHECKSUM" != "$OLD_SQL_CHECKSUM"
then
	echo "Database hase changed" >> $LOG_PATH
	#Flag our variable so we can push the new db to amazon s3
	SQL_HAS_CHANGED=1
fi
echo "Backing up /var/www" >> $LOG_PATH
tar -c $WWW_DIR 2>/dev/null | gzip -n > $LOCAL_STORAGE_DIR/www_current.tar.gz 2>/dev/null
#compare the new compressed file with the old one to check for changes
NEW_WWW_CHECKSUM=`md5sum $LOCAL_STORAGE_DIR/www_current.tar.gz | awk '{ print $1 }'`
OLD_WWW_CHECKSUM=`md5sum $LOCAL_STORAGE_DIR/$WWW_BACKUP_NAME.tar.gz | awk '{ print $1 }'`
if test "$NEW_WWW_CHECKSUM" != "$OLD_WWW_CHECKSUM"
then
	echo "Filesystem hase changed" >> $LOG_PATH
	#Flag our variable so we can push the new db to amazon s3
	WWW_HAS_CHANGED=1
fi

if [ $WWW_HAS_CHANGED -eq 1 ]
then
	echo "Pushing www to s3 bucket" >> $LOG_PATH
	s3cmd put $LOCAL_STORAGE_DIR/www_current.tar.gz s3://$REMOTE_S3_BUCKET/$WWW_BACKUP_NAME.`date +%d.%m.%Y`.tar.gz
	mv $LOCAL_STORAGE_DIR/www_current.tar.gz $LOCAL_STORAGE_DIR/$WWW_BACKUP_NAME.tar.gz
else
	echo "No changes in $WWW_DIR detected" >> $LOG_PATH
	rm $LOCAL_STORAGE_DIR/www_current.tar.gz
fi

if [ $SQL_HAS_CHANGED -eq 1 ]
then
	echo "Pushing sql to s3 bucket" >> $LOG_PATH
	s3cmd put $LOCAL_STORAGE_DIR/current_dump.sql s3://$REMOTE_S3_BUCKET/$DB_BACKUP_NAME.`date +%d.%m.%Y`.sql
	mv $LOCAL_STORAGE_DIR/current_dump.sql $LOCAL_STORAGE_DIR/$DB_BACKUP_NAME.sql
else
	echo "No changes in database detected..." >> $LOG_PATH
	rm $LOCAL_STORAGE_DIR/current_dump.sql
fi




