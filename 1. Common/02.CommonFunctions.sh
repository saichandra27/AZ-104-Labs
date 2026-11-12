#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$script_dir/01.Variables.sh"

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

createNetworkSecurityGroup() {
    local nsgName=$1
    local location=$2

    if az network nsg show \
        --resource-group "$RESOURCE_GROUP" \
        --name "$nsgName" >/dev/null 2>&1; then
        echo "Network Security Group '$nsgName' already exists. Skipping."
        return 0
    fi

    az network nsg create \
        --resource-group "$RESOURCE_GROUP" \
        --name "$nsgName" \
        --location "$location"
}

createApplicationSecurityGroup() {
    local asgName=$1
    local location=$2

    if az network asg show \
        --resource-group "$RESOURCE_GROUP" \
        --name "$asgName" >/dev/null 2>&1; then
        echo "Application Security Group '$asgName' already exists. Skipping."
        return 0
    fi

    az network asg create \
        --resource-group "$RESOURCE_GROUP" \
        --name "$asgName" \
        --location "$location"
}

createNetworkSecurityRule() {
    local nsgName=$1
    local ruleName=$2
    local priority=$3
    local direction=$4
    local access=$5
    local protocol=$6
    local sourceAddressPrefix=$7
    local sourcePortRange=$8
    local destinationAddressPrefix=$9
    local destinationPortRange=${10}

    if az network nsg rule show \
        --resource-group "$RESOURCE_GROUP" \
        --nsg-name "$nsgName" \
        --name "$ruleName" >/dev/null 2>&1; then
        echo "Network Security Rule '$ruleName' already exists in NSG '$nsgName'. Skipping."
        return 0
    fi

    az network nsg rule create \
        --resource-group "$RESOURCE_GROUP" \
        --nsg-name "$nsgName" \
        --name "$ruleName" \
        --priority "$priority" \
        --direction "$direction" \
        --access "$access" \
        --protocol "$protocol" \
        --source-address-prefixes "$sourceAddressPrefix" \
        --source-port-ranges "$sourcePortRange" \
        --destination-address-prefixes "$destinationAddressPrefix" \
        --destination-port-ranges "$destinationPortRange"
}

updateSubnetWithNSG() {
    local vnetName=$1
    local subnetName=$2
    local nsgName=$3

    az network vnet subnet update \
        --resource-group "$RESOURCE_GROUP" \
        --vnet-name "$vnetName" \
        --name "$subnetName" \
        --network-security-group "$nsgName"
}