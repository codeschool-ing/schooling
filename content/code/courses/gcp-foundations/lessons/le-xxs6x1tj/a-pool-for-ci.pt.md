---
title: Um pool para o CI do planner, escrito e planejado
version: 1
---

O repositório do planner é o `example/planner` no GitHub, e o workflow de deploy dele deve rodar o
Terraform como o deployer da lição 8, só a partir da branch `main`, sem chave em lugar nenhum. Três
recursos fazem isso: um pool, um provider para o GitHub, e uma concessão que deixa as identidades certas
do pool agirem como o deployer. Crie um diretório com o arquivo do provider da lição 2:

```sh
mkdir -p ~/gcp/federation && cd ~/gcp/federation
cp ~/gcp/hierarchy/provider.tf .
terraform init -input=false
```

Um primeiro rascunho do `pool.tf` chama o pool de `ci`:

```hcl
resource "google_iam_workload_identity_pool" "ci" {
  workload_identity_pool_id = "ci"
  display_name              = "CI"
}
```

```
ana@laptop:~/gcp/federation$ terraform validate -no-color

Error: "workload_identity_pool_id" cannot be smaller than 4 characters

  with google_iam_workload_identity_pool.ci,
  on pool.tf line 2, in resource "google_iam_workload_identity_pool" "ci":
   2:   workload_identity_pool_id = "ci"
```

**Um id de pool tem de quatro a trinta e dois caracteres**, letras minúsculas, dígitos e hífens. O arquivo
completo o chama de `ci-pool` e acrescenta o resto:

```hcl
resource "google_iam_workload_identity_pool" "ci" {
  workload_identity_pool_id = "ci-pool"
  display_name              = "CI"
}

resource "google_iam_workload_identity_pool_provider" "github" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.ci.workload_identity_pool_id
  workload_identity_pool_provider_id = "github"
  display_name                       = "GitHub Actions"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
    "attribute.ref"        = "assertion.ref"
  }

  # The lock: only tokens from repositories of the example organisation.
  attribute_condition = "assertion.repository_owner == 'example'"
}

# The second lock: only the planner repository may act as the deployer.
resource "google_service_account_iam_member" "ci_acts_as_deployer" {
  service_account_id = "projects/planner-dev/serviceAccounts/deployer@planner-dev.iam.gserviceaccount.com"
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.ci.name}/attribute.repository/example/planner"
}
```

```
ana@laptop:~/gcp/federation$ terraform plan -input=false -no-color | grep -E '^  # |attribute_condition|issuer_uri|      \+ role|^Plan:'
  # google_iam_workload_identity_pool.ci will be created
  # google_iam_workload_identity_pool_provider.github will be created
      + attribute_condition                = "assertion.repository_owner == 'example'"
          + issuer_uri = "https://token.actions.githubusercontent.com"
  # google_service_account_iam_member.ci_acts_as_deployer will be created
      + role               = "roles/iam.workloadIdentityUser"
Plan: 3 to add, 0 to change, 0 to destroy.
```

## Lendo o que foi planejado

- **O mapeamento nomeia as afirmações** que este provider vai transformar em atributos. O `assertion.sub`
  do GitHub tem a forma `repo:example/planner:ref:refs/heads/main`, então o `google.subject` é único por
  repositório e branch.
- **A condição** recusa todo token cujo repositório pertença a outra organização, antes de qualquer papel
  ser lido.
- **A concessão é `roles/iam.workloadIdentityUser`**, não o Token Creator. É o papel que deixa uma
  identidade federada personificar uma conta de serviço, e ele é concedido no deployer, ao conjunto de
  identidades cujo atributo `repository` é `example/planner`.

**Ainda falta uma tranca**, e o plano não consegue apontá-la: qualquer branch do `example/planner`,
inclusive uma branch que um colaborador de fora abriu num pull request, bate com esse `principalSet`.
Restringi-lo à `main` é uma condição mais estrita, `assertion.repository == 'example/planner' &&
assertion.ref == 'refs/heads/main'`, ou uma concessão ao único `principal://` cujo subject nomeia a
`main`. Qual dos dois uma equipe escolhe é uma escolha de desenho; deixar a brecha aberta não é.

O plano é do provider. Se o emissor do GitHub responde, se o id do pool está livre no projeto e se o
deployer existe são perguntas do Google, feitas só no apply.
