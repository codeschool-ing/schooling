---
title: Quais credenciais vencem, roles num perfil, e o CloudShell
version: 1
---

**Para credenciais, o ambiente vence o `AWS_PROFILE`, e o `--profile` vence o ambiente.** Essa
assimetria é o fato isolado mais útil sobre a linha de comando neste curso, porque o `env.sh`
exporta as chaves de teste do moto em todo terminal. A cadeia da lição 10 explica. O provedor `env`
vem primeiro, e nomear um perfil com `--profile` tira esse provedor da cadeia naquele comando.
Nomeá-lo com uma variável não tira.

## Medido de três jeitos

Com o `env.sh` lido, nomeie o perfil com a variável:

```
ana@laptop:~/aws$ AWS_PROFILE=lab aws configure list
NAME       : VALUE                    : TYPE             : LOCATION
profile    : lab                      : env              : ['AWS_PROFILE', 'AWS_DEFAULT_PROFILE']
access_key : ****************test     : env              : 
secret_key : ****************test     : env              : 
region     : sa-east-1                : env              : ['AWS_REGION', 'AWS_DEFAULT_REGION']
```

**O perfil é `lab`, e as chaves não são dele.** A coluna `TYPE` diz `env`: as chaves de teste que o
`env.sh` exportou venceram, e o perfil não contribuiu com nada além do nome. Nomeie-o com a opção:

```
ana@laptop:~/aws$ aws configure list --profile lab
NAME       : VALUE                    : TYPE             : LOCATION
profile    : lab                      : manual           : --profile
access_key : ****************test     : shared-credentials-file : 
secret_key : ****************test     : shared-credentials-file : 
region     : sa-east-1                : env              : ['AWS_REGION', 'AWS_DEFAULT_REGION']
```

**Agora as chaves vêm de `shared-credentials-file`**, o arquivo do próprio perfil. As duas execuções
usam as mesmas chaves só porque `lab` também guarda `test` e `test`. Com um perfil real a primeira
assinaria como uma identidade e a segunda como outra, e nada na tela além da coluna `TYPE` diria
isso.

O terceiro jeito mantém o `AWS_PROFILE` e tira as chaves do ambiente por um comando. É o jeito de
usar um perfil neste curso **sem mudar o `env.sh`**, de que toda outra lição depende:

```
ana@laptop:~/aws$ env -u AWS_ACCESS_KEY_ID -u AWS_SECRET_ACCESS_KEY AWS_PROFILE=lab aws configure list
NAME       : VALUE                    : TYPE             : LOCATION
profile    : lab                      : env              : ['AWS_PROFILE', 'AWS_DEFAULT_PROFILE']
access_key : ****************test     : shared-credentials-file : 
secret_key : ****************test     : shared-credentials-file : 
region     : sa-east-1                : env              : ['AWS_REGION', 'AWS_DEFAULT_REGION']
```

Um terminal que nunca leu o `env.sh` se comporta igual, exceto que também não tem o endpoint e
mandaria as requisições para a AWS. **No laboratório, prefira `--profile`**. Fora dele, um perfil
escolhido com `AWS_PROFILE` num shell sem chaves exportadas é o arranjo do dia a dia.

## Uma role num perfil: de uma conta para outra

As pessoas da loja trabalham em várias contas, e a lição 9 assumiu roles entre elas à mão. Um perfil
consegue fazer isso a cada comando. Crie a organização e a conta de staging, e depois um perfil
cujas credenciais são uma role nela:

```
ana@laptop:~/aws$ aws organizations create-organization --feature-set ALL --query Organization.Id --output text
o-5sixxus3on
ana@laptop:~/aws$ aws organizations create-account --account-name shop-staging --email aws+shop-staging@example.com --query CreateAccountStatus.[State,AccountId] --output text
SUCCEEDED	986198030938
ana@laptop:~/aws$ STAGING=$(aws organizations list-accounts --query "Accounts[?Name==\`shop-staging\`].Id" --output text)
```

