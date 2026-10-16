---
title: Versionamento, e o delete que não apaga nada
version: 1
---

**Um bucket versionado nunca sobrescreve e nunca apaga, a menos que você nomeie uma versão.** Todo
`PUT` numa chave acrescenta uma versão por cima das anteriores, e um `DELETE` sem versão acrescenta
mais uma, vazia, chamada marcador de exclusão, que faz a chave parecer ausente enquanto todo byte que
ela já guardou fica no bucket e na conta. As pessoas ligam o versionamento para proteger os dados e se
surpreendem duas vezes: primeiro porque um arquivo apagado pode voltar, e depois com o quanto custa
guardar todas as versões.

A lição 1 terminou numa sobrescrita que não tinha volta, porque aquele bucket não guardava versões.
Esta lição começa com o moto vazio, como toda lição, com o moto rodando no terminal dele e as quatro
linhas de "Seu laboratório, em resumo", da lição 1, digitadas neste. O bucket curado ganha
versionamento antes do primeiro objeto:

```
ana@laptop:~/aws$ aws s3 mb s3://quitanda-curated-prod
make_bucket: quitanda-curated-prod
ana@laptop:~/aws$ aws s3api get-bucket-versioning --bucket quitanda-curated-prod
ana@laptop:~/aws$ aws s3api put-bucket-versioning --bucket quitanda-curated-prod --versioning-configuration Status=Enabled
ana@laptop:~/aws$ aws s3api get-bucket-versioning --bucket quitanda-curated-prod
{
    "Status": "Enabled"
}
```

Um bucket novo responde ao `get-bucket-versioning` com nada, o que quer dizer que o versionamento
nunca foi ligado; esse estado se chama não versionado. `Enabled` é o segundo estado, e o terceiro,
`Suspended`, aparece no fim desta seção. **Não há volta para o não versionado**: um bucket que já teve
versionamento ligado só pode ser suspenso.

## Duas escritas, duas versões

A tabela curada de clientes da Quitanda é reescrita inteira toda noite. Escreva-a duas vezes:

```
ana@laptop:~/aws$ printf 'customer_id,city\nc-17,Santos\n' > customers.csv && aws s3 cp customers.csv s3://quitanda-curated-prod/customers/customers.csv
upload: ./customers.csv to s3://quitanda-curated-prod/customers/customers.csv
ana@laptop:~/aws$ printf 'customer_id,city\nc-17,Campinas\n' > customers.csv && aws s3 cp customers.csv s3://quitanda-curated-prod/customers/customers.csv
upload: ./customers.csv to s3://quitanda-curated-prod/customers/customers.csv
ana@laptop:~/aws$ aws s3api list-object-versions --bucket quitanda-curated-prod --query 'Versions[].[VersionId,IsLatest,Size,LastModified]' --output text
a55c0eb8-8736-4934-83b6-31b1aa70fe08	True	31	2026-10-16T16:11:06+00:00
fd4f0d85-b684-4c89-a9c4-5782a0a06eec	False	29	2026-10-16T16:11:05+00:00
ana@laptop:~/aws$ aws s3 cp s3://quitanda-curated-prod/customers/customers.csv -
customer_id,city
c-17,Campinas
ana@laptop:~/aws$ aws s3api get-object --bucket quitanda-curated-prod --key customers/customers.csv --version-id fd4f0d85-b684-4c89-a9c4-5782a0a06eec old.csv --query VersionId && cat old.csv
"fd4f0d85-b684-4c89-a9c4-5782a0a06eec"
customer_id,city
c-17,Santos
```

**As duas versões estão lá**, cada uma com o próprio `VersionId`, e a mais nova diz `IsLatest`. Um
`GET` simples da chave devolve a mais recente; um `GET` com `--version-id` devolve qualquer uma delas.
A mais antiga agora é uma versão não atual, e é cobrada exatamente como a atual: mesma classe, mesmo
preço por GB, enquanto existir.

## Um delete, e o caminho de volta

