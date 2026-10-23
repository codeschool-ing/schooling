---
title: A chave que atravessa a emenda
version: 1
---

**O jeito mais simples de deixar um job de um provedor agir em outro é criar um usuário no segundo,
dar a ele uma chave de acesso e colar a chave no primeiro. Funciona de primeira, nunca para de
funcionar, e esse é todo o problema.** Esta seção monta a versão da clínica no seu laboratório e
depois a lê do jeito que um auditor leria.

## O moto, com a verificação ligada

A aula 6 trata de permissões, mas esta seção já precisa que o moto distinga uma chave de outra.
Inicie-o no primeiro terminal com uma contagem de requisições que ele deixa passar antes de começar a
verificar:

```sh
INITIAL_NO_AUTH_ACTION_COUNT=3 moto_server -p 4567
```

As três primeiras requisições, enviadas com a chave `test`, criam um administrador e dão uma chave a
ele. A quarta é recusada, o que prova que a verificação está ligada, e o `export` passa este terminal
para a chave do administrador pelo resto da aula:

```
ana@laptop:~/aws$ aws iam create-user --user-name admin --query User.Arn --output text
arn:aws:iam::123456789012:user/admin
ana@laptop:~/aws$ aws iam attach-user-policy --user-name admin --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
ana@laptop:~/aws$ key=$(aws iam create-access-key --user-name admin)
ana@laptop:~/aws$ aws iam list-users

aws: [ERROR]: An error occurred (InvalidClientTokenId) when calling the ListUsers operation: The security token included in the request is invalid.
ana@laptop:~/aws$ export AWS_ACCESS_KEY_ID=$(echo "$key" | jq -r .AccessKey.AccessKeyId) AWS_SECRET_ACCESS_KEY=$(echo "$key" | jq -r .AccessKey.SecretAccessKey)
ana@laptop:~/aws$ aws sts get-caller-identity --query Arn --output text
arn:aws:iam::123456789012:user/admin
```

Uma função curta roda um comando com outra chave, sem mudar a do terminal. Digite-a uma vez; as
transcrições a usam sempre que uma requisição é feita como outra pessoa:

```sh
with_key() {
  local k=$1; shift
  AWS_ACCESS_KEY_ID=$(echo "$k" | jq -r .AccessKey.AccessKeyId) \
  AWS_SECRET_ACCESS_KEY=$(echo "$k" | jq -r .AccessKey.SecretAccessKey) "$@"
}
```

## O arranjo, do jeito que o caio montou

Um bucket para a exportação, um usuário para o job, uma política que deixa ele ler o bucket, e uma
chave:

```
ana@laptop:~/aws$ aws s3api create-bucket --bucket clinic-exports --create-bucket-configuration LocationConstraint=sa-east-1 --query Location --output text
/clinic-exports
ana@laptop:~/aws$ aws s3api put-object --bucket clinic-exports --key 2026-10-23.csv --query ETag --output text
"d41d8cd98f00b204e9800998ecf8427e"
ana@laptop:~/aws$ aws iam create-user --user-name reports-sync --query User.Arn --output text
arn:aws:iam::123456789012:user/reports-sync
ana@laptop:~/aws$ aws iam put-user-policy --user-name reports-sync --policy-name read-exports --policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":["s3:GetObject","s3:ListBucket"],"Resource":["arn:aws:s3:::clinic-exports","arn:aws:s3:::clinic-exports/*"]}]}'
ana@laptop:~/aws$ sync=$(aws iam create-access-key --user-name reports-sync)
```

Essa última linha é a que atravessa a emenda. **O JSON em `$sync` guarda uma chave de acesso
secreta, e na clínica ele foi colado na configuração de um job agendado no Google Cloud.** De lá,
toda noite, o job faz isto:

```
ana@laptop:~/aws$ with_key "$sync" aws s3api list-objects-v2 --bucket clinic-exports --query "Contents[].Key" --output text
2026-10-23.csv
```

Leia o arranjo pelo lado da AWS. Existe um usuário chamado `reports-sync`, que não é uma pessoa. Ele
tem uma chave, criada uma vez. Ele lê um bucket. **Nada na AWS diz onde a chave mora**: a outra
metade do arranjo está no console de outro provedor, atrás das permissões de outro provedor, e as
pessoas que conseguem lê-la lá não são pessoas que a AWS conhece.

## Lendo como um auditor

Duas perguntas acham uma chave dessas em qualquer conta. A primeira é o **relatório de
credenciais**, uma tabela que a AWS mantém de todo usuário do IAM e do estado das credenciais dele.
Peça o relatório e leia cinco das suas colunas:

