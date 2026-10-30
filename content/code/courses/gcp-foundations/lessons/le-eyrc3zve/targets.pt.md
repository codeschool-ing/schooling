---
title: Alvos: tags ou contas de serviço
version: 1
---

**Uma regra nomeia as máquinas dela de um de três jeitos**: todas as máquinas da rede, as máquinas que têm uma
**tag de rede**, ou as máquinas que rodam como uma **conta de serviço**. Os mesmos três, menos *todas*, nomeiam
as origens de uma regra de entrada quando o tráfego vem de dentro da rede. Qual deles uma empresa usa é uma
decisão de segurança, não de gosto.

| | uma tag de rede | uma conta de serviço |
|---|---|---|
| o que é | uma palavra na máquina, como `web` | a identidade com que a máquina roda, lição 8 |
| quem pode pô-la numa máquina | **quem pode editar a máquina** | quem tem `roles/iam.serviceAccountUser` naquela conta |
| o que ela já significa | nada mais | tudo o que a conta pode fazer no IAM |

A diferença está na segunda linha. **Uma tag é uma palavra que qualquer um que edite a máquina pode pôr**, e
pôr `db` numa máquina abre para ela toda regra que tem `db` como alvo. Prender uma conta de serviço exige um
papel na própria conta, a mesma permissão de agir como de que a lição 8 avisou, então uma regra com alvo em
`db@` não pode ser ampliada por alguém que só edita instâncias. O planner usa contas de serviço para toda regra
que deixa algo entrar, e tags só para regras que tiram algo, em que uma tag mal posta só pode deixar uma
máquina mais difícil de alcançar.

## Escrevendo uma

Em `~/gcp/firewall`, com o arquivo do provider da lição 2:

```sh
mkdir -p ~/gcp/firewall && cd ~/gcp/firewall
cp ~/gcp/hierarchy/provider.tf .
terraform init -input=false
```

Salve isto como `firewall.tf`. Ela deixa as máquinas web alcançarem o banco na 5432, e tem dois erros:

```hcl
resource "google_compute_firewall" "web_to_db" {
  project  = "planner-dev"
  name     = "allow-web-to-db"
  network  = "planner"
  priority = 70000

  allow {
    protocol = "tcp"
    ports    = ["5432"]
  }

  source_tags             = ["web"]
  target_service_accounts = ["db@planner-dev.iam.gserviceaccount.com"]
}
```

```
ana@laptop:~/gcp/firewall$ terraform plan -input=false -no-color 2>&1 | grep -E "^Error|conflicts"
Error: expected priority to be in the range (0 - 65535), got 70000
Error: Conflicting configuration arguments
"source_tags": conflicts with target_service_accounts
Error: Conflicting configuration arguments
"target_service_accounts": conflicts with source_tags
```

**O provider recusa os dois antes de perguntar ao Google.** Uma prioridade para em 65535. E uma regra pode
nomear as máquinas por tags ou por contas de serviço, nunca pelos dois: uma origem por tag com um alvo por
conta mistura os dois jeitos de nomear, o que a API do Google recusa e o provider sabe que ela recusa. Nomeie
a origem pela conta também. Substitua o `firewall.tf` por isto:

```hcl
resource "google_compute_firewall" "web_to_db" {
  project = "planner-dev"
  name    = "allow-web-to-db"
  network = "planner"

  allow {
    protocol = "tcp"
    ports    = ["5432"]
  }

  source_service_accounts = ["web@planner-dev.iam.gserviceaccount.com"]
  target_service_accounts = ["db@planner-dev.iam.gserviceaccount.com"]
}
```

```
ana@laptop:~/gcp/firewall$ terraform plan -input=false -no-color | grep -E "^Plan|priority|direction"
      + direction               = (known after apply)
      + priority                = 1000
Plan: 1 to add, 0 to change, 0 to destroy.
```

Prioridade 1000, o padrão, já que o arquivo não diz mais uma. A direção está *known after apply*: o arquivo
também não diz uma, e o Google preenche `INGRESS` quando cria a regra. Planejado, não criado; a rede `planner` é
a que a lição 15 planejou e ninguém fez.

**Uma regra nomeia uma origem pela conta, não pelo endereço.** O banco não fica sabendo que 10.10.0.5 pode se
conectar; fica sabendo que o que roda como `web@` pode, onde quer que esteja na rede e qualquer que seja o
endereço dele hoje. Máquinas vêm e vão com endereços novos, e uma regra escrita em endereços dá errado na
primeira vez que uma delas é trocada.
