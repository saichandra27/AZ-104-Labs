#!/usr/bin/env bash

#region Variables for Implementing Virtual Networks
RESOURCE_GROUP="MyResourceGroup"
LOCATION="eastus"

APP_VNET="app-vnet"
HUB_VNET="hub-vnet"

APP_VNET_PREFIX="10.1.0.0/16"
HUB_VNET_PREFIX="10.0.0.0/16"

FRONTEND_SUBNET="frontend"
FRONTEND_PREFIX="10.1.0.0/24"

BACKEND_SUBNET="backend"
BACKEND_PREFIX="10.1.1.0/24"

APP_FIREWALL_SUBNET="AzureFirewallSubnet"
APP_FIREWALL_PREFIX="10.1.63.0/26"

HUB_FIREWALL_SUBNET="AzureFirewallSubnet"
HUB_FIREWALL_PREFIX="10.0.0.0/26"

APP_FIREWALL_PIP="app-vnet-firewall-pip"
HUB_FIREWALL_PIP="hub-vnet-firewall-pip"
#endregion

#region Variables for Implementing Network Security Groups
CORE_SERVICES_VNET="CoreServicesVnet"
SHARED_SERVICES_SUBNET="SharedServicesSubnet"
DATABASE_SUBNET="DatabaseSubnet"

CORE_SERVICES_VNET_PREFIX="10.20.0.0/16"
SHARED_SERVICES_SUBNET_PREFIX="10.20.10.0/24"
DATABASE_SUBNET_PREFIX="10.20.20.0/24"

MANUFACTURING_VNET="ManufacturingVnet"
SENSORS_SUBNET_1="SensorsSubnet1"
SENSORS_SUBNET_2="SensorsSubnet2"

MANUFACTURING_VNET_PREFIX="10.30.0.0/16"
SENSORS_SUBNET_1_PREFIX="10.30.20.0/24"
SENSORS_SUBNET_2_PREFIX="10.30.21.0/24"

MYNSGSECURE="myNSGSecure"
ASGWEB="asg-web";
#endregion