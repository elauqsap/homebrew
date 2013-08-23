#!/bin/bash

##
# Shell script to check if a host is online or not.
# If it is online the script will email a user to 
# notify them that the host is available to check.
# Otherwise it will sleep for a set amount of time
# to check back later for the host.
##

bool=true					# boolean value to keep while loop running
mail=your@email.com 		# default email address
nap=30m						# default sleep time
array=("$@")				# arguments array
index=0						# index value to the array
host=$(hostname)

# function to parse args for new user defined settings
args( )
{
	count=${#array[@]}						# get the array size, store it
	while [ "$index" -le "$count" ]			# loop through arg count
	do
		case "${array[$index]}" in			# switch for script args
			-m)								# case for email
				tmp=index;let "tmp++"		# inc index to get the string after
				mail=${array[$tmp]}			# new email setting
				;;							# end case
			-t)								# case for sleep time
				tmp=index; let "tmp++"		# inc index to get the string after
				nap=${array[$tmp]}			# new sleep setting
				;;							# end case
			*)								# default case
				;;							# end case
		esac								# end switch
		let "index++"						# inc index to next spot in array
	done									# end while loop
}

if [ -z "$1" ]								# check for a first argument
then
	echo "Usage: $0 host [args] &"			# inform user of default use
	echo "$0 -h for more help"			
	exit 1									# stop the script
elif [ "$1" = "-h" ]						# give the user more in depth usage
then
	echo -e "Script to periodically check if a given host is up on the network\nUsage: $0 host [args] &"
	echo 'Running the command with an ampersand ("&") at the end will run the script'
	echo -e "in a separate shell so you can logout but continue the script\n\nArguments:"
	echo -e "-m\t change the default email address\n-t\t change the default time interval (30m)"
	echo -e " \t s - seconds\n \t m - minutes\n \t d - days\n \t no suffix will default to seconds" 
	exit 1
fi

args																							# call our args function

while $bool																						# while loop until false
do
	`ping -c 1 -W 5 $1 &> hostfile`																# ping the host 
	check=`cat hostfile | grep -i -c "unknown"`													# see if it is a real host
	rm -rf hostfile
	if [ "$check" -eq "1" ]																		
	then
		echo "$1 is not a valid, please check it" 1>err.log										# message goes to stderr
		exit 1																					# bad host, exit program
	fi
	`ping -c 1 -W 10 $1 | grep -i "100.0% packet loss" 1>>err.log`								# check for no packets loss
	if [ "$?" -eq "1" ]																			 
	then
		bool=false																				# set while to false
		date=`date`																				# get the current date & time
		echo "The following host $1 is now online $date" | mail \ 
			-s "SentinelScript Host Online" -r SentinelScript@$host $mail						# email the user
		exit 0																					# stop script
	else
		sleep $nap																				# otherwise sleep
	fi
done																							# end while loop
