---
title: Índices compostos, e onde o emulador é mais fraco
version: 1
---

**Uma consulta que filtra ou ordena por dois campos precisa de um índice que tenha os dois, nessa
ordem, e o Firestore não cria esses sozinho.** Um **índice composto** é declarado: uma coleção ou um
collection group, uma lista de campos, cada um ascendente ou descendente. `pending-biggest` precisa de
`status` e depois `total_cents` descendente, para que todos os pedidos pendentes fiquem juntos no
índice já ordenados pelo total, e a consulta lê as cinco primeiras entradas desse trecho e para. Nenhum
índice de campo único tem esse formato, porque o de `status` é ordenado só por `status` e o de
`total_cents` mistura todos os status.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Dois índices sobre os mesmos pedidos. À esquerda, o índice de campo único em status: as quatro entradas pendentes estão juntas, mas os totais não têm ordem, 4287, 14730, 9960, 13410, então achar o maior exige ler todas e ordenar. À direita, o índice composto em status e depois total_cents descendente: as entradas pendentes estão juntas e já ordenadas, 14730, 13410, 9960, 4287, então a consulta lê as primeiras entradas desse trecho e para.\" data-fig=\"l10-composite\"><defs><marker id=\"ah-l10-composite\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M 0 0 L 10 5 L 0 10 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"30\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">índice de campo único</text><text x=\"30\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">status</text><rect x=\"30\" y=\"56\" width=\"300\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"42\" y=\"68\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">cancelled</text><text x=\"318\" y=\"68\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">12030</text><rect x=\"30\" y=\"86\" width=\"300\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"42\" y=\"98\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">delivered</text><text x=\"318\" y=\"98\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">6149</text><rect x=\"30\" y=\"116\" width=\"300\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"42\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">delivered</text><text x=\"318\" y=\"128\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">20040</text><rect x=\"30\" y=\"146\" width=\"300\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"42\" y=\"158\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">pending</text><text x=\"318\" y=\"158\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">4287</text><rect x=\"30\" y=\"176\" width=\"300\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"42\" y=\"188\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">pending</text><text x=\"318\" y=\"188\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">14730</text><rect x=\"30\" y=\"206\" width=\"300\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"42\" y=\"218\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">pending</text><text x=\"318\" y=\"218\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">9960</text><rect x=\"30\" y=\"236\" width=\"300\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"42\" y=\"248\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">pending</text><text x=\"318\" y=\"248\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">13410</text><text x=\"30\" y=\"286\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">pendentes juntos, totais sem ordem</text><text x=\"30\" y=\"304\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o maior exige ler toda entrada</text><text x=\"390\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">índice composto</text><text x=\"390\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">status, total_cents desc</text><rect x=\"390\" y=\"56\" width=\"300\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"402\" y=\"68\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">cancelled</text><text x=\"678\" y=\"68\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">12030</text><rect x=\"390\" y=\"86\" width=\"300\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"402\" y=\"98\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">delivered</text><text x=\"678\" y=\"98\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">20040</text><rect x=\"390\" y=\"116\" width=\"300\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"402\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">delivered</text><text x=\"678\" y=\"128\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">6149</text><rect x=\"390\" y=\"146\" width=\"300\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"402\" y=\"158\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">pending</text><text x=\"678\" y=\"158\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">14730</text><rect x=\"390\" y=\"176\" width=\"300\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"402\" y=\"188\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">pending</text><text x=\"678\" y=\"188\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">13410</text><rect x=\"390\" y=\"206\" width=\"300\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"402\" y=\"218\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">pending</text><text x=\"678\" y=\"218\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">9960</text><rect x=\"390\" y=\"236\" width=\"300\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"402\" y=\"248\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">pending</text><text x=\"678\" y=\"248\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">4287</text><text x=\"390\" y=\"286\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">pendentes juntos, o maior primeiro</text><text x=\"390\" y=\"304\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a consulta lê o topo e para</text></svg>", "caption": "Os mesmos pedidos pendentes em dois índices. Só o composto os guarda na ordem que pending-biggest pede."}
```

**A ideia errada é que o Firestore escolhe o melhor índice que tem.** Ele usa um índice que serve
exatamente à consulta, ou recusa. A recusa do Google Cloud é um `FAILED_PRECONDITION` cuja mensagem diz
que a consulta exige um índice e traz um link para o console com o índice já preenchido. É a
experiência que todo desenvolvedor de Firestore tem na primeira consulta real, e é a que o emulador
não dá.

## O emulador responde mesmo assim

```
ana@laptop:~/gcp$ python3 query.py pending-biggest
customers/c-34/orders/o-10046    2026-10-25 pending    14730 coffee-500g,rice-5kg,eggs-12
customers/c-31/orders/o-10033    2026-10-14 pending    13410 eggs-12,rice-5kg,coffee-500g
customers/c-23/orders/o-10014    2026-10-09 pending    12449 eggs-12,tomato,rice-5kg
customers/c-33/orders/o-10043    2026-10-17 pending    10168 rice-5kg,tomato
customers/c-26/orders/o-10020    2026-10-07 pending     9960 rice-5kg,eggs-12
ana@laptop:~/gcp$ python3 query.py lapa-late-october
customers/c-34/orders/o-10045    2026-10-21 delivered   9750 banana,rice-5kg
customers/c-22/orders/o-10011    2026-10-24 cancelled  12030 rice-5kg,banana,eggs-12
customers/c-26/orders/o-10021    2026-10-25 cancelled   7557 banana,tomato,rice-5kg
customers/c-34/orders/o-10046    2026-10-25 pending    14730 coffee-500g,rice-5kg,eggs-12
```

**As duas consultas responderam, sem índice composto nenhum.** O emulador no modo padrão, o Native, não
confere índice nenhum: responde ao que for perguntado, com um plano próprio que o Google Cloud não
rodaria. Um programa testado só contra ele pode ir para produção com uma consulta que falha na
primeira chamada, e nada no laptop teria avisado. **É aqui que o emulador é mais fraco que o
Firestore**, e o hábito que decorre disso é manter os índices compostos num arquivo desde o primeiro
dia, publicado com o código, em vez de esperar o erro.

**O emulador também não consegue dizer o que uma consulta leu.** O **Query Explain** do Firestore
devolve o plano e, com `analyze`, os documentos e as entradas de índice lidos e as operações de leitura
cobradas:

`explain.py`:

```python
#!/usr/bin/env python3
"""Ask Firestore what it read to answer a query: Query Explain."""
from google.cloud import firestore
from google.cloud.firestore_v1.base_query import FieldFilter
from google.cloud.firestore_v1.query_profile import ExplainOptions, QueryExplainError

