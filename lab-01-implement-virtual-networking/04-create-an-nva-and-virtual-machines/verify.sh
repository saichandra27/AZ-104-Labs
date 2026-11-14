#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Load configuration
# shellcheck source=/dev/null
source "$script_dir/variables.sh"

# Verification counters
PASSED=0
FAILED=0

pass() {
    echo "[PASS] $1"
    ((PASSED+=1))
}

fail() {
    echo "[FAIL] $1"
    ((FAILED+=1))
}

info() {
    echo "[INFO] $1"
}

# --------------------------------------------------
# 1. Verify Virtual Machine exists
# --------------------------------------------------

info "Verifying NVA virtual machine..."

if az vm show \
    --resource-group "$RESOURCE_GROUP" \
    --name "$VIRTUALMACHINENAME" \
    --output none 2>/dev/null; then

    pass "NVA virtual machine exists."

else
    fail "NVA virtual machine does not exist."
    echo "Verification cannot continue without the VM."
    exit 1
fi

# --------------------------------------------------
# 2. Verify VM is running
# --------------------------------------------------

VM_POWER_STATE=$(az vm get-instance-view \
    --resource-group "$RESOURCE_GROUP" \
    --name "$VIRTUALMACHINENAME" \
    --query "instanceView.statuses[?starts_with(code, 'PowerState/')].displayStatus | [0]" \
    --output tsv)

if [[ "$VM_POWER_STATE" == "VM running" ]]; then
    pass "NVA virtual machine is running."
else
    fail "NVA virtual machine is not running. State: $VM_POWER_STATE"
fi

# --------------------------------------------------
# 3. Verify VM subnet placement
# --------------------------------------------------

NICID=$(az vm nic list \
    --resource-group "$RESOURCE_GROUP" \
    --vm-name "$VIRTUALMACHINENAME" \
    --query "[0].id" \
    --output tsv)

if [[ -z "$NICID" || "$NICID" == "None" ]]; then
    fail "Could not retrieve NVA NIC ID."
    exit 1
fi

pass "NVA NIC ID retrieved."

SUBNET_ID=$(az network nic show \
    --ids "$NICID" \
    --query "ipConfigurations[0].subnet.id" \
    --output tsv)

EXPECTED_SUBNET_ID=$(az network vnet subnet show \
    --resource-group "$RESOURCE_GROUP" \
    --vnet-name "$VNET_NAME" \
    --name "$DMZ_SUB_NET" \
    --query id \
    --output tsv)

if [[ "${SUBNET_ID,,}" == "${EXPECTED_SUBNET_ID,,}" ]]; then
    pass "NVA is deployed in the expected DMZ subnet."
else
    fail "NVA is not deployed in the expected DMZ subnet."
    info "Actual subnet: $SUBNET_ID"
    info "Expected subnet: $EXPECTED_SUBNET_ID"
fi

# --------------------------------------------------
# 4. Verify Azure NIC IP forwarding
# --------------------------------------------------

IP_FORWARDING_ENABLED=$(az network nic show \
    --ids "$NICID" \
    --query "enableIPForwarding" \
    --output tsv)

if [[ "$IP_FORWARDING_ENABLED" == "true" ]]; then
    pass "Azure NIC IP forwarding is enabled."
else
    fail "Azure NIC IP forwarding is not enabled."
fi

# --------------------------------------------------
# 5. Retrieve public IP address
# --------------------------------------------------

NVAIP=$(az vm list-ip-addresses \
    --resource-group "$RESOURCE_GROUP" \
    --name "$VIRTUALMACHINENAME" \
    --query "[0].virtualMachine.network.publicIpAddresses[0].ipAddress" \
    --output tsv)

if [[ -n "$NVAIP" && "$NVAIP" != "None" ]]; then
    pass "NVA public IP address exists."
    info "NVA Public IP: $NVAIP"
else
    fail "NVA public IP address not found."
fi

# --------------------------------------------------
# 6. Retrieve private IP address
# --------------------------------------------------

NVAPRIVATEIP=$(az network nic show \
    --ids "$NICID" \
    --query "ipConfigurations[0].privateIPAddress" \
    --output tsv)

if [[ -n "$NVAPRIVATEIP" && "$NVAPRIVATEIP" != "None" ]]; then
    pass "NVA private IP address exists."
    info "NVA Private IP: $NVAPRIVATEIP"
else
    fail "NVA private IP address not found."
