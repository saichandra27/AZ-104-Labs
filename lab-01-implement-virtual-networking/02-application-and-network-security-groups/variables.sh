#!/usr/bin/env bash
#region Variables for Implementing Network Security Groups
export CORE_SERVICES_VNET="CoreServicesVnet"
export SHARED_SERVICES_SUBNET="SharedServicesSubnet"
export DATABASE_SUBNET="DatabaseSubnet"

export CORE_SERVICES_VNET_PREFIX="10.20.0.0/16"
export SHARED_SERVICES_SUBNET_PREFIX="10.20.10.0/24"
export DATABASE_SUBNET_PREFIX="10.20.20.0/24"

export MANUFACTURING_VNET="ManufacturingVnet"
export SENSORS_SUBNET_1="SensorsSubnet1"
export SENSORS_SUBNET_2="SensorsSubnet2"

export MANUFACTURING_VNET_PREFIX="10.30.0.0/16"
export SENSORS_SUBNET_1_PREFIX="10.30.20.0/24"
export SENSORS_SUBNET_2_PREFIX="10.30.21.0/24"

export MYNSGSECURE="myNSGSecure"
export ASGWEB="asg-web";
#endregion