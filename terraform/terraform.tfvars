resource_prefix = "adsec"
node_location   = "northeurope"
node_count      = 2

vmsize = "Standard_D2s_v3"

adminuser = "adminuser"
adminpassword = "P@ssw0rd123!"

active_directory_domain = "contoso.com"
active_directory_netbios_name = "CONTOSO"
domadminuser = "adminuser"
domadminpassword = "P@ssw0rd123!!!"
safemode_password = "P@ssw0rd123!!!"

tags = {
  "Environment" = "lab"
  "Customer" = "lab"
}