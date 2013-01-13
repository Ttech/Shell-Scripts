#!/bin/bash
####################################
####                            ####
####	2012 Ttech              ####
####	Bash Router Enabler     ####
####                            ####
####################################


# this should be the only part you need to modify
# the rest is fuly automated

# internal and external ip addresses and interfaces 
# don't mess this up, just don't

internal_ip="127.0.0.1"
external_ip="127.0.0.1"
internal_if="eth1"
external_if="eth0"


# ports to open
tcp=(80 44 322 21 25 6667);
udp=(2532 56454)


function check_root(){
	if [ "$UID" != "0" ]; then
		echo "This script must be run as root" 1>&2
		exit 1
	fi
}

function output(){
	level=$1
	message=$2

	if [ -z $3 ]; then
		sleep_time=$3
	else
		sleep_time=2
	fi

	if which dialog 2>/dev/null; then
		dialog --infobox "$level - $message" 3 $((${#message} + ${#level} + 7))
		sleep $sleep_time
	else
		echo -e "[$level]\t$message"
	fi
}

function iptables_status(){
	# set some variables
	local proto=$2
	local port=$3
	case $1 in
		0) output NOTICE "Sucessfully adding ${proto} port ${port}"
		;;
		1) output FATAL "Could add ${proto} port ${port} to iptables"
		;;
		126) output FATAL "Permission problem or command is not an executable"
			 exit 1
		;;
		127) output FATAL "No such command"
			 exit 1
		;;
		128) output WHAT "Invalid Argument"
		esac
}

function iptables_router(){
	output STATUS "Attemping to create ROUTER"
	iptables-restore <<-EOF
		*nat
		:PREROUTING ACCEPT [0:0]
		:INPUT ACCEPT [0:0]
		:OUTPUT ACCEPT [0:0]
		:POSTROUTING ACCEPT [0:0]
		-A POSTROUTING -o ${external_if} -j MASQUERADE
		COMMIT
		*mangle
		:PREROUTING ACCEPT [0:0]
		:INPUT ACCEPT [0:0]
		:FORWARD ACCEPT [0:0]
		:OUTPUT ACCEPT [0:0]
		:POSTROUTING ACCEPT [0:0]
		COMMIT
		*filter
		:INPUT DROP [0:0]
		:FORWARD DROP [0:0]
		:OUTPUT ACCEPT [0:0]
		-A INPUT -i ${internal_if} -j ACCEPT
		-A INPUT -i lo -j ACCEPT
		-A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
		-A INPUT -i ${external_if} -p icmp -j ACCEPT
		-A FORWARD -i ${internal_if} -o ${external_if} -j ACCEPT
		-A FORWARD -i ${external_if} -o ${internal_if} -m state --state RELATED,ESTABLISHED -j ACCEPT
		COMMIT
	EOF
	if [ $? -eq 0 ]; then
			output STATUS "Finished setting routing rules"
	else
			output FATAL "Could not set routing rules"
		exit 1
	fi
}

function load_kernel_modules(){
	# Do we want o learn about kernel modules? YEA!
	kernel_modules=("ip_tables" "echo iptables_nat" "nf_conntrack" "nf_contrack_ftp" "nf_nat_ftp" "nf_contrack_irc");
	for module in "${kernel_modules[@]}"
	do
		# load kernel modules
		#modprobe ${module}
		if [ $? -eq 0 ]; then
			output NOTICE "Loading Kernel Module \"${module}\""
		else
			output FATAL "Could not load ${module} entering failed state"
			exit 1
		fi
	done
}

function enable_forwarding(){
	# Setting ip forwarding and routing
	output STATUS "Setting up router - enabling"
	# enable ip forwarding ( so we can act as a router )
	echo "1" > /proc/sys/net/ipv4/ip_forward
	# set some awesome dynaddress stuff
	echo "1" > /proc/sys/net/ipv4/ip_dynaddr

}

#-m state --state NEW --dport 2342 -i eth0 -j ACCEPT

function menu_dialog(){
	loop=1

	while [ $loop -eq 1 ]
	do
		if which dialog 2>/dev/null; then
			option=`dialog --stdout --title "Router Main Menu" \
			--menu "Please choose an option:" 15 55 5 \
			1 "Loading Kernel Modules" \
			2 "Set sysctl Options" \
			3 "Load iptables router" \
			4 "Add Local Port Forward" \
			5 "Add Remote Port Forward" \
			6 "Exit from this menu"`
		echo $option
		else
			echo -e "iptables Router Main Menu\n\nSelect an option to continue\n"
			echo -e "\t\t1) Load Kernel Modules
			2) Set sysctl Options
			3) Load iptables router
			4) Add Local Port Forward
			5) Add Remote Port Forward
			6) Exit"
			echo "Option:"
			read -n 1 option
			echo -e "\n"
		fi
		case $option in
			1) load_kernel_modules
			;;
			2) enable_forwarding
			;;
			3) iptables_router
			;;
			4) iptables_local_add
			;;
			5) echo "Adding Remote"
			;;
			6)
				# We need to ask the user if we want to quit
				echo -e "\nAre you are you want to exit?"
				read -n 1 response
				echo -e "\n"
				if [ $response == "y" ]; then
					echo "Good bye..."
					exit 1
				else
					echo "Carry on then..."
				fi
			;;
			esac
		echo ""
	done
}

