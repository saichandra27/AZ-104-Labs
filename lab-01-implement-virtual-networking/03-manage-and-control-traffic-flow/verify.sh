#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
#shellcheck source=/dev/null
source "$script_dir/../functions_create.sh"
source "$script_dir/../functions_update.sh"
source "$script_dir/../variables.sh"

verify_custom_route(){
    
    #verify app vnet and public subnets
    verify_vnet_created_successfully  "$VNET"
    
    #verify private subnet
    verify_subnet_created_successfully "$VNET" "$PRIVATE_SUB_NET" 
    
    #verify dmz subnet
    verify_subnet_created_successfully "$VNET" "$DMZ_SUB_NET_PREFIX"

    #verify public route table
    verify_custom_route_table "$PUBLIC_TABLE_ROUTE"

    #verify custom route
    verify_custom_route "$PRODUCTION_SUBNET" "$PUBLIC_TABLE_ROUTE"

    #verify associated subnet with route table
    verify_subnet_with_route_table \
    "$VNET_NAME" \
    "$PUBLIC_SUBNET_NAME" \
    "$ROUTE_TABLE_NAME"
}

#execute the function to create_custom_route
verify_custom_route