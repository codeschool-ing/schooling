---
title: "Replay: o orquestrador roda de novo desde o topo"
version: 1
---

A imagem que quase todo mundo traz de um orquestrador é a de um gerador Python pausado no seu
`yield`, parado na memória até o resultado da atividade chegar. **Não é o que acontece.** Depois de
cada `yield` a execução do orquestrador acaba e o processo a esquece. Quando o resultado chega, a
extensão chama o orquestrador de novo, a partir da primeira linha, e responde a todo `yield` que já
respondeu com o histórico da instância, até o código chegar a um `yield` para o qual o histórico não
tem resposta. Esse é trabalho novo, e a execução acaba ali de novo. Isso é o **replay**, e é a razão
inteira de um orquestrador sobreviver a um reinício: não há nada na memória para perder.

É também a razão das regras no fim desta seção. Uma função que roda quatro vezes para um pedido
precisa decidir a mesma coisa quatro vezes.

## Quatro execuções para um pedido

A linha de log no topo de `order_flow` estava ali para isto. Peça ao log do host por ela, e pelas
três atividades, na ordem em que aconteceram:

```
ana@laptop:~/azure$ docker logs shopfn 2>&1 | grep -E "order_flow for A-1001|Executed 'Functions\.(reserve_stock|charge|ship)'" | head -7
      order_flow for A-1001, replaying=False
      Executed 'Functions.reserve_stock' (Succeeded, Id=7db1de6a-e19d-4b02-b9b9-cf07113cf2c2, Duration=1014ms)
      order_flow for A-1001, replaying=True
      Executed 'Functions.charge' (Succeeded, Id=3c28ebe7-079f-4ee1-9a8e-9e00996c090a, Duration=1007ms)
      order_flow for A-1001, replaying=True
      Executed 'Functions.ship' (Succeeded, Id=f0a1e5c6-4ce8-4ebf-8241-f790f0be8a3f, Duration=1005ms)
      order_flow for A-1001, replaying=True
```

