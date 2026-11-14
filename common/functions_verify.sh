#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=/dev/null
source "$script_dir/variables.sh"

# Function to verify VNet successfully created or already exists
verify_vnet_created_successfully() {
    local vnetName=$1

    if az network vnet show \
        --resource-group "$RESOURCE_GROUP" \
        --name "$vnetName" >/dev/null 2>&1; then
        echo "VNet '$vnetName' created successfully."
        return 0
    fi

    echo "VNet '$vnetName' verification failed."
    return 1
}

# Function to verify subnet successfully created or already exists
verify_subnet_created_successfully() {
    local vnetName=$1
    local subnetName=$2

    if az network vnet subnet show \
        --resource-group "$RESOURCE_GROUP" \
        --vnet-name "$vnetName" \
        --name "$subnetName" >/dev/null 2>&1; then
        echo "Subnet '$subnetName' in VNet '$vnetName' created successfully."
        return 0
    fi

    echo "Subnet '$subnetName' verification failed."
    return 1
}

# Function to verify virtual network peering exists
verify_vnet_peering_created_successfully() {
    local vnetName=$1
    local peeringName=$2

    if az network vnet peering show \
        --resource-group "$RESOURCE_GROUP" \
        --vnet-name "$vnetName" \
        --name "$peeringName" >/dev/null 2>&1; then
        echo "VNet Peering '$peeringName' in VNet '$vnetName' created successfully."
        return 0
    fi

    echo "VNet Peering '$peeringName' verification failed."
    return 1
}

# Function to verify network security group successfully created or already exists
verify_nsg_created_successfully() {
    local nsgName=$1

    if az network nsg show \
        --resource-group "$RESOURCE_GROUP" \
        --name "$nsgName" >/dev/null 2>&1; then
        echo "Network Security Group '$nsgName' created successfully."
        return 0
    fi

    echo "Network Security Group '$nsgName' verification failed."
    return 1
}

# Function to verify application security group successfully created or already exists
verify_asg_created_successfully() {
    local asgName=$1

    if az network asg show \
        --resource-group "$RESOURCE_GROUP" \
        --name "$asgName" >/dev/null 2>&1; then
        echo "Application Security Group '$asgName' created successfully."
        return 0
    fi

    echo "Application Security Group '$asgName' verification failed."
    return 1
}

# Function to verify network security rule successfully created or already exists
verify_nsg_rule_created_successfully() {
    local nsgName=$1
    local ruleName=$2

    if az network nsg rule show \
        --resource-group "$RESOURCE_GROUP" \
        --nsg-name "$nsgName" \
        --name "$ruleName" >/dev/null 2>&1; then
        echo "Network Security Rule '$ruleName' in NSG '$nsgName' created successfully."
        return 0
    fi

    echo "Network Security Rule '$ruleName' verification failed."
    return 1
}

# Function to verify custom route table
verify_custom_route_table() {
    local name=$1

    if az network route-table show \
        --resource-group "$RESOURCE_GROUP" \
        --name "$name" >/dev/null 2>&1; then
        echo "Route Table '$name' verified successfully."
        return 0
    fi

    echo "Route Table '$name' verification failed."
    return 1
}

# Function to verify custom route
verify_custom_route() {
    local routeTableName=$1
    local routeName=$2
    local addressPrefix=$3
    local nextHopType=$4
    local nextHopIpAddress=$5

    local routeDetails

    if ! routeDetails=$(az network route-table route show \
        --resource-group "$RESOURCE_GROUP" \
        --route-table-name "$routeTableName" \
        --name "$routeName" \
        --query "[addressPrefix,nextHopType,nextHopIpAddress]" \
        --output tsv 2>/dev/null); then

        echo "Custom Route '$routeName' verification failed: route not found."
        return 1
    fi

    local expectedDetails

    expectedDetails=$(printf '%s\t%s\t%s' \
        "$addressPrefix" \
        "$nextHopType" \
        "$nextHopIpAddress")

    if [[ "$routeDetails" == "$expectedDetails" ]]; then
        echo "Custom Route '$routeName' verified successfully."
        return 0
    fi

    echo "Custom Route '$routeName' verification failed."
    echo "Expected: $addressPrefix $nextHopType $nextHopIpAddress"
    echo "Actual: $routeDetails"
    return 1
}

# Function to verify subnet successfully associated with route table
verify_subnet_with_route_table() {
    local vnetName=$1
    local subnetName=$2
    local routeTableName=$3

    local associatedRouteTable

    if ! associatedRouteTable=$(az network vnet subnet show \
        --resource-group "$RESOURCE_GROUP" \
        --vnet-name "$vnetName" \
        --name "$subnetName" \
        --query "routeTable.id" \
        --output tsv 2>/dev/null); then

        echo "Unable to retrieve subnet '$subnetName'."
        return 1
    fi

    if [[ "$associatedRouteTable" == *"/routeTables/$routeTableName" ]]; then
        echo "Route Table '$routeTableName' successfully associated with Subnet '$subnetName' in VNet '$vnetName'."
        return 0
    fi

    echo "Route Table '$routeTableName' is not associated with Subnet '$subnetName'."
    return 1
}