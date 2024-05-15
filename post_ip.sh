#!/bin/bash

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

SECRETS_FILE="$SCRIPT_DIR/.secret"

# Exit if .env file exists
if [ -f "$SECRETS_FILE" ]; then

    # Check if there are arguments
    if [ $# -gt 0 ]; then
        echo "action: ${2}"
        if [ $# -eq 2 ] && [ "$2" = "up" ]; then
            echo "Running the script with 'up' argument."
        else
            echo "Usage: $0 [ip_address up] [access_key]"
            exit 1
        fi
    fi


    export $(grep -v '^#' "$SECRETS_FILE" | xargs)
    ip_address="$(hostname -I)"

    # Create a JSON payload with the IP address and access key
    data="{\"ip_address\":\"$ip_address\",\"key\":\"$DDNS_KEY\",\"device\":\"$DDNS_DEVICE\"}"

    # Send the POST request using curl
    curl -X POST -H "Content-Type: application/json" -d "$data" "$DDNS_URL"
    exit 0
fi


if [ "$EUID" -ne 0 ]; then
    echo "On first run this script must be run as root. Exiting..."
    exit 1
fi

NM_DISPATCHER_DIR="/etc/NetworkManager/dispatcher.d"

if [ ! -d "$NM_DISPATCHER_DIR" ]; then
    echo "Network Manager must be installed and active"
    echo "Exiting..."
    exit 1
fi

read -p "Enter Device Name: " DDNS_DEVICE
read -p "Enter URL to post ip data to: " DDNS_URL
read -p "Enter security key: " DDNS_KEY

echo "DDNS_DEVICE=\"$DDNS_DEVICE\"" > "$SECRETS_FILE"
echo "DDNS_URL=\"$DDNS_URL\"" >> "$SECRETS_FILE"
echo "DDNS_KEY=\"$DDNS_KEY\"" >> "$SECRETS_FILE"

echo "Saved URL and key in $SECRETS_FILE"

chmod 777 post_ip.sh
ln -s "$SCRIPT_DIR/post_ip.sh" "$NM_DISPATCHER_DIR/post_ip"

echo "Created symlink in $NM_DISPATCHER_DIR/post_ip"
