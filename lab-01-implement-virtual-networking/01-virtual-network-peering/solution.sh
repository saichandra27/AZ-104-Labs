#!/usr/bin/env bash
set -euo pipefail
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$script_dir/../1. Common/02.CommonFunctions.sh"

#function to create virtual networks and subnets
create_virtual_networks() {
    az group create \
        --name "$RESOURCE_GROUP" \
        --location "$LOCATION"
    #create APP_VNET and subnets
    create_vnet "$APP_VNET" "$LOCATION" "$APP_VNET_PREFIX" "$FRONTEND_SUBNET" "$FRONTEND_PREFIX"
    create_subnet "$APP_VNET" "$BACKEND_SUBNET" "$BACKEND_PREFIX"
    create_subnet "$APP_VNET" "$APP_FIREWALL_SUBNET" "$APP_FIREWALL_PREFIX"
    
    #create HUB_VNET and subnets
    create_vnet "$HUB_VNET" "$LOCATION" "$HUB_VNET_PREFIX" "$HUB_FIREWALL_SUBNET" "$HUB_FIREWALL_PREFIX"

    #create virtual network peering between APP_VNET and HUB_VNET   
    create_virtual_network_peering "$APP_VNET" "$HUB_VNET" "app-to-hub"
    create_virtual_network_peering "$HUB_VNET" "$APP_VNET" "hub-to-app"
}

#execute the function to create virtual networks and subnets
create_virtual_networks