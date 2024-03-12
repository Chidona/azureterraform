resource "azurerm_resource_group" "resource_group" {
  name     = "class-rg"
  location = "eastus"
}

resource "azurerm_resource_group" "new_resource_group" {
  name     = "NetworkWatcherRG"
  location = "eastus"
}


resource "azurerm_subnet" "subnet" {
  name                 = "class-sbn"
  resource_group_name  = azurerm_resource_group.resource_group.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_interface" "main" {
  name                = "class-vm581_z1"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_virtual_machine" "class-vm" {
  name                  = "class-vm"
  location              = azurerm_resource_group.resource_group.location
  network_interface_ids = [azurerm_network_interface.main.id]
  resource_group_name   = "class-rg"
  vm_size               = "Standard_D2s_v3"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  storage_os_disk {
    name              = "classvm-os-disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
    os_type           = "Linux"
  }

  os_profile {
    admin_password = "User11!"
    admin_username = "azureuser"
    computer_name  = "class-azurevm"
  }

  os_profile_linux_config {
    disable_password_authentication = false

  }

  tags = {
    environment = "dev"
  }


}

resource "azurerm_storage_account" "stgaccount" {
  name                     = "storageaccountciancj"
  resource_group_name      = azurerm_resource_group.resource_group.name
  location                 = azurerm_resource_group.resource_group.location
  account_tier             = "Standard"
  account_replication_type = "GRS"

  tags = {
    environment = "dev"
  }
}

######################################
#azurerm bastion host for our vm
###########################################

resource "azurerm_virtual_network" "vnet" {
  name                = "cian-vn"
  location            = azurerm_resource_group.resource_group.location
  address_space       = ["10.0.0.0/16"]
  resource_group_name = azurerm_resource_group.resource_group.name

}

resource "azurerm_subnet" "AzureBastionSubnet" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.resource_group.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/26"]
}

resource "azurerm_public_ip" "vmip" {
  name                = "vmip"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "vmbastion" {
  name                = "vmbastion"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.AzureBastionSubnet.id
    public_ip_address_id = azurerm_public_ip.vmip.id
  }
}


####################
#kubernetes cluster
###################

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks1-cian"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  dns_prefix          = "ciandns"

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_D2_v2"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Environment = "Production"
  }
}

output "client_certificate" {
  value     = azurerm_kubernetes_cluster.aks.kube_config[0].client_certificate
  sensitive = true
}

output "kube_config" {
  value = azurerm_kubernetes_cluster.aks.kube_config_raw

  sensitive = true
}

#####################################
#keyvalut creation
#####################################

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "ciankeyvault" {
  name                        = "ciankeyvault"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Get", "List",
    ]

    secret_permissions = [
      "Get", "List",
    ]

    storage_permissions = [
      "Get",
    ]
  }
}