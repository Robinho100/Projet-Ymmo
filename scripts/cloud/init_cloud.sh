#!/bin/bash

################################################################################
# Ymmo Project - Azure Cloud Initialization Script
# Purpose: Automated setup of Azure infrastructure for Ymmo HQ + Branch network
# Author: Titouan (Lead INFRA)
# Tested on: Ubuntu 22.04 LTS
################################################################################

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'  # No Color

# Default parameters
RESOURCE_GROUP="ymmo-infra"
LOCATION="francecentral"
VM_SIZE="Standard_B4ms"
IMAGE="MicrosoftWindowsServer:WindowsServer:2022-Datacenter:latest"
ADMIN_USER="ymmo_admin"
VNET_NAME="ymmo-vnet"
VNET_PREFIX="10.0.0.0/16"
SUBNET_SIEGE="10.0.0.0/24"
SUBNET_NAME="siege-subnet"
NSG_NAME="ymmo-nsg"

################################################################################
# Helper Functions
################################################################################

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

check_prerequisites() {
    log_info "Checking prerequisites..."

    # Check Azure CLI
    if ! command -v az &> /dev/null; then
        log_error "Azure CLI not found. Install it: https://docs.microsoft.com/cli/azure/install-azure-cli"
    fi

    # Check if logged in to Azure
    if ! az account show &> /dev/null; then
        log_error "Not logged into Azure. Run: az login"
    fi

    log_success "Prerequisites OK"
}

create_resource_group() {
    log_info "Creating Resource Group: $RESOURCE_GROUP (Location: $LOCATION)"

    if az group exists --name "$RESOURCE_GROUP" -o json | grep -q true; then
        log_warning "Resource Group already exists, skipping creation"
    else
        az group create \
            --name "$RESOURCE_GROUP" \
            --location "$LOCATION" \
            --tags project=ymmo environment=production
        log_success "Resource Group created"
    fi
}

create_network() {
    log_info "Setting up Virtual Network: $VNET_NAME"

    # Create Virtual Network
    if az network vnet show -g "$RESOURCE_GROUP" -n "$VNET_NAME" &> /dev/null; then
        log_warning "VNet already exists, skipping creation"
    else
        az network vnet create \
            --name "$VNET_NAME" \
            --resource-group "$RESOURCE_GROUP" \
            --address-prefix "$VNET_PREFIX" \
            --subnet-name "$SUBNET_NAME" \
            --subnet-prefix "$SUBNET_SIEGE"
        log_success "VNet created with subnet"
    fi

    # Create Network Security Group
    if az network nsg show -g "$RESOURCE_GROUP" -n "$NSG_NAME" &> /dev/null; then
        log_warning "NSG already exists, skipping creation"
    else
        az network nsg create \
            --resource-group "$RESOURCE_GROUP" \
            --name "$NSG_NAME"

        # Allow RDP (3389) for admin
        az network nsg rule create \
            --resource-group "$RESOURCE_GROUP" \
            --nsg-name "$NSG_NAME" \
            --name AllowRDP \
            --priority 100 \
            --direction Inbound \
            --access Allow \
            --protocol Tcp \
            --source-address-prefixes '*' \
            --destination-address-prefixes '*' \
            --destination-port-ranges 3389

        # Allow WinRM (5985/5986) for automation
        az network nsg rule create \
            --resource-group "$RESOURCE_GROUP" \
            --nsg-name "$NSG_NAME" \
            --name AllowWinRM \
            --priority 110 \
            --direction Inbound \
            --access Allow \
            --protocol Tcp \
            --source-address-prefixes '*' \
            --destination-address-prefixes '*' \
            --destination-port-ranges 5985 5986

        # Allow HTTP/HTTPS
        az network nsg rule create \
            --resource-group "$RESOURCE_GROUP" \
            --nsg-name "$NSG_NAME" \
            --name AllowHTTP \
            --priority 120 \
            --direction Inbound \
            --access Allow \
            --protocol Tcp \
            --source-address-prefixes '*' \
            --destination-address-prefixes '*' \
            --destination-port-ranges 80 443

        # Allow VPN (500, 4500 for IPSec)
        az network nsg rule create \
            --resource-group "$RESOURCE_GROUP" \
            --nsg-name "$NSG_NAME" \
            --name AllowVPN \
            --priority 130 \
            --direction Inbound \
            --access Allow \
            --protocol Udp \
            --source-address-prefixes '*' \
            --destination-address-prefixes '*' \
            --destination-port-ranges 500 4500

        log_success "NSG created with security rules"
    fi
}

