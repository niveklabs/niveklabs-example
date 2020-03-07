provider "azurerm" {
  version = "2.0.0"

  client_id       = var.client_id
  client_secret   = var.client_secret
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id

  features {}

}

provider "github" {
  version = "2.3.2"

  individual = true
  anonymous  = true
}

# github user public ssh key
module "github_user" {
  source = "github.com/niveklabs/github//d/github_user?ref=v2.3.2"

  username = var.github_username
}

module "azurerm_resource_group" {
  source = "github.com/niveklabs/azurerm//r/azurerm_resource_group?ref=v2.0.0"

  location = "East US"
  name     = "example-resources"
}

module "azurerm_virtual_network" {
  source = "github.com/niveklabs/azurerm//r/azurerm_virtual_network?ref=v2.0.0"

  address_space       = ["10.0.0.0/16"]
  location            = module.azurerm_resource_group.this.location
  name                = "example-network"
  resource_group_name = module.azurerm_resource_group.this.name
}

module "azurerm_subnet" {
  source = "github.com/niveklabs/azurerm//r/azurerm_subnet?ref=v2.0.0"

  address_prefix       = "10.0.2.0/24"
  name                 = "internal"
  resource_group_name  = module.azurerm_resource_group.this.name
  virtual_network_name = module.azurerm_virtual_network.this.name
}

module "azurerm_network_interface" {
  source = "github.com/niveklabs/azurerm//r/azurerm_network_interface?ref=v2.0.0"

  location            = module.azurerm_resource_group.this.location
  name                = "example-nic"
  resource_group_name = module.azurerm_resource_group.this.name

  ip_configuration = [{
    name                          = "internal"
    primary                       = null
    private_ip_address            = null
    private_ip_address_allocation = "dynamic"
    private_ip_address_version    = null
    public_ip_address_id          = null
    subnet_id                     = module.azurerm_subnet.id
  }]
}

module "azurerm_linux_virtual_machine" {
  source = "github.com/niveklabs/azurerm//r/azurerm_linux_virtual_machine?ref=v2.0.0"

  admin_username        = var.github_username
  location              = module.azurerm_resource_group.this.location
  name                  = "example-machine"
  network_interface_ids = [module.azurerm_network_interface.id]
  resource_group_name   = module.azurerm_resource_group.this.name
  size                  = "Standard_F2"

  admin_ssh_key = [{
    public_key = module.github_user.ssh_keys[0]
    username   = var.github_username
  }]

  os_disk = [{
    caching                   = "ReadWrite"
    diff_disk_settings        = []
    disk_encryption_set_id    = null
    disk_size_gb              = null
    name                      = null
    storage_account_type      = "Standard_LRS"
    write_accelerator_enabled = null
  }]

  source_image_reference = [{
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }]

}
