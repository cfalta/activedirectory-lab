
##########################################################
# Configure the Azure Provider
##########################################################
provider "azurerm" {
  features {}
}

##########################################################
# Create base infrastructure
##########################################################

# resource group
resource "azurerm_resource_group" "windows_rg" {
  name     = "${var.resource_prefix}-RG"
  location = var.node_location
  tags = var.tags
}

# virtual network within the resource group
resource "azurerm_virtual_network" "windows_vnet" {
  name                = "${var.resource_prefix}-vnet"
  resource_group_name = azurerm_resource_group.windows_rg.name
  location            = var.node_location
  address_space       = var.node_address_space
  dns_servers         = [cidrhost(var.node_address_prefix, 10)]
  tags = var.tags
}

# subnet within the virtual network
resource "azurerm_subnet" "windows_subnet" {
  name                 = "${var.resource_prefix}-subnet"
  resource_group_name  = azurerm_resource_group.windows_rg.name
  virtual_network_name = azurerm_virtual_network.windows_vnet.name
  address_prefixes       = [var.node_address_prefix]

}

##########################################################
# Create vm components
##########################################################

# public ips - member server
resource "azurerm_public_ip" "windows_public_ip" {
  count = var.node_count
  name  = "${var.resource_prefix}-${format("%02d", count.index)}-PublicIP"
  #name = "${var.resource_prefix}-PublicIP"
  location            = azurerm_resource_group.windows_rg.location
  resource_group_name = azurerm_resource_group.windows_rg.name
  allocation_method   = "Dynamic"
  domain_name_label = "${var.resource_prefix}-${format("%02d", count.index)}"

  tags = var.tags
}

# network interfaces - member server
resource "azurerm_network_interface" "windows_nic" {
  count = var.node_count
  #name = "${var.resource_prefix}-NIC"
  name                = "${var.resource_prefix}-${format("%02d", count.index)}-NIC"
  location            = azurerm_resource_group.windows_rg.location
  resource_group_name = azurerm_resource_group.windows_rg.name
  tags = var.tags
  #

  ip_configuration {
    name      = "internal"
    subnet_id = azurerm_subnet.windows_subnet.id
    #private_ip_address_allocation = "Dynamic"
    private_ip_address_allocation = "static"
    private_ip_address            = cidrhost(var.node_address_prefix, 100+count.index)
    public_ip_address_id          = element(azurerm_public_ip.windows_public_ip.*.id, count.index)
  }
}

# public ip - dc
resource "azurerm_public_ip" "dc_public_ip" {
  name = "${var.resource_prefix}-DC-PublicIP"
  location            = azurerm_resource_group.windows_rg.location
  resource_group_name = azurerm_resource_group.windows_rg.name
  allocation_method   = "Dynamic"
  domain_name_label = "${var.resource_prefix}-dc"
  tags = var.tags
}

# network interface - dc
resource "azurerm_network_interface" "dc_nic" {
  name = "${var.resource_prefix}-DC-NIC"
  location            = azurerm_resource_group.windows_rg.location
  resource_group_name = azurerm_resource_group.windows_rg.name
  tags = var.tags

  ip_configuration {
    name      = "internal"
    subnet_id = azurerm_subnet.windows_subnet.id
    #private_ip_address_allocation = "Dynamic"
    private_ip_address_allocation = "static"
    private_ip_address            = cidrhost(var.node_address_prefix, 10)
    public_ip_address_id          = azurerm_public_ip.dc_public_ip.id
  }
}

