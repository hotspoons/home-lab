#!/bin/bash
NIC=$(route | grep '^default' | grep -o '[^ ]*$')
IP=$(ip route get 1.2.3.4 | awk '{print $7}' | tr -s '\n')
GW=$(route -n | grep 'UG[ \t]' | awk '{print $2}')
MAC=$(cat /sys/class/net/$NIC/address)
# TODO we should figure out a reliable way to get the network mask, e.g.
#NMASK=$(ifconfig NIC | awk '/netmask/{split($4,a,":"); print a[1]}')
DNS=$(( nmcli dev list || nmcli dev show ) 2>/dev/null | grep DNS | awk '{print $2}')

cp .env.example .env

echo "NIC=$NIC" >> .env
echo "IP=$IP" >> .env
echo "GW=$GW" >> .env
echo "DNS=$DNS" >> .env
echo "MAC=$MAC" >> .env