function menu_dialog(){
	loop=1

	while [ $loop -eq 1 ]
	do
		if which dialog 2>/dev/null; then		
			option=`dialog --stdout --title "Router Main Menu" \
			--menu "Please choose an option:" 15 55 5 \
			1 "Loading Kernel Modules" \
			2 "Set sysctl Options" \
			3 "Load iptables router" \
			4 "Add Local Port Forward" \
			5 "Add Remote Port Forward" \
			6 "Clear iptables" \
			7 "Exit from this menu"`
		echo $option
		else
			echo -e "iptables Router Main Menu\n\nSelect an option to continue\n"
			echo -e "\t\t1) Load Kernel Modules
			2) Set sysctl Options 
			3) Load iptables router
			4) Add Local Port Forward
			5) Add Remote Port Forward
			6) Clear iptables
			7) Exit"
			echo "Option:"
			read -n 1 option
			echo -e "\n"
		fi
		case $option in
			1) load_kernel_modules
			;;
			2) enable_forwarding
			;;
			3) iptables_router
			;;
			4) iptables_local_add
			;;
			5) iptables_remote_add
			;;
			6) iptables_clear
			;;
			7) quit_menu
			;;
			esac
		echo ""
	done
}

function iptables_clear(){
	output STATUS "Attemping to clear iptablbes..."
	iptables -X
	iptables -F
	# Do we want to show the user what is going on yet? probably not
	#iptables -L
	if [ $? -eq 0 ]; then
		output STATUS "Successfully CLEARED iptables"
	else
		output FATAL "Could not complete mission!" 
	fi
}

function quit_menu(){
	if which dialog 2>/dev/null; then
		output=$(dialog --stdout --title "Confirmation"  --yesno "Want to quit?" 6 20)
	else 
		echo "Do you want to quit?"
		read output
	fi


	case $? in
		0)
			exit 1
		## 1 = cancel, 255 = escape
		;;
		esac
}

function iptables_local_add() {
	output STATUS "Creating Local iptables forwards for protocol ${1}"

	# this dumb thing is to allow us to get an array passed into the function
	# let's try to be less hacky, okay? --dwfreed
	protocol=$2"[@]"
	# load tcp ports into echo iptables
	for port in "${!protocol}"
	do
		# iptables goes here
		iptables -A INPUT -p $1 --dport ${port} -j ACCEPT
		iptables_status $? $1 ${port}
	done
}

function iptables_remote_add() {
	if which dialogg 2>/dev/null; then
		proto=$(dialog --stdout --title "Please Enter A Proto" --backtitle "Please Enter Protocol" --inputbox "Please enter protocol (hint: tcp, udp, icmp)" 8 60 'tcp')
	else 
		echo "Please enter a protocl type (tcp, udp, icmp):"
		read -n 4 proto
	fi
	if [ $? != 0 ]; then
		output FATAL "You did not enter a protocol, I shall not continue"
	else
	        if which dialogg 2>/dev/null; then
			source_port=$(dialog --stdout --title "Please Enter A Port" --backtitle "Plesae Enter your source port (public facing)" --inputbox "Please enter public port number" 8 60 80)
		else 
			echo "Please enter your public port:"
			read -n 6 source_port
		fi
		if [ $? != 0 ]; then
	        	output FATAL "You did not enter a port number, I shall not continue"
		else
		        if which dialogg 2>/dev/null; then
			        port=$(dialog --stdout --title "Please Enter A Port" --backtitle "Plesae Enter your source port (private facing)" --inputbox "Please enter private port number" 8 60 80)
			else
				echo "Enter a private port:"
				read -n 6 port
			fi
	        	if [ $? != 0 ]; then
	                	output FATAL "You did not enter a port number, I shall not continue"
	        	else
	                        if which dialogg 2>/dev/null; then
			                dest_ip=$(dialog --stdout --title "Please Enter an IP Address" --backtitle "Plesae Enter your internal ip address" --inputbox "Please enter private ip address." 8 60 '127.0.0.1')
				else
					echo "Enter IP ADDRESS INTERNAL:"
					read -n 12 dest_ip
				fi
	        	        if [ $? != 0 ]; then
	                	        output FATAL "You did not enter an ip address, I shall not continue"
	               		 else
					iptables -t nat -I PREROUTING -p ${proto} --dport ${source_port} -i ${external_if} -j DNAT --to ${dest_ip}:${port}
					iptables_status $? ${proto} ${source_port}
					iptables -t nat -A PREROUTING -d ${external_ip} -p ${proto} --dport ${source_port} -j DNAT --to-destination ${dest_ip}:${port}
					iptables_status $? ${proto} ${source_port}
					iptables -A FORWARD -i ${external_if} -p ${proto} --dport ${source_port} -d ${dest_ip} -j ACCEPT
					iptables_status $? ${proto} ${source_port}
					iptables -I INPUT -i ${external_if} -p ${proto} --dport ${port} -j ACCEPT
	                	fi
	 		fi
		fi
	fi
}

# we need to run this as root, check!
check_root
# we need to display a main menu and start
menu_dialog
