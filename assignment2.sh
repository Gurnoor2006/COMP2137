#!/bin/bash

# Assignment 2 - System Configuration Script
# This script configures a Ubuntu server to meet specified requirements

# Color codes for output formatting
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print header
print_header() {
    echo -e "${YELLOW}"
    echo "========================================"
    echo "$1"
    echo "========================================"
    echo -e "${NC}"
}

# Function to check if last command succeeded
check_status() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Success${NC}"
    else
        echo -e "${RED}Failed${NC}"
        exit 1
    fi
}

# Update system packages
print_header "Updating System Packages"
apt-get update -y
check_status

# Configure network interface
print_header "Configuring Network Interface"
# Backup existing Netplan config
cp /etc/netplan/00-installer-config.yaml /etc/netplan/00-installer-config.yaml.bak

# Create new Netplan configuration
cat > /etc/netplan/00-installer-config.yaml <<EOL
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      dhcp4: false
      addresses: [192.168.16.21/24]
      gateway4: 192.168.16.2
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]
EOL

netplan apply
check_status

# Update /etc/hosts file
print_header "Updating /etc/hosts"
sed -i '/server1/d' /etc/hosts
echo "192.168.16.21    server1" >> /etc/hosts
check_status

# Install required packages
print_header "Installing Apache2"
apt-get install -y apache2
systemctl enable apache2
systemctl start apache2
check_status

print_header "Installing Squid"
apt-get install -y squid
systemctl enable squid
systemctl start squid
check_status

# Create users with SSH keys
print_header "Creating User Accounts"
users=("dennis" "aubrey" "captain" "snibbles" "brownie" "scooter" "sandy" "perrier" "cindy" "tiger" "yoda")

for user in "${users[@]}"; do
    # Create user if doesn't exist
    if ! id "$user" &>/dev/null; then
        echo -n "Creating user $user... "
        useradd -m -s /bin/bash "$user"
        check_status
    fi
    
    # Create .ssh directory if it doesn't exist
    if [ ! -d "/home/$user/.ssh" ]; then
        mkdir -p "/home/$user/.ssh"
        chown "$user:$user" "/home/$user/.ssh"
        chmod 700 "/home/$user/.ssh"
    fi
    
    # Generate SSH keys if they don't exist
    if [ ! -f "/home/$user/.ssh/id_rsa" ]; then
        echo -n "Generating RSA key for $user... "
        sudo -u "$user" ssh-keygen -t rsa -b 4096 -f "/home/$user/.ssh/id_rsa" -N ""
        check_status
    fi
    
    if [ ! -f "/home/$user/.ssh/id_ed25519" ]; then
        echo -n "Generating Ed25519 key for $user... "
        sudo -u "$user" ssh-keygen -t ed25519 -f "/home/$user/.ssh/id_ed25519" -N ""
        check_status
    fi
    
    # Add public keys to authorized_keys
    echo -n "Configuring authorized_keys for $user... "
    cat "/home/$user/.ssh/id_rsa.pub" >> "/home/$user/.ssh/authorized_keys"
    cat "/home/$user/.ssh/id_ed25519.pub" >> "/home/$user/.ssh/authorized_keys"
    
    # Special key for dennis
    if [ "$user" == "dennis" ]; then
        echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG4rT3vTt99Ox5kndS4HmgTrKBT8SKzhK4rhGkEVGlCI student@generic-vm" >> "/home/$user/.ssh/authorized_keys"
        
        # Add dennis to sudo group
        usermod -aG sudo dennis
    fi
    
    chown "$user:$user" "/home/$user/.ssh/authorized_keys"
    chmod 600 "/home/$user/.ssh/authorized_keys"
    check_status
done

# Final status check
print_header "Verifying Services"
echo -n "Apache2 status: "
systemctl is-active apache2
echo -n "Squid status: "
systemctl is-active squid

print_header "Assignment 2 Configuration Complete"
echo "Server has been successfully configured!"
echo "Network configured: 192.168.16.21/24"
echo "Apache2 and Squid installed and running"
echo "Users created with SSH keys:"
printf '%s\n' "${users[@]}"
