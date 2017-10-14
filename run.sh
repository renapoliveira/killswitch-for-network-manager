#!/bin/bash
source config.sh
trap ctrl_c INT

UUID=$(nmcli connection | grep "$VPN" | sed -e 's/'"$VPN"'//g' | awk '{print $1}')

function ctrl_c() {
	echo "Flushing iptables and exiting"
	sudo iptables --flush
	exit 1
}

sudo iptables --flush
#Allow connection with the VPN IP
sudo iptables -A OUTPUT -d $IP -j ACCEPT
sudo iptables -A INPUT -s $IP -j ACCEPT
#Allow connection through the tunnel
sudo iptables -A OUTPUT -o $TUNNEL -j ACCEPT
sudo iptables -A INPUT -i $TUNNEL -j ACCEPT
#Block all connection through the main interface
sudo iptables -A OUTPUT -o $INTERFACE -j DROP
sudo iptables -A INPUT -i $INTERFACE -j DROP

#Check every 5 seconds if VPN goes down, then reconnect it
while [ true ]
do
	if [[ $(nmcli connection) != *$TUNNEL* ]]; then
		nmcli connection up $UUID
	fi
	sleep 5
done

