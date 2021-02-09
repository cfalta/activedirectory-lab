resource_prefix = "ADLAB"
node_location   = "westeurope"
node_count      = 2

vmsize = "Standard_D2s_v3"

active_directory_domain = "contoso.com"
safemode_password = "P@ssw0rd123!"
active_directory_netbios_name = "CONTOSO"

adminuser = "adminuser"
adminpassword = "P@ssw0rd123!"

tags = {
  "Environment" = "Test"
  "Customer" = "Test"
}