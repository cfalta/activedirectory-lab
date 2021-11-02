resource_prefix = "adsec"

node_location_dc   = "northeurope"
vmsize_dc = "Standard_D2s_v3"
active_directory_domain = "contoso.com"
active_directory_netbios_name = "CONTOSO"
domadminuser = "adminuser"
domadminpassword = "P@ssw0rd123!!!"
safemode_password = "P@ssw0rd123!!!"

node_location_member = "westeurope"
vmsize_member = "Standard_D2s_v3"
node_count = 2
adminuser = "adminuser"
adminpassword = "P@ssw0rd123!"

tags = {
  "Environment" = "lab"
  "Customer" = "lab"
}