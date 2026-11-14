#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=/dev/null
source "$script_dir/variables.sh"

# Function to create public IP address
create_public_ip_address() {
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

# Function to create virtual network
create_vnet() {
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

# Function to create subnet
create_subnet() {
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

# Function to create virtual network peering
create_virtual_network_peering() {
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

# Function to create network security group
create_network_security_group() {
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

# Function to create application security group
create_application_security_group() {
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

# Function to create network security rule
create_network_security_rule() {
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

# Function to create route table
create_route_table() {
    local name=$1
    local disableBgpRoutePropagation=$2

    if az network route-table show \
        --resource-group "$RESOURCE_GROUP" \
        --name "$name" >/dev/null 2>&1; then
        echo "Route Table '$name' already exists. Skipping."
        return 0
    fi

    az network route-table create \
        --name "$name" \
        --resource-group "$RESOURCE_GROUP" \
        --disable-bgp-route-propagation "$disableBgpRoutePropagation"
}

# Function to create custom route
create_custom_route() {
    local name=$1
    local routeTableName=$2
    local addressPrefix=$3
    local nextHopType=$4
    local nextHopIpAddress=${5:-}

    if az network route-table route show \
        --resource-group "$RESOURCE_GROUP" \
        --route-table-name "$routeTableName" \
        --name "$name" >/dev/null 2>&1; then
        echo "Custom Route '$name' already exists in Route Table '$routeTableName'. Skipping."
        return 0
    fi

    az network route-table route create \
        --route-table-name "$routeTableName" \
        --resource-group "$RESOURCE_GROUP" \
        --name "$name" \
        --address-prefix "$addressPrefix" \
        --next-hop-type "$nextHopType" \
        ${nextHopIpAddress:+--next-hop-ip-address "$nextHopIpAddress"}
}