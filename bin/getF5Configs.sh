#!/bin/bash

# Define Contants
# =-=-=-=-=-=-=-=

typeset -r TIMESTAMP=`date "+%Y%m%d-%H%M"`
typeset -r BASENAME=$(basename $0 .sh)
typeset -r EMAIL_NOTIFY='your.email@mycompany.com'
typeset -r HOME_DIR=$(dirname $0)/../
typeset -r ETC_DIR=${HOME_DIR}/etc
typeset -r VAR_DIR=${HOME_DIR}/var

typeset -r TARGET_FILES='bigip.conf
                         bigip_base.conf'

typeset -r SSH_OPTS="-i ${ETC_DIR}/ssh.key
                      -o CheckHostIP=no
                      -o StrictHostKeyChecking=no
                      -o ConnectionAttempts=2
                      -o PasswordAuthentication=no"


# Define Functions
# =-=-=-=-=-=-=-=-

function timeStamp () {
  echo -e "`date '+[%Y%m%d-%H:%M:%S]'` : $BASENAME : $*"
}


# Define Variables
# =-=-=-=-=-=-=-=-

errorFlag=0


# Redirect all output to the logfile
# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

exec > ${VAR_DIR}/log/f5backup_${TIMESTAMP}.log 2>&1


# Connect to each F5 device, create backup, and copy it down
# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

for host in $(egrep -o '^([0-9]{1,3}.){4}$' ${ETC_DIR}/targets) ; do 
  
  timeStamp "[INFO] Connecting to $host and creating backup"

  ssh $SSH_OPTS $host true && {

    ssh $SSH_OPTS $host 'tmsh save sys ucs config.ucs' || {
      timeStamp "[ERROR] Failed to create backup of $host"
      errorFlag=1
    }
    
    timeStamp "[INFO] Retrieving backup of $host"

    scp -q $SSH_OPTS ${host}:/var/local/ucs/config.ucs ${VAR_DIR}/ucs/${host}-${TIMESTAMP}.ucs || {
      timeStamp "[ERROR] Failed to retrieve backup file for $host"
      errorFlag=1
    }

    for file in $TARGET_FILES ; do
  
      timeStamp "[INFO] Retrieving $file configuration file"

      scp -q $SSH_OPTS ${host}:/config/${file} ${VAR_DIR}/configs/${host}-${file} || {
        timeStamp "[ERROR] Failed to retieve configuration file\(s\) for $host" 
        errorFlag=1
      }
  
    done

  } || {
    timeStamp "[ERROR] Failed to connect to $host"
    errorFlag=1
  }

done


# Remove .ucs files older than 30 days
# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

timeStamp "[INFO] Removing .ucs files older than 30 days"

find ${VAR_DIR}/ucs/ -maxdepth 1 -type f -mtime +30 -exec rm {} \; || {
  timeStamp "[ERROR] Failed to delete old .ucs files"
  errorFlag=1
}


# Commit the updated configuration files to Subversion 
# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

timeStamp "[INFO] Commiting updates to Subversion"
svn add $VAR_DIR || {
  timeStamp "[ERROR] Failed to add files in $VAR_DIR to repo"
  errorFlag=1
}
svn commit -m "Generic save/checkpoint." $VAR_DIR || {
  timeStamp "[ERROR] Failed to commit updates to Subversion"
  errorFlag=1
}


# If errors occured, send email to team
# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

[[ $errorFlag != 0 ]] && {
  timeStamp "[INFO] Sending error notification"
  mail -s "[ERROR] $BASENAME" $EMAIL_NOTIFY <<EOF
Team,

The $BASENAME process had errors during execution.

The error log has been included below for your review.

$(cat ${VAR_DIR}/log/f5backup_${TIMESTAMP}.log | sed 's/^/  /g')

EOF

}
