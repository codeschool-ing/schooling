---
title: Autoritativo ou aditivo: três recursos do Terraform para uma política
version: 1
---

Como uma política é substituída inteira, uma ferramenta que a gerencia precisa decidir **quanto da
política é dela**. O provider do Google para o Terraform oferece três respostas, com três recursos, e
escolher o errado é o jeito mais comum de uma execução do Terraform tirar o acesso de alguém:

| recurso | é dono de | o que faz com todo o resto |
|---|---|---|
| `google_project_iam_policy` | a **política inteira** | remove toda vinculação que o arquivo não nomeia, a dos owners inclusive |
| `google_project_iam_binding` | **um papel** | define exatamente a lista de membros desse papel; remove quem mais o tiver |
| `google_project_iam_member` | **um principal num papel** | acrescenta, e não mexe em mais nada |

Os dois primeiros são **autoritativos**: o que o arquivo diz é a verdade inteira sobre o que eles
possuem. O terceiro é **aditivo**: só promete que uma concessão existe. Os mesmos três existem para
pastas, organizações, contas de serviço, tópicos e a maioria dos recursos, com os mesmos nomes depois do
nome do próprio recurso.

## Vendo a diferença num plano

Crie um diretório com o arquivo do provider da lição 2:

```sh
mkdir -p ~/gcp/policy && cd ~/gcp/policy
cp ~/gcp/hierarchy/provider.tf .
terraform init -input=false
```

Salve isto como `iam.tf`. Ele concede Viewer duas vezes, uma de forma autoritativa e outra aditiva, em
dois projetos que só existem no papel:

```hcl
# Authoritative for one role on planner-staging: after an apply, these two
# are the only Viewers, whoever else held the role before.
resource "google_project_iam_binding" "staging_viewers" {
  project = "planner-staging"
  role    = "roles/viewer"
  members = [
    "group:planner-devs@example.com",
    "group:planner-oncall@example.com",
  ]
}

# Additive on planner-dev: Ana holds Viewer, and every other Viewer stays.
resource "google_project_iam_member" "dev_viewer_ana" {
  project = "planner-dev"
  role    = "roles/viewer"
  member  = "user:ana@example.com"
}
```

```
ana@laptop:~/gcp/policy$ terraform plan -input=false -no-color | sed -n '/# google/,/^    }/p'
  # google_project_iam_binding.staging_viewers will be created
  + resource "google_project_iam_binding" "staging_viewers" {
      + etag    = (known after apply)
      + id      = (known after apply)
      + members = [
          + "group:planner-devs@example.com",
          + "group:planner-oncall@example.com",
        ]
      + project = "planner-staging"
      + role    = "roles/viewer"
    }
  # google_project_iam_member.dev_viewer_ana will be created
  + resource "google_project_iam_member" "dev_viewer_ana" {
      + etag    = (known after apply)
      + id      = (known after apply)
      + member  = "user:ana@example.com"
      + project = "planner-dev"
      + role    = "roles/viewer"
    }
```

**Os dois planos parecem iguais, e esse é o perigo.** Os dois dizem `will be created`, os dois listam
membros. Nada no plano diz que a vinculação, no apply, removeria um terceiro Viewer que alguém concedeu
à mão no mês passado, porque o Terraform não sabe que esse Viewer existe até ler a política no Google. A
diferença está no nome do recurso, e o nome é o que se deve ler. Os dois levam um `etag` que é
`(known after apply)`: o provider lê a política, e o etag dela, no momento em que grava, que é o
ler-mudar-gravar da seção anterior feito no seu lugar.

## As regras que mantêm uma equipe segura

- **Nunca misture o recurso autoritativo e o aditivo para o mesmo papel no mesmo recurso.** Um
  `google_project_iam_binding` para Viewer e um `google_project_iam_member` para Viewer num projeto brigam
  a cada apply: um acrescenta a Ana, o outro a remove, e o plano nunca se acomoda.
- **Use o `google_project_iam_policy` quase nunca.** Ele é dono dos owners. Um arquivo que esqueça de
  listá-los os remove, e com eles as pessoas que poderiam recolocá-los. A documentação do provider do
  Google diz o mesmo, em letras maiúsculas.
- **Prefira `_member` onde pessoas também concedem à mão, e `_binding` onde o Terraform é o único
  autor.** Um papel cujos membros devem ser exatamente os do arquivo, como o Owner da produção, é o caso
  do `_binding`: o que for acrescentado à mão é removido no apply seguinte, e é essa a ideia.

O plano é do provider, rodado no notebook. O que o apply removeria depende da política que o Google tem
hoje, e só um apply contra um projeto real consegue mostrar isso.
