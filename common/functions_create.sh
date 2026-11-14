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

# Function to create or reconcile virtual network
create_vnet() {
    local name=$1
    local location=$2
    local addressPrefix=$3
    local subnetName=$4
    local subnetPrefix=$5

    if ! az network vnet show \
        --resource-group "$RESOURCE_GROUP" \
        --name "$name" >/dev/null 2>&1; then

        echo "Creating VNet '$name'..."

        az network vnet create \
            --resource-group "$RESOURCE_GROUP" \
            --name "$name" \
            --location "$location" \
            --address-prefixes "$addressPrefix" \
            --subnet-name "$subnetName" \
            --subnet-prefixes "$subnetPrefix"

        return 0
    fi

    echo "VNet '$name' already exists. Checking configuration..."

    # Check and reconcile VNet address space
    local existingPrefixes

    existingPrefixes=$(az network vnet show \
        --resource-group "$RESOURCE_GROUP" \
        --name "$name" \
        --query "addressSpace.addressPrefixes" \
        --output tsv)

    if [[ "$existingPrefixes" != "$addressPrefix" ]]; then
        echo "Updating VNet '$name' address space..."

        az network vnet update \
            --resource-group "$RESOURCE_GROUP" \
            --name "$name" \
            --address-prefixes "$addressPrefix"
    else
        echo "VNet '$name' address space is correct."
    fi

    # Ensure the initial subnet exists and has the expected prefix
    create_subnet "$name" "$subnetName" "$subnetPrefix"
}

# Function to create or reconcile subnet
create_subnet() {
    local vnetName=$1
    local subnetName=$2
    local addressPrefix=$3

    if ! az network vnet subnet show \
        --resource-group "$RESOURCE_GROUP" \
        --vnet-name "$vnetName" \
        --name "$subnetName" >/dev/null 2>&1; then

        echo "Creating Subnet '$subnetName' in VNet '$vnetName'..."

        az network vnet subnet create \
            --resource-group "$RESOURCE_GROUP" \
            --vnet-name "$vnetName" \
            --name "$subnetName" \
            --address-prefixes "$addressPrefix"

        return 0
    fi

    echo "Subnet '$subnetName' already exists. Checking configuration..."

    local existingPrefix

    existingPrefix=$(az network vnet subnet show \
        --resource-group "$RESOURCE_GROUP" \
        --vnet-name "$vnetName" \
        --name "$subnetName" \
        --query "addressPrefix" \
        --output tsv)

    if [[ "$existingPrefix" != "$addressPrefix" ]]; then
        echo "Updating Subnet '$subnetName' address prefix..."

        az network vnet subnet update \
            --resource-group "$RESOURCE_GROUP" \
            --vnet-name "$vnetName" \
            --name "$subnetName" \
            --address-prefixes "$addressPrefix"
    else
        echo "Subnet '$subnetName' configuration is correct. Skipping."
    fi
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

# Function to create or reconcile route table
create_route_table() {
    local name=$1
    local disableBgpRoutePropagation=$2

    if ! az network route-table show \
        --resource-group "$RESOURCE_GROUP" \
        --name "$name" >/dev/null 2>&1; then

        echo "Creating Route Table '$name'..."

        az network route-table create \
            --name "$name" \
            --resource-group "$RESOURCE_GROUP" \
            --disable-bgp-route-propagation "$disableBgpRoutePropagation"

        return 0
    fi

    echo "Route Table '$name' already exists. Checking configuration..."

    local existingSetting

    existingSetting=$(az network route-table show \
        --resource-group "$RESOURCE_GROUP" \
        --name "$name" \
        --query "disableBgpRoutePropagation" \
        --output tsv)

    if [[ "$existingSetting" != "$disableBgpRoutePropagation" ]]; then
        echo "Updating Route Table '$name' BGP propagation setting..."

        az network route-table update \
            --resource-group "$RESOURCE_GROUP" \
            --name "$name" \
            --disable-bgp-route-propagation "$disableBgpRoutePropagation"
    else
        echo "Route Table '$name' configuration is correct. Skipping."
    fi
}

# Function to create or reconcile custom route
create_custom_route() {
    local name=$1
    local routeTableName=$2
    local addressPrefix=$3
    local nextHopType=$4
    local nextHopIpAddress=${5:-}

    local args=(
        az network route-table route create
        --route-table-name "$routeTableName"
        --resource-group "$RESOURCE_GROUP"
        --name "$name"
        --address-prefix "$addressPrefix"
        --next-hop-type "$nextHopType"
    )

    if [[ -n "$nextHopIpAddress" ]]; then
        args+=(--next-hop-ip-address "$nextHopIpAddress")
    fi

    if ! az network route-table route show \
        --resource-group "$RESOURCE_GROUP" \
        --route-table-name "$routeTableName" \
        --name "$name" >/dev/null 2>&1; then

        echo "Creating Custom Route '$name'..."

        "${args[@]}"
        return 0
    fi

    echo "Custom Route '$name' already exists. Checking configuration..."

    local existingDetails

    existingDetails=$(az network route-table route show \
        --resource-group "$RESOURCE_GROUP" \
        --route-table-name "$routeTableName" \
        --name "$name" \
        --query "[addressPrefix,nextHopType,nextHopIpAddress]" \
        --output tsv)

    local expectedDetails

    expectedDetails=$(printf '%s\t%s\t%s' \
        "$addressPrefix" \
        "$nextHopType" \
        "$nextHopIpAddress")

    if [[ "$existingDetails" != "$expectedDetails" ]]; then
        echo "Updating Custom Route '$name'..."

        local updateArgs=(
            az network route-table route update
            --resource-group "$RESOURCE_GROUP"
            --route-table-name "$routeTableName"
            --name "$name"
            --address-prefix "$addressPrefix"
            --next-hop-type "$nextHopType"
        )

        if [[ -n "$nextHopIpAddress" ]]; then
            updateArgs+=(--next-hop-ip-address "$nextHopIpAddress")
        fi

        "${updateArgs[@]}"
    else
        echo "Custom Route '$name' configuration is correct. Skipping."
    fi
}