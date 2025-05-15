#!/bin/bash

# Get the current hostname
Hostname=$(hostname)

# Get the current IP address
IP=$(hostname -I | awk '{print $1}')

# Get the default gateway IP address
Gateway=$(ip route | grep default | awk '{print $3}')

# Display the system identification information
echo "Hostname: $Hostname"
echo "IP Address: $IP"
echo "Gateway IP: $Gateway"
