## Provisions for ContainerVMs
## Multiple NICs per container

# create another set of VM
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "resourcegroup" {
  name     = "Session1.4"
  location = "eastus"
  tags = {
    Owner = "Aingel Carbonell"
    environment = "Jaira Tutorials"
  }
}


# Create virtual network
resource "azurerm_virtual_network" "aingelnet" {
    name                = "myVnet"
    address_space       = ["192.168.0.0/16"]
    location            = azurerm_resource_group.resourcegroup.location
    resource_group_name = azurerm_resource_group.resourcegroup.name
    tags = azurerm_resource_group.resourcegroup.tags
}

# container of subnet list
variable "networksubnets"{
    description = "Series of network subnets"
    type        = list(string)
    default     = ["192.168.0.0/24","192.168.12.0/24","192.168.16.0/24","192.168.20.248/29"]
}
# networksubnets[0] = 

# Create subnets
resource "azurerm_subnet" "subnet" {
    count               = length(var.networksubnets)
    name                 = "subnet${count.index}"
    resource_group_name  = azurerm_resource_group.resourcegroup.name
    virtual_network_name = azurerm_virtual_network.aingelnet.name
    address_prefixes       = [var.networksubnets[count.index]]

    delegation {
        name = "delegation"

        service_delegation {
            name    = "Microsoft.ContainerInstance/containerGroups"
            actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
        }
    }
}

