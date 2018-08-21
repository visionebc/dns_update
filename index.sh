#!/bin/bash

#  Program that update several ip's in DNS in Hurricane Electric
#  Autor: visionebc
#  Contact: scripts@visionebc.mx
#
#******************************
# Define variables
#******************************
RED='\033[0;41;30m'
STD='\033[0;0;39m'

MAIL="scripts@visionebc.mx" #Change mail of contact in case of failure

SCRIPT=$(readlink -f $0);
dir_base=`dirname $SCRIPT`;

LOG="$dir_base/log.txt"
HOSTS="$dir_base/hosts.txt"

LCRON=`crontab -l`
WHOAMI=`whoami`

if [ ! -f $LOG ]; then
	touch $LOG
fi
if [ ! -f $HOSTS ]; then
	touch $HOSTS
fi

#******************************
# Define functions
#******************************
function log {
	DATE=`date '+%Y-%m-%d %T'`
	echo "[$DATE] $1" >> $LOG
}
function ipl {
	IPF=`grep "New IP" $LOG | tail -1 | awk '{print $9}'`
	#IPF=`cat $dir_base/ip.txt`
	echo $IPF
}
pause(){
  read -p "Press [Enter] key to continue..." fackEnterKey
}

one(){
	echo ""
 	echo "***************** 1. Add hostnames"
 	echo "Type the hostname that you want to add, followed by [ENTER]:"
 	read varhost
    echo "Type the key of the hostname, followed by [ENTER]:"
    read varkey
    echo "Adding: "$varhost."--".$varkey
    `echo $varhost"--"$varkey >> $HOSTS`
    pause
}
 
two(){
	x=1
	echo ""
	echo "***************** 2. Delete Hostnames"
	OUT=$(echo "$line" | awk '{split($0,a,"--"); print a[1]}' $HOSTS)
	for host in $OUT
	do  
	   echo $x". "$host
	   x=$((x+1))
	done
	echo "Type the number of the hostname that you want to delete, followed by [ENTER]:"
	read varhost
	hosts_n=`echo "$1" | sed ''"$varhost"'q;d' $HOSTS`
	echo "Deleting: $hosts_n"
	sed -i ''"$varhost"'d' $HOSTS
 	pause
}

three(){
	x=1
	echo ""
	echo "***************** 3. Hostnames"
	OUT=$(echo "$line" | awk '{split($0,a,"--"); print a[1]}' $HOSTS)
	for host in $OUT
	do
	   echo $x". "$host
	   x=$((x+1))
	done
 	pause
}
four(){
	echo ""
	echo "***************** 4. Logs"
	tail -10 $LOG
 	pause
}
five(){
	echo ""
	echo "***************** 5. Specific logs"
	varx=($(wc -l $HOSTS))
	varx=$(((varx + 2)*2))
	grep Specific $LOG | tail -$varx
 	pause
}
six(){
	echo ""
	echo "***************** 6. Error Logs"
	tail -10 $LOG | grep 'Error in cathing IP'
 	pause
}
seven(){
	ipl #Calling funtion to know the actual ip
	echo ""
	echo "***************** 7. Update ip"
	IP=`curl -sk https://visionebc.com/ip/`
	if [ -z "$IP" ] || [[ $IP =~ (.*)(Error|error|ERROR)(.*) ]];
	then
		echo "[`date '+%Y-%m-%d %T'`] [Error in cathing IP]">>$LOG
		mail -s "Error in cathing IP" $MAIL <<< " Error in cathing IP"
		echo "================================"
		echo "Error in cathing IP"
	else
		if [ $IP == $IPF ]
		then
			echo "NO IP CHANGES"
			log "[No IP changes]"
		else
			varx=($(wc -l $HOSTS))
			vary=0
			echo "Wait, making changes."
			while read line
			do 
				vary=$(($vary+1))
				HOSTNAME=`echo "$line" | awk '{split($0,a,"--"); print a[1]}'`
			 	PASSWD=`echo "$line" | awk '{split($0,a,"--"); print a[2]}'`
			 	UPDATE=`curl -s "https://dyn.dns.he.net/nic/update" -d "hostname=$HOSTNAME" -d "password=$PASSWD" -d "myip=$IP" | cut -d " " -f 1`
			 	echo "[`date '+%Y-%m-%d %T'`] [Specific] [$HOSTNAME] [$UPDATE]">>$LOG
			 	pcnt=$(((vary*100) / varx))
			 	sharp=$sharp"#"
			 	echo -ne "[$sharp =>  ]($pcnt %)\r" 
			 	if [ $UPDATE = 'badauth' ]
				then
					mail -s "Error changing ip" $MAIL <<< "Error --badauth-- in $HOSTNAME"
				fi
			done < $HOSTS
			log "[New IP detected] [from $IPF] [to $IP ]"
			echo "================================>Change complete" 
			if [ $UPDATE = 'good' ]
			then
				mail -s "IP changed" $MAIL <<< "New IP detected. Updated record from $CURRENT_IP to $IP"
			fi
		fi
	fi
 	pause
}

eight(){
	echo ""
	echo "***************** 8. Add to cron"
	echo -e "\e[92mType the Minutes [0 - 59], followed by [ENTER]:"
	read varmin
		if [[ $varmin == "*" ]]; then
			2>&1
		else
		set +e
			while [ $varmin -lt 0 ] || [ $varmin -gt 59 ] || [[ $varmin =~ [a-zA-Z] ]];do
				echo -e "${RED}Error...${STD}" && sleep 1
				echo "*** $varmin *** is not between [0 - 59]. Type the MINUTES [0 - 59], followed by [ENTER]:"
				read varmin
				if [[ $varmin == "*" ]]; then
					break
				fi
			done
			false
			set -e
		fi
		varcmp="*/$varmin * * * * $SCRIPT \"x\" "
    	varfcmd=$WHOAMI"cron"
        echo "$varcmp"
		crontab -l > "$varfcmd"
		echo "$varcmp" >> "$varfcmd"
		crontab "$varfcmd"
		rm "$varfcmd"
		echo "Task inside"
 	pause
}
 
#******************************
# Menu
#******************************
show_menus() {
	clear
	echo -e "\e[0m"
	echo "####################################################"
	echo "#                                                  #"  
	echo "#  Program that update several ip's in             #"
	echo "#  DNS in Hurricane Electric                       #"
	echo "#  Autor: visionebc                                #"
	echo "#  Contact: scripts@visionebc.mx                   #"
	echo "#                                                  #" 
	echo "####################################################"
	echo ""
	echo "----  IP ACTUAL EN SISTEMA: `ipl`"
	echo ""
	echo "1. Add hostname"
	echo "2. Delete hostname"
	echo "3. See hostnames"
	echo "4. See logs"
	echo "5. Specific logs"
	echo "6. Error logs"
	echo "7. Update IP"
	echo "8. Add to cron"
	echo "9. Exit"
}
read_options(){
	local choice
	read -p "Enter choice [ 1 - 9]: " choice
	case $choice in
		1) one ;;
		2) two ;;
		3) three ;;
		4) four ;;
		5) five ;;
		6) six ;;
		7) seven ;;
		8) eight ;;
		9) exit 0;;
		*) echo -e "${RED}Error...${STD}" && sleep 1
	esac
}
  
#*************************************************************************
# Main
#    Script that also could run with argument to put directly in cron
#*************************************************************************
name=$1
if [[ -n "$name" ]]; then
	seven
else
    while true
	do
		show_menus
		read_options
	done
fi
