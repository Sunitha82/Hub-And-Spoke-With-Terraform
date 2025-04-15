# Azure Hub-and-Spoke Network - Brief Guide

## Overview
This Terraform configuration deploys an Azure Hub-and-Spoke network architecture with:
- Central Hub VNet with Azure Firewall
- Two Spoke VNets for workload isolation
- VNet Peering between Hub and Spokes
- Route Tables for controlling traffic flow
- Spoke-to-spoke communication via Firewall

## Quick Deployment Steps

1. **Prepare environment**
   ```bash
   # Login to Azure
   az login
   
   # Set subscription (optional)
   az account set --subscription "Subscription Name"
   ```

2. **Create a working directory**
   ```bash
   mkdir azure-hub-spoke
   cd azure-hub-spoke
   ```

3. **Create Terraform configuration file (main.tf)**
   - Copy the Terraform code provided in the previous messages

4. **Initialize and deploy**
   ```bash
   # Initialize Terraform
   terraform init
   
   # Preview the changes
   terraform plan
   
   # Deploy the infrastructure
   terraform apply
   ```

5. **Verify deployment**
   ```bash
   # List created VNets
   az network vnet list --resource-group rg-hub-spoke-network --query "[].name" -o tsv
   
   # Check VNet peering status
   az network vnet peering list --resource-group rg-hub-spoke-network --vnet-name vnet-hub -o table
   
   # Get Firewall IP
   terraform output firewall_private_ip
   ```

## Main Components
- Hub VNet (10.0.0.0/16) with Firewall, Gateway, Bastion, and Management subnets
- Spoke 1 VNet (10.1.0.0/16) with Workload and Management subnets
- Spoke 2 VNet (10.2.0.0/16) with Workload and Management subnets
- Azure Firewall with spoke-to-spoke and internet access rules
- Route Tables forcing traffic through the Firewall

## Key Considerations
- Ensure you have appropriate Azure permissions
- For Terraform 1.1.x, set `required_version = ">= 1.1.0"`
- Add `skip_provider_registration = true` if you lack permissions to register resource providers
- Total deployment time is approximately 15-20 minutes, with Azure Firewall taking the longest
