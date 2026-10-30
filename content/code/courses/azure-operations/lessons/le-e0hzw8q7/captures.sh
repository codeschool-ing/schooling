#!/usr/bin/env bash
# The terminal sessions quoted in lesson 7 of azure-operations, as a script that
# produces them. Its output is not committed; every transcript was copied from it.
#
#   bash lab.sh student && bash lab.sh tools   # once
#   bash captures.sh
#
# STAGED: the state is the real one `terraform apply` writes for lesson 6's
# terraform_data configuration, rebuilt here. The two accidents are typed on
# purpose. Azurite implements snapshots and not soft delete or versioning, and
# block no-undelete records its refusal. `terraform plan` runs against the local
# terraform_data configuration only: nothing here reaches Azure.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"
student_env
azurite_up
rm -rf "$HOME/azure/tf/release" && mkdir -p "$HOME/azure/tf/release" && cd "$HOME/azure/tf/release" || exit 1
cat > main.tf <<'HCL'
# main.tf
resource "terraform_data" "release" {
  input = "v42"
}
HCL
quiet 'terraform init -input=false -no-color'
quiet 'terraform apply -auto-approve -input=false -no-color'
quiet 'az storage container create --name tfstate'
quiet 'az storage blob upload --container-name tfstate --name shop.tfstate --file terraform.tfstate --no-progress'

block plan-before
run 'terraform plan -no-color | grep -m1 "No changes"'

block snapshot
run 'az storage blob snapshot --container-name tfstate --name shop.tfstate --query snapshot -o tsv'
SNAP=$(az storage blob list --container-name tfstate --include s --query "[?snapshot].snapshot | [0]" -o tsv)

block overwrite
run "echo '{\"version\": 4, \"serial\": 1, \"resources\": []}' > empty.tfstate"
run 'az storage blob upload --container-name tfstate --name shop.tfstate --file empty.tfstate --overwrite --no-progress -o none'
run 'az storage blob list --container-name tfstate --include s --query "[].{snapshot:snapshot, size:properties.contentLength}" -o table'

block what-terraform-sees
run 'cp terraform.tfstate saved.tfstate && cp empty.tfstate terraform.tfstate'
run 'terraform plan -no-color | grep -E "will be created|Plan:"'

block restore
run "az storage blob download --container-name tfstate --name shop.tfstate --snapshot $SNAP --file restored.tfstate --no-progress -o none"
run "jq '{serial, lineage, resources: [.resources[].type]}' restored.tfstate"
run 'az storage blob upload --container-name tfstate --name shop.tfstate --file restored.tfstate --overwrite --no-progress -o none'
run 'cp restored.tfstate terraform.tfstate && terraform plan -no-color | grep -m1 "No changes"'

block delete
run 'az storage blob delete --container-name tfstate --name shop.tfstate --delete-snapshots include'
run 'az storage blob list --container-name tfstate --include s -o tsv | wc -l'

block no-undelete
run 'az storage blob undelete --container-name tfstate --name shop.tfstate 2>&1 | grep -E "ErrorCode"'
lab_down
