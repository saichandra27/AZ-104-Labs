# Exercise: Create and configure virtual networks

<https://learn.microsoft.com/en-us/training/modules/configure-virtual-networks/9-simulation-create-networks>

Exercise scenario

Your organization is migrating a web-based application to Azure. Your first task is to put in place the virtual networks and subnets. You also need to securely peer the virtual networks. You identify these requirements.

Two virtual networks are required, app-vnet and hub-vnet. The virtual networks simulate a hub and spoke network architecture.
The app-vnet hosts the application. The app-vnet virtual network requires two subnets. The frontend subnet hosts the web servers. The backend subnet hosts the database servers.
The hub-vnet only requires a subnet for the firewall.
The two virtual networks must be able to communicate with each other securely and privately through virtual network peering.
Both virtual networks should be in the same region.
