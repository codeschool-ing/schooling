---
title: Identidades de fora, e todo tipo escrito
version: 1
---

**O último tipo de principal vem do diretório de outra pessoa.** Uma empresa cujo pessoal entra com o
Microsoft Entra ID ou o Okta, e um sistema de CI como o GitHub Actions cujos jobs levam um token
assinado, podem ganhar a confiança do Google Cloud sem que exista conta Google nenhuma para eles. O
Google chama isso de **federação**, e escreve os principals que ela produz com um prefixo mais longo:

| escrito como | o que é |
|---|---|
| `principal://iam.googleapis.com/locations/global/workforcePools/staff/subject/ana@example.com` | uma pessoa de um provedor de identidade de fora, por um pool de **workforce** |
| `principalSet://iam.googleapis.com/locations/global/workforcePools/staff/group/planner-devs` | um grupo desse provedor |
| `principal://iam.googleapis.com/projects/415104041262/locations/global/workloadIdentityPools/ci-pool/subject/repo:example/planner:ref:refs/heads/main` | um workload de fora, por um pool de **workload** |
| `principalSet://iam.googleapis.com/projects/415104041262/locations/global/workloadIdentityPools/ci-pool/attribute.repository/example/planner` | todo workload cujo token diz que veio de um repositório |

Duas palavras a separar: um pool de **workforce** é para pessoas, e mora na organização; um pool de
**workload** é para programas, e mora num projeto. A lição 9 monta um pool de workload para o CI do
planner, e a lição 10 diz quando um pool de workforce é a resposta certa para pessoas. Aqui, o ponto é só
que **estes são principals como quaisquer outros**: um papel é concedido a um deles exatamente como a um
`user:` ou um `group:`, e o nome comprido é o preço de dizer com precisão que identidade de fora se quer.

## Todo tipo, conferido pelo provider

Nenhuma dessas identidades existe no laboratório, mas todas podem ser escritas numa política e
conferidas. Crie um diretório com o arquivo do provider da lição 2:

```sh
mkdir -p ~/gcp/principals && cd ~/gcp/principals
cp ~/gcp/hierarchy/provider.tf .
terraform init -input=false
```

Uma primeira tentativa de dar um papel à Ana, salva como `grants.tf`, esquece o prefixo:

```hcl
resource "google_project_iam_member" "ana" {
  project = "planner-dev"
  role    = "roles/viewer"
  member  = "ana@example.com"
}
```

```
ana@laptop:~/gcp/principals$ terraform validate -no-color

Error: invalid value "ana@example.com" for member (IAM members must have one of the values outlined here: https://cloud.google.com/billing/docs/reference/rest/v1/Policy#Binding)

  with google_project_iam_member.ana,
  on grants.tf line 4, in resource "google_project_iam_member" "ana":
   4:   member  = "ana@example.com"
```

**O provider recusou um endereço sem tipo.** `ana@example.com` poderia ser uma pessoa ou um grupo, e o
IAM não adivinha. O arquivo completo concede um papel a um principal de cada tipo:

```hcl
locals {
  project = "planner-dev"
  pool    = "projects/415104041262/locations/global/workloadIdentityPools/ci-pool"
}

resource "google_project_iam_member" "grants" {
  for_each = {
    person   = "user:ana@example.com"
    group    = "group:planner-devs@example.com"
    domain   = "domain:example.com"
    workload = "serviceAccount:reports@planner-dev.iam.gserviceaccount.com"
    outside  = "principalSet://iam.googleapis.com/${local.pool}/attribute.repository/example/planner"
  }
  project = local.project
  role    = "roles/viewer"
  member  = each.value
}
```

O `for_each` cria um recurso por entrada do mapa, cada um com o próprio nome, para que uma concessão
possa ser acrescentada ou removida sem mexer nas outras:

```
ana@laptop:~/gcp/principals$ terraform plan -input=false -no-color | grep -E '^  # |^Plan:'
  # google_project_iam_member.grants["domain"] will be created
  # google_project_iam_member.grants["group"] will be created
  # google_project_iam_member.grants["outside"] will be created
  # google_project_iam_member.grants["person"] will be created
  # google_project_iam_member.grants["workload"] will be created
Plan: 5 to add, 0 to change, 0 to destroy.
```

**Cinco concessões, uma por tipo de principal, e toda uma seria recusada se aplicada**: não só pelo
token placeholder, mas porque nenhuma dessas identidades existe. O Google confere, no momento de uma
concessão, que um `user:`, `group:` ou `serviceAccount:` nomeia algo real, e o número do pool de workload
foi inventado para este curso. O provider conferiu a forma; só o Google confere a substância.
