#!/usr/bin/env bash
#region Variables for Implementing Virtual Networks
LOCATION="eastus"

APP_VNET="app-vnet"
HUB_VNET="hub-vnet"

APP_VNET_PREFIX="10.1.0.0/16"

FRONTEND_PREFIX="10.1.0.0/24"
BACKEND_PREFIX="10.1.1.0/24"
APP_FIREWALL_PREFIX="10.1.63.0/26"

HUB_VNET_PREFIX="10.0.0.0/16"
HUB_FIREWALL_PREFIX="10.0.0.0/26"

FRONTEND_SUBNET="frontend"

BACKEND_SUBNET="backend"

APP_FIREWALL_SUBNET="AzureFirewallSubnet"

HUB_FIREWALL_SUBNET="AzureFirewallSubnet"

APP_FIREWALL_PIP="app-vnet-firewall-pip"
HUB_FIREWALL_PIP="hub-vnet-firewall-pip"
#endregion