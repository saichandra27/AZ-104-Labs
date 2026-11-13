#!/usr/bin/env bash
set -euo pipefail
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$script_dir/../1. Common/02.CommonFunctions.sh"

verify_vnet_created_successfully "$APP_VNET"

verify_subnet_created_successfully "$APP_VNET" "$FRONTEND_SUBNET"

verify_subnet_created_successfully "$APP_VNET" "$BACKEND_SUBNET"

verify_subnet_created_successfully "$APP_VNET" "$APP_FIREWALL_SUBNET"

verify_vnet_created_successfully "$HUB_VNET"

verify_subnet_created_successfully "$HUB_VNET" "$HUB_FIREWALL_SUBNET"

verify_vnet_peering_created_successfully "APP_VNET" "APP_FIREWALL_PIP"

verify_vnet_peering_created_successfully "HUB_VNET" "HUB_FIREWALL_PIP"