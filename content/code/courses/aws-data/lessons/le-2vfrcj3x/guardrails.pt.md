---
title: Workgroups, projeção de partições e CTAS
version: 1
---

**Um lago cobrado por byte precisa de um limite no byte**, porque a consulta cara não é uma
complicada: é um `SELECT *` sem filtro, digitado por alguém explorando, contra a tabela com mais
histórico. O limite do Athena mora num **workgroup**, a unidade em que toda consulta roda. Um
workgroup carrega onde os resultados são gravados, se as configurações dele valem por cima do que um
cliente pede, e quantos bytes uma consulta pode ler antes de o Athena cancelá-la.

## Um workgroup com corte

```
ana@laptop:~/aws$ aws athena create-work-group --name analysts --configuration 'ResultConfiguration={OutputLocation=s3://quitanda-athena-results-prod/analysts/},EnforceWorkGroupConfiguration=true,BytesScannedCutoffPerQuery=10485760'
ana@laptop:~/aws$ aws athena get-work-group --work-group analysts --query 'WorkGroup.Configuration.[BytesScannedCutoffPerQuery,EnforceWorkGroupConfiguration]' --output text
10485760	True
ana@laptop:~/aws$ aws athena start-query-execution --work-group analysts --query-string "SELECT * FROM quitanda.orders_csv"
{
    "QueryExecutionId": "3b75ad5a-d87c-49cf-9d27-370e0bcdd10a"
}
ana@laptop:~/aws$ aws athena get-query-execution --query-execution-id 3b75ad5a-d87c-49cf-9d27-370e0bcdd10a --query 'QueryExecution.[WorkGroup,Status.State,Statistics.DataScannedInBytes]' --output text
analysts	SUCCEEDED	0
```

**O moto guardou o corte e não fez valer nada.** `BytesScannedCutoffPerQuery` é 10.485.760, dez
megabytes, o menor corte que o Athena aceita, e `EnforceWorkGroupConfiguration` está ligado, então um
cliente não consegue mandar os resultados para outro lugar. Depois, um `SELECT *` sobre o mês em CSV,
uma tabela que o moto nem tem, num workgroup que deveria tê-lo parado em dez megabytes dos 40.641.097
que essa tabela guarda, voltou `SUCCEEDED` tendo lido 0 bytes. Na AWS essa consulta é cancelada assim
que a leitura passa do corte, e quem a digitou recebe um erro que nomeia o limite em vez de uma conta.

Essa é a parte desta seção que dava para rodar, e ela mostra só que a requisição está bem formada. O
que o corte faz não foi rodado aqui; está descrito a partir da documentação da AWS, e o lugar de ver
isso é a primeira consulta numa conta real que passar dele.

Mais duas coisas pertencem a um workgroup e valem ser configuradas no primeiro dia. **Um workgroup
por tipo de usuário**: as perguntas avulsas dos analistas, as perguntas agendadas do painel, os jobs
da noite. Cada um fica com o próprio prefixo de resultados, o próprio corte e a própria linha na
conta, porque o Athena informa os bytes por workgroup. E **um limite para o workgroup inteiro**, por hora ou por dia, que dispara um alarme quando é ultrapassado e não cancela nada. O corte por consulta para uma pergunta ruim; o limite do workgroup percebe um painel que faz uma pergunta
razoável vezes demais.

## Partições que ninguém precisa adicionar

"O Athena lê os arquivos onde eles estão" nomeou a surpresa mais comum, um dia que está no S3 e não
no catálogo. **A projeção de partições tira o catálogo da questão**: a tabela diz como os valores de
partição são formados, e o Athena calcula a lista de chaves de uma consulta em vez de procurá-la.
Para os pedidos, são algumas propriedades na tabela:

```sql
ALTER TABLE quitanda.orders SET TBLPROPERTIES (
  'projection.enabled'          = 'true',
  'projection.dt.type'          = 'date',
  'projection.dt.format'        = 'yyyy-MM-dd',
  'projection.dt.range'         = '2026-10-01,NOW',
  'projection.dt.interval'      = '1',
  'projection.dt.interval.unit' = 'DAYS',
  'storage.location.template'   = 's3://quitanda-curated-prod/orders/dt=${dt}/'
)
```

Com isso no lugar, o arquivo de hoje à noite pode ser lido amanhã de manhã sem nada registrado. Uma consulta por `dt = '2026-10-15'` vai direto a um prefixo sem perguntar ao catálogo quais partições existem, e numa tabela de dezenas de milhares de partições essa pergunta é onde vão os primeiros segundos de uma consulta. O preço é que o modelo agora é uma promessa sobre as chaves: um arquivo gravado com
qualquer outro nome fica invisível, e um dia sem arquivo é um prefixo que o Athena lista e encontra
vazio. Não foi rodado aqui, já que o moto não roda SQL do Athena; é a forma que a AWS documenta para
uma projeção de datas.

## CTAS: uma consulta que grava uma tabela

`CREATE TABLE … AS SELECT` roda uma consulta e grava o resultado como uma tabela nova, no formato que
você nomeia, sob o prefixo que você nomeia. **É como o próprio Athena transforma a camada raw na
curated**:

```sql
CREATE TABLE quitanda.orders_from_csv
WITH (
  format            = 'PARQUET',
  write_compression = 'SNAPPY',
  external_location = 's3://quitanda-curated-prod/orders_from_csv/',
  partitioned_by    = ARRAY['dt']
) AS
SELECT order_id, customer_id, hour, items, total_cents, payment, neighbourhood, dt
FROM quitanda.orders_csv
```

A coluna de partição vai por último no `SELECT`, que é a regra pela qual o CTAS a lê. A consulta é
cobrada como qualquer outra, pelo CSV que ela lê, uma vez, e toda consulta depois dela lê o Parquet.
Dois limites decidem se é a ferramenta certa. **Um CTAS grava no máximo 100 partições**, então os 31
dias de outubro cabem e um ano não, o que transforma uma carga do histórico numa série de comandos
`INSERT INTO` de cem dias cada. E é um comando sem memória do que fez ontem: o job que converte cada
dia novo, toda noite, é o assunto da lição 17. Este comando também não foi rodado.
