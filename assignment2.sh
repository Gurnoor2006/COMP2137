#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print a formatted header
print_header() {
    echo -e "${YELLOW}\n========================================"
    echo "$1"
    echo -e "========================================${NC}"
}

# Function to check the status of the last command
check_status() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✔ Success${NC}"
    else
        echo -e "${RED}✘ Failed${NC}"
        exit 1
    fi
}

# Update system packages
print_header "Updating System Packages"
apt-get update -y
check_status

# Configure static network interface using Netplan
print_header "Configuring Network Interface"
NETPLAN_FILE="/etc/netplan/00-installer-config.yaml"
cp "$NETPLAN_FILE" "$NETPLAN_FILE.bak"

cat > "$NETPLAN_FILE" <<EOL
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

# Update /etc/hosts with static hostname mapping
print_header "Updating /etc/hosts"
sed -i '/server1/d' /etc/hosts
echo "192.168.16.21    server1" >> /etc/hosts
check_status

# Install Apache2
print_header "Installing Apache2"
apt-get install -y apache2
check_status
systemctl enable apache2
systemctl start apache2
check_status

# Install Squid proxy
print_header "Installing Squid"
apt-get install -y squid
check_status
systemctl enable squid
systemctl start squid
check_status

# Create users and generate SSH keys
print_header "Creating User Accounts"
users=("dennis" "aubrey" "captain" "snibbles" "brownie" "scooter" "sandy" "perrier" "cindy" "tiger" "yoda")

for user in "${users[@]}"; do
    echo -e "Processing user: ${YELLOW}$user${NC}"
    
    # Create the user if not exists
    if ! id "$user" &>/dev/null; then
        useradd -m -s /bin/bash "$user"
        check_status
    fi

    SSH_DIR="/home/$user/.ssh"
    AUTH_KEYS="$SSH_DIR/authorized_keys"

    mkdir -p "$SSH_DIR"
    chown "$user:$user" "$SSH_DIR"
    chmod 700 "$SSH_DIR"

    # Generate SSH key pairs if they don't already exist
    if [ ! -f "$SSH_DIR/id_rsa" ]; then
        sudo -u "$user" ssh-keygen -t rsa -b 4096 -f "$SSH_DIR/id_rsa" -N "" &>/dev/null
        check_status
    fi

    if [ ! -f "$SSH_DIR/id_ed25519" ]; then
        sudo -u "$user" ssh-keygen -t ed25519 -f "$SSH_DIR/id_ed25519" -N "" &>/dev/null
        check_status
    fi

    # Add public keys to authorized_keys
    cat "$SSH_DIR/id_rsa.pub" "$SSH_DIR/id_ed25519.pub" > "$AUTH_KEYS"

    # Add special key and sudo access for 'dennis'
    if [ "$user" == "dennis" ]; then
        echo "Adding special key and sudo privileges to dennis"
        echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG4rT3vTt99Ox5kndS4HmgTrKBT8SKzhK4rhGkEVGlCI student@generic-vm" >> "$AUTH_KEYS"
        usermod -aG sudo dennis
    fi

    chown "$user:$user" "$AUTH_KEYS"
    chmod 600 "$AUTH_KEYS"
    check_status
done

# Final service verification
print_header "Verifying Services"

echo -n "Apache2 status: "
systemctl is-active apache2

echo -n "Squid status: "
systemctl is-active squid

# Completion message
print_header "Assignment 2 Configuration Complete"
echo -e "${GREEN}Server successfully configured!${NC}"
echo -e "Network: ${YELLOW}192.168.16.21/24${NC}"
echo -e "Services: ${GREEN}Apache2${NC} and ${GREEN}Squid${NC} installed and running"
echo -e "User accounts created with SSH keys:"
printf '%s\n' "${users[@]}"
