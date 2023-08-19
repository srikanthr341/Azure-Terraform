
resource "azurerm_resource_group" "sa_rg" {
    name =  var.resource_group_name #"sa_rg"
    location = var.region_name #"East US"
}

resource "azurerm_storage_account" "storage" {
  name                     = "srikanthboyapalli"
  resource_group_name      = azurerm_resource_group.sa_rg.name
  location                 = azurerm_resource_group.sa_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  allow_blob_public_access = true
}

resource "azurerm_storage_container" "container" {
  name                  = "sri"
  storage_account_name  = azurerm_storage_account.storage.name
  container_access_type = "container" #"container" # "blob" "private"
}

resource "azurerm_virtual_network" "example" {
  name                = "example-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.sa_rg.location
  resource_group_name = azurerm_resource_group.sa_rg.name
}

# we will create VM in this subnet
resource "azurerm_subnet" "public_subnet" {
  name                 = "public_subnet"
  resource_group_name  = azurerm_resource_group.sa_rg.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.1.0/24"]
}

# we will create private endpoint in this subnet
resource "azurerm_subnet" "endpoint_subnet" {
  name                 = "endpoint_subnet"
  resource_group_name  = azurerm_resource_group.sa_rg.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.2.0/24"]

  enforce_private_link_endpoint_network_policies = true
}

resource "azurerm_public_ip" "public_ip" {
  name                = format("%s_%s", var.name, "ip")
  resource_group_name = var.resource_group_name
  location            = var.region_name
  allocation_method   = "Dynamic"
}
resource "azurerm_network_interface" "example" {
  name                = format("%s_%s", var.name, "network_interface")
  location            = var.region_name
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.public_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.public_ip.id
  }
}
 
resource "azurerm_windows_virtual_machine" "example" {
  name                = "example-machine"
  resource_group_name = azurerm_resource_group.sa_rg.name
  location            = azurerm_resource_group.sa_rg.location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  admin_password      = "Password123$"
  network_interface_ids = [
    azurerm_network_interface.example.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
}

resource "azurerm_network_security_group" "nsg" {
  name                = format("%s_%s", var.name, "nsg")
  location            = var.region_name
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "allow_ssh_sg"
    priority                   = 100 
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  depends_on = [
    azurerm_network_interface.example
  ]
}

resource "azurerm_network_interface_security_group_association" "association" {
  network_interface_id      = azurerm_network_interface.example.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}
 

output "storage_account_id" {
    value = azurerm_storage_account.storage.id
}

 
output "storage_account_name" {
  value = azurerm_storage_account.storage.name
}

resource "azurerm_private_dns_zone" "example" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.sa_rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "network_link" {
  name                  = "vnet_link"
  resource_group_name   = azurerm_resource_group.sa_rg.name
  private_dns_zone_name = azurerm_private_dns_zone.example.name
  virtual_network_id    = azurerm_virtual_network.example.id
}


resource "azurerm_private_endpoint" "endpoint" {
  name                = format("%s-%s", var.name, "private-endpoint")
  location            = var.region_name
  resource_group_name = var.resource_group_name
  subnet_id           = azurerm_subnet.endpoint_subnet.id

  private_service_connection {
    name                           = format("%s-%s", var.name, "privateserviceconnection")
    private_connection_resource_id =  azurerm_storage_account.storage.id #var.private_link_enabled_resource_id
    is_manual_connection           = false
    subresource_names              = ["blob"] #var.subresource_names
  }
}

resource "azurerm_private_dns_a_record" "dns_a" {
  name                = format("%s-%s", var.name, "arecord")
  zone_name           = azurerm_private_dns_zone.example.name #var.private_dns_zone_name
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = [azurerm_private_endpoint.endpoint.private_service_connection.0.private_ip_address]
}