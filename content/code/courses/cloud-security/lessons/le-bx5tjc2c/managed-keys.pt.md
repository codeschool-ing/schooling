---
title: Três tipos de chave, e qual delas você enxerga
version: 1
---

**Na AWS, toda chave que cifra os seus dados em repouso é de um de três tipos. O que os distingue é
o que você enxerga e controla: nada, um pouco, ou tudo.** As três ficam no Key Management
Service da AWS, o KMS, em hardware que a AWS opera, e nenhuma sai de lá em claro. O que muda é de
quem é a política que decide quem pode usar a chave.

| tipo | exemplo | quem escreve a política dela | dá para desativá-la ou apagá-la? | cada uso fica registrado na sua conta? |
|---|---|---|---|---|
| chave de propriedade da AWS | a chave por trás do `AES256` do S3, a criptografia da seção anterior | a AWS, de forma invisível | não | não |
| chave gerenciada pela AWS | `aws/s3`, `aws/ebs`: criada na sua conta na primeira vez que um serviço precisa de uma | a AWS; você pode ler, não mudar | não | sim |
| chave gerenciada pelo cliente | uma chave que a clínica cria para os prontuários | **a clínica** | sim | sim |

A tabela vem da documentação do KMS. Duas consequências importam para quem defende. **Só uma chave
gerenciada pelo cliente deixa você dizer quem pode decifrar** separadamente de quem pode ler o
bucket. E **só chaves na sua conta deixam rastro** nos seus logs: toda decifração com uma chave
gerenciada pela AWS ou pelo cliente é um evento do CloudTrail, que a aula 15 lê, enquanto a chave de
propriedade da AWS trabalha onde você não vê.

## Uma chave gerenciada pelo cliente, no seu laboratório

Inicie o moto vazio e crie a chave da clínica. Um alias é um nome legível para ela, `alias/` mais o
que você escolher, para que nada precise citar o id da chave:

```
ana@laptop:~/aws$ k=$(aws kms create-key --description "clinic records" --query KeyMetadata.KeyId --output text)
ana@laptop:~/aws$ aws kms create-alias --alias-name alias/clinic-records --target-key-id "$k"
ana@laptop:~/aws$ aws kms describe-key --key-id alias/clinic-records --query "KeyMetadata.[KeyManager,KeyState,Origin]" --output text
CUSTOMER	Enabled	AWS_KMS
ana@laptop:~/aws$ aws kms list-aliases --query "Aliases[].AliasName"
[
    "alias/clinic-records",
    "alias/aws/acm",
    "alias/aws/dynamodb",
    "alias/aws/ebs",
    "alias/aws/elasticfilesystem",
    "alias/aws/es",
    "alias/aws/glue",
    "alias/aws/kinesisvideo",
    "alias/aws/lambda",
    "alias/aws/rds",
    "alias/aws/redshift",
    "alias/aws/s3",
    "alias/aws/secretsmanager",
    "alias/aws/ssm",
    "alias/aws/xray"
]
```

**`CUSTOMER` é a terceira linha da tabela**, `Enabled` é o estado da chave, e `AWS_KMS` diz que o
próprio KMS gerou o material da chave, em vez de recebê-lo de você. Entre os aliases, `alias/aws/`
seguido do nome de um serviço é como as chaves gerenciadas pela AWS são nomeadas. O moto lista os
nomes delas; numa conta real cada uma aparece na primeira vez que aquele serviço cifra algo para
você.

## A política da chave, que decide primeiro

Toda chave do KMS tem uma **política de chave**, uma política de recurso presa à chave, e uma chave
nova ganha esta, a menos que você escreva a sua. O `get-key-policy`, como a maioria das chamadas que
administram uma chave, recebe o id ou o ARN da chave e recusa o alias, na AWS como no moto; é para
isso que o `k` foi guardado:

```
ana@laptop:~/aws$ aws kms get-key-policy --key-id "$k" --policy-name default --query Policy --output text
{"Version": "2012-10-17", "Id": "key-default-1", "Statement": [{"Sid": "Enable IAM User Permissions", "Effect": "Allow", "Principal": {"AWS": "arn:aws:iam::123456789012:root"}, "Action": "kms:*", "Resource": "*"}]}
```

Ela permite `kms:*` ao principal `arn:aws:iam::123456789012:root`, e esse principal não quer dizer o
usuário raiz. **Quer dizer a conta**, e o que ele faz é passar a decisão ao IAM: qualquer usuário ou
papel cuja política de identidade permita uma ação do KMS nesta chave pode executá-la. Esse é o
padrão porque, sem ele, ninguém conseguiria administrar a chave.

A regra por baixo é a que torna o KMS diferente de quase todo outro serviço, e ela vem da
documentação do KMS: **nenhuma política do IAM concede uso de uma chave do KMS a menos que a política
da chave o permita**, diretamente ou passando a decisão à conta, como esta faz. Uma política de chave
que nomeia só o sistema de prontuários da clínica, e não passa mais a decisão à conta, é uma chave
com que um administrador com `AdministratorAccess` não consegue decifrar. É um controle forte e uma
borda afiada: uma política de chave que não nomeia mais ninguém capaz de mudá-la é uma chave que
ninguém administra, e o caminho de volta que o KMS documenta passa pelo Suporte da AWS.
