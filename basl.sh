#!/bin/bash

# BASL - Bourne Again Social Life
#
# Copyright (C) 2015 Yann Privé
#
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later
# version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along with
# this program. If not, see http://www.gnu.org/licenses/.

# General parameters
LANGUAGE='fr_FR'
CSV_CONTACTS='/path/to/contacts.csv'
MOBILE_REGEXP='\+33[67][0-9]{8}'
TARGET_DONGLE='dongle0'
ASTERISK_PATH='/usr/sbin/asterisk'

# Reads the messages
readarray BDAY_MESSAGES < <(sed '0,/#/d;/#/,$d;/^\s*$/d' ./messages/${LANGUAGE}.md)
readarray NWYR_MESSAGES < <(sed '1,/#/d;/^\s*$/d' ./messages/${LANGUAGE}.md)

# Parses the structure of the CSV
csv_header=$(head -n 1 ${CSV_CONTACTS} | sed 's/,/\n/g' | nl -b a -v 0 -s ',')
csv_length=$(echo ${csv_header} | wc -w) 

for field in ${csv_header[@]}
do
	variable=$(echo $field | cut -d ',' -f 2)
	value=$(echo $field | cut -d ',' -f 1)
	eval ${variable}=${value}
done

# Gets the birthdays to wish
ids=$(cut -d ',' -f $((${birthday}+1)) ${CSV_CONTACTS} | grep -n ^$(date +"%d%m") | cut -d ':' -f 1)
for id in ${ids[@]}
do
	friends+=($(sed "${id}q;d" ${CSV_CONTACTS}))
done

# Sends the SMS
for friend in ${friends[@]}
do

	# Gets the contact details
	for i in $(seq 0 ${csv_length})
	do
		infos[${i}]=$(echo $friend | cut -d ',' -f $((${i}+1)))
	done
	
	# Processes the birthday value
	if [ $(echo -n ${infos[${birthday}]} | wc -m) -eq 8 ]
	then
		age_p=$(($(date +"%Y") - $(echo ${infos[${birthday}]} | cut -c 5-8)))
	else
		age_p=''
	fi
	
	# Processes the name (or nickname) to display
	if [ -n "${infos[${nickname}]}" ]
	then
		name_p=${infos[${nickname}]}
	else
		name_p=${infos[${name}]}
	fi

	# Checks that the phone number is valid
	if [ $(echo ${infos[${mobile}]} | grep -E "^${MOBILE_REGEXP}" | wc -l) -eq 1 ]
	then

		# If we do not know the birth year, uses a message without age
		if [ -n "${age_p}" ]
		then
			msg_number=$(($RANDOM % ${#BDAY_MESSAGES[@]}))
		else
			while [ -z ${message_p+x} ] || [ $(echo ${message_p} | grep '$age' | wc -l) -eq 1 ]
			do
				msg_number=$(($RANDOM % ${#BDAY_MESSAGES[@]}))
				message_p=${BDAY_MESSAGES[${msg_number}]}
			done
		fi

		# Expands the variables in the message and prepares it for execution
		message_p=$(echo ${BDAY_MESSAGES[${msg_number}]} | sed 's/$age/$age_p/g;s/$name/$name_p/g' | sed "s/'/\\\'/g")
		message_p=$(eval "echo ${message_p}" | sed "s/'/\\\'/g")
		
		# Sleeps a bit to make things look real :)
		sleep $(($RANDOM % 20))m

		# Sends the message
		eval "$ASTERISK_PATH -rx $'dongle sms ${TARGET_DONGLE} ${infos[${mobile}]} ${message_p}'"
	fi
done

exit 0