```
ana@laptop:~/aws$ aws s3 rm s3://quitanda-curated-prod/customers/customers.csv
delete: s3://quitanda-curated-prod/customers/customers.csv
ana@laptop:~/aws$ aws s3 ls s3://quitanda-curated-prod --recursive
ana@laptop:~/aws$ aws s3api get-object --bucket quitanda-curated-prod --key customers/customers.csv out.csv

aws: [ERROR]: An error occurred (NoSuchKey) when calling the GetObject operation: The specified key does not exist.
ana@laptop:~/aws$ aws s3api list-object-versions --bucket quitanda-curated-prod --query '{versions: Versions[].[VersionId,IsLatest], markers: DeleteMarkers[].[VersionId,IsLatest]}'
{
    "versions": [
        [
            "a55c0eb8-8736-4934-83b6-31b1aa70fe08",
            false
        ],
        [
            "fd4f0d85-b684-4c89-a9c4-5782a0a06eec",
            false
        ]
    ],
    "markers": [
        [
            "93880f0d-43ff-43e0-955f-00f8dab8a298",
            true
        ]
    ]
}
```

**A chave sumiu da listagem e do `GET`, e nada foi removido.** O `aws s3 rm` mandou um `DELETE` sem
versão, então o S3 acrescentou por cima um marcador de exclusão: uma versão sem bytes cujo único
trabalho é fazer a chave responder `NoSuchKey`. As duas versões de verdade continuam listadas, agora
as duas com `IsLatest` falso. É por isso que o versionamento protege contra o acidente mais comum, um
script que apaga o prefixo errado: o próprio marcador pode ser apagado.

```
ana@laptop:~/aws$ aws s3api delete-object --bucket quitanda-curated-prod --key customers/customers.csv --version-id 93880f0d-43ff-43e0-955f-00f8dab8a298
{
    "VersionId": "93880f0d-43ff-43e0-955f-00f8dab8a298"
}
ana@laptop:~/aws$ aws s3 cp s3://quitanda-curated-prod/customers/customers.csv -
customer_id,city
c-17,Campinas
```

**Apagar o marcador traz a chave de volta**, com os bytes da última versão escrita. Um `DELETE` que
nomeia uma versão é o único tipo que remove algo de vez, e remove aquela versão e nada mais. Uma
política de identidade, que a lição 4 põe para trabalhar, pode permitir `s3:DeleteObject`, que põe
marcadores, e negar `s3:DeleteObjectVersion`, que destrói versões; esse par é como um bucket deixa um
pipeline fazer faxina sem deixá-lo destruir nada.

## Suspenso não é desligado

Suspender é o terceiro estado, e aqui o moto e o S3 se separam:

```
ana@laptop:~/aws$ aws s3api put-bucket-versioning --bucket quitanda-curated-prod --versioning-configuration Status=Suspended
ana@laptop:~/aws$ printf 'customer_id,city\nc-17,Sorocaba\n' > customers.csv && aws s3 cp customers.csv s3://quitanda-curated-prod/customers/customers.csv
upload: ./customers.csv to s3://quitanda-curated-prod/customers/customers.csv
ana@laptop:~/aws$ aws s3api list-object-versions --bucket quitanda-curated-prod --query 'Versions[].[VersionId,IsLatest,Size]' --output text
null	True	31
ana@laptop:~/aws$ aws s3api get-object --bucket quitanda-curated-prod --key customers/customers.csv --version-id fd4f0d85-b684-4c89-a9c4-5782a0a06eec old.csv --query VersionId

aws: [ERROR]: An error occurred (NoSuchVersion) when calling the GetObject operation: The specified version does not exist.
```

**No S3 um bucket suspenso continua guardando todas as versões que tinha.** Escritas novas ganham o
id de versão `null`, que cada escrita seguinte substitui, e as duas versões escritas antes da
suspensão ficam onde estavam, listadas e cobradas. Suspender para o crescimento e mantém o histórico,
então não é um jeito de economizar com versões já guardadas; removê-las exige um `DELETE` por versão,
ou a regra de ciclo de vida da seção depois da próxima.

**O moto jogou o histórico fora.** A listagem mostra só a versão `null`, e a versão mais antiga, cujo
id o `get-object` de antes usou, agora dá `NoSuchVersion`. Isso é um defeito do moto 5.2.3 e o
contrário do que o S3 faz, e é a direção perigosa de errar: um script de limpeza testado aqui
pareceria ter apagado as versões antigas com a suspensão, e na AWS elas continuariam lá, e na conta.
