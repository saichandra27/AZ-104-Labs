#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=/dev/null
source "$script_dir/../common/functions_verify.sh"

# shellcheck source=/dev/null
source "$script_dir/variables.sh"

# Function to verify custom route implementation
verify_traffic_flow() {

    # Verify VNet
    verify_vnet_created_successfully "$VNET"

    # Verify public subnet
    verify_subnet_created_successfully \
        "$VNET" \
        "$PUBLIC_SUB_NET"

    # Verify private subnet
    verify_subnet_created_successfully \
        "$VNET" \
        "$PRIVATE_SUB_NET"

    # Verify DMZ subnet
    verify_subnet_created_successfully \
        "$VNET" \
        "$DMZ_SUB_NET"

    # Verify public route table
    verify_custom_route_table "$PUBLIC_TABLE_ROUTE"

    # Verify custom route
    verify_custom_route \
        "$PUBLIC_TABLE_ROUTE" \
        "$PUBLIC_TO_PRIVATE_ROUTE" \
        "$PRIVATE_SUB_NET_PREFIX" \
        "$NEXT_HOP_TYPE" \
        "$NEXT_HOP_IP_ADDRESS"

    # Verify public subnet association with route table
    verify_subnet_with_route_table \
        "$VNET" \
        "$PUBLIC_SUB_NET" \
        "$PUBLIC_TABLE_ROUTE"
    
    echo "Traffic flow configuration verified!"

}

# Execute verification
verify_traffic_flow