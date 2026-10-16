---
title: DynamoDB, o que a chave não permite
version: 1
---

A tabela é rápida para toda pergunta que começa por um comprador. Aqui estão duas que não começam:

```
ana@lab:~/tickets$ ddb query --table-name tickets --key-condition-expression 'ticket = :t' --expression-attribute-values '{":t": {"S": "show-1#seat-42"}}'

An error occurred (ValidationException) when calling the Query operation: Query condition missed key schema element
ana@lab:~/tickets$ ddb scan --table-name tickets --filter-expression 'begins_with(ticket, :s)' --expression-attribute-values '{":s": {"S": "show-1#"}}' --return-consumed-capacity TOTAL --query '{Count: Count, ScannedCount: ScannedCount, CapacityUnits: ConsumedCapacity.CapacityUnits}'
{
    "Count": 3,
    "ScannedCount": 5,
    "CapacityUnits": 0.5
}
ana@lab:~/tickets$ docker rm -f dynamo
dynamo
```

**Uma consulta só pela chave de ordenação é recusada.** "Quem tem o lugar 42 do show 1?" nomeia um
ingresso e nenhum comprador, e o DynamoDB responde com uma `ValidationException`: uma consulta
precisa nomear a chave de partição, porque é assim que ele acha a partição a ler. Não existe um
planejador que recorra a ler tudo.

**Uma varredura (*scan*) lê tudo.** Ela percorre todo item da tabela e depois aplica o filtro.
`ScannedCount` é 5 e `Count` é 3: ela leu a tabela inteira para devolver três itens, e **a capacidade
é cobrada pelo que foi lido, não pelo que foi devolvido**. Em cinco itens isso dá meia unidade. Em
cinquenta milhões de itens é a tabela inteira de leituras a cada chamada, e uma varredura no caminho
de um pedido é o jeito mais comum de uma conta do DynamoDB surpreender o dono.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"A tabela tickets arrumada pela chave. Três partições, uma por comprador: ana com três itens ordenados pelo ingresso, show-1 seat-42, show-1 seat-43 e show-7 seat-3; bia com um; caio com um. Uma consulta por ana e ingressos que começam com show-1 lê dois itens vizinhos numa partição. Uma varredura lê os cinco itens de todas as partições.\"><rect x=\"20\" y=\"30\" width=\"210\" height=\"170\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"125\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">buyer = ana</text><rect x=\"35\" y=\"62\" width=\"180\" height=\"26\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"125\" y=\"75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">show-1#seat-42</text><rect x=\"35\" y=\"96\" width=\"180\" height=\"26\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"125\" y=\"109\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">show-1#seat-43</text><rect x=\"35\" y=\"130\" width=\"180\" height=\"26\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"125\" y=\"143\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">show-7#seat-3</text><rect x=\"255\" y=\"30\" width=\"210\" height=\"170\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">buyer = bia</text><rect x=\"270\" y=\"62\" width=\"180\" height=\"26\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">show-1#seat-44</text><rect x=\"490\" y=\"30\" width=\"210\" height=\"170\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"595\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">buyer = caio</text><rect x=\"505\" y=\"62\" width=\"180\" height=\"26\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"595\" y=\"75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">show-7#seat-4</text><text x=\"125\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">consulta: 2 lidos, 2 devolvidos</text><text x=\"480\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">varredura: 5 lidos, 3 devolvidos</text></svg>", "caption": "Uma consulta lê uma fatia de uma partição; uma varredura lê todo item e filtra depois."}
```

## Outra entrada: um índice secundário

Quando um segundo padrão de acesso importa, "quem tem este lugar", a resposta é um **índice
secundário global**: uma segunda cópia dos itens, mantida pelo DynamoDB, com outra chave, aqui o
ingresso. É o "uma tabela por consulta" da aula 4 feito pelo banco em vez do programa. Ele custa uma
segunda escrita para cada escrita, e **é atualizado de forma assíncrona**: uma consulta no índice logo
depois de uma escrita pode ainda não vê-la, que é o atraso de réplica da aula 2 num lugar novo.

## O que seria diferente no serviço de verdade

O DynamoDB Local responde os mesmos pedidos com os mesmos formatos, e é um processo na sua máquina. O
serviço não é:

- **as partições são reais.** Cada partição tem limites de leituras e escritas por segundo; uma chave
  de partição que leva a maior parte do tráfego, o show quente de novo, é estrangulada enquanto o
  resto da tabela está parado;
- **capacidade é dinheiro.** No modo `PAY_PER_REQUEST` toda leitura e escrita é cobrada; no modo
  provisionado você reserva um ritmo e os pedidos além dele são recusados. O Local informa unidades
  de capacidade e não cobra nada;
- **as leituras são eventualmente consistentes por padrão.** Uma leitura pode pedir consistência
  forte, pelo dobro do custo, que é a troca da aula 3 impressa na tabela de preços.

Remova o contêiner quando terminar, como fez o último comando acima.