db = firestore.Client(project='planner-dev')
query = db.collection_group('orders').where(filter=FieldFilter('status', '==', 'pending'))
try:
    results = query.get(explain_options=ExplainOptions(analyze=True))
    print(len(results), 'documents')
    print(results.get_explain_metrics())
except QueryExplainError as missing:
    print('no explain metrics:', missing)
```

```
ana@laptop:~/gcp$ python3 explain.py
no explain metrics: explain_metrics not available until query is complete.
```

**O emulador não devolveu métricas**, porque não as produz. No Google Cloud o mesmo programa imprime o
índice usado e as contagens; a própria página de preços nomeia o Query Explain como o jeito de
confirmar se uma consulta é cobrada pelas entradas de índice lidas.

## Declarar o índice, não executado

**No Google Cloud, o índice de `pending-biggest` é um comando**, mostrado aqui como você o digitaria.
**Ele não foi executado**: os comandos de índice vão para o serviço de administração do Firestore, que
não tem emulador, e nenhuma saída aparece.

```sh
gcloud firestore indexes composite create --collection-group=orders --query-scope=collection-group \
  --field-config=field-path=status,order=ascending \
  --field-config=field-path=total_cents,order=descending
```

**`--query-scope=collection-group` importa aqui**, porque a consulta lê toda coleção `orders` debaixo de
todo cliente; o mesmo índice com o escopo padrão, `collection`, serviria a uma consulta nos pedidos de
um cliente e não a esta. Um índice leva tempo para ser construído sobre os documentos que já existem,
e enquanto isso a consulta continua falhando. O Firestore documenta um limite de índices compostos por
banco, que é um motivo para projetar as consultas antes dos índices em vez de acrescentar um por tela.

**Todo índice composto é pago em toda escrita.** Um pedido novo é um documento, e vira uma entrada em
cada índice de campo único de cada campo dele e uma entrada em todo índice composto cujos campos ele
tem. Essas entradas são armazenamento, cobrado com os documentos, e trabalho que a escrita precisa
fazer antes de ser confirmada. Uma coleção com uma dúzia de índices compostos grava uma dúzia de
entradas a mais por documento, que é o motivo para manter a lista nas consultas que o app de fato
roda.

## O modo Datastore, que pode ser rígido

**O mesmo emulador tem um segundo modo que confere índices**, e é o mais perto que o laptop chega da
recusa real. O modo Datastore é o assunto da última seção; o que importa aqui são duas flags,
`--require-indexes` e `--index-file`, que a ajuda do emulador diz funcionarem só nesse modo. O arquivo
de índices está no formato do Datastore.

`index.yaml`:

```yaml
indexes:
- kind: Order
  properties:
  - name: status
  - name: total_cents
    direction: desc
