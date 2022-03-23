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
    default     = ["192.168.0.0/24","192.168.12.0/24","192.168.16.0/24","192.168.20.248/29"]
}
# networksubnets[0] = 

# Create subnets
resource "azurerm_subnet" "subnet" {
    count               = length(var.networksubnets)
    name                 = "subnet${count.index}"
    resource_group_name  = azurerm_resource_group.aingelrg1.name
    virtual_network_name = azurerm_virtual_network.aingelnet.name
    address_prefixes       = [var.networksubnets[count.index]]
}
# subnets[0-3]

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
/*
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
*/

resource "azurerm_network_interface" "mynic0" {
    count                     = 4
    name                      = "nicsub0${count.index}"
    location                  = azurerm_resource_group.aingelrg1.location
    resource_group_name       = azurerm_resource_group.aingelrg1.name

    ip_configuration {
        name                          = "myNicConfiguration"
        subnet_id                     = azurerm_subnet.subnet[0].id
        private_ip_address_allocation = "Dynamic"
    }
    tags = azurerm_resource_group.aingelrg1.tags
}
resource "azurerm_network_interface" "mynic1" {
    count                     = 6
    name                      = "nicsub1${count.index}"
    location                  = azurerm_resource_group.aingelrg1.location
    resource_group_name       = azurerm_resource_group.aingelrg1.name

    ip_configuration {
        name                          = "myNicConfiguration"
        subnet_id                     = azurerm_subnet.subnet[1].id
        private_ip_address_allocation = "Dynamic"
    }
    tags = azurerm_resource_group.aingelrg1.tags
}
resource "azurerm_network_interface" "mynic2" {
    count                     = 4
    name                      = "nicsub2${count.index}"
    location                  = azurerm_resource_group.aingelrg1.location
    resource_group_name       = azurerm_resource_group.aingelrg1.name

    ip_configuration {
        name                          = "myNicConfiguration"
        subnet_id                     = azurerm_subnet.subnet[2].id
        private_ip_address_allocation = "Dynamic"
    }
    tags = azurerm_resource_group.aingelrg1.tags
}
resource "azurerm_network_interface" "mynic3" {
    count                     = 2
    name                      = "nicsub3${count.index}"
    location                  = azurerm_resource_group.aingelrg1.location
    resource_group_name       = azurerm_resource_group.aingelrg1.name

    ip_configuration {
        name                          = "myNicConfiguration"
        subnet_id                     = azurerm_subnet.subnet[3].id
        private_ip_address_allocation = "Dynamic"
    }
    tags = azurerm_resource_group.aingelrg1.tags
}

# Connect the security group to the network interface
/*resource "azurerm_network_interface_security_group_association" "netsecgrpassoc" {
    network_interface_id      = azurerm_network_interface.mynic.id
    network_security_group_id = azurerm_network_security_group.netsecgroupssh.id
}
resource "azurerm_network_interface_security_group_association" "netsecgrpassoc2" {
    network_interface_id      = azurerm_network_interface.mynic2.id
    network_security_group_id = azurerm_network_security_group.netsecgroupssh.id
}*/

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
        name = "dockerhost1",
        nic = [azurerm_network_interface.mynic0[0].id,azurerm_network_interface.mynic1[0].id],
        username = "azureuser",
            publisher = "Canonical",
            offer     = "UbuntuServer",
            sku       = "18.04-LTS",
            version   = "latest"
    },{
        name = "dockerhost2"
        nic = [azurerm_network_interface.mynic0[1].id,azurerm_network_interface.mynic1[1].id],
        username = "azureuser",
            publisher = "Canonical",
            offer     = "UbuntuServer",
            sku       = "18.04-LTS",
            version   = "latest"
    },{
        name = "dockerhost3"
        nic = [azurerm_network_interface.mynic0[2].id,azurerm_network_interface.mynic1[2].id],
        username = "azureuser",
            /* publisher = "MicrosoftWindowsServer",
            offer     = "WindowsServer",
            sku       = "2016-Datacenter",
            version   = "latest", */
            publisher = "Canonical",
            offer     = "UbuntuServer",
            sku       = "18.04-LTS",
            version   = "latest"
    },{
        name = "webserver"
        nic = [azurerm_network_interface.mynic0[3].id,azurerm_network_interface.mynic3[0].id],
        username = "azureuser",
            publisher = "Canonical",
            offer     = "UbuntuServer",
            sku       = "18.04-LTS",
            version   = "latest"
    },{
        name = "depmgr"
        nic = [azurerm_network_interface.mynic1[3].id,azurerm_network_interface.mynic2[0].id],
        username = "azureuser",
            publisher = "Canonical",
            offer     = "UbuntuServer",
            sku       = "18.04-LTS",
            version   = "latest"
    },{
        name = "dbserver"
        nic = [azurerm_network_interface.mynic1[4].id,azurerm_network_interface.mynic2[1].id,azurerm_network_interface.mynic3[1].id],
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
    resource_group_name         = azurerm_resource_group.aingelrg1.name
    location                    = azurerm_resource_group.aingelrg1.location
    account_tier                = "Standard"
    account_replication_type    = "LRS"
    tags = azurerm_resource_group.aingelrg1.tags
}

# Create virtual machines
resource "azurerm_linux_virtual_machine" "VMS" {
    count                 = length(local.vms)
    name                  = local.vms[count.index].name
    location              = azurerm_resource_group.aingelrg1.location
    resource_group_name   = azurerm_resource_group.aingelrg1.name
    network_interface_ids = local.vms[count.index].nic
    size                  = "Standard_B1s"
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
    tags = azurerm_resource_group.aingelrg1.tags
}
