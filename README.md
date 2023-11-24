WireGuard Setup Script for Raspberry Pi
Overview

This repository contains a script for setting up a WireGuard VPN server on a Raspberry Pi. It simplifies the process of installing WireGuard, configuring the server, and adding VPN clients. Additionally, it provides an option for setting up DuckDNS for dynamic DNS management.
Features

    Automated WireGuard installation
    Server configuration setup
    Client configuration with QR code generation
    Optional DuckDNS setup for dynamic IPs
    Support for adding multiple clients

Prerequisites

    A Raspberry Pi with Debian-based OS
    Internet connection
    Basic understanding of networking and VPN concepts

Installation

    Clone the repository:

    bash

git clone https://github.com/Brownster/wireguard_duckdns_install_script

Navigate to the repository directory:

bash

    cd /wireguard_duckdns_install_script

Usage

    Run the script:

    arduino

    sudo bash wireguard-setup.sh

    Follow the on-screen prompts to configure the WireGuard server and add clients.

Adding Clients

    The script allows the addition of multiple clients.
    For each client, a unique QR code is generated for easy setup.
    Scan the QR code with the WireGuard app on your client device.

DuckDNS Setup

    If you have a dynamic public IP, the script can set up DuckDNS to update your IP address regularly.
    You will need a DuckDNS account and token.

Contributions

Contributions to this project are welcome. Please ensure that your pull requests are well-described and tested.
