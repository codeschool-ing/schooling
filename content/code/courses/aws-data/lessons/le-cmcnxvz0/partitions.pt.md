---
title: Partições, uma linha cada
version: 1
---

**Uma partição é uma linha no catálogo com um valor e um prefixo próprio.** A tabela diz que `dt`
vem da chave; cada partição diz um valor de `dt` e onde estão os arquivos desse valor. Um leitor que
quer `dt = '2026-10-15'` pede essa linha ao catálogo, recebe um local e não lista mais nada. É assim
que o Athena pula 30 dias de 31, e é por isso que o dia novo da lição 15 ficou invisível para o
Athena até alguém acrescentar a linha dele.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" aria-label=\"Duas caixas lado a lado. À esquerda, o Glue Data Catalog em sa-east-1 guarda o banco quitanda, que guarda a tabela orders: sete colunas em Parquet, um local e a chave de partição dt. Dentro da tabela ficam as partições, uma linha cada, para dt 2026-10-01, 2026-10-02 e 2026-10-31, e 31 linhas ao todo. À direita, o S3 guarda os bytes: o bucket quitanda-curated-prod com um prefixo por dia, cada um com orders.parquet. Uma seta vai de cada linha de partição até o prefixo dela.\" data-fig=\"l16-catalog\"><rect x=\"10\" y=\"10\" width=\"370\" height=\"300\" rx=\"6\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"24\" y=\"28\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Glue Data Catalog, sa-east-1</text><rect x=\"24\" y=\"42\" width=\"342\" height=\"256\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"38\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">banco</text><text x=\"74\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">quitanda</text><rect x=\"38\" y=\"72\" width=\"314\" height=\"214\" rx=\"4\" fill=\"none\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\"></rect><text x=\"52\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">tabela</text><text x=\"93\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">orders</text><text x=\"52\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">7 colunas, Parquet</text><text x=\"52\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">s3://quitanda-curated-prod/orders/</text><text x=\"52\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">chave de partição</text><text x=\"155\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">dt</text><text x=\"52\" y=\"164\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">partições, uma linha cada</text><rect x=\"52\" y=\"180\" width=\"286\" height=\"20\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"62\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">dt=2026-10-01</text><rect x=\"52\" y=\"206\" width=\"286\" height=\"20\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"62\" y=\"216\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">dt=2026-10-02</text><rect x=\"52\" y=\"252\" width=\"286\" height=\"20\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"62\" y=\"262\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">dt=2026-10-31</text><text x=\"62\" y=\"239\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">… 31 linhas</text><rect x=\"420\" y=\"10\" width=\"290\" height=\"300\" rx=\"6\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"434\" y=\"28\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">S3, os bytes</text><text x=\"434\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">quitanda-curated-prod</text><rect x=\"434\" y=\"180\" width=\"262\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"444\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">orders/dt=2026-10-01/orders.parquet</text><line x1=\"338\" y1=\"190\" x2=\"428\" y2=\"190\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><path d=\"M 428 186 L 434 190 L 428 194 Z\" fill=\"var(--phosphor)\"></path><rect x=\"434\" y=\"206\" width=\"262\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"444\" y=\"216\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">orders/dt=2026-10-02/orders.parquet</text><line x1=\"338\" y1=\"216\" x2=\"428\" y2=\"216\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><path d=\"M 428 212 L 434 216 L 428 220 Z\" fill=\"var(--phosphor)\"></path><rect x=\"434\" y=\"252\" width=\"262\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"444\" y=\"262\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">orders/dt=2026-10-31/orders.parquet</text><line x1=\"338\" y1=\"262\" x2=\"428\" y2=\"262\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><path d=\"M 428 258 L 434 262 L 428 266 Z\" fill=\"var(--phosphor)\"></path><text x=\"444\" y=\"239\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">…</text></svg>", "caption": "O catálogo descreve e o S3 guarda. Cada partição é uma linha com um valor de dt e um prefixo próprio; uma consulta filtrada em dt pede as linhas ao catálogo e abre só os prefixos delas.", "same": ["Glue Data Catalog, sa-east-1"]}
```

## Trinta e uma linhas

O lago precisa dos arquivos antes de as partições significarem alguma coisa, então o `lake.py` da
lição 15 grava outubro de novo no moto vazio:

```
ana@laptop:~/aws$ aws s3 mb s3://quitanda-raw-prod && aws s3 mb s3://quitanda-curated-prod
make_bucket: quitanda-raw-prod
make_bucket: quitanda-curated-prod
ana@laptop:~/aws$ python3 lake.py
755,511 orders in 31 days
  s3://quitanda-raw-prod/raw/orders/  31 objects    40,641,097 bytes
  s3://quitanda-curated-prod/orders/  31 objects    12,703,975 bytes
```

Uma partição carrega um storage descriptor inteiro, colunas e formato incluídos, o que torna 31 delas
muita coisa para digitar. Um programa curto as escreve a partir do próprio JSON da tabela, mudando
só o local:

`partitions.py`:

```python
import json
import sys

table = json.load(open('orders-table.json'))
storage = table['StorageDescriptor']
partitions = []
for d in range(1, 32):
    day = f'2026-10-{d:02d}'
    partitions.append({'Values': [day],
                       'StorageDescriptor': dict(storage, Location=f"{storage['Location']}dt={day}/")})