```

Num terceiro terminal, numa porta própria:

```sh
cd ~/gcp && export PATH="$HOME/gcp/google-cloud-sdk/bin:$HOME/gcp/bin:$PATH" && source venv/bin/activate
gcloud emulators firestore start --database-mode=datastore-mode --require-indexes --index-file=index.yaml --host-port=localhost:8081
```

**Um banco em modo Datastore é lido por outra biblioteca cliente**, `google-cloud-datastore`, que não
está na lista da aula 1, e ela acha o emulador por `DATASTORE_EMULATOR_HOST`:

```sh
pip install -q google-cloud-datastore==2.27.0
```

`ds.py`:

```python
#!/usr/bin/env python3
"""The same orders as entities of kind Order, in a database in Datastore mode."""
from google.api_core.exceptions import FailedPrecondition
from google.cloud import datastore
from google.cloud.datastore.query import PropertyFilter

client = datastore.Client(project='planner-dev')
for n, (status, cents, day) in enumerate([('pending', 4287, '2026-10-10'), ('delivered', 6149, '2026-10-06'),
                                          ('pending', 12449, '2026-10-09'), ('pending', 9960, '2026-10-07')]):
    order = datastore.Entity(client.key('Order', f'o-{10001 + n}'))
    order.update({'status': status, 'total_cents': cents, 'day': day})
    client.put(order)

for sort in ('-total_cents', 'day'):
    query = client.query(kind='Order', filters=[PropertyFilter('status', '=', 'pending')], order=[sort])
    try:
        print(f'pending, by {sort:<13}', [order.key.name for order in query.fetch()])
    except FailedPrecondition as refused:
        print(f'pending, by {sort:<13}', 'refused:', refused.message)
```

```
ana@laptop:~/gcp$ DATASTORE_EMULATOR_HOST=localhost:8081 python3 ds.py
pending, by -total_cents  ['o-10003', 'o-10004', 'o-10001']
pending, by day           refused: The query requires a composite index that is not defined in your indexes file.
```

**A consulta para a qual o arquivo declara um índice respondeu, e a outra foi recusada**, com uma frase
que diz isso. O Datastore chama um documento de **entidade** (*entity*) e uma coleção de **kind**, e as
duas consultas são `pending-biggest` de novo e depois os pedidos pendentes por dia, que precisa de
`status` e depois `day`, um índice que ninguém declarou. Essa recusa é o que o Google Cloud faz nos dois
modos, e é o comportamento a esperar do serviço real, qualquer que tenha sido o modo no laptop.