create_vm() {
    local VM_NAME="$1"
    local VM_IP="$2"

    log_info "Creating VM: $VM_NAME (IP: $VM_IP)"

    if az vm show -g "$RESOURCE_GROUP" -n "$VM_NAME" &> /dev/null; then
        log_warning "VM $VM_NAME already exists, skipping creation"
        return
    fi

    # Create NIC with static IP
    NIC_NAME="${VM_NAME}-nic"
    az network nic create \
        --resource-group "$RESOURCE_GROUP" \
        --name "$NIC_NAME" \
        --vnet-name "$VNET_NAME" \
        --subnet "$SUBNET_NAME" \
        --network-security-group "$NSG_NAME" \
        --private-ip-address "$VM_IP"

    # Create VM
    az vm create \
        --resource-group "$RESOURCE_GROUP" \
        --name "$VM_NAME" \
        --nics "$NIC_NAME" \
        --image "$IMAGE" \
        --size "$VM_SIZE" \
        --admin-username "$ADMIN_USER" \
        --generate-ssh-keys \
        --os-disk-size-gb 128 \
        --os-disk-caching ReadWrite \
        --storage-sku Standard_LRS \
        --tags role=server project=ymmo

    log_success "VM $VM_NAME created"
}

install_vm_extensions() {
    local VM_NAME="$1"

    log_info "Installing extensions on $VM_NAME..."

    # Enable WinRM for remote management
    az vm run-command invoke \
        -g "$RESOURCE_GROUP" \
        -n "$VM_NAME" \
        --command-id RunPowerShellScript \
        --scripts @- <<'EOF'
# Enable WinRM
Enable-PSRemoting -Force
Set-Item WSMan:\localhost\Config\MaxEnvelopeSizeKb -Value 4096 -Force

# Install Docker Desktop (or Docker EE)
# For production, prefer Docker EE + Kubernetes
choco install docker-desktop -y --no-progress
EOF

    log_success "Extensions installed"
}

generate_config() {
    log_info "Generating configuration files..."

    # Create deployment config
    cat > ./deployment-config.json <<EOF
{
  "deployment": {
    "timestamp": "$(date -u +'%Y-%m-%dT%H:%M:%SZ')",
    "version": "1.0.0",
    "azure": {
      "subscription": "$(az account show -q --query id -o tsv)",
      "resourceGroup": "$RESOURCE_GROUP",
      "location": "$LOCATION",
      "vnet": "$VNET_NAME",
      "vnetPrefix": "$VNET_PREFIX"
    },
    "vms": {
      "hq": {
        "name": "ymmo-hq-vm",
        "role": "Active Directory + Web + DB",
        "ip": "10.0.0.1",
        "size": "$VM_SIZE"
      },
      "fw": {
        "name": "ymmo-fw-vm",
        "role": "Firewall + VPN Gateway",
        "ip": "10.0.0.254",
        "size": "$VM_SIZE"
      }
    },
    "network": {
      "vpnProtocol": "IPSec IKEv2",
      "encryption": "AES-256",
      "tunnelTarget": "10.0.0.0/16"
    }
  }
}
EOF

    log_success "Configuration saved to deployment-config.json"
}

show_summary() {
    log_info "========================================="
    log_info "Ymmo Azure Deployment Summary"
    log_info "========================================="
    echo "Resource Group    : $RESOURCE_GROUP"
    echo "Location          : $LOCATION"
    echo "VNet Prefix       : $VNET_PREFIX"
    echo "Subnet (Siège)    : $SUBNET_SIEGE"
    echo "Admin User        : $ADMIN_USER"
    echo ""
    echo "Next steps:"
    echo "1. Configure Active Directory on ymmo-hq-vm (10.0.0.1)"
    echo "2. Setup VPN tunnels on ymmo-fw-vm (10.0.0.254)"
    echo "3. Run: ./scripts/ad/create-groups.ps1"
    echo "4. Run: ./scripts/vpn/ipsec-config.sh --mode hub"
    echo ""
    log_info "========================================="
}

################################################################################
# Main Execution
################################################################################

main() {
    log_info "Starting Ymmo Azure Infrastructure Setup"
    log_info "Time: $(date)"

    # Run setup phases
    check_prerequisites
    create_resource_group
    create_network

    # Create HQ + Firewall VMs
    create_vm "ymmo-hq-vm" "10.0.0.1"
    create_vm "ymmo-fw-vm" "10.0.0.254"

    # Install extensions
    install_vm_extensions "ymmo-hq-vm"
    install_vm_extensions "ymmo-fw-vm"

    # Generate config
    generate_config

    # Show summary
    show_summary

    log_success "Azure infrastructure ready! Check RDP/WinRM accessibility."
}

# Run main function
main "$@"