# NSG
resource "azurerm_network_security_group" "windows_nsg" {

  name                = "${var.resource_prefix}-NSG"
  location            = azurerm_resource_group.windows_rg.location
  resource_group_name = azurerm_resource_group.windows_rg.name

  # Security rule can also be defined with resource azurerm_network_security_rule, here just defining it inline.
  security_rule {
    name                       = "Inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  tags = var.tags

}

# Subnet and NSG association
resource "azurerm_subnet_network_security_group_association" "windows_subnet_nsg_association" {
  subnet_id                 = azurerm_subnet.windows_subnet.id
  network_security_group_id = azurerm_network_security_group.windows_nsg.id

}

##########################################################
# Sleep - we need this to give the DC enough time to provision before joining VMs
##########################################################

resource "time_sleep" "wait_300_seconds" {
  create_duration = "300s"
 depends_on = [azurerm_virtual_machine_extension.create-active-directory-forest]
}


##########################################################
# Create VMs
##########################################################

# VM object for member server - will create X server based on the node_count variable in terraform.tfvars
resource "azurerm_windows_virtual_machine" "windows_vm" {
  count = var.node_count
  name  = "${var.resource_prefix}-${format("%02d", count.index)}"
  #name = "${var.resource_prefix}-VM"
  location              = azurerm_resource_group.windows_rg.location
  resource_group_name   = azurerm_resource_group.windows_rg.name
  network_interface_ids = [element(azurerm_network_interface.windows_nic.*.id, count.index)]
  size                  = var.vmsize
  admin_username        = var.adminuser
  admin_password        = var.adminpassword

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  depends_on = [time_sleep.wait_300_seconds]

  tags = var.tags
}

#VM object for the DC - contrary to the member server, this one is static so there will be only a single DC
resource "azurerm_windows_virtual_machine" "windows_vm_domaincontroller" {
  name  = "${var.resource_prefix}-dc"
  location              = azurerm_resource_group.windows_rg.location
  resource_group_name   = azurerm_resource_group.windows_rg.name
  network_interface_ids = [azurerm_network_interface.dc_nic.id]
  size                  = var.vmsize
  admin_username        = var.domadminuser
  admin_password        = var.domadminpassword

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  tags = var.tags
}


##########################################################
## Define VM extensions to install ADDS and join member
##########################################################

# Promote VM to be a Domain Controller
# based on https://github.com/ghostinthewires/terraform-azurerm-promote-dc

locals { 
  import_command       = "Import-Module ADDSDeployment"
  password_command     = "$password = ConvertTo-SecureString ${var.safemode_password} -AsPlainText -Force"
  install_ad_command   = "Add-WindowsFeature -name ad-domain-services -IncludeManagementTools"
  configure_ad_command = "Install-ADDSForest -CreateDnsDelegation:$false -DomainMode Win2012R2 -DomainName ${var.active_directory_domain} -DomainNetbiosName ${var.active_directory_netbios_name} -ForestMode Win2012R2 -InstallDns:$true -SafeModeAdministratorPassword $password -Force:$true"
  shutdown_command     = "shutdown -r -t 10"
  powershell_command   = "${local.disable_fw}; ${local.import_command}; ${local.password_command}; ${local.install_ad_command}; ${local.configure_ad_command}; ${local.shutdown_command}; ${local.exit_code_hack}"
  
  exit_code_hack       = "exit 0"

  disable_fw          = "Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False"
  powershell_command_disable_fw   = "${local.disable_fw}; ${local.exit_code_hack}"
}

resource "azurerm_virtual_machine_extension" "create-active-directory-forest" {
  name                 = "create-active-directory-forest"
  virtual_machine_id   = azurerm_windows_virtual_machine.windows_vm_domaincontroller.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.9"

  settings = <<SETTINGS
    {
        "commandToExecute": "powershell.exe -Command \"${local.powershell_command}\""
    }
SETTINGS
}

# Join VM to Active Directory Domain
# based on https://github.com/ghostinthewires/terraform-azurerm-ad-join

resource "azurerm_virtual_machine_extension" "join-domain" {
  count = var.node_count
  virtual_machine_id   = azurerm_windows_virtual_machine.windows_vm[count.index].id
  name                 = "join-domain"
  publisher            = "Microsoft.Compute"
  type                 = "JsonADDomainExtension"
  type_handler_version = "1.3"
  

  # NOTE: the `OUPath` field is intentionally blank, to put it in the Computers OU
  settings = <<SETTINGS
    {
        "Name": "${var.active_directory_domain}",
        "OUPath": "",
        "User": "${var.active_directory_domain}\\${var.domadminuser}",
        "Restart": "true",
        "Options": "3"
    }
SETTINGS

  protected_settings = <<SETTINGS
    {
        "Password": "${var.domadminpassword}"
    }
SETTINGS
}

resource "azurerm_virtual_machine_extension" "disable_fw_member" {
  depends_on = [azurerm_virtual_machine_extension.join-domain]
  count = var.node_count
  virtual_machine_id   = azurerm_windows_virtual_machine.windows_vm[count.index].id
  name                 = "disable_fw"
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.9"

  settings = <<SETTINGS
    {
        "commandToExecute": "powershell.exe -Command \"${local.powershell_command_disable_fw}\""
    }
SETTINGS
}