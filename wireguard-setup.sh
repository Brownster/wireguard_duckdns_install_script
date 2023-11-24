#!/bin/bash

# Step 1: Update and Upgrade Raspberry Pi
echo "Updating and upgrading the Raspberry Pi..."
sudo apt update && sudo apt upgrade -y

# Check and install WireGuard
echo "Checking and installing WireGuard..."
if ! command -v wg &> /dev/null; then
    sudo apt install wireguard -y
else
    echo "WireGuard is already installed."
fi

# Check and install qrencode
echo "Checking and installing qrencode..."
if ! command -v qrencode &> /dev/null; then
    sudo apt install qrencode -y
fi

# Step 3: Generate Server Keys for WireGuard
echo "Generating server keys for WireGuard..."
wg genkey | tee privatekey | wg pubkey > publickey

# Step 4: Configure WireGuard Server
echo "Creating WireGuard server configuration..."
sudo mkdir -p /etc/wireguard
server_private_key=$(< privatekey)
sudo bash -c "echo \"[Interface]
Address = 10.6.0.1/24
SaveConfig = true
ListenPort = 51820
PrivateKey = $server_private_key\" > /etc/wireguard/wg0.conf"

# Step 5: Enable IP Forwarding
echo "Enabling IP forwarding..."
echo "net.ipv4.ip_forward=1" | sudo tee /etc/sysctl.d/99-sysctl.conf
sudo sysctl -p

# Function to add a new client
add_client() {
    echo "You will now enter details for a new VPN client."
    read -p "Enter client name: " client_name
    config_file="${client_name}.conf"

    client_private_key=$(wg genkey)
    client_public_key=$(echo "$client_private_key" | wg pubkey)

    read -p "Enter client IP address in VPN subnet: " client_ip
    read -p "Enter the server's public key: " server_public_key
    read -p "Enter the server endpoint: " server_endpoint

    echo "Creating client configuration file..."
    echo "[Interface]
PrivateKey = $client_private_key
Address = $client_ip
DNS = 8.8.8.8

[Peer]
PublicKey = $server_public_key
Endpoint = $server_endpoint
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25" > $config_file

    echo "Generating QR Code for the client configuration..."
    qrencode -t ansiutf8 < $config_file

    echo "Client Public Key: $client_public_key"
    echo "Add this public key to your WireGuard server configuration."
}

# Function to install DuckDNS
install_duckdns() {
    echo "Setting up DuckDNS..."
    read -p "Enter your DuckDNS domain: " duckdns_domain
    read -p "Enter your DuckDNS token: " duckdns_token

    duckdns_script_path="$HOME/duckdns/duck.sh"
    mkdir -p $HOME/duckdns
    echo "echo url=\"https://www.duckdns.org/update?domains=$duckdns_domain&token=$duckdns_token&ip=\" | curl -k -o $HOME/duckdns/duck.log -K -" > $duckdns_script_path
    chmod 700 $duckdns_script_path

    (crontab -l 2>/dev/null; echo "*/5 * * * * $duckdns_script_path >/dev/null 2>&1") | crontab -

    echo "DuckDNS is set up and will update your IP every 5 minutes."
}

# DuckDNS Setup
read -p "Do you need to set up DuckDNS? (yes/no): " setup_duckdns
if [[ $setup_duckdns =~ ^[Yy]es$ ]]; then
    install_duckdns
fi

# Client Addition Loop
while true; do
    add_client
    read -p "Do you want to add another client? (yes/no): " add_another
    case $add_another in
        [Yy]* ) continue;;
        [Nn]* ) break;;
        * ) echo "Please answer yes or no.";;
    esac
done

# Step 6: Start and Enable WireGuard
echo "Starting and enabling WireGuard service..."
sudo systemctl start wg-quick@wg0
sudo systemctl enable wg-quick@wg0

echo "WireGuard server and client setup complete."
