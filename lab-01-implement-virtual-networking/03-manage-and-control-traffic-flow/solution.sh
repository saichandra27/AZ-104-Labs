#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
#shellcheck source=/dev/null
source "$script_dir/../functions_create.sh"
source "$script_dir/../functions_update.sh"
source "$script_dir/../variables.sh"

create_custom_route(){
    
    #create app vnet and public subnets
    create_vnet   "$VNET" "$LOCATION" "$PUBLIC_V_NET_PREFIX" "$PUBLIC_SUB_NET" "$PUBLIC_SUB_NET_PREFIX"
    
    #create private subnet
    create_subnet "$VNET" "$PRIVATE_SUB_NET" "$PRIVATE_SUB_NET_PREFIX"
    
    #create dmz subnet
    create_subnet "$VNET" "$DMZ_SUB_NET_PREFIX" "$DMZ_SUB_NET_PREFIX"

    #create public route table
    create_route_table "$PUBLIC_TABLE_ROUTE" "$DISABLEBGPROUTEPROPAGATION"

    #create custom route
    create_custom_route "$PRODUCTION_SUBNET" "$PUBLIC_TABLE_ROUTE" "$NEXT_HOP_TYPE" "$NEXT_HOP_IP_ADDRESS"

    #associate subnet with route table
    update_subnet_with_route_table "$PUBLIC_SUB_NET" "$VNET" "$PUBLIC_TABLE_ROUTE"
}

#execute the function to create_custom_route
create_virtual_networks