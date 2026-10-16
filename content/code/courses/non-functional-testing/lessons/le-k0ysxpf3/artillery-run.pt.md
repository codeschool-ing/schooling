---
title: Rodando o Artillery, e o relatório dele
version: 1
---

O `artillery run` recebe o arquivo e começa as fases. Enquanto roda, imprime um bloco de métricas a
cada dez segundos, um por período, e no fim um resumo da execução inteira. Com a bilheteria rodando
no primeiro terminal, mande a saída para um arquivo e olhe o resumo:

```
ana@nft:~/artillery$ artillery run boxoffice.yml > run.log; echo "exit $?"
exit 0
ana@nft:~/artillery$ sed -n '/Summary report/,$p' run.log
Summary report @ 16:53:51(-0300)
--------------------------------

http.codes.200: ................................................................ 56
http.codes.201: ................................................................ 50
http.codes.409: ................................................................ 6
http.downloaded_bytes: ......................................................... 8966
http.request_rate: ............................................................. 6/sec
http.requests: ................................................................. 112
http.response_time:
  min: ......................................................................... 6
  max: ......................................................................... 202
  mean: ........................................................................ 36.2
  median: ...................................................................... 19.1
  p95: ......................................................................... 68.7
  p99: ......................................................................... 94.6
http.response_time.2xx:
  min: ......................................................................... 6
  max: ......................................................................... 202
  mean: ........................................................................ 37.2
  median: ...................................................................... 22
  p95: ......................................................................... 68.7
  p99: ......................................................................... 94.6
http.response_time.4xx:
  min: ......................................................................... 9
  max: ......................................................................... 53
  mean: ........................................................................ 19.5
  median: ...................................................................... 13.1
  p95: ......................................................................... 16.9
  p99: ......................................................................... 16.9
http.responses: ................................................................ 112
vusers.completed: .............................................................. 56
vusers.created: ................................................................ 56
vusers.created_by_name.look and book: .......................................... 56
vusers.failed: ................................................................. 0
vusers.session_length:
  min: ......................................................................... 2027
  max: ......................................................................... 2240.7
  mean: ........................................................................ 2081.6
  median: ...................................................................... 2059.5
  p95: ......................................................................... 2101.1
  p99: ......................................................................... 2231

Checks:
ok: maxErrorRate < 1
ok: http.response_time.p95 < 200
```

**O relatório do Artillery é uma lista de contadores e distribuições, com o nome do que contam.**

| linha | o que diz aqui |
|---|---|
| `http.codes.200`, `.201`, `.409` | 56 espetáculos, 50 reservas feitas e 6 assentos já ocupados: toda resposta, por status |
| `http.requests`, `http.responses` | 112 mandadas e 112 respondidas |
| `http.response_time` | `min`, `max`, `mean`, `median`, `p95` e `p99` de todas as respostas, em milissegundos: uma mediana de 19.1 e um percentil 95 de 68.7 |
| `http.response_time.2xx`, `.4xx` | o mesmo, dividido pela classe do status: os 409, que pulam o pagamento, tiveram mediana de 13.1 |
| `vusers.created`, `vusers.completed` | 56 visitantes chegaram e 56 terminaram a jornada |
| `vusers.failed` | visitantes cuja jornada parou num erro, 0 |
| `vusers.session_length` | quanto durou uma jornada, em milissegundos: uma mediana de 2059.5, os dois segundos de reflexão mais duas requisições |
| `Checks` | uma linha por regra do `ensure`, `ok` ou `fail` |

**Um 409 não é erro para o Artillery**, então não é preciso nada parecido com o callback de resposta
do k6: um erro é uma requisição sem resposta, e um status é só contado. O outro lado disso é que um
500 também não é erro. Uma bilheteria respondendo 500 a toda reserva passaria no `maxErrorRate` e
apareceria só como `http.codes.500` na lista, então uma regra sobre códigos de status precisa ser
escrita como uma regra própria no `ensure`.

## Uma regra que reprova

`--overrides` troca parte do `config` pela linha de comando, como JSON, sem editar o arquivo. Aqui
ele define um percentil 95 de 5 ms, que nenhuma resposta desta bilheteria alcança:

```
ana@nft:~/artillery$ artillery run boxoffice.yml --overrides '{"config": {"ensure": {"thresholds": [{"http.response_time.p95": 5}]}}}' > fail.log; echo "exit $?"
exit 1
ana@nft:~/artillery$ sed -n '/^Checks/,$p' fail.log
Checks:
ok: maxErrorRate < 1
fail: http.response_time.p95 < 5
```

**Uma regra reprovada faz o `artillery run` sair com 1**, e o bloco `Checks` diz qual com `fail:`.
Sem o `ensure` no arquivo, a execução teria saído com 0 fossem quais fossem os tempos.

`artillery run --output report.json` também escreve as métricas de cada período num arquivo JSON,
que é o que um pipeline guarda como registro da execução. A empresa do Artillery oferece um painel
hospedado que lê esses resultados; é um serviço pago na internet e não é usado neste curso.
