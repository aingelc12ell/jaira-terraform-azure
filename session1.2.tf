# use azurerm_resource_group as variables to the subsequent definitions/usage
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "aingelrg1" {
  name     = "Session1.2"
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

# Create subnet
resource "azurerm_subnet" "subnet0" {
    name                 = "Subnet0"
    resource_group_name  = azurerm_resource_group.aingelrg1.name
    virtual_network_name = azurerm_virtual_network.aingelnet.name
    address_prefixes       = ["192.168.0.0/24"]
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
resource "azurerm_network_security_group" "netsecgroup" {
    name                = "myNetworkSecurityGroup"
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

# Create network interface
resource "azurerm_network_interface" "mynic" {
    name                      = "myNIC"
    location                  = azurerm_resource_group.aingelrg1.location
    resource_group_name       = azurerm_resource_group.aingelrg1.name

    ip_configuration {
        name                          = "myNicConfiguration"
        subnet_id                     = azurerm_subnet.subnet0.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.publicip.id
    }

    tags = azurerm_resource_group.aingelrg1.tags
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "netsecgrpassoc" {
    network_interface_id      = azurerm_network_interface.mynic.id
    network_security_group_id = azurerm_network_security_group.netsecgroup.id
}

# Generate random text for a unique storage account name
resource "random_id" "randomId" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = azurerm_resource_group.aingelrg1.name
    }

    byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "mystorageaccount" {
    name                        = "diag${random_id.randomId.hex}"
    resource_group_name         = azurerm_resource_group.aingelrg1.name
    location                    = azurerm_resource_group.aingelrg1.location
    account_tier                = "Standard"
    account_replication_type    = "LRS"

    tags = azurerm_resource_group.aingelrg1.tags
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

# Create virtual machine
resource "azurerm_linux_virtual_machine" "myvm" {
    name                  = "myVM"
    location              = azurerm_resource_group.aingelrg1.location
    resource_group_name   = azurerm_resource_group.aingelrg1.name
    network_interface_ids = [azurerm_network_interface.mynic.id]
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

    computer_name  = "myvm"
    admin_username = "azureuser"
    disable_password_authentication = true

    admin_ssh_key {
        username       = "azureuser"
        public_key     = tls_private_key.myssh.public_key_openssh
    }

    boot_diagnostics {
        storage_account_uri = azurerm_storage_account.mystorageaccount.primary_blob_endpoint
    }

    tags = azurerm_resource_group.aingelrg1.tags
}