# Create public IPs
resource "azurerm_public_ip" "publicip" {
    name                         = "myPublicIP"
    location                     = azurerm_resource_group.resourcegroup.location
    resource_group_name          = azurerm_resource_group.resourcegroup.name
    allocation_method            = "Dynamic"

    tags = azurerm_resource_group.resourcegroup.tags
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "netsecgroupssh" {
    name                = "SSHNetworkSecurityGroup"
    location            = azurerm_resource_group.resourcegroup.location
    resource_group_name = azurerm_resource_group.resourcegroup.name

    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    tags = azurerm_resource_group.resourcegroup.tags
}
resource "azurerm_network_security_group" "netsecgrouphttp" {
    name                = "HTTPNetworkSecurityGroup"
    location            = azurerm_resource_group.resourcegroup.location
    resource_group_name = azurerm_resource_group.resourcegroup.name

    security_rule {
        name                       = "HTTP"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "80"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
    security_rule {
        name                       = "HTTPS"
        priority                   = 1002
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "443"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    tags = azurerm_resource_group.resourcegroup.tags
}

# Create network interface
resource "azurerm_network_interface" "mynic0" {
    count                     = 4
    name                      = "nicsub0${count.index}"
    location                  = azurerm_resource_group.resourcegroup.location
    resource_group_name       = azurerm_resource_group.resourcegroup.name

    ip_configuration {
        name                          = "myNicConfiguration"
        subnet_id                     = azurerm_subnet.subnet[0].id
        private_ip_address_allocation = "Dynamic"
    }
    tags = azurerm_resource_group.resourcegroup.tags
}
resource "azurerm_network_interface" "mynic1" {
    count                     = 6
    name                      = "nicsub1${count.index}"
    location                  = azurerm_resource_group.resourcegroup.location
    resource_group_name       = azurerm_resource_group.resourcegroup.name

    ip_configuration {
        name                          = "myNicConfiguration"
        subnet_id                     = azurerm_subnet.subnet[1].id
        private_ip_address_allocation = "Dynamic"
    }
    tags = azurerm_resource_group.resourcegroup.tags
}
resource "azurerm_network_interface" "mynic2" {
    count                     = 4
    name                      = "nicsub2${count.index}"
    location                  = azurerm_resource_group.resourcegroup.location
    resource_group_name       = azurerm_resource_group.resourcegroup.name

    ip_configuration {
        name                          = "myNicConfiguration"
        subnet_id                     = azurerm_subnet.subnet[2].id
        private_ip_address_allocation = "Dynamic"
    }
    tags = azurerm_resource_group.resourcegroup.tags
}
resource "azurerm_network_interface" "mynic3" {
    count                     = 2
    name                      = "nicsub3${count.index}"
    location                  = azurerm_resource_group.resourcegroup.location
    resource_group_name       = azurerm_resource_group.resourcegroup.name

    ip_configuration {
        name                          = "myNicConfiguration"
        subnet_id                     = azurerm_subnet.subnet[3].id
        private_ip_address_allocation = "Dynamic"
    }
    tags = azurerm_resource_group.resourcegroup.tags
}

# Connect the security group to the network interface

# Generate random text for a unique storage account name
resource "random_id" "randomId" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = azurerm_resource_group.resourcegroup.name
    }

    byte_length = 8
}


# Create (and display) an SSH key
resource "tls_private_key" "myssh" {
  algorithm = "RSA"
  rsa_bits = 4096
}
output "tls_private_key" { 
    value = tls_private_key.myssh.private_key_pem 
    sensitive = true
}

# VMS definition
locals{
    vms = [
    {
        name = "webserver"
        nic = [azurerm_network_interface.mynic0[3].id, azurerm_network_interface.mynic3[0].id],
        username = "azureuser",
            publisher = "Canonical",
            offer     = "UbuntuServer",
            sku       = "18.04-LTS",
            version   = "latest"
    },{
        name = "depmgr"
        nic = [azurerm_network_interface.mynic1[3].id, azurerm_network_interface.mynic2[0].id],
        username = "azureuser",
            publisher = "Canonical",
            offer     = "UbuntuServer",
            sku       = "18.04-LTS",
            version   = "latest"
    },{
        name = "dbserver"
        nic = [azurerm_network_interface.mynic1[4].id, azurerm_network_interface.mynic2[1].id, azurerm_network_interface.mynic3[1].id],
        username = "azureuser",
            publisher = "Canonical",
            offer     = "UbuntuServer",
            sku       = "18.04-LTS",
            version   = "latest"
    },{
        name = "appserver"
        nic = [azurerm_network_interface.mynic1[5].id],
        username = "azureuser",
            publisher = "Canonical",
            offer     = "UbuntuServer",
            sku       = "18.04-LTS",
            version   = "latest"
    },{
        name = "domaincon"
        nic = [azurerm_network_interface.mynic2[2].id],
        username = "azureuser",
            publisher = "Canonical",
            offer     = "UbuntuServer",
            sku       = "18.04-LTS",
            version   = "latest"
    },{
        name = "fileserver"
        nic = [azurerm_network_interface.mynic2[3].id],
        username = "azureuser",
            publisher = "Canonical",
            offer     = "UbuntuServer",
            sku       = "18.04-LTS",
            version   = "latest"
    }
    ]
}

# Create storage accounts for boot diagnostics
resource "azurerm_storage_account" "mystorageaccount" {
    count                       = length(local.vms)
    name                        = "diag${random_id.randomId.hex}a${count.index}"
    resource_group_name         = azurerm_resource_group.resourcegroup.name
    location                    = azurerm_resource_group.resourcegroup.location
    account_tier                = "Standard"
    account_replication_type    = "LRS"
    tags = azurerm_resource_group.resourcegroup.tags
}

# Create virtual machines
resource "azurerm_linux_virtual_machine" "VMS" {
    count                 = length(local.vms)
    name                  = local.vms[count.index].name
    location              = azurerm_resource_group.resourcegroup.location
    resource_group_name   = azurerm_resource_group.resourcegroup.name
    network_interface_ids = local.vms[count.index].nic
    size                  = "Standard_B1ls"
    os_disk {
        name              = "disk${local.vms[count.index].name}"
        caching           = "ReadWrite"
        storage_account_type = "Standard_LRS"
    }
    source_image_reference {
        publisher = local.vms[count.index].publisher
        offer     = local.vms[count.index].offer
        sku       = local.vms[count.index].sku
        version   = local.vms[count.index].version
    }
    computer_name  = local.vms[count.index].name
    admin_username = local.vms[count.index].username
    disable_password_authentication = true
    admin_ssh_key {
        username       = local.vms[count.index].username
        public_key     = tls_private_key.myssh.public_key_openssh
    }
    boot_diagnostics {
        storage_account_uri = azurerm_storage_account.mystorageaccount[count.index].primary_blob_endpoint
    }
    tags = azurerm_resource_group.resourcegroup.tags
}

## container instances
# container network
resource "azurerm_network_profile" "dockernet" {
  name                = "dockernetworkprofile"
  location            = azurerm_resource_group.resourcegroup.location
  resource_group_name = azurerm_resource_group.resourcegroup.name

  container_network_interface {
    name = "dockernic"

    ip_configuration {
      name      = "dockernet0ip"
      subnet_id = azurerm_subnet.subnet[0].id
    }
    ip_configuration {
      name  = "dockernet1ip"
      subnet_id = azurerm_subnet.subnet[1].id
    }
  }
}

resource "azurerm_container_group" "dockerhost-linux" {
    name                = "dockerlinux"
    location            = azurerm_resource_group.resourcegroup.location
    resource_group_name = azurerm_resource_group.resourcegroup.name
    ip_address_type     = "Private"
    network_profile_id  = azurerm_network_profile.dockernet.id
    dns_name_label      = "docker"
    os_type             = "Linux"

    container {
        name   = "dockerhost1"
        image  = "mcr.microsoft.com/azuredocs/aks-helloworld:latest"
        cpu    = "0.5"
        memory = "1.5"

        ports {
            port     = 80
            protocol = "TCP"
        }
    }

    container {
        name   = "dockerhost2"
        image  = "mcr.microsoft.com/azuredocs/aks-helloworld:latest"
        cpu    = "0.5"
        memory = "1.5"
    }

    tags = azurerm_resource_group.resourcegroup.tags
}

resource "azurerm_container_group" "dockerhost-win" {
    name                = "dockerwindows"
    location            = azurerm_resource_group.resourcegroup.location
    resource_group_name = azurerm_resource_group.resourcegroup.name
    ip_address_type     = "Private"
    network_profile_id  = azurerm_network_profile.dockernet.id
    dns_name_label      = "docker"
    os_type             = "Windows"

    container {
        name   = "dockerhost3"
        image  = "mcr.microsoft.com/azuredocs/aks-helloworld:latest"
        cpu    = "0.5"
        memory = "1.5"

        ports {
            port     = 80
            protocol = "TCP"
        }
    }

    tags = azurerm_resource_group.resourcegroup.tags
}