```
ana@laptop:~/aws$ aws configure set role_arn arn:aws:iam::$STAGING:role/OrganizationAccountAccessRole --profile staging
ana@laptop:~/aws$ aws configure set source_profile lab --profile staging
ana@laptop:~/aws$ aws configure set role_session_name ana --profile staging
ana@laptop:~/aws$ aws configure set output table --profile staging
ana@laptop:~/aws$ aws sts get-caller-identity --profile staging
-----------------------------------------------------------------------------------------
|                                   GetCallerIdentity                                   |
+---------+-----------------------------------------------------------------------------+
|  Account|  986198030938                                                               |
|  Arn    |  arn:aws:sts::986198030938:assumed-role/OrganizationAccountAccessRole/ana   |
|  UserId |  AROA6LHP3XJNFPMJSJBNZ:ana                                                  |
+---------+-----------------------------------------------------------------------------+
```

**`role_arn` diz qual role assumir e `source_profile` diz com quais credenciais.** A linha de
comando chamou `sts:AssumeRole` como `lab`, recebeu credenciais temporárias em `shop-staging`, e
assinou o `get-caller-identity` com elas. O `role_session_name` fixou o nome da sessão que ela
tiraria do relógio. A saída é uma tabela porque o perfil pediu uma. A role é a que a lição 3 mostrou
o moto criando em toda conta nova, sem política anexada, o que o moto aqui nem verifica.

O mesmo comando com o perfil e sem ele mostra duas contas, cada uma com a sua rede padrão:

```
ana@laptop:~/aws$ aws ec2 describe-vpcs --profile staging --query "Vpcs[].[OwnerId,CidrBlock]" --output text
986198030938	172.31.0.0/16
ana@laptop:~/aws$ aws ec2 describe-vpcs --query "Vpcs[].[OwnerId,CidrBlock]" --output text
123456789012	172.31.0.0/16
ana@laptop:~/aws$ ls ~/.aws/cli/cache/
83009e16ca18f53b349e21816a716fddcb4b28d3.json
session.db
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l25-role-profile\" aria-label=\"O que um comando com --profile staging faz. O perfil staging nomeia um role_arn em shop-staging e um source_profile, lab. As chaves de lab assinam uma chamada sts:AssumeRole. O STS devolve credenciais temporárias de OrganizationAccountAccessRole em shop-staging, que a linha de comando guarda em ~/.aws/cli/cache e com as quais assina o comando. O comando seguinte reusa o cache até as credenciais vencerem.\"><defs><marker id=\"l25-role-profile-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"10.0\" y=\"60.0\" width=\"160.0\" height=\"64.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"90.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">[profile staging]</text><text x=\"90.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">role_arn, source_profile</text><rect x=\"190.0\" y=\"60.0\" width=\"160.0\" height=\"64.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"270.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">[lab]</text><text x=\"270.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">as chaves assinam</text><rect x=\"370.0\" y=\"60.0\" width=\"160.0\" height=\"64.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"450.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">sts:AssumeRole</text><text x=\"450.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">em shop-staging</text><rect x=\"550.0\" y=\"60.0\" width=\"160.0\" height=\"64.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"630.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">~/.aws/cli/cache</text><text x=\"630.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">guardado até vencer</text><path d=\"M172.0 92.0 L188.0 92.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l25-role-profile-af-ah-phosphor)\"></path><path d=\"M352.0 92.0 L368.0 92.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l25-role-profile-af-ah-phosphor)\"></path><path d=\"M532.0 92.0 L548.0 92.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l25-role-profile-af-ah-phosphor)\"></path><path d=\"M630.0 126.0 L630.0 170.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l25-role-profile-af-ah-phosphor)\"></path><rect x=\"430.0\" y=\"172.0\" width=\"280.0\" height=\"40.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"570.0\" y=\"192.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">aws ec2 describe-vpcs --profile staging</text><text x=\"220.0\" y=\"192.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">assinado como a role, na outra conta</text><text x=\"90.0\" y=\"36.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">um comando</text></svg>", "caption": "Um perfil com role_arn assume a role no primeiro comando e a reusa até vencer.", "same": ["role_arn, source_profile"]}
```

