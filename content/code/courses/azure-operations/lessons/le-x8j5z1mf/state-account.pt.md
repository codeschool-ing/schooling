---
title: O estado, num blob só dele
version: 1
---

**No Azure, o estado remoto do Terraform é um blob numa conta de armazenamento.** O backend `azurerm` lê e escreve um
blob por configuração, sob a chave que você der, num contêiner que você criou antes. A conta é a que o
`modules/state.bicep` da lição 5 descreve, com versionamento de blobs e trinta dias de exclusão reversível, e ela mora
num grupo de recursos próprio, `rg-tfstate`, que nenhuma outra configuração gerencia. Essa separação é o ponto: a
configuração que um dia talvez apague `rg-shop` não pode ser a dona do registro do que `rg-shop` contém.

O Azurite faz o papel da conta aqui. Um arquivo de estado real, escrito pelo Terraform para uma configuração com um
recurso `terraform_data` (que não precisa de provider nem de nuvem), enviado para onde o backend o poria:

```
ana@laptop:~/azure/tf/release$ az storage container create --name tfstate -o tsv
True
ana@laptop:~/azure/tf/release$ az storage blob upload --container-name tfstate --name shop.tfstate --file terraform.tfstate --no-progress -o none
ana@laptop:~/azure/tf/release$ az storage blob list --container-name tfstate --query "[].{name:name, size:properties.contentLength}" -o table
Name          Size
------------  ------
shop.tfstate  861
```

O bloco de backend nomeia o mesmo lugar numa assinatura real:

```hcl
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
```

**`use_azuread_auth = true` lê e escreve o blob como a identidade com que o Terraform já entrou**, o que exige o papel
*Storage Blob Data Contributor* na conta. Sem ele, o backend busca a **chave de acesso** da conta e usa essa; quem
consegue listar chaves passa a ler todo arquivo de estado da conta, e o arquivo de estado é onde o Terraform guarda
todo valor que conhece, inclusive os marcados como sensíveis. Por isso a loja desliga de vez o acesso por chave na
conta de estado.

Inicializar com esse backend pede ao Azure o endpoint de armazenamento e falha no laboratório do mesmo jeito que o
`plan`, desta vez citando a API de Storage:

```
ana@laptop:~/azure/tf/shop$ terraform init -input=false -no-color -reconfigure 2>&1 | grep -v "^$" | head -6
Initializing the backend...
Error: unable to build authorizer for Storage API: could not configure AzureCli Authorizer: tenant ID was not specified and the default tenant ID could not be determined: obtaining tenant ID: obtaining account details: running Azure CLI: exit status 1: ERROR: Please run 'az login' to setup account.
```

Vale ver as duas falhas lado a lado: estado e recursos são alcançados por duas APIs diferentes, com dois papéis
diferentes, e uma identidade pode ter um e não o outro.
