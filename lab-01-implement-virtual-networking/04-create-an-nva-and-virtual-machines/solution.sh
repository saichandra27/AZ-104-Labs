#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Load configuration and helper functions
# shellcheck source=/dev/null
source "$script_dir/variables.sh"

# shellcheck source=/dev/null
source "$script_dir/../common/functions_create.sh"

# Deploy NVA in the DMZ subnet
create_vm \
    "$VIRTUALMACHINENAME" \
    "$VNET_NAME" \
    "$DMZ_SUB_NET" \
    "$IMAGE" \
    "$USER_NAME" \
    "$ADMIN_PASSWORD"

# Retrieve the NVA network interface ID
NICID=$(az vm nic list \
    --resource-group "$RESOURCE_GROUP" \
    --vm-name "$VIRTUALMACHINENAME" \
    --query "[0].id" \
    --output tsv)

if [[ -z "$NICID" ]]; then
    echo "ERROR: Could not retrieve NVA network interface ID."
    exit 1
fi

echo "NVA NIC ID: $NICID"

# Enable IP forwarding at Azure NIC level
az network nic update \
    --ids "$NICID" \
    --ip-forwarding true

echo "Azure NIC IP forwarding enabled."

# Retrieve NVA public IP address
NVAIP=$(az vm list-ip-addresses \
    --resource-group "$RESOURCE_GROUP" \
    --name "$VIRTUALMACHINENAME" \
    --query "[0].virtualMachine.network.publicIpAddresses[0].ipAddress" \
    --output tsv)

if [[ -z "$NVAIP" || "$NVAIP" == "None" ]]; then
    echo "ERROR: NVA public IP address not found."
    exit 1
fi

echo "NVA Public IP: $NVAIP"

# Enable persistent Linux IP forwarding
ssh -o StrictHostKeyChecking=accept-new \
    "$USER_NAME@$NVAIP" \
    'echo "net.ipv4.ip_forward = 1" |
     sudo tee /etc/sysctl.d/99-ip-forwarding.conf >/dev/null &&
     sudo sysctl --system'

echo "Linux IP forwarding enabled."
echo "NVA configuration completed successfully."
