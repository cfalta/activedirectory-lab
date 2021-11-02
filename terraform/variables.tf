## General stuff
# prefix for your lab, this will be prepended to all resources

variable "resource_prefix" {
  type = string
}

# tags to apply to all resources

variable "tags" {
  description = "Tags to apply on resource"
  type        = map(string)
}

## Variables for DC
# azure location for dc

variable "node_location_dc" {
  type = string
}

# vnet address space

variable "node_address_space_dc" {
  default = ["10.100.0.0/16"]
}

# subnet range

variable "node_address_prefix_dc" {
  default = "10.100.100.0/24"
}

variable "vmsize_dc" {
  type = string
}

## Variables for member server
# azure location for member server

variable "node_location_member" {
  type = string
}

# vnet address space

variable "node_address_space_member" {
  default = ["10.200.0.0/16"]
}

# subnet range

variable "node_address_prefix_member" {
  default = "10.200.200.0/24"
}

variable "vmsize_member" {
  type = string
}


# how many vms to create

variable "node_count" {
  type = number
}

# local admin credentials

variable "adminpassword" {
  type = string
}

variable "adminuser" {
  type = string
}


## Active Directory 

#fqdn of the domain

variable "active_directory_domain" {
  type = string
  description = "The name of the Active Directory domain, for example `consoto.local`"
}

#safemode password

variable "safemode_password" {
  type = string
  description = "The password associated with the local administrator account on the virtual machine"
}

#netbios name of the domain

variable "active_directory_netbios_name" {
  type = string
  description = "The netbios name of the Active Directory domain, for example `consoto`"
}

#Password for the default domain admin
variable "domadminpassword" {
  type = string
}

#Username for the default domain admin
variable "domadminuser" {
  type = string
}
