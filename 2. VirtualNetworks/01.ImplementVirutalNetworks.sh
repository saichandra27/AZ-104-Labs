#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$script_dir/../1. Common/02.CommonFunctions.sh"

createVirtualNetworks() {
    az group create \
        --name "$RESOURCE_GROUP" \
        --location "$LOCATION"

    createVnet "$APP_VNET" "$LOCATION" "$APP_VNET_PREFIX" "$FRONTEND_SUBNET" "$FRONTEND_PREFIX"
    createSubNet "$APP_VNET" "$BACKEND_SUBNET" "$BACKEND_PREFIX"

    createVnet "$HUB_VNET" "$LOCATION" "$HUB_VNET_PREFIX" "$HUB_FIREWALL_SUBNET" "$HUB_FIREWALL_PREFIX"

    createVirtualNetworkPeering "$APP_VNET" "$HUB_VNET" "app-to-hub"
    createVirtualNetworkPeering "$HUB_VNET" "$APP_VNET" "hub-to-app"
}

createVirtualNetworks