**Um pedido, três atividades, e o orquestrador rodou quatro vezes.** A primeira execução chegou ao
primeiro `yield`, agendou `reserve_stock` e acabou. Quando a reserva ficou pronta, a segunda
execução começou do topo: `context.is_replaying` era `True`, o primeiro `yield` foi respondido pelo
histórico, e a execução seguiu até agendar `charge`. A quarta repetiu as três e chegou ao `return`.
Cada linha de log num orquestrador é impressa uma vez por execução, e esse é o comportamento
documentado, não uma falha: uma linha que deve aparecer uma vez é escrita atrás de
`if not context.is_replaying`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 318\" role=\"img\" aria-label=\"Quatro execuções de order_flow para A-1001. A execução 1 chega ao yield reserve_stock, agenda e para; 4 linhas no histórico. A execução 2 responde reserve_stock pelo histórico e agenda charge; 8 linhas. A execução 3 responde duas e agenda ship; 12 linhas. A execução 4 responde as três pelo histórico e retorna; 16 linhas. Só a execução 1 tem replaying=False.\"><text x=\"70\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">execução do orquestrador</text><text x=\"223.0\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">yield reserve_stock</text><text x=\"343.0\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">yield charge</text><text x=\"463.0\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">yield ship</text><text x=\"583.0\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">return</text><text x=\"670\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">linhas no histórico</text><text x=\"70\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">execução 1</text><text x=\"70\" y=\"81\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">replaying=False</text><rect x=\"168\" y=\"52\" width=\"110\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"223.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">agendada, e para</text><rect x=\"288\" y=\"52\" width=\"110\" height=\"40\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><rect x=\"408\" y=\"52\" width=\"110\" height=\"40\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><rect x=\"528\" y=\"52\" width=\"110\" height=\"40\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"670\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--amber)\" font-weight=\"600\">4</text><text x=\"70\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">execução 2</text><text x=\"70\" y=\"133\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">replaying=True</text><rect x=\"168\" y=\"104\" width=\"110\" height=\"40\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"223.0\" y=\"124.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">do histórico</text><rect x=\"288\" y=\"104\" width=\"110\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"343.0\" y=\"124.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">agendada, e para</text><rect x=\"408\" y=\"104\" width=\"110\" height=\"40\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><rect x=\"528\" y=\"104\" width=\"110\" height=\"40\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"670\" y=\"124.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--amber)\" font-weight=\"600\">8</text><text x=\"70\" y=\"169\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">execução 3</text><text x=\"70\" y=\"185\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">replaying=True</text><rect x=\"168\" y=\"156\" width=\"110\" height=\"40\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"223.0\" y=\"176.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">do histórico</text><rect x=\"288\" y=\"156\" width=\"110\" height=\"40\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"343.0\" y=\"176.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">do histórico</text><rect x=\"408\" y=\"156\" width=\"110\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"463.0\" y=\"176.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">agendada, e para</text><rect x=\"528\" y=\"156\" width=\"110\" height=\"40\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"670\" y=\"176.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--amber)\" font-weight=\"600\">12</text><text x=\"70\" y=\"221\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">execução 4</text><text x=\"70\" y=\"237\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">replaying=True</text><rect x=\"168\" y=\"208\" width=\"110\" height=\"40\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"223.0\" y=\"228.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">do histórico</text><rect x=\"288\" y=\"208\" width=\"110\" height=\"40\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"343.0\" y=\"228.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">do histórico</text><rect x=\"408\" y=\"208\" width=\"110\" height=\"40\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"463.0\" y=\"228.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">do histórico</text><rect x=\"528\" y=\"208\" width=\"110\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"583.0\" y=\"228.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">retorna</text><text x=\"670\" y=\"228.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--amber)\" font-weight=\"600\">16</text><rect x=\"168\" y=\"268\" width=\"16\" height=\"14\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"192\" y=\"275\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">respondida pelo histórico, nada roda</text><rect x=\"168\" y=\"290\" width=\"16\" height=\"14\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"192\" y=\"297\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">nova: escrita na fila, e a execução para</text></svg>", "caption": "O replay, como A-1001 passou por ele. Cada execução começa da primeira linha; os yields já respondidos saem do histórico, e o primeiro que não foi é trabalho novo. Cada execução acrescenta quatro linhas à tabela History."}
```

## O histórico é uma tabela

O provedor Azure Storage guarda o histórico de uma instância numa tabela da conta de armazenamento,
com o nome do task hub. O Azurite tem três:

```
ana@laptop:~/azure$ az storage table list --query "[].name" -o tsv
TestHubNameHistory
TestHubNameInstances
TestHubNamePartitions
```

`TestHubName` é o nome padrão do task hub fora do Azure; no Azure é o nome do function app.
**`TestHubNameHistory` é o registro de eventos, uma linha por evento, com o id da instância como
partition key**. Leia o de A-1001:

```
ana@laptop:~/azure$ az storage entity query -t TestHubNameHistory --filter "PartitionKey eq 'A-1001'" --query "items[].[RowKey, EventType, Name]" -o tsv
0000000000000000	OrchestratorStarted	None
0000000000000001	ExecutionStarted	order_flow
0000000000000002	TaskScheduled	reserve_stock
0000000000000003	OrchestratorCompleted	None
0000000000000004	OrchestratorStarted	None
0000000000000005	TaskCompleted	None
0000000000000006	TaskScheduled	charge
0000000000000007	OrchestratorCompleted	None
0000000000000008	OrchestratorStarted	None
0000000000000009	TaskCompleted	None
000000000000000A	TaskScheduled	ship
000000000000000B	OrchestratorCompleted	None
000000000000000C	OrchestratorStarted	None
000000000000000D	TaskCompleted	None
000000000000000E	ExecutionCompleted	None
000000000000000F	OrchestratorCompleted	None
sentinel	None	None
```

Dezesseis eventos e uma linha `sentinel` que o provedor guarda para si. Toda execução do orquestrador
fica entre `OrchestratorStarted` e `OrchestratorCompleted`. A primeira acrescentou a entrada
(`ExecutionStarted`) e o primeiro `TaskScheduled`; cada uma das seguintes acrescentou o resultado que
a acordou (`TaskCompleted`) e o próximo pedido; a última acrescentou `ExecutionCompleted`. Quatro
eventos por execução, quatro execuções. As linhas só são acrescentadas, nunca alteradas: a
documentação chama isso de padrão event sourcing, e avisa que as colunas da tabela são um auxílio de
depuração que pode mudar entre versões da extensão.

A segunda tabela guarda uma linha por instância, o que o endereço de status lê:

```
ana@laptop:~/azure$ az storage entity query -t TestHubNameInstances --filter "PartitionKey eq 'A-1001'" --query "items[0].{name: Name, status: RuntimeStatus, created: CreatedTime, completed: CompletedTime}"
{
  "completed": "2026-10-30T20:38:09.612420+00:00",
  "created": "2026-10-30T20:37:52.469068+00:00",
  "name": "order_flow",
  "status": "Completed"
}
```

A documentação descreve as duas tabelas como mantidas eventualmente consistentes entre si, sendo o
histórico a verdade. E as filas são onde o trabalho espera:

```
ana@laptop:~/azure$ az storage queue list --only-show-errors --query "[].name" -o tsv
testhubname-control-00
testhubname-control-01
testhubname-control-02
testhubname-control-03
testhubname-workitems
```

Quatro **filas de controle** levam as mensagens para os orquestradores (uma partida, o resultado de
uma atividade, um timer, um evento), e cada instância pertence a uma delas por um hash do seu id. A
**fila de work items** leva as atividades. São as mesmas filas do Azure que o gatilho da lição 15
lia, e por isso uma orquestração neste provedor custa transações de armazenamento além de
execuções.

## De onde vem a hora

Troque a linha de log de `order_flow` por uma que imprime dois relógios. O import vai sob
`import time`:

```python
from datetime import datetime, timezone
```

e a linha, agora duas, no lugar da antiga:

```python
    logging.info('order_flow for %s, replaying=%s, now=%s, context=%s', order['order'], context.is_replaying,
                 datetime.now(timezone.utc).time(), context.current_utc_datetime.time())
