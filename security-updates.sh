#!/bin/bash
# You may poll for updates by running this script in a cron job, or
# have updates triggerd by piping security announcement emails into this script.
# For example, with a ~/.forward or ~/.qmail-drupal file
# that contains a line reading (without #, and unquoted for qmail):
# "|/path/to/this/script/named/security-updates.sh mailpipe"
# and subscribing $USER-drupal@$HOST to the security email newsletter.
# https://www.drupal.org/security.

# Non-security only updates may be done by passing the "update-all" parameter
# to this script.

# To limit this script to only 1 site, set WEB_ROOT to the Drupal site directory.
# To use on multiple sites, set WEB_ROOT to the directory containing all Drupal sites with a '/*' appended.

WEB_ROOT="/var/www/virtual/${USER}/*"

# Replace with "public_html" if you use a public_html subfolder
PUBLIC_DIR="."
EMAIL="${USER}@${HOST}"
BACKUP_DIR="$HOME/drush-backups" # should be the same place as drush uses

# The drupal (command line) console is required to enable mainenance mode for drupal 8.


if [ -z "$*" ] || [ "$1" == "mailpipe" ] && [ -z "$2" ]
then
        DRUSHPARAM="--security-only"
elif [ "$1" == "update-all" ] || [ "$2" == "update-all" ]
then
       	DRUSHPARAM=""
else
       	DRUSHPARAM="$*"
fi


# determine available commands
drush=`which drush`
drupal=`which drupal`

# Create a backup folder if it does not exist.
if [[ ! -d "$BACKUP_DIR" ]]
then
	echo "Creating new backup directory in $BACKUP_DIR"
	mkdir -p "$BACKUP_DIR"
fi

# Capture message piped into this script and send it to $EMAIL.
# This allows to trigger this script by directing security anouncement emails to it.
if [ "$1" == "mailpipe" ]
then
	stdin=$(cat)
	if [ -n "$stdin" ]
	then
		echo "$stdin" | mail -s "$WEB_ROOT: security-updates.sh mailpipe triggered" "$EMAIL"
	fi
fi

echo "Scanning WEB_ROOT directory $WEB_ROOT for Drupal installations."

for i in $WEB_ROOT/
do

	# Handle symlinks
	SITE_DIR=$(readlink -f $i)
	cd $SITE_DIR
	  cd $PUBLIC_DIR

	# Does the directory have a Drupal site?
	SITE_STATUS=$($drush status | grep "Drupal" | wc -l)
	if [[ $SITE_STATUS -gt 0 ]]
	then
		echo "Drupal installation for $i found in $(pwd)."

		# Make sure status is up to date
		drush pm-refresh

		# Check for security updates
		OUTPUT="$(drush pm-updatestatus ${DRUSHPARAM})"
		if [[ $OUTPUT == *"UPDATE"* ]]
		then
			# enable  maintenance
			if [ -z "$drupal" ]
			then
				drush vset maintance_mode 1	# this does not work with drupal 8
			else
				drupal site:maintenance ON
			fi

			# Take a backup and if it succeeds, run the update
			SITE_NAME=`basename ${i}`
			drush sql-dump | gzip > ${BACKUP_DIR}/${USER}-${SITE_NAME}-pre-sec-update_$(date +%F_%T).sql.gz && drush up ${DRUSHPARAM} -y | mail -s "${USER}-${SITE_NAME} website needs testing" "$EMAIL"

			# disable  maintenance
			if [ -z "$drupal" ]
			then
				drush vset maintance_mode 0     # this does not work with drupal 8
			else
				drupal site:maintenance OFF
			fi

			# Notify stakeholders
			echo "A ${DRUSHPARAM} update has been applied to $SITE_NAME. You should test production now."
		else
			echo "No ${DRUSHPARAM} updates."
		fi
	else
		echo "No Drupal site found in $(pwd)."
	fi
done
echo "Done with Drupal ${DRUSHPARAM} updates."
