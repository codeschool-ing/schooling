---
title: GitHub Actions, e o único script que ele chama
version: 2
---

**Este workflow não foi executado para esta aula.** Rodá-lo exige uma conta no GitHub, que este curso
nunca pede. Então o arquivo abaixo, `.github/workflows/terraform.yml` no `~/shop`, está escrito como
seria commitado e conferido só até onde um parser de YAML consegue conferir, na seção 05. Cada passo
dele chama o `ci.sh`, e o `ci.sh` roda de verdade mais abaixo. Se você tem uma conta e quer
experimentar, o plano gratuito do GitHub roda workflows; a metade da AWS precisa então de uma conta
de verdade, como a aula 1 descreve, e dos roles da seção 06.

```yaml
# Illustrative: written for lesson 15 and never run by it. Every step calls
# ci.sh, which the lesson does run.
name: terraform

on:
  pull_request:
    branches: [main]
  push:
    branches: [main]

permissions:
  contents: read

concurrency:
  group: terraform-${{ github.ref }}
  cancel-in-progress: false

jobs:
  check:
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
      - uses: hashicorp/setup-terraform@dfe3c3f87815947d99a8997f908cb6525fc44e9e # v4.0.1
        with:
          terraform_version: 1.16.4
          terraform_wrapper: false
      - uses: aquasecurity/setup-trivy@81e514348e19b6112ce2a7e3ecbafe19c1e1f567 # v0.3.1
        with:
          version: v0.75.0
      - run: ./ci.sh check
      - run: ./ci.sh scan

  plan:
    needs: check
    runs-on: ubuntu-24.04
    permissions:
      contents: read
      id-token: write
      pull-requests: write
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
      - uses: hashicorp/setup-terraform@dfe3c3f87815947d99a8997f908cb6525fc44e9e # v4.0.1
        with:
          terraform_version: 1.16.4
          terraform_wrapper: false
      - uses: aws-actions/configure-aws-credentials@e1253824e5c10ff9df46874f81ed3ec929e19cfd # v6.3.0
        with:
          role-to-assume: arn:aws:iam::123456789012:role/shop-plan
          aws-region: sa-east-1
      - run: ./ci.sh plan
      - if: github.event_name == 'pull_request'
        env:
          GH_TOKEN: ${{ github.token }}
          PR: ${{ github.event.pull_request.number }}
        run: |
          { echo '~~~'; cat plan.txt; echo '~~~'; } > comment.md
          gh pr comment "$PR" --body-file comment.md
      - if: github.event_name == 'push'
        uses: actions/upload-artifact@043fb46d1a93c77aae656e7c1c64a875d1fc6a0a # v7.0.1
        with:
          name: tfplan
          path: tfplan
          retention-days: 3

  apply:
    if: github.event_name == 'push'
    needs: plan
    runs-on: ubuntu-24.04
    environment: production
    permissions:
      contents: read
      id-token: write
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
      - uses: hashicorp/setup-terraform@dfe3c3f87815947d99a8997f908cb6525fc44e9e # v4.0.1
        with:
          terraform_version: 1.16.4
          terraform_wrapper: false
      - uses: aws-actions/configure-aws-credentials@e1253824e5c10ff9df46874f81ed3ec929e19cfd # v6.3.0
        with:
          role-to-assume: arn:aws:iam::123456789012:role/shop-apply
          aws-region: sa-east-1
      - uses: actions/download-artifact@3e5f45b2cfb9172054b4087a40e8e0b5a5461e7c # v8.0.1
        with:
          name: tfplan
      - run: ./ci.sh apply
```

Leia de cima para baixo. Ele roda num pull request contra a `main` e num push na `main`, o que numa
branch protegida quer dizer um merge. O `permissions` do topo dá a cada job um token que só lê o
repositório; os jobs que precisam de mais pedem por conta própria. Depois vêm três jobs, ligados
por `needs`: o `check` roda sempre, o `plan` só depois que o `check` passou, e o `apply` só depois do
`plan` e só num push. Num pull request, o plan é publicado como comentário e a execução termina ali.
Na `main`, o arquivo salvo sobe como artefato e o `apply` espera pelo environment `production`, que
é onde mora a aprovação; a seção sobre aplicar o plan volta a ele.

**Cada action está fixada num commit, com a tag de origem ao lado.** Uma tag como `v7` é um nome
que o dono da action pode mover para outro código a qualquer momento, e esse código passa a rodar
com as suas credenciais. Um commit não se move. Os seis commits deste arquivo são aqueles para os
quais as tags apontavam em 2 de outubro de 2026, lidos de cada repositório com `git ls-remote`. O
comentário é o que torna o pin legível para quem, mais tarde, decidir que ele envelheceu. O
`terraform_version` fixa o próprio Terraform na versão que este curso usa, e
`terraform_wrapper: false` desliga um wrapper que a action instala em volta do binário e de que
este pipeline não precisa.

## Os passos moram num script

O workflow decide quando cada estágio roda e com quais credenciais. O que um estágio faz está
escrito uma vez só, num script que o repositório carrega, o `ci.sh`:

