# BackupWebserverToS3
A script to automatically backup /var/www and all of the mysql databases to amazon S3 storage
It compares using md5 and only uploads to S3 if the backup is different than the one stored locally

# Requirements
s3cmd: a utility to grab or put files to an s3 bucket
in ubuntu it can be installed with sudo apt-get install s3cmd
run it once prior to using this script to configure it 
Configure the following variables in the top of the shell script

LOG_DIR: The directory to store your log files
LOG_FILE: The file name you would like to use, currently it uses the current date.log

LOCAL_STORAGE_DIR: The storage directory that you will hold the most recent backups
REMOTE_S3_BUCKET: The bucket name on amazon s3 that you will be storing the backups remotely

WWW_DIR: The directory of all your web files you would like to backup

##Neither of the following require file extensions
DB_BACKUP_NAME: the name of the file storing your sql database
WWW_BACKUP_NAME: the name of the file storing your web files

SQL_PASSWORD: The password of your SQL database
SQL_USER: The username for your SQL

