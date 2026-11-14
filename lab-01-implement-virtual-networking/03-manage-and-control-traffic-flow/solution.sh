#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=/dev/null
source "$script_dir/variables.sh"

# shellcheck source=/dev/null
source "$script_dir/../common/functions_create.sh"

# shellcheck source=/dev/null
source "$script_dir/../common/functions_update.sh"

# Function to implement custom routes
deploy_traffic_flow() {

    # Create or reconcile VNet and public subnet
    create_vnet \
        "$VNET" \
        "$LOCATION" \
        "$PUBLIC_V_NET_PREFIX" \
        "$PUBLIC_SUB_NET" \
        "$PUBLIC_SUB_NET_PREFIX"

    # Create or reconcile private subnet
    create_subnet \
        "$VNET" \
        "$PRIVATE_SUB_NET" \
        "$PRIVATE_SUB_NET_PREFIX"

    # Create or reconcile DMZ subnet
    create_subnet \
        "$VNET" \
        "$DMZ_SUB_NET" \
        "$DMZ_SUB_NET_PREFIX"

    # Create or reconcile public route table
    create_route_table \
        "$PUBLIC_TABLE_ROUTE" \
        "$DISABLEBGPROUTEPROPAGATION"

    # Create or reconcile custom route to private subnet through planned NVA
    create_custom_route \
        "$PUBLIC_TO_PRIVATE_ROUTE" \
        "$PUBLIC_TABLE_ROUTE" \
        "$PRIVATE_SUB_NET_PREFIX" \
        "$NEXT_HOP_TYPE" \
        "$NEXT_HOP_IP_ADDRESS"

    # Associate public subnet with route table
    update_subnet_with_route_table \
        "$VNET" \
        "$PUBLIC_SUB_NET" \
        "$PUBLIC_TABLE_ROUTE"
}

# Execute implementation
deploy_traffic_flow