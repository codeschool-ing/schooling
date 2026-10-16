---
title: Uma política de identidade que nega de verdade
version: 1
---

**Uma política de identidade diz o que um usuário ou papel pode fazer, e tudo o que ela não permite é
negado.** A lição 8 de `aws-foundations` é onde essa avaliação foi ensinada; aqui ela encontra o S3.
A única coisa que este laboratório não conseguia mostrar até agora é uma negação, porque por padrão o
moto não avalia política nenhuma: a lição 1 listou um bucket com uma chave que ninguém emitiu.

O moto tem um segundo modo, que avalia políticas de identidade. Ele é ligado por uma variável no
servidor, `INITIAL_NO_AUTH_ACTION_COUNT`, que é o número de requisições que o moto deixa passar sem
conferir antes de começar a conferir todas. Essas primeiras requisições são a preparação: um bucket,
um relatório, um usuário, a política do usuário e a chave do usuário, cinco requisições ao todo. Pare
o moto com `Ctrl+C` no terminal dele e ligue-o de novo assim:

```sh
INITIAL_NO_AUTH_ACTION_COUNT=5 moto_server -p 4567
```

Da sexta requisição em diante, o moto confere que a chave existe no IAM dele, e que o usuário da chave
pode fazer a ação. A chave `test` não está no IAM de ninguém, então ela só funciona nas cinco primeiras.

## A preparação, cinco requisições

O painel que mostra os relatórios da Quitanda precisa lê-los e nada mais. A política dele:

`reader.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::quitanda-curated-prod/reports/*"
    },
    {
      "Effect": "Allow",
      "Action": "s3:ListBucket",
      "Resource": "arn:aws:s3:::quitanda-curated-prod"
    }
  ]
}
```

O `GetObject` é permitido nos objetos sob `reports/` e o `ListBucket` no próprio bucket, que é outro
recurso: o ARN de um objeto carrega a chave dele, o do bucket não. Agora as cinco requisições:

```
ana@laptop:~/aws$ aws s3 mb s3://quitanda-curated-prod
make_bucket: quitanda-curated-prod
ana@laptop:~/aws$ aws s3 cp daily.csv s3://quitanda-curated-prod/reports/daily.csv
upload: ./daily.csv to s3://quitanda-curated-prod/reports/daily.csv
ana@laptop:~/aws$ aws iam create-user --user-name dashboard --query User.Arn --output text
arn:aws:iam::123456789012:user/dashboard
ana@laptop:~/aws$ aws iam put-user-policy --user-name dashboard --policy-name read-reports --policy-document file://reader.json
```

A quinta requisição cria a chave de acesso do painel, e **a chave secreta nunca é impressa**: um
segredo na tela é um segredo no histórico do terminal, numa gravação, numa captura de tela. O comando
abaixo lê as duas metades para variáveis e as põe onde a linha de comando procura chaves, para que o
resto deste terminal fale como o painel:

```sh
read -r AK SK < <(aws iam create-access-key --user-name dashboard \
  --query 'AccessKey.[AccessKeyId,SecretAccessKey]' --output text)
export AWS_ACCESS_KEY_ID=$AK AWS_SECRET_ACCESS_KEY=$SK
```

## O bucket visto pelo painel

```
ana@laptop:~/aws$ aws sts get-caller-identity --query Arn --output text
arn:aws:iam::123456789012:user/dashboard
ana@laptop:~/aws$ aws s3 cp s3://quitanda-curated-prod/reports/daily.csv -
day,orders,total_cents
2026-10-15,412,5108840
ana@laptop:~/aws$ aws s3 cp daily.csv s3://quitanda-curated-prod/reports/edited.csv
upload failed: ./daily.csv to s3://quitanda-curated-prod/reports/edited.csv An error occurred (AccessDenied) when calling the PutObject operation: Access Denied
ana@laptop:~/aws$ aws s3 ls

aws: [ERROR]: An error occurred (AccessDenied) when calling the ListBuckets operation: Access Denied
ana@laptop:~/aws$ AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test aws s3 cp s3://quitanda-curated-prod/reports/daily.csv -
download failed: s3://quitanda-curated-prod/reports/daily.csv to - An error occurred (403) when calling the HeadObject operation: Forbidden
```

**A leitura deu certo e a escrita foi recusada com `AccessDenied`.** Nada na política cita
`PutObject`, então ele é negado sem `Deny` nenhum, que é o padrão de onde toda política parte. O
`ListBuckets`, a requisição por trás de um `aws s3 ls` puro, foi recusado pelo mesmo motivo. E o
`get-caller-identity` nomeia o usuário, que é a primeira coisa a conferir sempre que uma permissão se
comporta de um jeito inesperado: a pergunta é sempre qual identidade perguntou. O último comando assina
com `test` de novo, e é recusado, porque da sexta requisição em diante essa chave não é de ninguém.

## O SignatureDoesNotMatch que é do moto

Listar o bucket é onde este modo tropeça em si mesmo, com um erro que não tem nada a ver com
permissões:

```
ana@laptop:~/aws$ aws s3 ls s3://quitanda-curated-prod

aws: [ERROR]: An error occurred (SignatureDoesNotMatch) when calling the ListObjectsV2 operation: The request signature we calculated does not match the signature you provided. Check your key and signing method.
ana@laptop:~/aws$ aws s3 ls s3://quitanda-curated-prod --recursive
2026-10-16 13:26:15         46 reports/daily.csv
ana@laptop:~/aws$ aws s3api list-objects-v2 --bucket quitanda-curated-prod --prefix reports/ --query 'Contents[].Key'

aws: [ERROR]: An error occurred (SignatureDoesNotMatch) when calling the ListObjectsV2 operation: The request signature we calculated does not match the signature you provided. Check your key and signing method.
ana@laptop:~/aws$ aws s3api list-objects-v2 --bucket quitanda-curated-prod --prefix reports --query 'Contents[].Key'
[
    "reports/daily.csv"
]
ana@laptop:~/aws$ url=$(aws s3 presign s3://quitanda-curated-prod/reports/daily.csv); curl -s -o /dev/null -w '%{http_code}\n' "$url"
500
```

**O `--recursive` funcionou e a listagem simples não, com a mesma chave, no mesmo bucket.** A
diferença é uma barra. Um `aws s3 ls` simples manda `delimiter=/` na query string, para agrupar as
chaves nas linhas `PRE` da lição 1, e o `--prefix reports/` do terceiro comando põe outra ali. Neste
modo o moto recalcula a assinatura de cada requisição para compará-la com a enviada, e o recálculo
dele erra quando um valor da query contém `/`: as duas assinaturas diferem e o moto culpa o cliente.
O S3 aceita as mesmas requisições. O jeito de contornar aqui é listar com `--recursive`, ou com um
prefixo sem barra.

Neste modo o moto também não consegue servir URLs pré-assinadas, com um erro interno, e é por isso
que a seção anterior rodou no modo padrão.

## De volta ao modo padrão

O terminal agora guarda as chaves do painel, e o moto recusa `test`. Pare o moto com `Ctrl+C`, ligue-o
do jeito de sempre, `moto_server -p 4567`, e ponha as chaves de volta:

```sh
export AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test
```

O resto desta lição roda no modo padrão, e as próximas seções dizem onde isso esconde o que o S3
faria.
