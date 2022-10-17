#!/bin/bash
NIC=$(route | grep '^default' | grep -o '[^ ]*$')
IP=$(ip route get 1.2.3.4 | awk '{print $7}' | tr -s '\n')
GW=$(route -n | grep 'UG[ \t]' | awk '{print $2}')
DNS=$(( nmcli dev list || nmcli dev show ) 2>/dev/null | grep DNS | awk '{print $2}')

echo "NIC=$NIC" >> .env
echo "IP=$IP" >> .env
echo "GW=$GW" >> .env
echo "DNS=$DNS" >> .env