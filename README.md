# auto-updates
Automatic security updates for Drupal.

To limit this script to only one Drupal site, set ``WEB_ROOT`` to your Drupal root. And, to update multiple sites, 
set ``WEB_ROOT`` at the shared folder for all Drupal sites.

Install
-------
```
cd ~ && git clone https://github.com/thenewgroup/auto-updates.git
```
Next, you *must* edit the variables at the top of the script to match your environment.

Automatically Running the Script
------------------

You could regularly poll for updats by adding this to crontab -e (run every full hour),
```
0 * * * * ~/auto-updates/security-updates.sh
```
or have updates triggered by security announcement emails (see comments in script).

Manually Triggering Updates
--------------------------
If you call the script with the ``update-all`` parameter it will perform all pending updates (not just ``--security-only``).
