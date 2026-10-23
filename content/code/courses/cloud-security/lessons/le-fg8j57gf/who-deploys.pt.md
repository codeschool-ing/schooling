---
title: Quem segura as chaves no fim do caminho
version: 1
---

**A identidade que aplica é a coisa mais poderosa de um fluxo de publicação. Ela deve ser um papel que o pipeline assume por minutos: nunca uma chave guardada nas configurações do pipeline, e
nunca o mesmo papel para todas as etapas.** A aula 12 mostrou como uma chave guardada sobrevive a toda
tentativa de removê-la. Um pipeline com a chave de administrador da conta é esse vazamento esperando um
motivo.

## Um token, não uma chave

A aula 4 trocou um token do Google Cloud por credenciais temporárias da AWS, para que um job em outra
nuvem nunca tivesse uma chave. Um pipeline é o mesmo tipo de carga de trabalho. O GitHub Actions, por
exemplo, assina um token de identidade para cada job, dizendo para qual repositório, branch ou ambiente
o job roda, e a AWS pode confiar nessa assinatura por meio de um **provedor OIDC**: uma entrada no IAM
que nomeia o emissor.

A clínica divide o trabalho entre **dois papéis**, porque as etapas precisam de poderes diferentes:

- **`infra-plan`** lê a conta, para o plano que todo pull request roda. Qualquer pull request do
  repositório pode assumi-lo.
- **`infra-apply`** escreve. Só um job rodando para o ambiente protegido `production` pode assumi-lo, e
  o GitHub só inicia um job assim depois que um revisor nomeado aprova.

Inicie o moto vazio. A política de confiança de cada papel nomeia o emissor e fixa as afirmações do
token. Salve a primeira como `trust-plan.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { "Federated": "arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com" },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
          "token.actions.githubusercontent.com:sub": "repo:clinic/infra:pull_request"
        }
      }
    }
  ]
}
```

E a segunda como `trust-apply.json`, idêntica exceto pela afirmação que diz quem pode assumi-lo:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { "Federated": "arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com" },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
          "token.actions.githubusercontent.com:sub": "repo:clinic/infra:environment:production"
        }
      }
    }
  ]
}
```

```
ana@laptop:~/aws$ aws iam create-open-id-connect-provider --url https://token.actions.githubusercontent.com --client-id-list sts.amazonaws.com --query OpenIDConnectProviderArn --output text
arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com
ana@laptop:~/aws$ aws iam create-role --role-name infra-plan --assume-role-policy-document file://trust-plan.json --query Role.Arn --output text
arn:aws:iam::123456789012:role/infra-plan
ana@laptop:~/aws$ aws iam attach-role-policy --role-name infra-plan --policy-arn arn:aws:iam::aws:policy/ReadOnlyAccess
ana@laptop:~/aws$ aws iam create-role --role-name infra-apply --assume-role-policy-document file://trust-apply.json --query Role.Arn --output text
arn:aws:iam::123456789012:role/infra-apply
ana@laptop:~/aws$ aws iam list-roles --query "Roles[?starts_with(RoleName, 'infra-')].[RoleName,AssumeRolePolicyDocument.Statement[0].Condition.StringEquals.\"token.actions.githubusercontent.com:sub\"]" --output text
infra-plan	repo:clinic/infra:pull_request
infra-apply	repo:clinic/infra:environment:production
```

**A condição `sub` carrega o desenho inteiro.** Sem ela, qualquer repositório do GitHub poderia
apresentar um token assinado pelo mesmo emissor e assumir o papel, já que o GitHub assina o token de
todo job com as mesmas chaves. Com ela, o `infra-plan` só responde a pull requests de `clinic/infra`, e
o `infra-apply` só ao job que o GitHub roda depois que os revisores do ambiente `production` aprovam.
As permissões de que o papel de apply precisa são as dos recursos que ele gerencia, e escolhê-las é o
assunto da aula 6; aqui ele fica sem política.

**O moto guarda essas condições e não julga nenhuma**, como a aula 4 mostrou: ele entregaria qualquer
um dos papéis a qualquer token. O que a AWS faz com as afirmações vem da documentação dela para o
provedor do GitHub.

## O lado do workflow

Do lado do GitHub, um job pede o seu token declarando a permissão `id-token: write` e entrega o nome do
papel à action da própria AWS, que faz a troca. O job de apply de um workflow assim fica parecido com
isto; ele **não foi executado**, porque o laboratório não tem runner do GitHub nem AWS com que trocar
tokens:

```yaml
apply:
  runs-on: ubuntu-24.04
  environment: production
  permissions:
    id-token: write
    contents: read
  steps:
    - uses: actions/checkout@v4
    - uses: aws-actions/configure-aws-credentials@v4
      with:
        role-to-assume: arn:aws:iam::123456789012:role/infra-apply
        aws-region: sa-east-1
    - run: terraform init -input=false && terraform apply -input=false plan.bin
```

Três linhas carregam a segurança. `environment: production` é o que faz o GitHub esperar os
revisores, e o que põe `environment:production` no `sub` do token. `id-token: write` deixa este job, e
só ele, pedir um token. E as actions aparecem aqui com uma tag de versão para facilitar a leitura; um
workflow de verdade fixa cada uma no hash completo do commit, porque uma tag pode ser movida para
apontar para outro código. Como o `plan.bin` salvo viaja do job de plan para este é assunto do
pipeline; o que importa é que o apply o use.

## Tirando o caminho das pessoas

Dois papéis são metade. A outra metade é que **os papéis das próprias pessoas perdem o acesso de
escrita** ao que o pipeline gerencia: a ana, o caio e a bia ficam com acesso de leitura, e existe um
papel de emergência para o dia em que o próprio pipeline quebrar, usado raramente, com nome, e
registrado toda vez. Enquanto isso não for verdade, a porta das seções anteriores é um conselho, e a
requisição única da aula 1 continua a uma requisição de distância.
