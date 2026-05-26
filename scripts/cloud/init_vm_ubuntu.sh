#!/bin/bash
# ==============================================================================
# SCRIPT D'INITIALISATION VM UBUNTU - PROJET YMMO
# Auteur : Robin (Lead Archi)
# ==============================================================================

set -e

echo "🚀 INITIALISATION DE LA VM UBUNTU - PROJET YMMO"

sudo apt update && sudo apt upgrade -y
sudo apt install -y git curl wget docker.io docker-compose ufw

# Configuration Firewall
sudo ufw allow ssh
sudo ufw allow http
sudo ufw allow https
sudo ufw allow 51820/udp
echo "y" | sudo ufw enable

echo "✅ INITIALISATION TERMINÉE !"
