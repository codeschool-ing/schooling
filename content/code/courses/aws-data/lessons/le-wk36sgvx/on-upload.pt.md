---
title: Escolhendo a classe quando o objeto é escrito
version: 1
---

**A classe é uma propriedade de cada objeto, definida quando o objeto é escrito**, e a requisição que o
escreve é o mesmo `PutObject` de sempre, com um cabeçalho a mais. Não existe "bucket do Glacier" nem um
serviço à parte para onde mandar arquivos. A linha de comando expõe o cabeçalho como
`--storage-class`.

A Quitanda fecha cada mês exportando seus pedidos, e o arquivo de setembro é a primeira coisa que vai
para o bucket de arquivo. Crie um, com 500 pedidos:

```sh
mkdir -p export
printf 'order_id,customer_id,total_cents\n' > export/orders-2026-09.csv
for i in $(seq 1 500); do
  printf 'ord-09-%d,c-%d,%d\n' "$i" $((i % 40)) $((990 + i * 7)) >> export/orders-2026-09.csv
done
```

Depois ponha quatro cópias dele em quatro classes, o que ninguém faria com um arquivo só e é o jeito
mais rápido de ver o que muda e o que não muda:

```
ana@laptop:~/aws$ aws s3 mb s3://quitanda-archive-prod
make_bucket: quitanda-archive-prod
ana@laptop:~/aws$ aws s3 cp export/orders-2026-09.csv s3://quitanda-archive-prod/orders/2026-09/standard.csv
upload: export/orders-2026-09.csv to s3://quitanda-archive-prod/orders/2026-09/standard.csv
ana@laptop:~/aws$ aws s3 cp export/orders-2026-09.csv s3://quitanda-archive-prod/orders/2026-09/ia.csv --storage-class STANDARD_IA
upload: export/orders-2026-09.csv to s3://quitanda-archive-prod/orders/2026-09/ia.csv
ana@laptop:~/aws$ aws s3 cp export/orders-2026-09.csv s3://quitanda-archive-prod/orders/2026-09/instant.csv --storage-class GLACIER_IR
upload: export/orders-2026-09.csv to s3://quitanda-archive-prod/orders/2026-09/instant.csv
ana@laptop:~/aws$ aws s3 cp export/orders-2026-09.csv s3://quitanda-archive-prod/orders/2026-09/deep.csv --storage-class DEEP_ARCHIVE
upload: export/orders-2026-09.csv to s3://quitanda-archive-prod/orders/2026-09/deep.csv
ana@laptop:~/aws$ aws s3api list-objects-v2 --bucket quitanda-archive-prod --query "Contents[].[Key,StorageClass,Size]" --output text
orders/2026-09/deep.csv	DEEP_ARCHIVE	10295
orders/2026-09/ia.csv	STANDARD_IA	10295
orders/2026-09/instant.csv	GLACIER_IR	10295
orders/2026-09/standard.csv	STANDARD	10295
ana@laptop:~/aws$ aws s3api head-object --bucket quitanda-archive-prod --key orders/2026-09/ia.csv
{
    "AcceptRanges": "bytes",
    "LastModified": "2026-10-16T15:54:11+00:00",
    "ContentLength": 10295,
    "ETag": "\"bdb98a48e0b7c1ba562cd7d624f65c55\"",
    "ContentType": "text/csv",
    "Metadata": {},
    "StorageClass": "STANDARD_IA"
}
ana@laptop:~/aws$ aws s3api head-object --bucket quitanda-archive-prod --key orders/2026-09/standard.csv
{
    "AcceptRanges": "bytes",
    "LastModified": "2026-10-16T15:54:10+00:00",
    "ContentLength": 10295,
    "ETag": "\"bdb98a48e0b7c1ba562cd7d624f65c55\"",
    "ContentType": "text/csv",
    "Metadata": {}
}
```

**Toda cópia tem o mesmo tamanho e chega do mesmo jeito**; a única diferença é a palavra em
`StorageClass`. Repare no que o `head-object` faz com ela. Para a cópia em Standard-IA ele imprime
`"StorageClass": "STANDARD_IA"`, e para a cópia escrita sem classe ele não imprime campo
`StorageClass` nenhum. **Classe ausente quer dizer Standard**, no moto e no S3, e um programa que lê o
campo precisa tratar a ausência como `STANDARD` em vez de erro. O `list-objects-v2` é a exceção, e
preenche o campo para toda chave.

O arquivo tem 10.295 bytes, cerca de 10 KB. Na AWS, as cópias em Standard-IA e Glacier Instant
Retrieval seriam cobradas cada uma como 128 KB, e a cópia em Deep Archive como os próprios bytes mais os
40 KB que a seção anterior descreveu. O moto não cobra nada, então a listagem não diz nada disso.

## Os nomes que a linha de comando conhece

Os nomes das classes são uma lista fechada, e a linha de comando a confere antes de enviar qualquer
coisa:

```
ana@laptop:~/aws$ aws s3 cp export/orders-2026-09.csv s3://quitanda-archive-prod/orders/2026-09/x.csv --storage-class INFREQUENT_ACCESS 2>&1 | head -2

aws: [ERROR]: An error occurred (ParamValidation): argument --storage-class: Found invalid choice 'INFREQUENT_ACCESS'
```

`ParamValidation` é a recusa da própria linha de comando: nenhuma requisição chegou ao moto. Os nomes
válidos são `STANDARD`, `STANDARD_IA`, `ONEZONE_IA`, `INTELLIGENT_TIERING`, `GLACIER_IR`, `GLACIER`,
`DEEP_ARCHIVE` e o antigo `REDUCED_REDUNDANCY`, entre alguns para outros tipos de bucket. **`GLACIER` é
o Glacier Flexible Retrieval**: a classe manteve o nome quando o produto foi renomeado, e é por isso
que a API e a lista de preços discordam sobre como chamá-la.

## Mudando a classe de um objeto

A classe de um objeto só muda quando o objeto é escrito de novo. Copiá-lo sobre si mesmo com uma
classe nova faz isso:

```
ana@laptop:~/aws$ aws s3api head-object --bucket quitanda-archive-prod --key orders/2026-09/standard.csv --query "[StorageClass,LastModified,ETag]"
[
    null,
    "2026-10-16T15:54:10+00:00",
    "\"bdb98a48e0b7c1ba562cd7d624f65c55\""
]
ana@laptop:~/aws$ aws s3 cp s3://quitanda-archive-prod/orders/2026-09/standard.csv s3://quitanda-archive-prod/orders/2026-09/standard.csv --storage-class GLACIER_IR
copy: s3://quitanda-archive-prod/orders/2026-09/standard.csv to s3://quitanda-archive-prod/orders/2026-09/standard.csv
ana@laptop:~/aws$ aws s3api head-object --bucket quitanda-archive-prod --key orders/2026-09/standard.csv --query "[StorageClass,LastModified,ETag]"
[
    "GLACIER_IR",
    "2026-10-16T15:54:23+00:00",
    "\"bdb98a48e0b7c1ba562cd7d624f65c55\""
]
```

**O ETag ficou e o `LastModified` andou**, porque a cópia escreveu um objeto novo, com os mesmos bytes,
por cima do antigo. Na AWS isso é uma requisição `COPY`, com preço de `PUT`, e encerra cedo a vida do
objeto antigo: uma cópia que sai do Standard-IA nos primeiros 30 dias paga o resto dos 30. Fazer isso
à mão para alguns arquivos não tem problema. Para um prefixo inteiro, todo mês, é para isso que serve
uma regra de ciclo de vida, e a lição 3 escreve uma.
