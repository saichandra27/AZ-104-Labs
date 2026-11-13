#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
#shellcheck source=/dev/null
source "$script_dir/../1. Common/02.CommonFunctions.sh"
source "$script_dir/../variables.sh"

create_virtual_networks(){

    create_vnet   "$VNET" "$LOCATION" "$PUBLIC_V_NET_PREFIX" "$PUBLIC_SUB_NET" "$PUBLIC_SUB_NET_PREFIX"
    create_subnet "$VNET" "$PRIVATE_SUB_NET" "$PRIVATE_SUB_NET_PREFIX"
    create_subnet "$VNET" "$DMZ_SUB_NET_PREFIX" "$DMZ_SUB_NET_PREFIX"

}