#!/bin/bash

# Update package list
sudo apt update

# Upgrade all packages to the latest version
sudo apt upgrade -y

# Clean up unnecessary packages
sudo apt autoremove -y

# Clean package cache
sudo apt clean

echo "System update completed successfully!"