```
ana@laptop:~/aws$ aws iam generate-credential-report --query State --output text
STARTED
ana@laptop:~/aws$ aws iam get-credential-report --query Content --output text | base64 -d | cut -d, -f1,9,10,11,13
user,access_key_1_active,access_key_1_last_rotated,access_key_1_last_used_date,access_key_1_last_used_service
admin,true,2026-10-23T03:47:15+00:00,2026-10-23T03:47:23+00:00,not_supported
reports-sync,true,2026-10-23T03:47:20+00:00,2026-10-23T03:47:21+00:00,not_supported
```

Na AWS o relatório leva alguns segundos para ficar pronto, e pedi-lo cedo demais é recusado com um
erro dizendo que ainda não está pronto; o moto o monta na hora. Na coluna do serviço o moto escreve
`not_supported`, onde a AWS escreve o nome do serviço que a chave chamou por último. A segunda
pergunta, o registro do último uso da própria chave, dá esse nome também no moto:

```
ana@laptop:~/aws$ aws iam get-access-key-last-used --access-key-id "$(echo "$sync" | jq -r .AccessKey.AccessKeyId)"
{
    "UserName": "reports-sync",
    "AccessKeyLastUsed": {
        "LastUsedDate": "2026-10-23T03:47:21.621049+00:00",
        "ServiceName": "s3",
        "Region": "sa-east-1"
    }
}
```

**Uma chave que foi rotacionada pela última vez no dia em que foi criada e é usada toda noite é uma
chave guardada por uma máquina.** Isso, sozinho, não é uma falha. O que a torna uma é tudo o que o
relatório não consegue dizer:

- **ela não vence.** A chave de acesso de um usuário do IAM vale até alguém desativá-la. Se o
  segredo vazar da configuração do job em 2028, ele ainda funciona em 2028;
- **o dono dela está do outro lado.** A equipe da AWS vê um usuário que não criou e não consegue
  inspecionar o lugar onde a chave está guardada. A equipe do Google Cloud vê um texto que recebeu e
  não administra;
- **rotacioná-la exige os dois lados ao mesmo tempo.** Uma chave nova precisa ser criada na AWS e
  colada no outro provedor antes de a antiga ser desligada. Quando isso exige duas equipes, não
  acontece, e é por isso que chaves desse tipo costumam ser achadas com anos de idade;
- **a trilha se divide.** A AWS registra que a chave leu o bucket, a partir de um endereço que
  pertence ao Google. Qual job, em qual projeto, rodado por quem, está nos logs do Google Cloud, e os
  dois registros não têm nada em comum além de um horário.

O último item dessa lista vem da documentação da AWS e do Google: o moto não guarda registros do
CloudTrail (aula 15), então o endereço de onde uma requisição veio não foi capturado aqui.

## As duas alavancas, testadas onde quebrar é de graça

Uma chave de acesso pode ser **desativada**, o que tem volta, ou **apagada**, o que não tem. Numa
conta real a ordem é sempre a mesma: desativar, esperar para ver se algo quebra, depois apagar. Teste
as duas aqui, onde quebrar o job noturno não custa nada:

```
ana@laptop:~/aws$ aws iam update-access-key --user-name reports-sync --access-key-id "$(echo "$sync" | jq -r .AccessKey.AccessKeyId)" --status Inactive
ana@laptop:~/aws$ with_key "$sync" aws s3api list-objects-v2 --bucket clinic-exports --query "Contents[].Key" --output text
2026-10-23.csv
```

**Este é um ponto em que o moto e a AWS discordam.** A chave foi marcada como `Inactive`, e o moto
ainda respondeu à requisição feita com ela. A AWS recusa uma requisição assinada com uma chave
inativa; a documentação dela diz isso, e isto não foi executado. A exclusão é algo que o moto aplica:

```
ana@laptop:~/aws$ aws iam delete-access-key --user-name reports-sync --access-key-id "$(echo "$sync" | jq -r .AccessKey.AccessKeyId)"
ana@laptop:~/aws$ with_key "$sync" aws s3api list-objects-v2 --bucket clinic-exports --query "Contents[].Key" --output text

aws: [ERROR]: An error occurred (InvalidAccessKeyId) when calling the ListObjectsV2 operation: The AWS Access Key Id you provided does not exist in our records.
```

`InvalidAccessKeyId`, *não existe nos nossos registros*: **para a API, uma chave apagada nunca
existiu.** A próxima seção troca a chave por algo que nem precisa ser aposentado.
