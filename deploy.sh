#!/bin/bash
# Aqua Core Solutions -- Water Treatment Facility Network Segmentation
# Recreates the full VNet/subnet/NSG architecture via Azure CLI.
set -e

RESOURCE_GROUP="rg-aquacore-water-ot"
LOCATION="eastus2"
VNET_NAME="vnet-aquacore-water-ot"
BASTION_SUBNET="subnet-bastion"
OT_SUBNET="subnet-ot-private"
BASTION_NSG="nsg-bastion"
OT_NSG="nsg-ot-private"

# Your admin IP must be set as an environment variable before running --
# never hardcode a real IP into this script.
# Usage: export ADMIN_IP="your.real.ip.address" && ./deploy.sh
if [ -z "$ADMIN_IP" ]; then
  echo "ERROR: ADMIN_IP environment variable is not set."
  echo "Run: export ADMIN_IP=\"your.real.ip.address\""
  exit 1
fi

echo "Creating resource group..."
az group create --name $RESOURCE_GROUP --location $LOCATION

echo "Creating virtual network..."
az network vnet create \
  --resource-group $RESOURCE_GROUP \
  --name $VNET_NAME \
  --address-prefix 10.0.0.0/16

echo "Creating bastion subnet..."
az network vnet subnet create \
  --resource-group $RESOURCE_GROUP \
  --vnet-name $VNET_NAME \
  --name $BASTION_SUBNET \
  --address-prefix 10.0.1.0/24

echo "Creating OT private subnet..."
az network vnet subnet create \
  --resource-group $RESOURCE_GROUP \
  --vnet-name $VNET_NAME \
  --name $OT_SUBNET \
  --address-prefix 10.0.2.0/24

echo "Creating bastion NSG (SSH from admin IP only -- replace with your real IP)..."
az network nsg create --resource-group $RESOURCE_GROUP --name $BASTION_NSG

az network nsg rule create \
  --resource-group $RESOURCE_GROUP \
  --nsg-name $BASTION_NSG \
  --name Allow-Admin-SSH \
  --priority 100 \
  --source-address-prefixes "$ADMIN_IP/32" \
  --destination-port-ranges 22 \
  --protocol Tcp \
  --access Allow

echo "Creating OT NSG (SSH from bastion subnet only)..."
az network nsg create --resource-group $RESOURCE_GROUP --name $OT_NSG

az network nsg rule create \
  --resource-group $RESOURCE_GROUP \
  --nsg-name $OT_NSG \
  --name Allow-Bastion-Host \
  --priority 100 \
  --source-address-prefixes 10.0.1.0/24 \
  --destination-port-ranges 22 \
  --protocol Tcp \
  --access Allow

echo "Waiting for NSGs to fully propagate..."
sleep 15

echo "Attaching NSGs to their subnets..."
az network vnet subnet update \
  --resource-group $RESOURCE_GROUP \
  --vnet-name $VNET_NAME \
  --name $BASTION_SUBNET \
  --network-security-group $BASTION_NSG

az network vnet subnet update \
  --resource-group $RESOURCE_GROUP \
  --vnet-name $VNET_NAME \
  --name $OT_SUBNET \
  --network-security-group $OT_NSG

echo "Creating bastion VM (public IP, SSH-only)..."
az vm create \
  --resource-group $RESOURCE_GROUP \
  --name vm-it-monitor-bastion \
  --vnet-name $VNET_NAME \
  --subnet $BASTION_SUBNET \
  --size Standard_D2als_v7 \
  --image Ubuntu2204 \
  --admin-username azureuser \
  --generate-ssh-keys \
  --public-ip-sku Standard

echo "Creating OT control VM (no public IP)..."
az vm create \
  --resource-group $RESOURCE_GROUP \
  --name vm-ot-control \
  --vnet-name $VNET_NAME \
  --subnet $OT_SUBNET \
  --size Standard_D2als_v7 \
  --image Ubuntu2204 \
  --admin-username azureuser \
  --generate-ssh-keys \
  --public-ip-address ""

echo "Deployment complete."
