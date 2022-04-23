## Provision for MySQL Server; revise Subnets

# create another set of VM
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "resourcegroup" {
  name     = "Session2.2"
  location = "eastus"
  tags = {
    owner = "Aingel Carbonell"
    environment = "Tutorials"
  }
}


# Create virtual network
resource "azurerm_virtual_network" "vnetwork" {
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
resource "azurerm_subnet" "subnet1" {
    name                 = "subnet1"
    resource_group_name  = azurerm_resource_group.resourcegroup.name
    virtual_network_name = azurerm_virtual_network.vnetwork.name
    address_prefixes       = [var.networksubnets[0]]

    delegation {
        name = "delegation"

        service_delegation {
            name    = "Microsoft.ContainerInstance/containerGroups"
            actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
        }
    }
}
resource "azurerm_subnet" "subnet2" {
    name                 = "subnet2"
    resource_group_name  = azurerm_resource_group.resourcegroup.name
    virtual_network_name = azurerm_virtual_network.vnetwork.name
    address_prefixes       = [var.networksubnets[1]]
}
resource "azurerm_subnet" "subnet3" {
    name                 = "subnet3"
    resource_group_name  = azurerm_resource_group.resourcegroup.name
    virtual_network_name = azurerm_virtual_network.vnetwork.name
    address_prefixes       = [var.networksubnets[2]]
}
resource "azurerm_subnet" "subnet4" {
    name                 = "subnet4"
    resource_group_name  = azurerm_resource_group.resourcegroup.name
    virtual_network_name = azurerm_virtual_network.vnetwork.name
    address_prefixes       = [var.networksubnets[3]]
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
resource "azurerm_network_interface" "nic0" {
    count                     = 4
    name                      = "nicsub0${count.index}"
    location                  = azurerm_resource_group.resourcegroup.location
    resource_group_name       = azurerm_resource_group.resourcegroup.name

    ip_configuration {
        name                          = "nicConfiguration"
        subnet_id                     = azurerm_subnet.subnet1.id
        private_ip_address_allocation = "Dynamic"
    }
    tags = azurerm_resource_group.resourcegroup.tags
}
resource "azurerm_network_interface" "nic1" {
    count                     = 6
    name                      = "nicsub1${count.index}"
    location                  = azurerm_resource_group.resourcegroup.location
    resource_group_name       = azurerm_resource_group.resourcegroup.name

    ip_configuration {
        name                          = "nicConfiguration"
        subnet_id                     = azurerm_subnet.subnet2.id
        private_ip_address_allocation = "Dynamic"
    }
    tags = azurerm_resource_group.resourcegroup.tags
}
resource "azurerm_network_interface" "nic2" {
    count                     = 4
    name                      = "nicsub2${count.index}"
    location                  = azurerm_resource_group.resourcegroup.location
    resource_group_name       = azurerm_resource_group.resourcegroup.name

    ip_configuration {
        name                          = "nicConfiguration"
        subnet_id                     = azurerm_subnet.subnet3.id
        private_ip_address_allocation = "Dynamic"
    }
    tags = azurerm_resource_group.resourcegroup.tags
}
resource "azurerm_network_interface" "nic3" {
    count                     = 2
    name                      = "nicsub3${count.index}"
    location                  = azurerm_resource_group.resourcegroup.location
    resource_group_name       = azurerm_resource_group.resourcegroup.name

    ip_configuration {
        name                          = "nicConfiguration"
        subnet_id                     = azurerm_subnet.subnet4.id
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
        nic = [azurerm_network_interface.nic0[3].id,azurerm_network_interface.nic3[0].id],
        username = "azureuser",
            publisher = "Canonical",
            offer     = "UbuntuServer",
            sku       = "18.04-LTS",
            version   = "latest"
    },{
        name = "depmgr"
        nic = [azurerm_network_interface.nic1[3].id,azurerm_network_interface.nic2[0].id],
        username = "azureuser",
            publisher = "Canonical",
            offer     = "UbuntuServer",
            sku       = "18.04-LTS",
            version   = "latest"
    },{
        name = "appserver"
        nic = [azurerm_network_interface.nic1[5].id],
        username = "azureuser",
            publisher = "Canonical",
            offer     = "UbuntuServer",
            sku       = "18.04-LTS",
            version   = "latest"
    },{
        name = "domaincon"
        nic = [azurerm_network_interface.nic2[2].id],
        username = "azureuser",
            publisher = "Canonical",
            offer     = "UbuntuServer",
            sku       = "18.04-LTS",
            version   = "latest"
    },{
        name = "fileserver"
        nic = [azurerm_network_interface.nic2[3].id],
        username = "azureuser",
            publisher = "Canonical",
            offer     = "UbuntuServer",
            sku       = "18.04-LTS",
            version   = "latest"
    }
    ]

    mysql = {
        username = "root",
        password = "Y0u4rOwnP@ssw0rd"
    }
}

# Create storage accounts for boot diagnostics
resource "azurerm_storage_account" "storageaccount" {
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
        storage_account_uri = azurerm_storage_account.storageaccount[count.index].primary_blob_endpoint
    }
    tags = azurerm_resource_group.resourcegroup.tags
}

# container instances
resource "azurerm_network_profile" "dockernet" {
  name                = "dockernetworkprofile"
  location            = azurerm_resource_group.resourcegroup.location
  resource_group_name = azurerm_resource_group.resourcegroup.name

  container_network_interface {
    name = "dockernic"

    ip_configuration {
      name      = "dockerip1"
      subnet_id = azurerm_subnet.subnet1.id
    }
    ip_configuration {
      name  = "dockerip2"
      subnet_id = azurerm_subnet.subnet2.id
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

# database server
resource "azurerm_mysql_server" "mysqlserver" {
  name                = "mysqlserver"
  location            = azurerm_resource_group.resourcegroup.location
  resource_group_name = azurerm_resource_group.resourcegroup.name

  administrator_login          = local.mysql.username
  administrator_login_password = local.mysql.password

  sku_name   = "B_Gen5_2"
  storage_mb = 5120
  version    = "5.7"

  auto_grow_enabled                 = true
  backup_retention_days             = 7
  geo_redundant_backup_enabled      = false
  infrastructure_encryption_enabled = false
  public_network_access_enabled     = true
  ssl_enforcement_enabled           = true
  ssl_minimal_tls_version_enforced  = "TLS1_2"
}

resource "azurerm_mysql_virtual_network_rule" "mysqlservernetrule" {
    name                = "mysqlservernetrule"
    resource_group_name = azurerm_resource_group.resourcegroup.name
    server_name         = azurerm_mysql_server.mysqlserver.name
    subnet_id           = azurerm_subnet.subnet4.id
}
resource "azurerm_mysql_firewall_rule" "mysqlwebserver" {
  name                = "mysqlwebserver"
  resource_group_name = azurerm_resource_group.resourcegroup.name
  server_name         = azurerm_mysql_server.mysqlserver.name
  start_ip_address    = "192.168.20.248" #subnet4
  end_ip_address      = "192.168.20.254"
}
