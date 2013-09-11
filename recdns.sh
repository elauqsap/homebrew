#!/bin/bash

##
# Script to scan a subnet for open DNS servers. Then the list
# of servers are ran against a recursive DNS call and the 
# response is parsed. If the response conatins a recursive
# answer then the host is saved to a list.
##

HOME=~/recdns
UNMAP=$HOME/udp.gnmap
GNMAP=$HOME/dns.gnmap
OPEN=$HOME/open.txt
ANSWER=$HOME/ans.txt
SORTED=$HOME/sort.txt

which nmap > /dev/null
if [ "$?" -eq "1" ]; then
	echo -e "$0 requires nmap\napt-get install nmap"
	exit 
fi

which dig > /dev/null
if [ "$?" -eq "1" ]; then
	echo -e "$0 requires dig\napt-get install bind-utils"
	exit
fi

if [ -z $1 ]; then
	echo "Usage: $0 192.168.0.0 24"
	echo "$0 -h for more help"
	exit 1
fi

if [ "$1" = "-h" ]; then
	echo -e "This script provides a method for scanning a subnet for
Recursive Open DNS Resolvers. The point being to mitigate
these systems as they are widely used in DoS attacks.

Examples:
recdns 192.168.0.0 24\t# Will scan 192.168.0.0/24 
recdns 172.16.0.0 16\t# Will scan 172.16.0.0/16"
	exit
else
	valid_IP=$(echo $1 | awk -F'.' '$1>=0 && $1<=255 && $2>=0 && $2<=255 && $3>=0 && $3<=255 && $4>=0 && $4<=255 && NF==4')
	if [ -z "$valid_IP"  ]; then
		echo "$1 is not a valid network"; exit
	elif [ "$2" -lt 0 ] || [ "$2" -gt 32 ]; then
		echo "$2 is not a valid subnet"; exit
	fi
fi

if [ -d "$HOME" ]; then
	cd $HOME
else
	mkdir $HOME && cd $HOME
fi

echo "Scanning the subnet..."
SSTART=$(date +%s)
sudo bash -c 'nmap -sS -Pn -T4 -p 53 --max-rtt-timeout 150ms --max-retries 1 -oG '$GNMAP' '$1'/'$2' 1>/dev/null; nmap -sU -Pn -T3 -p 53 --max-rtt-timeout 590ms --max-retries 2 -oG '$UNMAP' --min-hostgroup 75 --max-hostgroup 95 '$1'/'$2' 1>/dev/null; chmod 644 '$GNMAP'; chmod 644 '$UNMAP''
SSTOP=$(date +%s)
echo "Finding Open DNS servers..."
cat $UNMAP | grep -i "open/udp/" | awk '{print $2}' > $OPEN
cat $GNMAP | grep -i "open/tcp/" | awk '{print $2}' >> $OPEN

DSTART=$(date +%s)
for i in `cat $OPEN`
do
	dig @$i www.bored.com | grep -A5 ";; ANSWER SECTION:" | grep -v "$i" | grep -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3} &> /dev/null'
	if [ "$?" -eq "0" ]
	then
		echo $i >> $ANSWER
	fi
done
DSTOP=$(date +%s)

if [ ! -e $ANSWER ]; then
	echo "No Open Recursive DNS Resolvers were found on $1/$2"
	printf "Scan Time: %ds\tResolve Time: %ds\n"  $(echo "$SSTOP - $SSTART"|bc) $(echo "$DSTOP - $DSTART"|bc)
	exit 0
fi
cat $ANSWER | uniq | sort | uniq > $SORTED

TOTAL=`cat $SORTED | wc -l | sed -e 's/^[ \t]*//'`
printf "Scan Time: %ds\tResolve Time: %ds\n"  $(echo "$SSTOP - $SSTART"|bc) $(echo "$DSTOP - $DSTART"|bc)
echo "Open DNS Resolvers on $1/$2: $TOTAL"
if [ "$TOTAL" -gt "0" ]; then
	echo "Run \`cat $SORTED\` to get a list of the Open Recursive DNS servers"
fi
exit 0
