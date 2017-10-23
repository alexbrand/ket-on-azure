# Kubernetes on Azure using KET

This guide will walk you through setting up a production Kubernetes cluster on 
Azure infrastructure using the [Kismatic Enterprise Toolkit (KET)](https://github.com/apprenda/kismatic).

# Azure Architecture
* Nodes live in a single VNet.
* Nodes live in a single subnet.
* Nodes use Azure Managed Disks
* Nodes do not have a public IP address.
* Bastion host (aka. jump box) is the only virtual machine that has a public IP address.
* Etcd, master and worker nodes are in their own Availability Set.
* The kubernetes API is accessible through a load balancer that has a public IP address.
* Default network security groups are created for etcd, master and worker nodes. The master node security group allows access to the API Server port from the internet.
* The default user account is `ketadmin`

# Requirements
* Azure account
* Azure subscription ID jotted down somewhere
* Azure CLI installed
* Terraform installed

# Walkthrough

## Create infrastructure
Log into Azure using the azure CLI:

```
az login
```

Create the infrastructure using Terraform:
```
cd terraform
terraform apply
```

Create a Service Principal:
```
az account set --subscription="${SUBSCRIPTION_ID}"
az ad sp create-for-rbac --role="Contributor" --scopes="/subscriptions/${SUBSCRIPTION_ID}"
```

This will return an `appId` and `password`. Make sure to save these as we will need them when setting up the cloud provider integration.

## Update the KET plan file
Use your favorite editor to enter the following information in the sample plan file:
* Private IP of all nodes
* Public IP of `kubernetes-api` load balancer in the `load_balanced_fqdn` and `load_balanced_short_name` fields.
* Admin password

## Update the cloud provider config file
Kubernetes can integrate with Azure to create Load Balancers and Persitent Volumes on demand. To enable this capabilities, set the required information in the `azure-cloud-provider.conf` file.

The following fields must be updated with your Azure account information:
* tenantId: Your Azure tenant ID 
* subscriptionId: Your Azure subscription ID
* aadClientId: The `appId` of the Service Principal created above
* aadClientSecret: The `password` of the Service Principal created above.

## Copy files to bastion host
```
bastion=$(terraform output -state=terraform/terraform.tfstate bastion_ip)
scp kismatic-cluster.yaml azure-cloud-provider.conf ketadmin@$bastion:~
```

## Install cluster from bastion
SSH into the bastion node:
```
bastion=$(terraform output -state=terraform/terraform.tfstate bastion_ip)
ssh ketadmin@$bastion
```

Download KET v1.6.0:
```
wget https://github.com/apprenda/kismatic/releases/download/v1.6.0/kismatic-v1.6.0-linux-amd64.tar.gz -O- | tar xz
```

Provision the cluster:
```
./kismatic install apply
```

# TODO
* [ ] Create subnets for each node role.
* [ ] Create separate ssh keypair instead of using the `~/.ssh/id_rsa`.
* [ ] Template the nodes section of the KET plan file using Terraform
