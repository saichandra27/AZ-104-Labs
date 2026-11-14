#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=/dev/null
source "$script_dir/variables.sh"

# Function to update subnet with network security group
update_subnet_with_nsg() {
    local vnetName=$1
    local subnetName=$2
    local nsgName=$3

    az network vnet subnet update \
        --resource-group "$RESOURCE_GROUP" \
        --vnet-name "$vnetName" \
        --name "$subnetName" \
        --network-security-group "$nsgName"
}

# Function to update subnet with route table
update_subnet_with_route_table() {
    local vnetName=$1
    local subnetName=$2
    local routeTableName=$3

    az network vnet subnet update \
        --resource-group "$RESOURCE_GROUP" \
        --vnet-name "$vnetName" \
        --name "$subnetName" \
        --route-table "$routeTableName"
}

#Function to enable the IP forwarding for network interface card
update_subnet_with_ip_forwarding() {
    local nicname=$1
    local ipForwarding=$2
    az network nic update \
        --name "$nicname" \
        --resource-group "$RESOURCE_GROUP" \
        --ip-forwarding "$ipForwarding"
}