json.dump(partitions, sys.stdout, indent=1)
```

```
ana@laptop:~/aws$ python3 partitions.py > partitions.json && jq length partitions.json
31
ana@laptop:~/aws$ aws glue batch-create-partition --database-name quitanda --table-name orders --partition-input-list file://partitions.json
ana@laptop:~/aws$ aws glue get-partitions --database-name quitanda --table-name orders --query 'length(Partitions)'
31
```

**Uma requisição criou 31 linhas**, e o `batch-create-partition` aceita até 100 por vez, então um
ano de dias são quatro requisições. Pedir algumas de volta é um filtro nas chaves de partição,
escrito quase como SQL:

```
ana@laptop:~/aws$ aws glue get-partitions --database-name quitanda --table-name orders --expression "dt BETWEEN '2026-10-10' AND '2026-10-12'" --query 'Partitions[].[Values[0],StorageDescriptor.Location]' --output text
2026-10-10	s3://quitanda-curated-prod/orders/dt=2026-10-10/
2026-10-11	s3://quitanda-curated-prod/orders/dt=2026-10-11/
2026-10-12	s3://quitanda-curated-prod/orders/dt=2026-10-12/
ana@laptop:~/aws$ aws glue get-partitions --database-name quitanda --table-name orders --expression "payment = 'pix'"

aws: [ERROR]: An error occurred (InvalidInputException) when calling the GetPartitions operation: Invalid partition expression!
```

**Essa expressão é o que o Athena envia quando uma consulta filtra em `dt`.** O catálogo responde
com três linhas e os locais delas, e o motor abre esses três prefixos e nenhum outro. O moto avaliou
as duas expressões de verdade. A segunda filtra em `payment`, uma coluna dentro dos arquivos, e o
catálogo a recusou, porque não sabe nada do que há dentro deles.

## Uma linha não é um arquivo

Enviado uma segunda vez, o lote não falha por inteiro. Ele responde com um erro por partição que já
existe:

```
ana@laptop:~/aws$ aws glue batch-create-partition --database-name quitanda --table-name orders --partition-input-list file://partitions.json --query 'length(Errors)'; echo "exit $?"
31
exit 0
ana@laptop:~/aws$ aws glue batch-create-partition --database-name quitanda --table-name orders --partition-input-list file://partitions.json --query 'Errors[0]'
{
    "PartitionValues": [
        "2026-10-01"
    ],
    "ErrorDetail": {
        "ErrorCode": "AlreadyExistsException",
        "ErrorMessage": "Partition already exists."
    }
}
```

**31 erros e um código de saída zero**, então um script que repete o mesmo lote toda noite nem
quebra nem percebe. Um job que registra o próprio dia deve ler a lista `Errors` em vez de confiar no
código de saída.

E uma partição pode nomear um prefixo onde não há nada:

```
ana@laptop:~/aws$ aws glue create-partition --database-name quitanda --table-name orders --partition-input '{"Values": ["2026-12-25"], "StorageDescriptor": {"Location": "s3://quitanda-curated-prod/orders/dt=2026-12-25/"}}'
ana@laptop:~/aws$ aws glue get-partitions --database-name quitanda --table-name orders --expression "dt > '2026-10-31'" --query 'Partitions[].Values[0]' --output text
2026-12-25
ana@laptop:~/aws$ aws s3 ls s3://quitanda-curated-prod/orders/dt=2026-12-25/; echo "exit $?"
exit 1
ana@laptop:~/aws$ aws glue delete-partition --database-name quitanda --table-name orders --partition-values 2026-12-25
```

**O catálogo aceitou o dia de Natal, e o S3 não tem nada sob ele.** A linha e os arquivos são dois
fatos guardados em dois serviços, e nada amarra um ao outro: uma partição sem arquivos é uma consulta
que não devolve nada, e um prefixo sem partição é um dia que não existe para o Athena. O último
comando tirou a linha de novo, porque o resto desta lição conta o que está lá.

## Quem acrescenta as linhas

Há quatro jeitos, e um lago costuma acabar usando dois deles:

- **quem grava**, que chama `batch-create-partition` logo depois de gravar um dia, então a linha
  existe no momento em que os arquivos existem;
- **`MSCK REPAIR TABLE`** no Athena, que lista o prefixo inteiro e acrescenta o que falta, e fica
  mais lento conforme o prefixo cresce;
- **um crawler**, a próxima seção;
- **a projeção de partições**, da lição 15, que não precisa de linha nenhuma.

## Quanto custa o catálogo

```
ana@laptop:~/aws$ python3 prices.py glue
AWS public price list, sa-east-1, USD, excluding tax

Glue, USD
  ETL job, per DPU-hour                                 0.69000  DPU-hour
  ETL job, Flex, per DPU-hour                           0.45000  DPU-hour
  crawler, per DPU-hour                                 0.69000  DPU-hour
  Data Catalog, per 100,000 objects beyond free         1.00000  month
  Data Catalog, per million requests beyond free        1.00000  million
```

**As duas linhas do catálogo dizem "beyond free"**, e a parte grátis é grande: a página de preços da
AWS dá o primeiro milhão de objetos guardados e o primeiro milhão de requisições por mês sem
cobrança. Um objeto é um banco, uma tabela, uma partição ou uma versão de tabela. Este lago é um
banco, uma tabela e 31 partições, 33 objetos, e dez anos de 20 tabelas particionadas por dia seriam
73.000 partições, ainda abaixo do milhão grátis. **As requisições são a linha que cresce**: toda
consulta do Athena pede ao catálogo a tabela e as partições dela, então um painel de muitos gráficos
atualizado a cada minuto é onde o catálogo deixa de ser grátis, a 1 dólar o milhão de requisições
além do primeiro milhão.
