# auto-updates
Automatic security updates for Drupal

To limit this script to only Drupal site, set WEB_ROOT to your Drupal root. And, to use on multiple sites, 
set WEB_ROOT at the shared folder for all Drupal sites.

Install
-------
cd ~ && git clone https://github.com/thenewgroup/auto-updates.git

Running the Script
------------------

Add this to crontab -e to run every 60 minutes.

0 * * * * ~/auto-updates/security-updates.sh
