#!/bin/bash

# This shell script finds all that are not related to
# the current shell. Once these PIDs are found the 
# script proceeds to perform a HUP, TERM, and KILL
# depending on if the process survived or not. If a
# process does survive all three a message is sent to
# stderr with info related to the process 

# 3/1/2013
# Written by PQ D
# Homework #6 terminate dead session script

#set -x
# Get your current shell tty, strip off /dev/
pts=`tty | awk -F/dev/ '{print $2}'`
# Excluding your current shell tty, get all current user processes
ps -ef | grep ^$USER | grep -Ev "$pts( |$)" >> pidList
# Count is used to determine if a process survived at the end
count=0
# Loop through the list for each PID
for i in `cat pidList | awk '{print $2}'`;
	do
	hup=$(ps -ux | awk '{print $2}' | grep $i) 		# Checks to see if the process is still alive 
	if [ $? -eq 0 ]; 					# if alive perform HUP
        then
		echo "Attempting sig HUP..."
		kill -HUP $i
		sleep 2s 					# sleep for 2 seconds ( to see if it survived HUP )
		term=$(ps -ux | awk '{print $2}' | grep $i) 	# check to see if process is still alive
		if [ $? -eq 0 ]; 				# if alive perform TERM
		then
			echo "Attempting sig TERM..."
			kill -TERM $i
		fi;
		sleep 2s 					# sleep for 2 seconds ( to see if it survived TERM )
		kill=$(ps -ux | awk '{print $2}' | grep $i) 	# check to see if process is still alive
		if [ $? -eq 0 ];
		then
			echo "Attempting sig KILL..." 
			kill -KILL $i				# if alive perform KILL	
		fi;
	fi; 							
	sleep 2s						# sleep for 2 seconds ( to see if it survived )
	check=$(ps -ux | awk '{print $2}' | grep $i) 		# check to see if process is still alive
	if [ $? -eq 0 ];
        	then
			echo $i >> killFail 			# Add PID to file 
			count=1 				# Set count to 1 for check later
                fi;
done
rm -rf pidList 							# get rid of the list of PIDs
if [ $count -eq 0 ];						# check if a process survived
then
	echo "No processes survived!" 				# if no print message out to stdout
	exit 0							# set exit status 0
else
	echo "Processes that survived:" >&2 			# if yes print message to stderr 
	for i in `cat killFail`; 				# loop through to find cmd, pid, stat, and user
	do
		cmd=`ps -ux | grep -v grep | grep $i | awk '{print $11,$12}'` 		# set cmd used
        	pid=`ps -ux | grep -v grep | grep $i | awk '{print $2}'`      		# set pid value
        	stat=`ps -ux | grep -v grep | grep $i | awk '{print $8}'`		# set current stat
       	        echo -e "USER: $USER\tPID: $pid\tSTAT: $stat\t COMMAND: $cmd" 1>&2 	# print to stderr the info requested
	done
	rm -rf killFail									# remove this file
	exit 1										# set exit status 1
fi;
#set +x
