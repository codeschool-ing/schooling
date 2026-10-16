---
title: A linha de comando com login pelo Identity Center
version: 1
---

**Na linha de comando, o Identity Center é um perfil que nomeia um portal, uma conta e um permission
set, e um login que enche um cache.** Nenhuma chave entra em arquivo nenhum. O `aws sso login` abre
o navegador uma vez, a pessoa entra no provedor de identidade, e nas horas seguintes todo comando
com aquele perfil recebe sozinho credenciais novas da role.

A imagem errada é que a linha de comando precisa das credenciais copiadas do portal de acesso
coladas em `~/.aws/credentials`. O portal oferece exatamente isso, e é o certo para uma vez só. Para
o dia a dia, é um segredo com cara de chave num arquivo que sobrevive à sessão de onde veio. **O
perfil faz o mesmo trabalho sem o arquivo.**

## O perfil, como arquivo

O `aws configure sso` faz cinco perguntas e escreve as respostas em `~/.aws/config`. As respostas
são curtas o bastante para escrever à mão, e o arquivo é mais claro que as perguntas. A lição 25
cobre o arquivo por inteiro. Salve isto como `~/.aws/config`, acrescentando ao fim se o arquivo já
existir, com o id da sua `shop-prod` no lugar deste:

```ini
[sso-session shop]
sso_start_url = https://my-sso-portal.awsapps.com/start
sso_region = sa-east-1
sso_registration_scopes = sso:account:access

[profile prod-readonly]
sso_session = shop
sso_account_id = 834307267662
sso_role_name = ReadOnly
region = sa-east-1
output = json
```

**Dois tipos de seção, para duas coisas diferentes.** `[sso-session shop]` é o login: o endereço do
portal, a região onde o Identity Center vive, e o escopo que a linha de comando pede. O endereço
aqui é o marcador que a documentação da AWS usa. Um real fica nas configurações do Identity Center.
`[profile prod-readonly]` é um destino: uma conta, um permission set pelo nome, e a região e o
formato de saída dos comandos rodados com ele. **Uma sessão serve a quantos perfis forem.** Um login
de manhã abre `prod-readonly`, um `staging-developer` ao lado, e todo outro par atribuído à pessoa.

```
ana@laptop:~/aws$ aws configure list-profiles
prod-readonly
```

## O que acontece antes de alguém ter feito login

Pergunte quem é o perfil:

```
ana@laptop:~/aws$ aws sts get-caller-identity --profile prod-readonly

aws: [ERROR]: Error loading SSO Token: Token for shop does not exist
```

**A linha de comando procurou um login em cache para a sessão `shop`, não achou, e parou.** Ela não
recorreu às chaves de teste que o `env.sh` exporta, porque um perfil nomeado com `--profile` tira da
cadeia as chaves do ambiente. A lição 25 mede essa regra e a sua exceção. O cache em que procurou é
`~/.aws/sso/cache/`, e quem o enche é um comando.

## O login, que não foi executado

**`aws sso login --profile prod-readonly` precisa de um Identity Center real e de um navegador, e
nenhum dos dois existe no laboratório.** Apontado para o moto, que não tem serviço de login, ele
falha na primeira requisição:

```
ana@laptop:~/aws$ aws sso login --profile prod-readonly --no-browser 2>&1 | grep -o "An error occurred ([0-9]*) when calling the [A-Za-z]* operation"
An error occurred (500) when calling the RegisterClient operation
```

Na AWS, a documentação descreve o resto, e este curso o descreve a partir dela. O `RegisterClient`
registra a linha de comando no serviço de login do Identity Center. O comando então imprime um
endereço e um código, e abre o navegador nele, a menos que receba `--no-browser`. A pessoa confere
que o código bate, entra no provedor de identidade com o segundo fator, e autoriza o acesso. A linha
de comando recebe um token, escreve-o em `~/.aws/sso/cache/`, e diz que entrou.

Daí em diante, **todo comando com o perfil troca esse token por credenciais da role**. O provedor
`sso` da cadeia da lição 10 pede ao portal as credenciais de `ReadOnly` em `834307267662`. Ele
recebe credenciais temporárias da role `AWSReservedSSO_ReadOnly_…`, e as renova quando acabam. Dois
relógios o limitam. A **duração de sessão do permission set**, quatro horas para `ReadOnly`, limita
cada conjunto de credenciais da role. A **sessão do Identity Center**, oito horas por padrão e
definida pelo administrador, limita o próprio login. Quando ela acaba, o próximo comando diz que o
token venceu e a pessoa roda `aws sso login` de novo. O `aws sso logout` a encerra de propósito, e
apaga o token do cache.

## O que isso compra, numa comparação

| | a chave de um usuário do IAM em `~/.aws/credentials` | um perfil com `sso-session` |
|---|---|---|
| o que fica no disco | o próprio segredo, válido até ser apagado | um token, válido pela sessão |
| segundo fator | por usuário, por conta, se alguém o configurou | no provedor de identidade, a cada login |
| quando a pessoa sai | uma chave por conta para achar e apagar | desativada uma vez, no provedor |
| o que o CloudTrail nomeia | o usuário do IAM | a role, com o nome da pessoa como sessão |

**Para uma pessoa num teclado, não há linha em que a chave vença.** É de onde a lição 12 parte: a
chave é o último recurso, guardada para os programas que não têm navegador nem role para vestir.
