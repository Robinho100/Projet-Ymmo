#!/bin/bash

################################################################################
# Ymmo Project - Azure Cloud Infrastructure Provisioning
# Purpose: Automated setup of Azure resources (VMs, VNet, NSG)
# Author: Titouan (Lead INFRA)
################################################################################

set -e

# Color codes
BLUE='\033[0;34m'
GREEN='\033[0;32m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }

RESOURCE_GROUP="ymmo-infra"
LOCATION="francecentral"

log_info "Starting Azure Provisioning..."

# Verification of Azure CLI
if ! command -v az &> /dev/null; then
    echo "Azure CLI missing."
    exit 1
fi

# Creation of Resource Group
az group create --name "$RESOURCE_GROUP" --location "$LOCATION" --tags project=ymmo

# Networking
az network vnet create --name "ymmo-vnet" --resource-group "$RESOURCE_GROUP" --address-prefix "10.0.0.0/16" --subnet-name "siege-subnet" --subnet-prefix "10.0.0.0/24"

# VMs creation (HQ & Firewall)
# HQ - Windows Server
az vm create --resource-group "$RESOURCE_GROUP" --name "ymmo-hq-vm" --image "Win2022Datacenter" --admin-username "ymmo_admin" --vnet-name "ymmo-vnet" --subnet "siege-subnet" --public-ip-address ""

# FW - Ubuntu (for VPN/Web)
az vm create --resource-group "$RESOURCE_GROUP" --name "ymmo-fw-vm" --image "Ubuntu2204" --admin-username "ymmo_admin" --vnet-name "ymmo-vnet" --subnet "siege-subnet"

log_success "Infrastructure provisioned successfully."
