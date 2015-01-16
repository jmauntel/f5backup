## Overview

This is a backup tool for F5 LTM configurations.  It contains the following logic:

1.  Connect to each device, create a .ucs file, download the .ucs file and the bigip.conf file
2.  Removes local .ucs files older than 30 days
3.  Commits bigip.conf files to Subversion
4.  Send notification email if any errors are encountered

## Requirements

* List of F5 LTM IP addresses that you want included in the backup
* SSH key-based authentication established for each target F5 device
* Email address to recieve alerts when backups fail
* SVN repository to hold the backups (this could be converted to git fairly easily)

## Supported Platforms

This code was developed and tested using CentOS 5, but is assumed to work
on other platforms as well.

## Dependencies

* bash >= 3.2.25
* svn >= 1.6.11
* mail >= 8.1.1

## Example log output:

```
[20150115-23:55:01] : getF5Configs : [INFO] Connecting to 10.1.1.71 and creating backup
Saving active configuration...
/var/local/ucs/config.ucs is saved.
[20150115-23:55:08] : getF5Configs : [INFO] Retrieving backup of 10.1.1.71
[20150115-23:55:08] : getF5Configs : [INFO] Retrieving bigip.conf configuration file
[20150115-23:55:08] : getF5Configs : [INFO] Retrieving bigip_base.conf configuration file
Sending        apps/f5backup/var/configs/10.1.1.71-bigip.conf
Transmitting file data ....
Committed revision 1597.
```

## Installation

* Execute the setup.sh script
* Add the ssh private key to the etc/ssh.key file
* Update the emaikl recipient in the bin/getF5Configs.sh script
* Update the list of target IP addresses in the etc/targets file
* Perform initial commit to the destination Subversion repository
* Copy cron/f5backup to /etc/cron.d/

## Manual Execution

```
bin/getF5Configs.sh
```

## Author

Author: Jesse Mauntel (maunteljw@gmail.com)