```

Construa, troque o contêiner e mande um pedido:

```
ana@laptop:~/azure$ grep -n -E "^from datetime|now=|current_utc_datetime.time" shopfn/function_app.py
4:from datetime import datetime, timezone
24:    logging.info('order_flow for %s, replaying=%s, now=%s, context=%s', order['order'], context.is_replaying,
25:                 datetime.now(timezone.utc).time(), context.current_utc_datetime.time())
ana@laptop:~/azure$ docker build -q -t shopfn:df1b shopfn
sha256:f5a46d22ccecac3a324669cfbff46dd7bcb2f09f8c05819d1d20d500a392e271
ana@laptop:~/azure$ docker rm -f shopfn
shopfn
ana@laptop:~/azure$ docker run -d --name shopfn --network functions -p 8080:80 -e AzureWebJobsStorage="$FN_STORAGE" -e WEBSITE_HOSTNAME=localhost:8080 -e AzureFunctionsWebHost__hostid=shopfn shopfn:df1b
3cf20270f8fe453c9a90db5e27ade9867a938f06b48897fb5ccd97e21ee1c5a8
ana@laptop:~/azure$ curl -s -o /dev/null -w 'HTTP %{http_code}\n' -XPOST localhost:8080/api/orders -d '{"order": "A-1003", "sku": "cap", "qty": 1}'
HTTP 202
ana@laptop:~/azure$ docker logs shopfn 2>&1 | grep -o "order_flow for A-1003.*"
order_flow for A-1003, replaying=False, now=20:38:56.266326, context=20:38:56.159828
order_flow for A-1003, replaying=True, now=20:38:57.544898, context=20:38:56.159828
order_flow for A-1003, replaying=True, now=20:38:58.609477, context=20:38:56.159828
order_flow for A-1003, replaying=True, now=20:38:59.663855, context=20:38:56.159828
```

**`now` mudou a cada execução; `context`, não.** O relógio da máquina dá a cada replay uma resposta
diferente, então qualquer decisão tomada a partir dele pode sair diferente na segunda execução e na
primeira. `context.current_utc_datetime` é lido do histórico: no topo da função ele é a hora da
execução que chegou lá primeiro, sempre. Ele avança à medida que o código passa por cada `yield`,
pelos mesmos valores em todo replay.

Se o orquestrador dissesse "depois das 18:00, despache amanhã" com `datetime.now()`, um pedido feito
às 17:59:59 poderia agendar `ship` na primeira execução e, repetido um segundo depois, tomar o outro
caminho. A extensão compara o que um replay pede com o que o histórico diz que foi pedido, e quando
diferem ela falha a instância com `Non-Deterministic workflow detected`. A seção `timers-and-events`
faz isso acontecer de propósito.

## As regras, e por que cada uma existe

A lista da documentação é longa, e todo item vem do mesmo fato: **um orquestrador tem de fazer os
mesmos pedidos na mesma ordem toda vez que roda.** Estas são as que um orquestrador em Python
encontra:

- **Nada de relógio**: `datetime.now()` ou `gmtime()`; use `context.current_utc_datetime`.
- **Nada de número aleatório nem de `uuid4()`**: pegue um valor aleatório de uma atividade, cujo
  resultado fica guardado, ou use `context.new_guid()`.
- **Nada de entrada ou saída**: nenhuma chamada HTTP, nenhum banco, nenhum arquivo, e nenhum binding
  além do gatilho de orquestração. Isso vai em atividades, que rodam uma vez por passo em vez de uma
  vez por replay; o orquestrador roda numa única thread para todas as orquestrações da instância,
  então uma chamada lenta ali atrasa todas.
- **Nada de variável de ambiente nem de global que possa mudar**: passe a configuração na entrada,
  ou faça uma atividade devolvê-la.
- **Nada de `time.sleep()`**: um timer durável no lugar, o assunto da seção `timers-and-events`.
- **Nada de `async def`**: o orquestrador é um gerador, e `yield` substitui `await`.

As atividades não têm nenhuma dessas regras. Elas rodam o código de verdade toda vez que são
chamadas, o que traz uma regra própria: a documentação descreve as mensagens por trás delas como
entregues pelo menos uma vez, então **uma atividade tem de ser segura de rodar duas vezes** para a
mesma entrada.

## O task hub, e os outros lugares onde ele pode morar

Não executado neste curso: tudo nesta parte precisa de uma assinatura.

**Um task hub é o estado das orquestrações de um app num backend.** O nome vem do `host.json`, em
`extensions.durableTask.hubName`; sem ele, a extensão usa o nome do app no Azure e `TestHubName` fora
dele. A documentação insiste que dois apps que dividem uma conta de armazenamento tenham cada um o
seu hub, deployment slots incluídos (lição 18), porque dois apps num mesmo hub pegam as mensagens um
do outro.

O provedor de armazenamento decide onde o hub mora, e a documentação, lida em 2026-10-30, lista
quatro:

| | onde fica o estado | o que saber |
|---|---|---|
| Azure Storage | tabelas, filas e blobs de uma conta de armazenamento sua | o padrão, e o que esta lição rodou; nada a configurar; no máximo 16 partições |
| Durable Task Scheduler | um recurso gerenciado do Azure, `Microsoft.DurableTask/schedulers`, acessado por gRPC | a recomendação da documentação; um painel; acesso por identidade; um emulador para trabalho local, não usado aqui |
| Netherite | Event Hubs e page blobs | a Microsoft encerra o suporte em 31 de março de 2028 e aponta para o Scheduler |
| MSSQL | um banco SQL Server ou Azure SQL | roda onde não há Azure nenhum |

Dois fatos decidem mais que o resto. **Um hub não pode ser movido de um provedor para outro**: a
resposta da documentação é um app novo no provedor novo. E o provedor é uma configuração no
`host.json` (`storageProvider` com um `type`), não uma mudança no orquestrador: o mesmo `order_flow`
roda nos quatro. Para um app Python, o quickstart do Scheduler pede o extension bundle na 4.32.0 ou
posterior.

No plano Consumption, acrescenta a documentação, **cada replay é cobrado como uma execução**, e o
tempo que um orquestrador passa esperando num `yield` não é cobrado. Os outros planos não cobram
pelos replays.
