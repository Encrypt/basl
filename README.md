# BASL - Bourne Again Social Life

## About
BASL is a bash script which automatically sends "happy birthday" and "happy new year" SMS to your close relatives.

## Prerequisites
In order to use it, you will need:
- A working asterisk server
- A cell phone plan
- The chan_dongle module loaded and configured
- Family or even... friends :')

## Installing and configuring
To use this script, clone this project to your home directory for example.

Fill the contacts.csv file with the appropriate information.
Please note that the birthday format must be either:
- DDMMYYYY, in which case an SMS with the age might be sent ; or
- DDMM, in which case sent messages to that person won't include the age.

Also, if the "nickname" value is not blank for a particular contact, her (or his) nickname will be used in the SMS.

If you want to wish an "happy new year", then add a "Y" (for yes!) in the newyear column of the CSV.
Else, put an "N".

The general parameters have to be set in the config.sh file:
- LANGUAGE: the language of the messages. Pick the name of the appropriate file in the "messages" folder, minus ".md".
- CSV_CONTACTS: path to your contacts CSV file.
- MOBILE_REGEXP: regular expression which matches your local phone numbers (now configured for France).
- TARGET_DONGLE: name of the target dongle which will send the SMS.
- ASTERISK_PATH: path to the asterisk executable.

Add two cron job to run the script at the appropriate moment (/etc/crontab under Debian):
```
15 9  * * *  root  /home/you/basl.sh -b
1 0  1 1 *  root  /home/you/basl.sh -n
```

The "b" option being for "birthday" and the "n" option for "new year".

And there you go!

## Licence
BASL is released under the GPLv3 licence.
