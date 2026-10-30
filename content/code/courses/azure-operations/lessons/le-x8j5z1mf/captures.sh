#!/usr/bin/env bash
# The terminal sessions quoted in lesson 6 of azure-operations, as a script that
# produces them. Its output is not committed; every transcript was copied from it.
#
#   bash lab.sh student && bash lab.sh tools   # once
#   bash captures.sh
#
# The azurerm provider comes from registry.terraform.io. `terraform plan` and
# `terraform init` with the azurerm backend are run on purpose without any
# Azure credentials, to record where each stops. The state blob and its lease
# are in Azurite: the lease commands are the ones the backend itself issues.
# The state file uploaded is a real one, written by `terraform apply` of a
# configuration with one terraform_data resource, which needs no provider.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"
student_env
unset ARM_SUBSCRIPTION_ID ARM_CLIENT_ID ARM_TENANT_ID ARM_USE_OIDC
azurite_up
rm -rf "$HOME/azure/tf" && mkdir -p "$HOME/azure/tf/shop" && cd "$HOME/azure/tf/shop" || exit 1

block version
run 'terraform version'

put main.tf <<'HCL'
# main.tf
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "5.12.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

variable "subscription_id" {
  type = string
}

resource "azurerm_resource_group" "shop" {
  name     = "rg-shop"
  location = "brazilsouth"
  tags = {
    team       = "shop"
    managed-by = "terraform"
  }
}
HCL

block init
run 'terraform init -input=false -no-color'
run 'du -sh .terraform'
run 'cat .terraform.lock.hcl | head -5'

block validate
run 'terraform validate -no-color'
run 'terraform fmt -check; echo "exit status $?"'

block plan
run 'terraform plan -input=false -no-color -var subscription_id=00000000-0000-0000-0000-000000000000 2>&1 | grep -v "^$"'

# ---- the state's home, in Azurite ------------------------------------------
mkdir -p "$HOME/azure/tf/release" && cd "$HOME/azure/tf/release" || exit 1
put main.tf <<'HCL'
# main.tf
resource "terraform_data" "release" {
  input = "v42"
}
HCL
quiet 'terraform init -input=false -no-color'
quiet 'terraform apply -auto-approve -input=false -no-color'

block container
run 'az storage container create --name tfstate -o tsv'
run 'az storage blob upload --container-name tfstate --name shop.tfstate --file terraform.tfstate --no-progress -o none'
run 'az storage blob list --container-name tfstate --query "[].{name:name, size:properties.contentLength}" -o table'

block lease
run 'az storage blob lease acquire --container-name tfstate --blob-name shop.tfstate --lease-duration -1 -o tsv'
run 'az storage blob show --container-name tfstate --name shop.tfstate --query properties.lease -o json'
run 'az storage blob lease acquire --container-name tfstate --blob-name shop.tfstate --lease-duration -1 -o tsv 2>&1 | grep -E "ErrorCode|already"'
run 'az storage blob upload --container-name tfstate --name shop.tfstate --file terraform.tfstate --overwrite --no-progress -o none 2>&1 | grep -E "ErrorCode|lease"'

block break
run 'az storage blob lease break --container-name tfstate --blob-name shop.tfstate --lease-break-period 0 -o tsv'
run 'az storage blob show --container-name tfstate --name shop.tfstate --query properties.lease.state -o tsv'

cd "$HOME/azure/tf/shop" || exit 1
put backend.tf <<'HCL'
# backend.tf
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "stshoptfstate"
    container_name       = "tfstate"
    key                  = "shop.tfstate"
    use_azuread_auth     = true
  }
}
HCL
block backend
run 'terraform init -input=false -no-color -reconfigure 2>&1 | grep -v "^$" | head -6'
lab_down