```sh
#!/bin/sh
# The pipeline's steps, written once. The workflow files decide when each
# stage runs and with which credentials; what a stage does is written here,
# so a laptop can run exactly what a runner runs.
set -eux
export TF_IN_AUTOMATION=1

case "$1" in
check)
  terraform fmt -check -recursive
  terraform init -input=false -backend=false
  terraform validate
  ;;
scan)
  trivy config --quiet --skip-check-update \
    --severity HIGH,CRITICAL --exit-code 1 .
  ;;
plan)
  terraform init -input=false
  terraform plan -input=false -lock-timeout=5m \
    -var-file=prod.tfvars -out=tfplan
  terraform show -no-color tfplan > plan.txt
  ;;
apply)
  terraform init -input=false
  terraform apply -input=false -lock-timeout=5m tfplan
  ;;
esac
```

Essa divisão é o que permite rodar os mesmos passos num laptop, no GitHub e no GitLab sem três
cópias se afastando umas das outras, e é o que permite a esta aula mostrar o que cada passo
imprime.

Antes da primeira execução, a Ana torna o script executável, inicializa o `~/shop` para que o lock
file exista, e faz o primeiro commit e o push. Salve antes o `.gitlab-ci.yml` da seção 05, para que o
commit tenha todos os arquivos, e então, no `~/shop`:

```sh
chmod +x ci.sh
terraform init -input=false
git add -A && git commit -qm "shop: network and pipeline" && git push -q origin main
```

Aqui está o pipeline desse commit, num clone novo que faz o papel do runner, feito a partir do seu
diretório home:

```
ana@laptop:~$ git clone -q git/shop.git ci/run-1
ana@laptop:~/ci/run-1$ git log --oneline -1
7bb05b9 shop: network and pipeline
```

```
ana@laptop:~/ci/run-1$ ./ci.sh check
+ export TF_IN_AUTOMATION=1
+ terraform fmt -check -recursive
+ terraform init -input=false -backend=false
Initializing provider plugins...
- Reusing previous version of hashicorp/aws from the dependency lock file
- Installing hashicorp/aws v6.67.0...
- Installed hashicorp/aws v6.67.0 (unauthenticated)

Terraform has been successfully initialized!
+ terraform validate
Success! The configuration is valid.
```

O `set -x` imprime cada comando com um `+` antes de rodá-lo, e é isso que deixa um log de CI legível
uma semana depois. O `init -backend=false` instalou o provider a partir do lock file e nunca pediu
o state. O estágio de plan usa o backend, e as últimas linhas dele são o resumo que quem revisa vai
ler:

```
ana@laptop:~/ci/run-1$ ./ci.sh plan
+ export TF_IN_AUTOMATION=1
+ terraform init -input=false
```

```
Plan: 3 to add, 0 to change, 0 to destroy.
+ terraform show -no-color tfplan
```

```
ana@laptop:~/ci/run-1$ ls
backend.tf
ci.sh
main.tf
plan.txt
prod.tfvars
tfplan
variables.tf
ana@laptop:~/ci/run-1$ tail -n 1 plan.txt
Plan: 3 to add, 0 to change, 0 to destroy.
```

## Duas configurações que existem para máquinas

**O `TF_IN_AUTOMATION`** muda só palavras. O Terraform deixa de fora os conselhos dirigidos a uma
pessoa no teclado, como qual comando digitar em seguida:

```
ana@laptop:~/ci/run-1$ TF_IN_AUTOMATION= terraform plan -input=false -var-file=prod.tfvars | tail -n 6
Plan: 3 to add, 0 to change, 0 to destroy.

─────────────────────────────────────────────────────────────────────────────

Note: You didn't use the -out option to save this plan, so Terraform can't
guarantee to take exactly these actions if you run "terraform apply" now.
ana@laptop:~/ci/run-1$ TF_IN_AUTOMATION=1 terraform plan -input=false -var-file=prod.tfvars | tail -n 3
    }

Plan: 3 to add, 0 to change, 0 to destroy.
```

É pelo mesmo motivo que o plan salvo acima termina no resumo, sem a linha que sugere
`terraform apply "tfplan"`: num pipeline, o próximo comando é assunto do workflow, não de quem lê.

**O `-input=false`** muda comportamento, e importa mais. Sem ele, uma variável que falta vira
pergunta, e o Terraform espera a resposta. Abaixo, o `sleep` faz o papel de um runner cuja entrada
ninguém nunca fecha, e o `timeout`, do limite de tempo do job:

```
ana@laptop:~/ci/run-1$ sleep 20 | timeout -s INT 5 terraform plan; echo "exit $?"
var.environment
  Which environment this state describes.

  Enter a value: 

Interrupt received.
Please wait for Terraform to exit or data loss may occur.
Gracefully shutting down...

╷
│ Error: No value for required variable
│ 
│   on variables.tf line 1:
│    1: variable "environment" {
│ 
│ The root module input variable "environment" is not set, and has no default
│ value. Use a -var or -var-file command line argument to provide a value for
│ this variable.
╵
exit 124
ana@laptop:~/ci/run-1$ terraform plan -input=false; echo "exit $?"
╷
│ Error: No value for required variable
│ 
│   on variables.tf line 1:
│    1: variable "environment" {
│ 
│ The root module input variable "environment" is not set, and has no default
│ value. Use a -var or -var-file command line argument to provide a value for
│ this variable.
╵
exit 1
```

A primeira execução ficou parada em `Enter a value:` até ser interrompida; num runner, ela teria
segurado o job, e um runner, até o limite. A segunda falhou no mesmo instante, com o motivo escrito
com todas as letras. **Num pipeline, uma pergunta que ninguém pode responder tem de ser um erro.** É
por isso que o `ci.sh` passa `-input=false` para todo `init`, `plan` e `apply`.
