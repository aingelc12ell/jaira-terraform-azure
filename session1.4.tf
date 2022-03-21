## Use for-loop and variables

# create another set of VM
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "aingelrg1" {
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
    location            = azurerm_resource_group.aingelrg1.location
    resource_group_name = azurerm_resource_group.aingelrg1.name
    tags = azurerm_resource_group.aingelrg1.tags
}

# container of subnet list
variable "networksubnets"{
    description = "Series of network subnets"
    type        = list(string)
    default     = ["192.168.0.0/24","192.168.120.0/24"]
}

# Create subnets
resource "azurerm_subnet" "subnet" {
    count               = length(var.networksubnets)
    name                 = "subnet${count.index}"
    resource_group_name  = azurerm_resource_group.aingelrg1.name
    virtual_network_name = azurerm_virtual_network.aingelnet.name
    address_prefixes       = [var.networksubnets[count.index]]
}

# Create public IPs
resource "azurerm_public_ip" "publicip" {
    name                         = "myPublicIP"
    location                     = azurerm_resource_group.aingelrg1.location
    resource_group_name          = azurerm_resource_group.aingelrg1.name
    allocation_method            = "Dynamic"

    tags = azurerm_resource_group.aingelrg1.tags
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "netsecgroupssh" {
    name                = "SSHNetworkSecurityGroup"
    location            = azurerm_resource_group.aingelrg1.location
    resource_group_name = azurerm_resource_group.aingelrg1.name

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

    tags = azurerm_resource_group.aingelrg1.tags
}
resource "azurerm_network_security_group" "netsecgrouphttp" {
    name                = "HTTPNetworkSecurityGroup"
    location            = azurerm_resource_group.aingelrg1.location
    resource_group_name = azurerm_resource_group.aingelrg1.name

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

    tags = azurerm_resource_group.aingelrg1.tags
}

# Create network interface
resource "azurerm_network_interface" "mynic" {
    name                      = "myNIC"
    location                  = azurerm_resource_group.aingelrg1.location
    resource_group_name       = azurerm_resource_group.aingelrg1.name

    ip_configuration {
        name                          = "myNicConfiguration"
        subnet_id                     = azurerm_subnet.subnet[0].id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.publicip.id
    }
    tags = azurerm_resource_group.aingelrg1.tags
}
resource "azurerm_network_interface" "mynic2" {
    name                      = "myNIC2"
    location                  = azurerm_resource_group.aingelrg1.location
    resource_group_name       = azurerm_resource_group.aingelrg1.name

    ip_configuration {
        name                          = "myNicConfiguration2"
        subnet_id                     = azurerm_subnet.subnet[1].id
        private_ip_address_allocation = "Dynamic"
    }
    tags = azurerm_resource_group.aingelrg1.tags
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "netsecgrpassoc" {
    network_interface_id      = azurerm_network_interface.mynic.id
    network_security_group_id = azurerm_network_security_group.netsecgroupssh.id
}
resource "azurerm_network_interface_security_group_association" "netsecgrpassoc2" {
    network_interface_id      = azurerm_network_interface.mynic2.id
    network_security_group_id = azurerm_network_security_group.netsecgroupssh.id
}

# Generate random text for a unique storage account name
resource "random_id" "randomId" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = azurerm_resource_group.aingelrg1.name
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
    vms = [{
        nic = azurerm_network_interface.mynic.id,
        username = "azureuser"
    },{
        nic = azurerm_network_interface.mynic2.id,
        username = "azureuser"
    }]
}

# Create storage accounts for boot diagnostics
resource "azurerm_storage_account" "mystorageaccount" {
    count                       = length(local.vms)
    name                        = "diag${random_id.randomId.hex}a${count.index}"
    resource_group_name         = azurerm_resource_group.aingelrg1.name
    location                    = azurerm_resource_group.aingelrg1.location
    account_tier                = "Standard"
    account_replication_type    = "LRS"
    tags = azurerm_resource_group.aingelrg1.tags
}

# Create virtual machines
resource "azurerm_linux_virtual_machine" "VMS" {
    count                 = length(local.vms)
    name                  = "VM${count.index}"
    location              = azurerm_resource_group.aingelrg1.location
    resource_group_name   = azurerm_resource_group.aingelrg1.name
    network_interface_ids = [local.vms[count.index].nic]
    size                  = "Standard_DS1_v2"
    os_disk {
        name              = "myOsDisk"
        caching           = "ReadWrite"
        storage_account_type = "Standard_LRS"
    }
    source_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "18.04-LTS"
        version   = "latest"
    }
    computer_name  = "myvm${count.index}"
    admin_username = local.vms[count.index].username
    disable_password_authentication = true
    admin_ssh_key {
        username       = local.vms[count.index].username
        public_key     = tls_private_key.myssh.public_key_openssh
    }
    boot_diagnostics {
        storage_account_uri = azurerm_storage_account.mystorageaccount[count.index].primary_blob_endpoint
    }
    tags = azurerm_resource_group.aingelrg1.tags
}