Os arquivos `.json` em `~/.aws/cli/cache/` guardam as credenciais temporárias da role, mantidas até
vencerem para que o próximo comando não assuma a role de novo. **Apagá-los é seguro**: o próximo
comando só assume a role mais uma vez. Duas configurações vizinhas ficam ao lado de `role_arn`. O
`credential_source` substitui o `source_profile` numa máquina que já tem credenciais do ambiente ou
do serviço de metadados, como na lição 10. O `mfa_serial` faz a linha de comando pedir um código
antes de assumir uma role cuja política de confiança exige MFA.

## `credential_process`, um programa que entrega credenciais

**O `credential_process` nomeia um programa cuja saída são as credenciais**, em JSON na saída
padrão. É como um gerenciador de senhas ou o cofre de uma empresa se liga à linha de comando sem o
segredo jamais ser escrito em `~/.aws`. Este imprime os marcadores do moto, e nada mais:

```sh
cat > ~/aws/lab-creds.sh <<'EOF'
#!/bin/sh
# Prints credentials the way credential_process expects them. These are moto's
# placeholders; a real one would ask a vault or a password manager.
printf '{"Version": 1, "AccessKeyId": "test", "SecretAccessKey": "test"}\n'
EOF
```

```
ana@laptop:~/aws$ sh ~/aws/lab-creds.sh
{"Version": 1, "AccessKeyId": "test", "SecretAccessKey": "test"}
ana@laptop:~/aws$ aws configure set credential_process "sh ~/aws/lab-creds.sh" --profile from-process
ana@laptop:~/aws$ aws sts get-caller-identity --profile from-process

aws: [ERROR]: Error when retrieving credentials from custom-process: sh: 0: cannot open ~/aws/lab-creds.sh: No such file
```

**O comando não é rodado por um shell**, então o `~` chegou ao `sh` como foi escrito e não nomeou
arquivo nenhum. Embrulhar a linha em `sh -c` a entrega a um shell, que a expande:

```
ana@laptop:~/aws$ aws configure set credential_process "sh -c \"sh ~/aws/lab-creds.sh\"" --profile from-process
ana@laptop:~/aws$ tail -2 ~/.aws/config
[profile from-process]
credential_process = sh -c "sh ~/aws/lab-creds.sh"
ana@laptop:~/aws$ aws configure list --profile from-process
NAME       : VALUE                    : TYPE             : LOCATION
profile    : from-process             : manual           : --profile
access_key : ****************test     : custom-process   : 
secret_key : ****************test     : custom-process   : 
region     : sa-east-1                : env              : ['AWS_REGION', 'AWS_DEFAULT_REGION']
```

O `custom-process` é o provedor da cadeia da lição 10 que respondeu. Um programa real pode devolver
também `SessionToken` e `Expiration`, e a linha de comando pergunta de novo quando esse horário passa.

A lição 11 usou o quarto tipo, `sso_session`. Com esses quatro a lista está completa: **chaves num
arquivo, uma role assumida a partir de outro perfil, um programa, ou um login pelo Identity
Center.**

## O CloudShell, que não precisa de perfil nenhum

**O AWS CloudShell é um shell no navegador, aberto pelo console, com a linha de comando já logada
como quem está usando o console.** Ele roda Amazon Linux na região em que o console está, com o AWS
CLI, Python e Node.js instalados. Ele guarda 1 GB do diretório pessoal por região entre sessões. Não
há chave para configurar, porque as credenciais são as da sessão do console, e acabam quando ela
acaba.

Ele serve nos momentos em que os perfis desta lição são demais: um comando numa conta em que alguém
entrou pelo Identity Center, de um computador sem nada instalado. **Ele não foi executado aqui**:
exige uma conta da AWS e um navegador, e o AWS CLI 2.37.4 não tem comando `cloudshell` para
alcançá-lo de um terminal. Esta descrição segue a documentação da AWS.
