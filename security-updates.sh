#!/bin/bash
# You may poll for updates by running this script in a cron job, or
# have updates triggerd by piping security announcement emails into this script.
# For example, with a ~/.forward or ~/.qmail-drupal file
# that contains a line reading (without the leading #):
# |"/path/to/this/script/named/security-updates.sh mailpipe"
# and subscribing $USER-drupal@$HOST to the security email newsletter.
# https://www.drupal.org/security.

# To limit this script to only 1 site, set WEB_ROOT to your Drupal root.
# To use on multiple sites, set WEB_ROOT at the shared folder for all Drupal sites.

WEB_ROOT="/var/www"

# Replace with "public_html" if you use a public_html subfolder
PUBLIC_DIR="."
EMAIL="${USER}@${HOST}"
BACKUP_DIR="$HOME/drush-backups" # should same place as drush uses

# The drupal (command line) console is required to enable mainenance mode for drupal 8.

# determine available commands
drush=`which drush`
drupal=`which drupal`


# Create a backup folder if it does not exist.
if [[ ! -d $BACKUP_DIR ]]
then
	echo "Creating new backup directory in $BACKUP_DIR"
	mkdir -p $BACKUP_DIR
fi

# Capture message piped into this script and send it to $EMAIL.
# This allows to trigger this script by directing security anouncement emails to it.
if [ $1 == "mailpipe" ]
then
    	stdin=$(cat)
        if [ -n "$stdin" ]
        then
            	echo "$stdin" | mail -s "$WEB_ROOT: security-updates.sh mailpipe triggered" "$EMAIL"
        fi
fi


echo "Scanning sites directory for Drupal installations"
cd $WEB_ROOT

for i in $WEB_ROOT/
do

	# Handle symlinks
	SITE_DIR=$(readlink -f $i)
	cd $SITE_DIR
	  cd $PUBLIC_DIR

	# Does the directory have a Drupal site?
	SITE_STATUS=$($drush status | wc -l)
	if [[ $SITE_STATUS -gt 7 ]]
	then
		echo "Drupal site found in $(pwd)"

		# Make sure status is up to date
		drush pm-refresh

		# Check for security updates
		OUTPUT="$(drush pm-updatestatus --security-only)"
		if [[ $OUTPUT == *"UPDATE"* ]]
		then
			# enable  maintenance
                        if [ -z "$drupal" ]
                        then
                            	drush vset maintance_mode 1     # this does not work with drupal 8
                        else
                            	drupal site:maintenance ON
                        fi

			# Take a backup and if it succeeds, run the update
			SITE_NAME=`basename ${i}`
			drush sql-dump | gzip > ${BACKUP_DIR}/${USER}-${SITE_NAME}-pre-sec-update_$(date +%F_%T).sql.gz && drush up --security-only -y | mail -s "${USER}-${SITE_NAME} website needs testing" "$EMAIL"

                        # disable  maintenance
                        if [ -z "$drupal" ]
                        then
                            	drush vset maintance_mode 0     # this does not work with drupal 8
                        else
                            	drupal site:maintenance OFF
                        fi

			# Notify stakeholders
			echo "A critical security update has been applied to $SITE_NAME. You should test production now."
		else
			echo "No available security updates"
		fi
	else
		echo "No Drupal site found"
	fi
done
echo "Done with Drupal security updates"
