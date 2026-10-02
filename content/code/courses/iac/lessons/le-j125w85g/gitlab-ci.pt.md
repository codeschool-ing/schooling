---
title: GitLab CI, e o plan como artefato
version: 1
---

O mesmo pipeline no GitLab é mais curto, porque o GitLab diz mais coisas com palavras-chave. Como o
workflow do GitHub, **este arquivo foi escrito para a aula e nunca executado**: aqui também não há
GitLab.

```yaml
# Illustrative: written for lesson 15 and never run by it. Every job calls
# ci.sh, which the lesson does run.
stages: [check, plan, apply]

default:
  image:
    name: hashicorp/terraform:1.16.4
    entrypoint: [""]

.aws:
  id_tokens:
    AWS_WEB_IDENTITY_TOKEN:
      aud: sts.amazonaws.com
  before_script:
    - echo "$AWS_WEB_IDENTITY_TOKEN" > "$CI_BUILDS_DIR/web-identity-token"
    - export AWS_WEB_IDENTITY_TOKEN_FILE="$CI_BUILDS_DIR/web-identity-token"
    - export AWS_REGION=sa-east-1

check:
  stage: check
  script:
    - ./ci.sh check

scan:
  stage: check
  image:
    name: aquasec/trivy:0.75.0
    entrypoint: [""]
  script:
    - ./ci.sh scan

plan:
  stage: plan
  extends: .aws
  variables:
    AWS_ROLE_ARN: arn:aws:iam::123456789012:role/shop-plan
  script:
    - ./ci.sh plan
  artifacts:
    paths: [tfplan, plan.txt]
    expire_in: 3 days

apply:
  stage: apply
  extends: .aws
  variables:
    AWS_ROLE_ARN: arn:aws:iam::123456789012:role/shop-apply
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
      when: manual
  environment: production
  resource_group: production
  needs: [plan]
  script:
    - ./ci.sh apply
```

O que o laboratório consegue dizer dos dois arquivos é que eles são YAML válido, e que cada um tem
os jobs que deveria ter:

```
ana@laptop:~/shop$ python3 -c 'import yaml; print(list(yaml.safe_load(open(".github/workflows/terraform.yml"))["jobs"]))'
['check', 'plan', 'apply']
ana@laptop:~/shop$ python3 -c 'import yaml; print([k for k, v in yaml.safe_load(open(".gitlab-ci.yml")).items() if "script" in v])'
['check', 'scan', 'plan', 'apply']
```

Isso está longe de provar que funcionam. Um parser de YAML não distingue uma palavra-chave que o
GitLab conhece de uma que ele ignoraria, e só uma execução real mostraria a troca de token ou o
artefato chegando. Leia os dois arquivos como uma descrição precisa do projeto, não como algo
testado.

## O que as palavras-chave fazem

O `stages` dá a ordem; jobs do mesmo estágio rodam em paralelo, então `check` e `scan` rodam lado a
lado e o `plan` espera pelos dois. O `default: image` roda todo job na imagem `hashicorp/terraform`,
na mesma versão que o laboratório usa. O `entrypoint` dela está vazio porque essa imagem inicia o
próprio `terraform`, e o GitLab precisa de um shell para rodar as linhas de `script`. O `scan` usa
a imagem do Trivy, que é como um job ganha uma ferramenta que a imagem padrão não tem.

**O `artifacts` é como o plan viaja.** Quando o `plan` termina, o GitLab guarda `tfplan` e
`plan.txt`, e um job posterior que tenha ele em `needs` recebe os dois arquivos no diretório de
trabalho antes de o script começar.

O artefato não é só um plan. A aula 9 abriu um plan salvo e encontrou dentro dele uma cópia do
state, então **quem pode baixar os artefatos deste pipeline pode ler o que o state guarda**, e a
aula 12 trata do que isso pode incluir. É também por isso que `expire_in: 3 days` é uma decisão e
não faxina: um plan que esperou mais do que isso por aprovação é um plan que alguém deveria refazer
em vez de aplicar, e um arquivo que você não guarda mais é um arquivo que ninguém baixa.

O `apply` carrega o resto. As `rules` dele só o incluem em pipelines da branch padrão, e o
`when: manual` faz dele um botão: o pipeline para depois do `plan` até alguém apertá-lo, depois de
ler o `plan.txt` ou o log do job. O `environment: production` é o que permite ao GitLab restringir
quem pode apertar. O `resource_group` e o `id_tokens` pertencem aos dois últimos assuntos desta
aula, um apply por vez e credenciais, e são explicados lá.

## O mesmo projeto em dois dialetos

| | GitHub Actions | GitLab CI |
| --- | --- | --- |
| ordem dos jobs | `needs` | `stages`, e `needs` |
| o arquivo do plan entre jobs | `upload-artifact`, `download-artifact` | `artifacts: paths`, recebido via `needs` |
| por quanto tempo fica guardado | `retention-days` | `expire_in` |
| a aprovação | `environment` com revisores obrigatórios | `when: manual` num environment protegido |
| um apply por vez | `concurrency` | `resource_group` |
| credenciais sem chaves | `id-token: write` e uma action | `id_tokens` e duas variáveis de ambiente |

**O que não mudou foi o `ci.sh`.** Os dois arquivos chamam os mesmos quatro estágios, então os
passos, as flags e a ordem estão escritos uma vez só, e trocar um serviço de CI pelo outro é mudar o
arquivo que os agenda, não o que eles fazem.
