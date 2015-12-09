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

# Gets the execution parameters
readonly PROGNAME=$(basename $0)
readonly PROGDIR=$(readlink -m $(dirname $0))
readonly ARGS="$@"
readonly ARGS_NB=$#

# Main function
main() {

	# Variables
	local option cmd

	# Reads the configuration file
	source config.sh

	# Checks that enough arguments were passed
	if [ ${ARGS_NB} -eq 0 ]
	then
		echo "Executing $PROGNAME requires at least 1 argument among -t, -h, -n or -b." >&2
		exit 1
	fi

	# If the previous passed, read the contacts and messages
	read_contacts_messages

	# Gets the command line arguments
	while getopts ':thnb' option $ARGS
	do
		case $option in
			t)
				echo 'Test option not yet implemented.' >&2
				;;
			h)
				echo 'Help option not yet implemented.' >&2
				;;
			n)
				if [ -z "$cmd" ]
				then
					readonly MAX_SLEEP_TIME=15
					cmd='prepare_sms newyear'
				else
					echo 'Error: you can not run the options n and b together.' >&2
				fi
				;;
			b)
				if [ -z "$cmd" ]
				then
					readonly MAX_SLEEP_TIME=1200
					cmd='prepare_sms birthday'
				else
					echo 'Error: you can not run the options n and b together.' >&2
				fi
				;;
			\?)
				echo "Invalid option: -$OPTARG" >&2
				;;
		esac
	done

	# Executes the command accordingly
	eval $cmd
}

# Reads the contacts and messages files
read_contacts_messages() {

	# Variables
	local csv_header field variable value

	# Reads the messages
	readarray BDAY_MESSAGES < <(sed '0,/#/d;/#/,$d;/^\s*$/d' ./messages/${LANGUAGE}.md)
	readarray NWYR_MESSAGES < <(sed '1,/#/d;/^\s*$/d' ./messages/${LANGUAGE}.md)

	# Parses the structure of the CSV
	csv_header=$(head -n 1 ${CSV_CONTACTS} | sed 's/,/\n/g' | nl -b a -v 0 -s ',')
	readonly CSV_LENGTH=$(echo ${csv_header} | wc -w) 

	for field in ${csv_header[@]}
	do
		variable=$(echo ${field} | cut -d ',' -f 2 | tr [a-z] [A-Z])
		value=$(echo ${field} | cut -d ',' -f 1)
		eval readonly ${variable}=${value}
	done
}

# Prepares the birthday or new year message
prepare_sms() {

	# Variables
	local ids i friends friend infos msg_number sleep_time
	local age_p name_p message_p
	local year_p=$(date +'%Y')
	local smstype="$1"

	# Gets the persons concerned
	if [ $smstype = 'birthday' ]
	then
		ids=$(cut -d ',' -f $((${BIRTHDAY}+1)) ${CSV_CONTACTS} | grep -n ^$(date +'%d%m') | cut -d ':' -f 1)
	elif [ $smstype = 'newyear' ]
	then
		ids=$(cut -d ',' -f $((${NEWYEAR}+1)) ${CSV_CONTACTS} | grep -n ^[yY] | cut -d ':' -f 1)
	else
		echo "Something went wrong, blame the author!" >&2
		return 1
	fi

	for i in ${ids[@]}
	do
		friends+=($(sed "${i}q;d" ${CSV_CONTACTS}))
	done

	# Goes through the friend list
	for friend in ${friends[@]}
	do

		# Gets the contact details
		for i in $(seq 0 ${CSV_LENGTH})
		do
			infos[${i}]=$(echo ${friend} | cut -d ',' -f $((${i}+1)))
		done

		# Processes the name (or nickname) to display
		if [ -n "${infos[${NICKNAME}]}" ]
		then
			name_p=${infos[${NICKNAME}]}
		else
			name_p=${infos[${NAME}]}
		fi

		# Case "birthday"
		if [ $smstype = 'birthday' ]
		then

			# Prepares the age & birthday message 
			if [ $(echo -n ${infos[${BIRTHDAY}]} | wc -m) -eq 8 ]
			then
				age_p=$((${year_p} - $(echo ${infos[${BIRTHDAY}]} | cut -c 5-8)))
				message_p=${BDAY_MESSAGES[$(($RANDOM % ${#BDAY_MESSAGES[@]}))]}
			else
				while [ -z ${message_p+x} ] || [ $(echo ${message_p} | grep '$age' | wc -l) -eq 1 ]
				do
					msg_number=$(($RANDOM % ${#BDAY_MESSAGES[@]}))
					message_p=${BDAY_MESSAGES[${msg_number}]}
				done
			fi

			# Sets the sleeping time before sending the sms
			sleep_time=$(($RANDOM % (${MAX_SLEEP_TIME} + 1)))

		# Else, case "newyear"
		else

			# Prepares the new year message
			message_p=${NWYR_MESSAGES[$(($RANDOM % ${#NWYR_MESSAGES[@]}))]}
			
			# Sets the sleeping time before sending the sms
			sleep_time=$(($RANDOM % (${MAX_SLEEP_TIME} - 4) + 5))

		fi

		# Checks that the phone number is valid
		if [ $(echo ${infos[${MOBILE}]} | grep -E "^${MOBILE_REGEXP}" | wc -l) -eq 1 ]
		then

			# Expands the variables in the message and prepares it for execution
			message_p=$(echo ${message_p} | sed 's/$year/$year_p/g;s/$age/$age_p/g;s/$name/$name_p/g' | sed "s/'/\\\'/g")
			message_p=$(eval "echo ${message_p}" | sed "s/'/\\\'/g")

			# Sends the SMS
			if [ $smstype = 'birthday' ]
			then
				queue_sms "${sleep_time}" "${infos[${MOBILE}]}" "${message_p}" &
			else
				queue_sms "${sleep_time}" "${infos[${MOBILE}]}" "${message_p}"
			fi
		fi
	done
}

# Function to queue the SMS
queue_sms() {

	# Variables
	local sleep_time=$1
	local mobile=$2
	local message=$3

	# Message to send
	sleep ${sleep_time}
	eval "${ASTERISK_PATH} -rx $'dongle sms ${TARGET_DONGLE} ${mobile} ${message}'"
}

# Launches the main function
main

exit 0
