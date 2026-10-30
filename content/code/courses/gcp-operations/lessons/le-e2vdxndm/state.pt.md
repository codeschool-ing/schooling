---
title: Por que o valor nunca passa pelo Terraform
version: 1
---

**Tudo o que o Terraform gerencia é escrito no estado dele, em texto puro, seja qual for o nome que a configuração
dá.** `sensitive = true` esconde um valor da saída do plano e do terminal; não o criptografa no estado. Um
`google_secret_manager_secret_version` com `secret_data` no Terraform põe, portanto, a senha no arquivo de estado, e
o bucket de estado da lição 6 vira uma segunda cópia de todo segredo, legível por todos que leem o estado. Você
pode ver isso no seu computador sem o Google: o `terraform_data`, embutido no Terraform, guarda o que recebe, como
qualquer recurso guardaria. Escreva isto em `~/gcp/tf/leak/main.tf`:

```hcl
# tf/leak/main.tf
variable "db_password" {
  type      = string
  sensitive = true
}

resource "terraform_data" "connection" {
  input = "postgres://shop:${var.db_password}@10.0.0.5/shop"
}

output "connection" {
  value     = terraform_data.connection.output
  sensitive = true
}
```

Aplique com uma senha de treino, do jeito que uma esteira passaria uma real:

```
ana@laptop:~/gcp/tf/leak$ TF_VAR_db_password=k7-practice-only-9f terraform apply -auto-approve -input=false -no-color | grep -E "connection|Apply"
  # terraform_data.connection will be created
  + resource "terraform_data" "connection" {
  + connection = (sensitive value)
terraform_data.connection: Creating...
terraform_data.connection: Creation complete after 0s [id=63dedcf4-bd79-86d0-19fa-56ccb0240b0f]
Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
connection = <sensitive>
```

Tudo na tela diz `(sensitive value)` e `<sensitive>`. Agora peça a saída pelo nome, e olhe no estado:

```
ana@laptop:~/gcp/tf/leak$ terraform output connection
"postgres://shop:k7-practice-only-9f@10.0.0.5/shop"
ana@laptop:~/gcp/tf/leak$ grep -c k7-practice-only-9f terraform.tfstate
3
ana@laptop:~/gcp/tf/leak$ jq -r '.resources[0].instances[0].attributes.input.value' terraform.tfstate
postgres://shop:k7-practice-only-9f@10.0.0.5/shop
```

**A senha está no estado três vezes**, e um comando a imprime. `sensitive` é uma promessa sobre o terminal, não
sobre o arquivo. Levar o estado para um bucket (lição 6) leva a senha junto, e a lição 12 de `iac` é a regra geral
da qual este é um caso.

Então o arranjo da loja tem duas metades. O Terraform cria o **segredo**, a replicação, a rotação e o IAM dele,
nada disso secreto. Uma pessoa ou um job de rotação acrescenta as **versões** com `gcloud secrets versions add`,
lendo o valor da entrada padrão. O valor vive no Secret Manager e em mais lugar nenhum, e o estado guarda só o nome
do segredo.

Apague `~/gcp/tf/leak` depois de ler. Um arquivo com uma senha dentro é um arquivo que alguém copia.
