---
title: A cadeia de credenciais, e onde um programa encontra suas chaves
version: 1
---

**Um programa que chama a AWS nunca precisa carregar uma chave; precisa encontrar credenciais, e o
SDK sabe onde procurar.** Todo SDK da AWS, e a linha de comando construída sobre um deles, percorre
uma lista ordenada de lugares chamada **cadeia de provedores de credenciais** e para no primeiro
lugar que responde. O topo da lista é uma chave que alguém digitou. A base é uma credencial que a
plataforma entrega a uma máquina por algumas horas de cada vez, e esta lição é sobre a base.

A imagem errada comum é que o `aws` lê `AWS_ACCESS_KEY_ID` e que a história acaba aí. É o primeiro
lugar onde a linha de comando procura, e é por isso que o `env.sh` funciona desde a lição 1, mas é
um lugar entre uma dúzia.

Reinicie o moto no primeiro terminal (Ctrl+C, depois `moto_server -p 4567`) para que esta lição
comece de uma AWS vazia. **Nada nesta lição liga a verificação de permissões do moto.** As
credenciais que o moto entrega na base da cadeia são marcadores que a verificação dele recusaria, e a
última seção mede uma chamada que quebra a verificação de vez.

```
ana@laptop:~/aws$ aws configure list
NAME       : VALUE                    : TYPE             : LOCATION
profile    : <not set>                : None             : None
access_key : ****************test     : env              : 
secret_key : ****************test     : env              : 
region     : sa-east-1                : env              : ['AWS_REGION', 'AWS_DEFAULT_REGION']
```

`aws configure list` diz quais credenciais a linha de comando usaria e onde as encontrou. A coluna
`TYPE` é o provedor: `env`, o ambiente que o `env.sh` preencheu. Os quatro últimos caracteres da
chave aparecem e o resto fica escondido, o que torna seguro colar a saída num chamado.

## A ordem, como a linha de comando a relata

`--debug` faz a linha de comando narrar o que faz, inclusive cada provedor que tenta. Tire as chaves
do ambiente e aponte o provedor de metadados para o moto, que serve uma imitação do serviço de
metadados do EC2 na própria porta:

```
ana@laptop:~/aws$ unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY
ana@laptop:~/aws$ export AWS_EC2_METADATA_SERVICE_ENDPOINT=http://localhost:4567/
ana@laptop:~/aws$ aws sts get-caller-identity --debug 2>&1 | grep -oE "Looking for credentials via: .*|Found credentials .*|(PUT|GET) /latest[^ ]*"
Looking for credentials via: env
Looking for credentials via: assume-role
Looking for credentials via: assume-role-with-web-identity
Looking for credentials via: sso
Looking for credentials via: shared-credentials-file
Looking for credentials via: login
Looking for credentials via: custom-process
Looking for credentials via: config-file
Looking for credentials via: ec2-credentials-file
Looking for credentials via: boto-config
Looking for credentials via: container-role
Looking for credentials via: iam-role
PUT /latest/api/token
GET /latest/meta-data/iam/security-credentials/
GET /latest/meta-data/iam/security-credentials/default-role
Found credentials from IAM Role: default-role
```

O `grep` guarda três tipos de linha de algumas centenas: os provedores tentados, o que respondeu e
as requisições enviadas ao serviço de metadados. **Doze provedores foram consultados, nesta ordem, e
o décimo segundo respondeu.** Os nomes são os que o `botocore`, a biblioteca dentro da linha de
comando, dá a eles:

| provedor | onde procura | quem põe credenciais lá |
|---|---|---|
| `env` | `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN` | você, ou um sistema de CI |
| `assume-role` | um perfil com `role_arn` | você, no `~/.aws/config` (lição 25) |
| `assume-role-with-web-identity` | `AWS_ROLE_ARN` e `AWS_WEB_IDENTITY_TOKEN_FILE` | o Kubernetes no EKS, ou um sistema de CI (esta lição) |
| `sso` | um perfil com `sso_session` | o IAM Identity Center (lição 11) |
| `shared-credentials-file` | `~/.aws/credentials` | você |
| `login` | o que o `aws login` deixou | o seu login no console, pelo navegador |
| `custom-process` | um perfil com `credential_process` | um programa que você indica (lição 25) |
| `config-file` | chaves escritas no `~/.aws/config` | você |
| `ec2-credentials-file`, `boto-config` | dois arquivos de um SDK Python mais antigo | ninguém, hoje |
| `container-role` | `AWS_CONTAINER_CREDENTIALS_RELATIVE_URI` ou `_FULL_URI` | o ECS, e o EKS Pod Identity |
| `iam-role` | o serviço de metadados da instância | o EC2, por meio de um instance profile |

