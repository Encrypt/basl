BASL - Bourne Again Social Life
===============================

# About
BASL is a bash script which automatically sends "happy birthday" SMS to your close relatives.

# Prerequisites
In order to use it, you will need:
- A working asterisk server
- A cell phone plan
- The chan_dongle module loaded and configured
- Family or even... friends :')

# Installing and configuring
To use this script, clone this project to your home directory for example.

Fill the contacts.csv file with the appropriate information.
Please note that the birthday format must be either:
- DDMMYYYY, in which case an SMS with the age might be sent ; or
- DDMM, in which case sent messages to that person won't include the age.

Also, if the "nickname" value is not blank for a particular contact, her (or his) nickname will be used in the SMS.

Change the general parameters of basl.sh with your current configuration:
- CSV_CONTACTS: path to your contacts csv file.
- MOBILE_REGEXP: regular expression which matches your local phone numbers (now configured for France).
- TARGET_DONGLE: name of the target dongle which will send the SMS.
- ASTERISK_PATH: path to the asterisk executable.

Add a cron job to run the script everyday (/etc/crontab under Debian):
> 15 9  \* \* \*  root  /home/you/basl.sh

And there you go!

# Licence
BASL is released under the GPLv3 licence.
