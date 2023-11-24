#!/bin/bash

# Step 1: Update and Upgrade Raspberry Pi
# This step ensures that all the packages on the Raspberry Pi are up to date.
echo "Updating and upgrading the Raspberry Pi. This may take a few minutes..."
sudo apt update && sudo apt upgrade -y

# Install WireGuard
# Checks if WireGuard is already installed. If not, it installs WireGuard.
echo "Checking for WireGuard installation..."
if ! command -v wg &> /dev/null; then
    echo "WireGuard not found. Installing WireGuard..."
    sudo apt install wireguard -y
else
    echo "WireGuard is already installed."
fi

# Install qrencode
# Checks if qrencode is already installed. If not, it installs qrencode.
# qrencode is used to generate QR codes for easy client configuration.
echo "Checking for qrencode installation..."
if ! command -v qrencode &> /dev/null; then
    echo "qrencode not found. Installing qrencode..."
    sudo apt install qrencode -y
else
    echo "qrencode is already installed."
fi

# Step 3: Generate Server Keys for WireGuard
# This generates the private and public keys needed for the WireGuard server.
echo "Generating server keys for WireGuard..."
wg genkey | tee privatekey | wg pubkey > publickey

# Step 4: Configure WireGuard Server
# This step sets up the basic configuration for your WireGuard server.
echo "Creating WireGuard server configuration..."
sudo mkdir -p /etc/wireguard
server_private_key=$(< privatekey)
sudo bash -c "echo \"[Interface]
Address = 10.6.0.1/24
SaveConfig = true
ListenPort = 51820
PrivateKey = $server_private_key\" > /etc/wireguard/wg0.conf"

# Step 5: Enable IP Forwarding
# IP Forwarding is required for routing traffic through the VPN.
echo "Enabling IP forwarding to allow traffic routing through the VPN..."
echo "net.ipv4.ip_forward=1" | sudo tee /etc/sysctl.d/99-sysctl.conf
sudo sysctl -p

# Function to add a new client
# This function guides you through adding a new VPN client.
add_client() {
    echo "Adding a new VPN client."
    read -p "Enter a name for the client (e.g., 'myphone'): " client_name
    config_file="${client_name}.conf"

    client_private_key=$(wg genkey)
    client_public_key=$(echo "$client_private_key" | wg pubkey)

    read -p "Enter an IP address for the client in the VPN subnet (e.g., 10.6.0.2/24): " client_ip
    server_public_key=$(< publickey)
    read -p "Enter the server endpoint (e.g., yourdomain.duckdns.org:51820): " server_endpoint

    echo "Creating the client configuration file..."
    echo "[Interface]
PrivateKey = $client_private_key
Address = $client_ip
DNS = 8.8.8.8

[Peer]
PublicKey = $server_public_key
Endpoint = $server_endpoint
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25" > $config_file

    echo "Generating a QR Code for the client configuration. Scan this with your WireGuard app."
    qrencode -t ansiutf8 < $config_file

    echo "Client Public Key: $client_public_key"
    echo "Add this public key to your WireGuard server configuration under a new [Peer] section."
}

# Function to install DuckDNS
# This function sets up DuckDNS, which is useful if you have a dynamic public IP.
install_duckdns() {
    echo "Setting up DuckDNS for dynamic DNS management..."
    read -p "Enter your DuckDNS domain (e.g., mydomain.duckdns.org): " duckdns_domain
    read -p "Enter your DuckDNS token: " duckdns_token

    duckdns_script_path="$HOME/duckdns/duck.sh"
    mkdir -p $HOME/duckdns
    echo "echo url=\"https://www.duckdns.org/update?domains=$duckdns_domain&token=$duckdns_token&ip=\" | curl -k -o $HOME/duckdns/duck.log -K -" > $duckdns_script_path
    chmod 700 $duckdns_script_path

    (crontab -l 2>/dev/null; echo "*/5 * * * * $duckdns_script_path >/dev/null 2>&1") | crontab -

    echo "DuckDNS is now set up and will automatically update your IP address every 5 minutes."
}

# DuckDNS Setup
# This section asks if you need to set up DuckDNS.
read -p "Do you need to set up DuckDNS (useful if your public IP changes frequently)? (yes/no): " setup_duckdns
if [[ $setup_duckdns =~ ^[Yy]es$ ]]; then
    install_duckdns
fi

# Client Addition Loop
# This loop allows you to add multiple VPN clients.
while true; do
    add_client
    read -p "Would you like to add another client? (yes/no): " add_another
    case $add_another in
        [Yy]* ) continue;;
        [Nn]* ) break;;
        * ) echo "Please answer yes or no.";;
    esac
done

# Step 6: Start and Enable WireGuard
# This step starts the WireGuard service and enables it to run at boot.
echo "Starting and enabling the WireGuard service..."
sudo systemctl start wg-quick@wg0
sudo systemctl enable wg-quick@wg0

echo "WireGuard server and client setup is now complete."
