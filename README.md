# ActiveDirectory Lab

This repository contains resources to quickly create an Active Directory lab in Azure to demonstrate common security flaws in an Active Directory domain. Terraform is used to automatically promote the DC and join the member server.

## Contents

### terraform
- main.tf
  - the main terraform config file (don't edit unless you know what u are doing)
- variables.tf
  - definition of all variables used in main.tf (you don't want to edit this too)
- terraform.tfvars
  - use this file to set the variables defined in variables.tf. That's the file you want to edit :-)
  
### scripts

## Usage

The easiest way to use terraform in Azure is through azure cloud shell, since it already includes terraform and you don't have to create an extra security principal for terraform to interact with your tenant. This is a good thing, espescially since we are talking about directory security here - a secure service account is the one we never create ;-)

So open cloudshell from the azure portal and clone the repository.

```
git clone https://github.com/cfalta/activedirectory-lab
cd ./activedirectory-lab/terraform/
```

Make sure you are okay with the defaults (Azure location, VM size, admin user and password...)

```
code ./terraform.tfvars
```

And when you're ready: initialize terraform and apply - thats it :-)

```
terraform init
terraform validate
terraform plan
terraform apply
```

Note:

- init = initialize terraform (azure provider)
- validate = make sure there are no syntax errors in the config
- plan = shows you what will happen if you run apply
- apply = create the resources

If you are done playing with AD, just run the following to remove all resources.

terraform destroy