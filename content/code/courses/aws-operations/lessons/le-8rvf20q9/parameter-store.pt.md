---
title: Parameter Store, por caminho
version: 1
---

O nome de um parâmetro é um caminho, e o caminho é como o código e as políticas o acham: tudo de que o
banco de produção da loja precisa mora sob `/shop/prod/db/`. Trabalhe em `~/aws/secrets`
(`mkdir -p ~/aws/secrets && cd ~/aws/secrets`). O host é uma `String` simples; a senha é uma
`SecureString`:

```
ana@laptop:~/aws/secrets$ aws ssm put-parameter --name /shop/prod/db/host --type String --value db.internal --query '[Version,Tier]' --output text
1	Standard
ana@laptop:~/aws/secrets$ aws ssm put-parameter --name /shop/prod/db/password --type SecureString --value first-pass --query '[Version,Tier]' --output text
1	Standard
ana@laptop:~/aws/secrets$ aws ssm get-parameter --name /shop/prod/db/password --query 'Parameter.[Type,Value]' --output text
SecureString	kms:alias/aws/ssm:first-pass
ana@laptop:~/aws/secrets$ aws ssm get-parameter --name /shop/prod/db/password --with-decryption --query Parameter.Value --output text
first-pass
```

Sem `--with-decryption` o valor volta criptografado, e com a opção, em texto puro. A terceira linha é a
que merece atenção: **essa é a ideia do moto sobre criptografia**, o nome da chave na frente do texto
puro. Na AWS o valor criptografado é texto cifrado do KMS, ilegível sem a chave, e pedir o texto puro
exige permissão para decifrar com essa chave além de permissão para ler o parâmetro. A chave padrão é a
`aws/ssm` da conta; uma chave da própria equipe é a lição 18.

## Por caminho

O código pede toda a sua configuração numa chamada, por caminho:

```
ana@laptop:~/aws/secrets$ aws ssm get-parameters-by-path --path /shop/prod --recursive --with-decryption --query 'Parameters[].[Name,Type,Version]' --output text
/shop/prod/db/host	String	1
/shop/prod/db/password	SecureString	1
```

O caminho também é o que uma política concede: uma política que deixa a aplicação de produção ler os
parâmetros sob `/shop/prod` dá a ela a sua configuração e nada da de staging, que mora sob
`/shop/staging`. Uma hierarquia por ambiente é o que deixa essa política curta.

## Mudando um valor

Um parâmetro não é sobrescrito por acidente:

```
ana@laptop:~/aws/secrets$ aws ssm put-parameter --name /shop/prod/db/password --type SecureString --value second-pass

aws: [ERROR]: An error occurred (ParameterAlreadyExists) when calling the PutParameter operation: The parameter already exists. To overwrite this value, set the overwrite option in the request to true.
ana@laptop:~/aws/secrets$ aws ssm put-parameter --name /shop/prod/db/password --type SecureString --value second-pass --overwrite --query Version
2
ana@laptop:~/aws/secrets$ aws ssm get-parameter-history --name /shop/prod/db/password --query 'Parameters[].[Version,LastModifiedDate]' --output text
1	2026-10-16T16:27:27.569000-03:00
2	2026-10-16T16:27:30.667000-03:00
```

Toda mudança é uma versão nova, e o histórico guarda as antigas, então um valor mudado na hora errada
pode ser lido de volta e restaurado. O programa que lê o parâmetro vê a versão nova na próxima leitura,
o que é um motivo para saber quando é a próxima leitura.

## O que o moto deixa passar

```
ana@laptop:~/aws/secrets$ aws ssm put-parameter --name /shop/prod/too-big --type String --value "$(printf "%5000s" | tr " " x)" --query Tier
"Standard"
```

**A AWS recusa isso**: um parâmetro standard guarda no máximo 4 KB, e 5.000 caracteres passam disso,
então a chamada falha com erro de validação, a menos que o nível seja `Advanced`. O moto guarda como
standard. Um valor desse tamanho costuma ser um arquivo que pertence ao S3, com a chave dele no parâmetro.