fi

# --------------------------------------------------
# 7. Verify Linux IP forwarding
# --------------------------------------------------

if [[ -n "$NVAIP" && "$NVAIP" != "None" ]]; then

    if LINUX_FORWARDING=$(ssh \
        -o BatchMode=yes \
        -o ConnectTimeout=10 \
        -o StrictHostKeyChecking=accept-new \
        "$USER_NAME@$NVAIP" \
        "sysctl -n net.ipv4.ip_forward" 2>/dev/null); then

        if [[ "$LINUX_FORWARDING" == "1" ]]; then
            pass "Linux IP forwarding is enabled."
        else
            fail "Linux IP forwarding is disabled."
        fi

        # Verify persistent configuration
        if ssh \
            -o BatchMode=yes \
            -o ConnectTimeout=10 \
            "$USER_NAME@$NVAIP" \
            "grep -Eq '^[[:space:]]*net\.ipv4\.ip_forward[[:space:]]*=[[:space:]]*1' /etc/sysctl.d/99-ip-forwarding.conf" \
            >/dev/null 2>&1; then

            pass "Persistent Linux IP forwarding configuration exists."
        else
            fail "Persistent Linux IP forwarding configuration missing."
        fi

    else
        fail "Unable to connect to NVA using SSH."
    fi
else
    fail "Skipping Linux forwarding verification: public IP unavailable."
fi

# --------------------------------------------------
# 8. Verify UDR route table association
# --------------------------------------------------

info "Verifying route table association..."

if [[ -n "${ROUTE_TABLE_NAME:-}" && -n "${PRIVATE_SUB_NET:-}" ]]; then

    ROUTE_TABLE_ID=$(az network route-table show \
        --resource-group "$RESOURCE_GROUP" \
        --name "$ROUTE_TABLE_NAME" \
        --query id \
        --output tsv)

    ASSOCIATED_ROUTE_TABLE=$(az network vnet subnet show \
        --resource-group "$RESOURCE_GROUP" \
        --vnet-name "$VNET_NAME" \
        --name "$PRIVATE_SUB_NET" \
        --query "routeTable.id" \
        --output tsv)

    if [[ "${ROUTE_TABLE_ID,,}" == "${ASSOCIATED_ROUTE_TABLE,,}" ]]; then
        pass "Route table is associated with private subnet."
    else
        fail "Route table is not associated with private subnet."
    fi

    # --------------------------------------------------
    # 9. Verify NVA next-hop configuration
    # --------------------------------------------------

    if [[ -n "${ROUTE_NAME:-}" ]]; then

        NEXT_HOP_TYPE=$(az network route-table route show \
            --resource-group "$RESOURCE_GROUP" \
            --route-table-name "$ROUTE_TABLE_NAME" \
            --name "$ROUTE_NAME" \
            --query nextHopType \
            --output tsv)

        NEXT_HOP_IP=$(az network route-table route show \
            --resource-group "$RESOURCE_GROUP" \
            --route-table-name "$ROUTE_TABLE_NAME" \
            --name "$ROUTE_NAME" \
            --query nextHopIpAddress \
            --output tsv)

        if [[ "$NEXT_HOP_TYPE" == "VirtualAppliance" ]]; then
            pass "UDR next-hop type is VirtualAppliance."
        else
            fail "UDR next-hop type is incorrect: $NEXT_HOP_TYPE"
        fi

        if [[ "$NEXT_HOP_IP" == "$NVAPRIVATEIP" ]]; then
            pass "UDR next-hop IP matches NVA private IP."
        else
            fail "UDR next-hop IP does not match NVA private IP."
            info "Configured next hop: $NEXT_HOP_IP"
            info "Expected next hop: $NVAPRIVATEIP"
        fi
    else
        info "ROUTE_NAME not configured. Skipping route verification."
    fi

else
    info "Route table variables not configured. Skipping UDR verification."
fi

# --------------------------------------------------
# 10. Final verification summary
# --------------------------------------------------

echo
echo "========================================"
echo "        NVA VERIFICATION SUMMARY"
echo "========================================"
echo "Passed : $PASSED"
echo "Failed : $FAILED"
echo "========================================"

if [[ "$FAILED" -eq 0 ]]; then
    echo "RESULT: ALL CHECKS PASSED"
    exit 0
else
    echo "RESULT: VERIFICATION FAILED"
    exit 1
fi
