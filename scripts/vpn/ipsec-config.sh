#!/bin/bash

################################################################################
# Ymmo Project - IPSec VPN Configuration Script
# Purpose: Setup IPSec tunnels between HQ (10.0.0.0/24) and 12 branch offices
# Protocol: IKEv2 with AES-256 encryption
# Author: Titouan (Lead INFRA)
# Tested on: Ubuntu 22.04 LTS, Strongswan
################################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# Parameters
MODE="${1:-hub}"  # hub or spoke
SUBNET="${2:-10.0.0.0/16}"
CONFIG_DIR="/etc/ipsec.d"
CERTS_DIR="/etc/ipsec.d/certs"
PRIVATE_DIR="/etc/ipsec.d/private"

################################################################################
# Install Strongswan & Dependencies
################################################################################

install_packages() {
    log_info "Installing Strongswan and IPSec tools..."

    apt-get update
    apt-get install -y --no-install-recommends \
        strongswan \
        strongswan-pki \
        libstrongswan-extra-plugins \
        libstrongswan-standard-plugins \
        iptables \
        curl \
        net-tools \
        iproute2

    log_success "Packages installed"
}

################################################################################
# Certificate Generation (for test environment)
################################################################################

generate_certificates() {
    log_info "Generating self-signed certificates for IPSec..."

    mkdir -p "$CERTS_DIR" "$PRIVATE_DIR"

    # Create CA private key
    if [ ! -f "$PRIVATE_DIR/ca-key.pem" ]; then
        ipsec pki --gen --type rsa --size 2048 --outform pem \
            > "$PRIVATE_DIR/ca-key.pem"
    fi

    # Create CA certificate
    if [ ! -f "$CERTS_DIR/ca-cert.pem" ]; then
        ipsec pki --self --in "$PRIVATE_DIR/ca-key.pem" --type pkcs1 \
            --dn "CN=Ymmo CA" --ca --lifetime 3650 --outform pem \
            > "$CERTS_DIR/ca-cert.pem"
    fi

    # Create server certificate (HQ/Gateway)
    if [ ! -f "$PRIVATE_DIR/server-key.pem" ]; then
        ipsec pki --gen --type rsa --size 2048 --outform pem \
            > "$PRIVATE_DIR/server-key.pem"

        ipsec pki --pub --in "$PRIVATE_DIR/server-key.pem" --type pkcs1 | \
            ipsec pki --issue --lifetime 1825 \
                --cacert "$CERTS_DIR/ca-cert.pem" \
                --cakey "$PRIVATE_DIR/ca-key.pem" \
                --dn "CN=ymmo-hq.local" \
                --san ymmo-hq.local \
                --flag serverAuth --outform pem \
            > "$CERTS_DIR/server-cert.pem"
    fi

    chmod 600 "$PRIVATE_DIR"/*.pem
    log_success "Certificates generated in $CERTS_DIR"
}

################################################################################
# Configure IPSec for HUB mode (Siège/HQ)
################################################################################

configure_hub() {
    log_info "Configuring IPSec HUB mode (Siège)..."

    cat > /etc/ipsec.conf <<'EOF'
config setup
    charondebug="all"
    uniqueids=yes
    strictcrlpolicy=no

conn %default
    type=tunnel
    dpdaction=clear
    dpddelay=900s
    dpdtimeout=30s
    keyinactivity=600s
    keylife=3600s
    rekey=yes
    left=%any
    leftauth=psk
    leftsubnet=10.0.0.0/24
    leftid="ymmo-hq.local"
    rightauth=psk

# HUB configuration: all branches connect to HQ
# Branches will use pre-shared keys for auth

# Example: Branch 1 (Agence 1 - 10.0.1.0/24)
conn branch-1
    right=203.0.113.10
    rightsubnet=10.0.1.0/24
    rightid="agence-1.local"
    auto=add
    ike=aes256-sha256-modp2048!
    esp=aes256-sha256-modp2048!

# Repeat for branches 2-12 (modify IPs and subnet accordingly)
# conn branch-2
#     right=203.0.113.11
#     rightsubnet=10.0.2.0/24
#     rightid="agence-2.local"
#     auto=add

conn rw
    type=tunnel
    leftid="ymmo-hq.local"
    rightauth=psk
    auto=add
    ike=aes256-sha256-modp2048!
    esp=aes256-sha256-modp2048!
EOF

    log_success "HUB configuration applied"
}

################################################################################
# Configure IPSec for SPOKE mode (Branch offices)
################################################################################

configure_spoke() {
    log_info "Configuring IPSec SPOKE mode (Agence)..."

    local BRANCH_NUM="${1:-1}"
    local BRANCH_SUBNET="10.0.${BRANCH_NUM}.0/24"
    local HQ_PUBLIC_IP="${2:-203.0.113.1}"

    cat > /etc/ipsec.conf <<EOF
config setup
    charondebug="all"
    uniqueids=yes
    strictcrlpolicy=no

conn %default
    type=tunnel
    dpdaction=clear
    dpddelay=900s
    dpdtimeout=30s
    keyinactivity=600s
    keylife=3600s
    rekey=yes
    left=%any
    leftauth=psk
    leftsubnet=$BRANCH_SUBNET
    leftid="agence-${BRANCH_NUM}.local"
    rightauth=psk
    right=$HQ_PUBLIC_IP
    rightsubnet=10.0.0.0/24
    rightid="ymmo-hq.local"
    auto=start
    ike=aes256-sha256-modp2048!
    esp=aes256-sha256-modp2048!

conn site-to-site
    type=tunnel
    left=%any
    leftauth=psk
    leftsubnet=$BRANCH_SUBNET
    right=$HQ_PUBLIC_IP
    rightauth=psk
    rightsubnet=10.0.0.0/24
    auto=add
    ike=aes256-sha256-modp2048!
    esp=aes256-sha256-modp2048!
EOF

    log_success "SPOKE configuration applied for Agence $BRANCH_NUM"
}

################################################################################
# Setup Pre-Shared Keys (PSK)
################################################################################

setup_psk() {
    log_info "Setting up pre-shared keys..."

    cat > /etc/ipsec.secrets <<'EOF'
# Format: local-id remote-id : PSK "secret"
# For production, use strong random PSK

ymmo-hq.local agence-1.local : PSK "YmmoSecure@2024Branch1!"
ymmo-hq.local agence-2.local : PSK "YmmoSecure@2024Branch2!"
ymmo-hq.local agence-3.local : PSK "YmmoSecure@2024Branch3!"
ymmo-hq.local agence-4.local : PSK "YmmoSecure@2024Branch4!"
ymmo-hq.local agence-5.local : PSK "YmmoSecure@2024Branch5!"
ymmo-hq.local agence-6.local : PSK "YmmoSecure@2024Branch6!"
ymmo-hq.local agence-7.local : PSK "YmmoSecure@2024Branch7!"
ymmo-hq.local agence-8.local : PSK "YmmoSecure@2024Branch8!"
ymmo-hq.local agence-9.local : PSK "YmmoSecure@2024Branch9!"
ymmo-hq.local agence-10.local : PSK "YmmoSecure@2024Branch10!"
ymmo-hq.local agence-11.local : PSK "YmmoSecure@2024Branch11!"
ymmo-hq.local agence-12.local : PSK "YmmoSecure@2024Branch12!"

# Include RSA keys for certificate-based auth (optional)
# include /etc/ipsec.secrets.rsa
EOF

    chmod 600 /etc/ipsec.secrets
    log_success "PSK configured"
}

################################################################################
# Enable IP Forwarding & Firewall Rules
################################################################################

configure_firewall() {
    log_info "Configuring firewall and IP forwarding..."

    # Enable IP forwarding
    echo 1 > /proc/sys/net/ipv4/ip_forward
    echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
    sysctl -p > /dev/null

    # Allow IPSec traffic
    iptables -A INPUT -p esp -j ACCEPT
    iptables -A INPUT -p udp --dport 500 -j ACCEPT
    iptables -A INPUT -p udp --dport 4500 -j ACCEPT
    iptables -A FORWARD -m policy --pol ipsec --dir in -j ACCEPT
    iptables -A FORWARD -m policy --pol ipsec --dir out -j ACCEPT

    # Save rules
    if command -v iptables-save &> /dev/null; then
        iptables-save > /etc/iptables/rules.v4
    fi

    log_success "Firewall configured"
}

################################################################################
# Test Connectivity
################################################################################

test_connectivity() {
    log_info "Testing IPSec tunnel connectivity..."

    # Check if Strongswan is running
    systemctl status strongswan || systemctl restart strongswan

    # List active tunnels
    ipsec status

    # Wait for tunnel negotiation
    sleep 5

    log_success "Tunnel status: use 'ipsec status' to verify"
}

################################################################################
# Main Execution
################################################################################

main() {
    log_info "========================================="
    log_info "Ymmo IPSec VPN Configuration"
    log_info "Mode: $MODE"
    log_info "========================================="

    install_packages
    generate_certificates
    setup_psk
    configure_firewall

    if [ "$MODE" = "hub" ]; then
        configure_hub
    elif [ "$MODE" = "spoke" ]; then
        BRANCH_NUM="${2:-1}"
        HQ_IP="${3:-203.0.113.1}"
        configure_spoke "$BRANCH_NUM" "$HQ_IP"
    else
        log_error "Invalid mode. Use 'hub' or 'spoke'"
    fi

    # Start Strongswan
    systemctl enable strongswan
    systemctl restart strongswan

    test_connectivity

    log_success "IPSec configuration complete!"
    log_info "Verify tunnels with: ipsec status"
}

main "$@"
