#!/usr/bin/env bash

#region Variables for Implementing Custom Routes

export LOCATION="eastus"

export VNET="vnet"

export PUBLIC_SUB_NET="publicsubnet"
export PRIVATE_SUB_NET="privatesubnet"
export DMZ_SUB_NET="dmzsubnet"

export PUBLIC_V_NET_PREFIX="10.0.0.0/16"

export PUBLIC_SUB_NET_PREFIX="10.0.0.0/24"
export PRIVATE_SUB_NET_PREFIX="10.0.1.0/24"
export DMZ_SUB_NET_PREFIX="10.0.2.0/24"

export PUBLIC_TABLE_ROUTE="publictable"
export PUBLIC_TO_PRIVATE_ROUTE="route-to-private-subnet"

export NEXT_HOP_TYPE="VirtualAppliance"
export NEXT_HOP_IP_ADDRESS="10.0.2.4"

export DISABLEBGPROUTEPROPAGATION="false"

#endregion Variables for Implementing Custom Routes