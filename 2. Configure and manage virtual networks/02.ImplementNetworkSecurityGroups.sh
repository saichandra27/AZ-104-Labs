#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
#shellcheck source=/dev/null
source "$script_dir/../1. Common/02.CommonFunctions.sh"

createNetworkSecurityGroups() {
    az group create \
        --name "$RESOURCE_GROUP" \
        --location "$LOCATION"

    #Create CoreServicesVnet, SharedServicesSubnet and DatabaseSubnet subnets
    createVnet "$CORE_SERVICES_VNET" "$LOCATION" "$CORE_SERVICES_VNET_PREFIX" "$SHARED_SERVICES_SUBNET" "$SHARED_SERVICES_SUBNET_PREFIX"
    createSubNet "$CORE_SERVICES_VNET" "$DATABASE_SUBNET" "$DATABASE_SUBNET_PREFIX"

    #Create ManufacturingVnet SensorSubnet1 and SensorSubnet2 subnets
    createVnet   "$MANUFACTURING_VNET" "$LOCATION" "$MANUFACTURING_VNET_PREFIX" "$SENSORS_SUBNET1" "$SENSORS_SUBNET1_PREFIX"
    createSubNet "$MANUFACTURING_VNET" "$SENSORS_SUBNET2" "$SENSORS_SUBNET2_PREFIX"

    #Create ApplicationSecurityGroup
    createApplicationSecurityGroup "$ASGWEB" "$LOCATION"

    #Create NetworkSecurityGroup
    createNetworkSecurityGroup "$MYNSGSECURE" "$LOCATION"

    #Associate NSG with SharedServicesSubnet
    updateSubnetWithNSG "$CORE_SERVICES_VNET" "$SHARED_SERVICES_SUBNET" "$MYNSGSECURE"

    #Create inbound AllowASG rule

    ASG_ID=$(az network asg show \
            --resource-group "$RESOURCE_GROUP" \
            --name "$ASGWEB" \
            --query id \
            --output tsv)

    echo "$ASG_ID"

    createNetworkSecurityRule "$MYNSGSECURE" "AllowASG" "Inbound" "Allow" "Tcp" "*" "*" "$ASG_ID" 80 80
    
    #Create outbound DenyAll rule
    createNetworkSecurityRule "$MYNSGSECURE" "DenyAll" "Outbound" "Deny" "*" "*" "*" "*" "*" "*"
}

createNetworkSecurityGroups