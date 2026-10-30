---
title: Com a identidade de quem o Terraform age
version: 1
---

**O bloco do provider não nomeia credenciais, e não deve.** O provider `azurerm` procura uma identidade numa ordem
fixa e usa a primeira que funciona. Sem nada configurado, ele cai no login da linha de comando do Azure, e é ali que
o laboratório para:

```
ana@laptop:~/azure/tf/shop$ terraform plan -input=false -no-color -var subscription_id=00000000-0000-0000-0000-000000000000 2>&1 | grep -v "^$"
Planning failed. Terraform encountered an error while generating this plan.
Error: unable to build authorizer for Resource Manager API: could not configure AzureCli Authorizer: tenant ID was not specified and the default tenant ID could not be determined: obtaining tenant ID: obtaining account details: running Azure CLI: exit status 1: ERROR: Please run 'az login' to setup account.
  with provider["registry.terraform.io/hashicorp/azurerm"],
  on main.tf line 11, in provider "azurerm":
  11: provider "azurerm" {
```

Leia o erro da direita para a esquerda: a linha de comando disse `Please run 'az login'`, então o provider não achou
um tenant, então não conseguiu montar um autorizador para o Resource Manager, então o plano falhou. **Este é o ponto
mais longe a que o Terraform chega neste laboratório.** `plan` e `apply` não foram executados contra o Azure em parte
nenhuma do curso; tudo daqui em diante sobre eles vem da documentação do provider.

Os jeitos de o provider entrar, e onde cada um cabe:

| como | onde cabe |
|---|---|
| **a linha de comando do Azure**, depois de `az login` | o seu notebook, agindo como você |
| **OIDC**: um token federado, `ARM_USE_OIDC=true` | uma esteira; o mecanismo da lição 2, sem segredo guardado |
| **uma identidade gerenciada**, `ARM_USE_MSI=true` | um agente auto-hospedado ou uma VM rodando dentro do Azure |
| um client secret ou certificado | só onde nenhuma das anteriores é possível |

No workflow do GitHub da loja, o job que roda o Terraform define quatro variáveis e nada secreto:

```sh
export ARM_CLIENT_ID=...          # the app registration, as in lesson 2
export ARM_TENANT_ID=...
export ARM_SUBSCRIPTION_ID=...
export ARM_USE_OIDC=true          # exchange the pipeline's token; no secret
```

A última linha da tabela é a que se evita, por todos os motivos que a lição 2 deu. **Um segredo escrito no bloco do
provider é um segredo no repositório**, e o repositório sobrevive a toda rotação.

A identidade decide o que o Terraform consegue mudar, então vale a mesma regra de qualquer esteira: a identidade que
planeja pull requests só precisa ler, e a que aplica a `main` ganha Contributor nos grupos de recursos que gerencia,
não Owner na assinatura.
