#!/bin/bash
# Place this script in cron and run hourly. To limit this script to only 1 site, set WEB_ROOT to your Drupal root.
#
# To use on multiple sites, set WEB_ROOT at the shared folder for all Drupal sites with a '/*' appended.

drush=`which drush`
WEB_ROOT="/var/www/*"

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

echo "Scanning WEB_ROOT directory $WEB_ROOT for Drupal installations"


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
		echo "Drupal installation for $i found in $(pwd)"

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
