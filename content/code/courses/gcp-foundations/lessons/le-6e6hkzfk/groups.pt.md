---
title: Grupos, escritos
version: 1
---

**Um grupo é o único objeto do diretório que as concessões do IAM devem nomear**, a regra da lição 5, e
um grupo pode ser criado e preenchido pelo Terraform, pela API do Cloud Identity. Isso põe a pergunta
"quem está no `planner-oncall`?" num arquivo que alguém revisa, em vez da memória de um administrador.
Crie um diretório com o arquivo do provider da lição 2:

```sh
mkdir -p ~/gcp/groups && cd ~/gcp/groups
cp ~/gcp/hierarchy/provider.tf .
terraform init -input=false
```

Salve isto como `groups.tf`:

```hcl
locals {
  customer = "customers/C01abcd23" # the directory's customer id, made up for this course
}

resource "google_cloud_identity_group" "oncall" {
  parent       = local.customer
  display_name = "planner on-call"
  description  = "Holds the on-call grants of lessons 7 and 8."

  group_key {
    id = "planner-oncall@example.com"
  }

  # The label that makes this an ordinary mailing-list group in the directory.
  labels = {
    "cloudidentity.googleapis.com/groups.discussion_forum" = ""
  }
}

resource "google_cloud_identity_group_membership" "ana" {
  group = google_cloud_identity_group.oncall.id

  preferred_member_key {
    id = "ana@example.com"
  }

  roles {
    name = "MEMBER"
  }
}
```

Como na lição 4, o plano é salvo com `-out`, e o `terraform show -json` e o `jq` tiram dele os campos que
importam, uma linha por recurso:

```
ana@laptop:~/gcp/groups$ terraform plan -input=false -no-color -out=plan.bin | grep "^Plan:"
Plan: 2 to add, 0 to change, 0 to destroy.
ana@laptop:~/gcp/groups$ terraform show -json plan.bin | jq -c '.resource_changes[] | {address, after: (.change.after | {parent, display_name, group_key, preferred_member_key, roles} | with_entries(select(.value != null)))}'
{"address":"google_cloud_identity_group.oncall","after":{"parent":"customers/C01abcd23","display_name":"planner on-call","group_key":[{"id":"planner-oncall@example.com","namespace":null}]}}
{"address":"google_cloud_identity_group_membership.ana","after":{"preferred_member_key":[{"id":"ana@example.com","namespace":null}],"roles":[{"expiry_detail":[],"name":"MEMBER"}]}}
```

## O que o arquivo diz e um console não diria

- **O pai é o diretório, não um projeto.** `customers/C01abcd23` é o id do próprio diretório, mostrado no
  Admin console. Grupos pertencem à empresa, não a projeto nenhum, e é por isso que sobrevivem a todo
  projeto em que são concedidos.
- **O endereço do grupo é o id dele.** O `planner-oncall@example.com` é o que as políticas do IAM nomeiam,
  então mudar o nome de exibição do grupo não muda nada em política nenhuma, e mudar o endereço quebraria
  toda concessão.
- **Uma participação é um recurso próprio.** Acrescentar a Ana é um bloco; removê-la é apagá-lo, num diff
  que alguém lê. Uma participação também pode ter uma **validade**, a versão do diretório para a concessão
  temporária da lição 7.

**Aplicar isto exige mais que um papel de projeto.** A API do Cloud Identity age sobre o diretório, então
quem chama precisa de um papel de administrador do diretório, e chamá-la com uma conta de serviço exige
que essa conta receba o papel no Admin console, fora do IAM do Google Cloud. A divisão é de propósito:
quem opera projetos não deveria, por ter Owner, conseguir se pôr no `break-glass`.

O plano acima é do provider. Nada chegou ao Google, e o id do cliente é inventado.
