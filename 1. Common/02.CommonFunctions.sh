#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$script_dir/01.Variables.sh"

createSubNet(){
    local vnetName=$1
    local subnetName=$2
    local addressPrefix=$3

    if az network vnet subnet show \
        --resource-group "$RESOURCE_GROUP" \
        --vnet-name "$vnetName" \
        --name "$subnetName" >/dev/null 2>&1; then
        echo "Subnet '$subnetName' in VNet '$vnetName' already exists. Skipping."
        return 0
    fi

    az network vnet subnet create \
        --resource-group "$RESOURCE_GROUP" \
        --vnet-name "$vnetName" \
        --name "$subnetName" \
        --address-prefixes "$addressPrefix"
}

createPublicIpAddress() {
    local name=$1
    local location=$2
    local sku=$3

    if az network public-ip show \
        --resource-group "$RESOURCE_GROUP" \
        --name "$name" >/dev/null 2>&1; then
        echo "Public IP '$name' already exists. Skipping."
        return 0
    fi

    az network public-ip create \
        --resource-group "$RESOURCE_GROUP" \
        --name "$name" \
        --location "$location" \
        --sku "$sku" \
        --allocation-method Static
}

createVnet() {
    local name=$1
    local location=$2
    local addressprefix=$3
    local subnetname=$4
    local subnetprefix=$5

    if az network vnet show \
        --resource-group "$RESOURCE_GROUP" \
        --name "$name" >/dev/null 2>&1; then
        echo "VNet '$name' already exists. Skipping VNet creation."
        return 0
    fi

    az network vnet create \
        --resource-group "$RESOURCE_GROUP" \
        --name "$name" \
        --location "$location" \
        --address-prefixes "$addressprefix" \
        --subnet-name "$subnetname" \
        --subnet-prefixes "$subnetprefix"
}

createVirtualNetworkPeering() {
    local vnetname=$1
    local remotevnetname=$2
    local peeringName=${3:-"${vnetname}-to-${remotevnetname}"}

    if az network vnet peering show \
        --resource-group "$RESOURCE_GROUP" \
        --vnet-name "$vnetname" \
        --name "$peeringName" >/dev/null 2>&1; then
        echo "Peering '$peeringName' already exists. Skipping."
        return 0
    fi

    az network vnet peering create \
        --resource-group "$RESOURCE_GROUP" \
        --name "$peeringName" \
        --vnet-name "$vnetname" \
        --remote-vnet "$remotevnetname" \
        --allow-vnet-access \
        --allow-forwarded-traffic
}

