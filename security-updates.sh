#!/bin/bash
# Place this script in cron and run once per hour.

WEBROOT="/var/www/html"
EMAIL="me@example.com"
SITE_NAME="example.com"

cd $WEBROOT

# Make sure status is up to date
 drush pm-refresh

# Check for Security Updates
OUTPUT="$(drush pm-updatestatus --security-only)"
if [[ $OUTPUT == *"UPDATE"* ]]
then
  drush vset maintance_mode 1

  # Take a backup and if it succeeds, run the update
  drush sql-dump | gzip > ~/backup/prod.sql.gz && drush up --security-only -y
  drush vset maintance_mode 0

  # Notify stakeholders
  echo "A critical security update has been applied to $SITE_NAME. You should test production now." | mail -s "Your website needs testing" "$EMAIL";
fi
