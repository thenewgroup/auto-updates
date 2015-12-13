#!/bin/bash
# You may poll for updates by running this script in a cron job, or
# have updates triggerd by piping security announcement emails into this script.
# For example, with a ~/.forward or ~/.qmail-drupal file
# that contains a line with: "|/path/to/this/script/named/security-updates.sh",
# and subscribing $USER-drupal@$HOST to the security email newsletter.
# https://www.drupal.org/security.
#
#To limit this script to only 1 site, set WEB_ROOT to your Drupal root.
#
# To use on multiple sites, set WEB_ROOT at the shared folder for all Drupal sites.

drush=`which drush`
WEB_ROOT="/var/www/"

# Replace with "public_html" if you use a public_html subfolder
PUBLIC_DIR="."
EMAIL="me@example.com"
BACKUP_DIR="$HOME/backups/"

# Create a backup folder if it does not exist.
if [[ ! -d $BACKUP_DIR ]]
then
	echo "Creating new backup directory in $BACKUP_DIR"
	mkdir -p $BACKUP_DIR
fi

# Capture any message piped into this script and send it to $EMAIL.
# Allows to trigger this script by directing security anouncement emails to it.
stdin=$(cat)
if [ -n "$stdin" ]
then
 echo "$stdin" | mail -s "$WEB_ROOT: security-updates.sh got triggered with a message" "$EMAIL"
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
			drush vset maintance_mode 1

			# Take a backup and if it succeeds, run the update
			SITE_NAME=`basename ${i}`
			drush sql-dump | gzip > ${BACKUP_DIR}/${SITE_NAME}-pre-sec-update.sql.gz && drush up --security-only -y | mail -s "Your website needs testing" "$EMAIL"
			drush vset maintance_mode 0

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