Duas consequências saem de **a primeira resposta vence**. Uma chave esquecida no ambiente de uma
máquina que tem uma role vence a role, em silêncio, e a máquina roda como quem for o dono da chave. E
os provedores do topo não custam nada para verificar, enquanto o último faz requisições de rede, e é
por isso que um laptop sem credencial nenhuma hesita um instante antes de dizer que não tem. Outros
SDKs mantêm a mesma ideia e diferem em detalhes da ordem; a documentação de cada SDK lista a sua.

## Perguntando você mesmo ao serviço de metadados

Numa instância EC2 o serviço de metadados fica em **`http://169.254.169.254/`**, um endereço
link-local que só a própria instância alcança, e nada precisa ser instalado para que ele responda. O
moto responde os mesmos caminhos em `localhost:4567`. O serviço tem duas versões, e a diferença está
na primeira requisição:

```
ana@laptop:~/aws$ curl -s http://localhost:4567/latest/meta-data/iam/security-credentials/; echo
default-role
```

Isso é o **IMDSv1**: um `GET` simples, respondido com o nome da role cujas credenciais a instância
tem. O moto sempre responde `default-role`. O **IMDSv2** pede antes um token de sessão, com um `PUT`
e um cabeçalho dizendo quantos segundos ele deve durar, e depois manda esse token em cada leitura:

```
ana@laptop:~/aws$ TOKEN=$(curl -s -X PUT -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" http://localhost:4567/latest/api/token)
ana@laptop:~/aws$ echo $TOKEN
fake-imdsv2-token
ana@laptop:~/aws$ curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://localhost:4567/latest/meta-data/iam/security-credentials/default-role; echo
{"AccessKeyId": "test-key", "SecretAccessKey": "test-secret-key", "Token": "test-session-token", "Expiration": "2026-10-17T16:00:38Z"}
```

A resposta é um conjunto inteiro de credenciais: um id de chave, um segredo, um token de sessão e uma
validade. Na AWS o id da chave começa com `ASIA`, o prefixo de uma chave temporária, e a resposta
traz mais três campos, `Code`, `LastUpdated` e `Type`. A documentação da AWS promete **credenciais
novas pelo menos cinco minutos antes de as antigas vencerem**, então um programa que pergunta de novo
quando a sua cópia acaba nunca segura uma chave morta. As do moto são marcadores fixos, `test-key`
com o token de sessão `test-session-token`, o token do IMDSv2 é sempre `fake-imdsv2-token`, e a
validade é um dia depois da requisição.

## A base da cadeia, pela linha de comando

Com as chaves ainda fora do ambiente e o endereço de metadados exportado, pergunte de novo quais
credenciais a linha de comando usaria:

```
ana@laptop:~/aws$ aws configure list
NAME       : VALUE                    : TYPE             : LOCATION
profile    : <not set>                : None             : None
access_key : ****************-key     : iam-role         : 
secret_key : ****************-key     : iam-role         : 
region     : sa-east-1                : env              : ['AWS_REGION', 'AWS_DEFAULT_REGION']
ana@laptop:~/aws$ aws sts get-caller-identity
{
    "UserId": "AKIAIOSFODNN7EXAMPLE",
    "Account": "123456789012",
    "Arn": "arn:aws:sts::123456789012:user/moto"
}
```

**`iam-role` é o provedor de metadados da instância**, e a localização está vazia porque não há
arquivo: as credenciais vieram por HTTP. O `get-caller-identity` responde como o usuário padrão do
moto, porque o moto não conhece uma chave chamada `test-key` e recorre a ele. Numa instância a AWS
responderia com a role, `arn:aws:sts::123456789012:assumed-role/shop-app/i-…`, onde **o nome da
sessão é o id da instância**, de modo que uma linha no CloudTrail diz qual máquina fez a chamada.

Agora leia o `env.sh` de novo. Ele põe as chaves de volta, e deixa o endereço de metadados onde
estava:

```
ana@laptop:~/aws$ source ~/aws/env.sh
ana@laptop:~/aws$ aws configure list
NAME       : VALUE                    : TYPE             : LOCATION
profile    : <not set>                : None             : None
access_key : ****************test     : env              : 
secret_key : ****************test     : env              : 
region     : sa-east-1                : env              : ['AWS_REGION', 'AWS_DEFAULT_REGION']
```

O `env` vence de novo, com o serviço de metadados ainda a uma variável de distância, porque a cadeia
nunca chegou tão longe. Mantenha este terminal como está agora, com o `env.sh` lido; a próxima seção
o usa.
