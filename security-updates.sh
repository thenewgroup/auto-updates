#!/bin/bash
# Place this script in cron and run once per hour.

WEBROOT="/var/www"
EMAIL="me@example.com"
BACKUP_DIR = "~/backups/manual"

echo "Scanning sites directory for drupal installations"
cd $WEBROOT

for i in $(ls)
do 
	SITE_DIR=$(readlink -f $i)
	# if your site files are in directories immediately
	# beneath your site_dir, i.e. /var/www/site.com,
	# then you don't need to `cd public_html'
	# just use `cd $a` below
	cd $SITE_DIR && cd public_html
	echo $(pwd) 
	# first check to see if site directory has a drupal site
	STATUS=$($drush status | wc -l)
	if [[ $status -gt 7 ]]
	then 
		echo "Drupal site found"
		# Make sure status is up to date
		drush pm-refresh
		# Check for Security Updates
		OUTPUT="$(drush pm-updatestatus --security-only)"
		if [[ $OUTPUT == *"UPDATE"* ]]
		then
			drush vset maintance_mode 1
			# Take a backup and if it succeeds, run the update
			drush sql-dump | gzip > ~/${BACKUP_DIR}/${i}-pre-sec-update.sql.gz && drush up --security-only -y
			drush vset maintance_mode 0
		  # Notify stakeholders
			echo "A critical security update has been applied to $i. You should test production now." | mail -s "Your website needs testing" "$EMAIL";
		else
			echo "No available security updates"
	else
		echo "No Drupal Site Found"
	fi 
	cd $WEBROOT
done
echo "Done with Drupal Security Updates"