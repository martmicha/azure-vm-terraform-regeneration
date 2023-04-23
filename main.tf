#Τerraform configuration block, providers
#Providers are plugins that allow the interaction with remote systems

#state which providers are required  
terraform{
  required_providers{                                                            
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.50.0"
    }
  }
}

#Define provider configurations
provider "azurerm" {
  features {}
}

#Create a resource group
#A Resource Group is a container that holds a collection of resources.
#The Azure Resource Manager is the service that is responsible for creating, updating and deleting the resources of an Azure account.

#resource "azurerm_resource_group" "rg"{                    #resource group is called "main"???

 # name = "project-codehub-reg"
 # location = var.location
#}

#Create virtual network
#resource "azurerm_virtual_network" "vnet"{ 
#  name                = "project-codehub-network"
#  location            = azurerm_resource_group.rg.location        #location is the same as the resource group's
#  resource_group_name = azurerm_resource_group.rg.name            #belongs in the resource group created above
#  address_space       = ["10.0.0.0/16"]
#}

data "azurerm_resource_group" "rg" {
  name = "project-codehub-reg"
}

data "azurerm_virtual_network" "vnet"{ 
  name = "project-codehub-network"
  resource_group_name  = data.azurerm_resource_group.rg.name
}

#Create a subnet
resource "azurerm_subnet" "subnet" {
  name                 = "project-codehub-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name          #The subnet is part of the virtual network created above
  address_prefixes     = ["10.0.1.0/24"]
}

# Create public IP
resource "azurerm_public_ip" "pubip" {
  name                = "project-codehub-PublicIp"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"

}

#Create Network Security Group and rule
resource "azurerm_network_security_group" "nsg" {
  name                = "project-codehub-acceptanceTestSecurityGroup1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"            #Allow inbound SSH traffic (on port 22) from any IP to any IP
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
    # Add a new security rule for port 8080
  security_rule {
    name                        = "HTTP-8080"
    priority                    = 110
    direction                   = "Inbound"
    access                      = "Allow"
    protocol                    = "Tcp"
    source_port_range           = "*"
    destination_port_range      = "8080"
    source_address_prefix       = "*"
    destination_address_prefix  = "*"
  }
}

# Create network interface
resource "azurerm_network_interface" "netif" {
  name                = "project-codehub-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id          #will have the id of the subnet created above
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pubip.id
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "nisga" {
  network_interface_id      = azurerm_network_interface.netif.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# Create virtual machine
resource "azurerm_virtual_machine" "vm" {
  name                  = "project-codehub-vm-node"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.netif.id]
  vm_size               = "Standard_DS1_v2"

  #delete_os_disk_on_termination    = true
  #delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "hostname"
    admin_username = var.admin_username
    admin_password = var.admin_password
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}



