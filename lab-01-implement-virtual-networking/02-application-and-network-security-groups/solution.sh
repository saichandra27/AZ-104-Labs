#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
#shellcheck source=/dev/null
source "$script_dir/../1. Common/02.CommonFunctions.sh"

create_network_security_groups() {
    az group create \
        --name "$RESOURCE_GROUP" \
        --location "$LOCATION"

    #Create CoreServicesVnet, SharedServicesSubnet and DatabaseSubnet subnets
    create_vnet "$CORE_SERVICES_VNET" "$LOCATION" "$CORE_SERVICES_VNET_PREFIX" "$SHARED_SERVICES_SUBNET" "$SHARED_SERVICES_SUBNET_PREFIX"
    create_subnet "$CORE_SERVICES_VNET" "$DATABASE_SUBNET" "$DATABASE_SUBNET_PREFIX"

    #Create ManufacturingVnet SensorSubnet1 and SensorSubnet2 subnets
    create_vnet   "$MANUFACTURING_VNET" "$LOCATION" "$MANUFACTURING_VNET_PREFIX" "$SENSORS_SUBNET1" "$SENSORS_SUBNET1_PREFIX"
    create_subnet "$MANUFACTURING_VNET" "$SENSORS_SUBNET2" "$SENSORS_SUBNET2_PREFIX"

    #Create ApplicationSecurityGroup
    create_application_security_group "$ASGWEB" "$LOCATION"

    #Create NetworkSecurityGroup
    create_network_security_group "$MYNSGSECURE" "$LOCATION"

    #Associate NSG with SharedServicesSubnet
    update_subnet_with_nsg "$CORE_SERVICES_VNET" "$SHARED_SERVICES_SUBNET" "$MYNSGSECURE"

    #Create inbound AllowASG rule

    ASG_ID=$(az network asg show \
            --resource-group "$RESOURCE_GROUP" \
            --name "$ASGWEB" \
            --query id \
            --output tsv)

    echo "$ASG_ID"

    create_network_security_rule "$MYNSGSECURE" "AllowASG" "Inbound" "Allow" "Tcp" "*" "*" "$ASG_ID" 80 80
    
    #Create outbound DenyAll rule
    create_network_security_rule "$MYNSGSECURE" "DenyAll" "Outbound" "Deny" "*" "*" "*" "*" "*" "*"
}

#execute the function to create network security groups and rules
create_network_security_groups