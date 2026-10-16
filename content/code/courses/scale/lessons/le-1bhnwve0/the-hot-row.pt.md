---
title: A linha quente, onde nenhuma direção ajuda
version: 1
---

Tudo até aqui espalhou as vendas por cem shows. Uma abertura de vendas de verdade faz o contrário:
às dez da manhã um show entra à venda e todo comprador quer **aquele**. Aqui está o mesmo teste, 16
trabalhadores, com toda venda para o show 1, contra as três cópias da última seção:

```
ana@lab:~/tickets$ python3 load.py -m POST -c 16 -d 10 'http://localhost:8080/events/1/tickets'
requests  1398 in 10.1 s = 138.3 per second
latency   p50 80.7 ms  p95 351.5 ms  p99 527.8 ms  max 814.9 ms
status    201: 1398
```

138 por segundo, onde as mesmas três cópias venderam 470 espalhadas por cem shows. E com as cópias
reduzidas de volta a uma:

```
ana@lab:~/tickets$ python3 load.py -m POST -c 16 -d 10 'http://localhost:8080/events/1/tickets'
requests  1391 in 10.1 s = 137.2 per second
latency   p50 80.7 ms  p95 327.7 ms  p99 521.8 ms  max 753.3 ms
status    201: 1391
```

137 por segundo. **Três cópias vendem exatamente o que uma vende.** As cópias extras não estão
quebradas nem paradas; estão esperando.

## Esperando o quê

O PostgreSQL consegue dizer o que cada conexão está fazendo neste momento. Rodada enquanto o teste
acima acontecia, uma contagem das conexões ativas pelo que estavam esperando:

```
ana@lab:~/tickets$ docker compose exec db psql -U tickets -c "SELECT wait_event_type, wait_event, count(*) FROM pg_stat_activity WHERE datname = 'tickets' AND state = 'active' GROUP BY 1, 2 ORDER BY 3 DESC"
 wait_event_type |  wait_event   | count 
-----------------+---------------+-------
 Lock            | transactionid |    15
                 |               |     1
(2 rows)
```

Quinze conexões esperando um `Lock` do tipo `transactionid`, e uma trabalhando. **Quinze vendas
esperando outra venda terminar**, por causa de uma linha do `app.py`:

```sql
UPDATE events SET sold = sold + 1 WHERE id = %s AND sold < capacity RETURNING sold
```

Um `UPDATE` trava a linha que muda até a sua transação acabar, para que duas vendas não leiam
ambas `sold = 41` e escrevam ambas `42`. Isso é correto e necessário: é o que impede a bilheteria de
vender o lugar 42 duas vezes. O que torna isso caro é **por quanto tempo a trava fica segura**. A
transação atualiza a linha, depois chama o `sign()`, uns 7 ms de processador, depois insere o
ingresso, e só então confirma. Toda venda do show 1 segura a linha do show por esses 7 ms, e a
próxima venda do show 1 não começa até ela ser liberada.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Uma linha do tempo de três vendas do show 1. A venda A roda o UPDATE, segura a trava da linha enquanto assina por uns 7 milissegundos, insere o ingresso e confirma. A venda B chega durante a assinatura de A e espera até A confirmar, depois faz o mesmo. A venda C espera A e depois B. A linha fica com uma venda de cada vez, então as vendas vão uma depois da outra.\"><path d=\"M120 200 L700 200\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"120\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><text x=\"190\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">3.5</text><text x=\"260\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">7</text><text x=\"330\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10.5</text><text x=\"400\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">14</text><text x=\"470\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">17.5</text><text x=\"540\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">21</text><text x=\"610\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">24.5</text><text x=\"680\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">28</text><text x=\"700\" y=\"186\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">ms</text><text x=\"60\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">venda A</text><rect x=\"120.0\" y=\"40\" width=\"140.0\" height=\"24\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"190.0\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">linha travada: sign()</text><path d=\"M260.0 36 L260.0 68\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"266.0\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">COMMIT</text><text x=\"60\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">venda B</text><rect x=\"176.0\" y=\"94\" width=\"84.0\" height=\"16\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"3 3\"></rect><text x=\"218.0\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">espera</text><rect x=\"260.0\" y=\"90\" width=\"140.0\" height=\"24\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"330.0\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">linha travada: sign()</text><path d=\"M400.0 86 L400.0 118\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"406.0\" y=\"88\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">COMMIT</text><text x=\"60\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">venda C</text><rect x=\"218.0\" y=\"144\" width=\"182.0\" height=\"16\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"3 3\"></rect><text x=\"309.0\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">espera</text><rect x=\"400.0\" y=\"140\" width=\"140.0\" height=\"24\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"470.0\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">linha travada: sign()</text><path d=\"M540.0 136 L540.0 168\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"546.0\" y=\"138\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">COMMIT</text></svg>", "caption": "Três vendas do mesmo show. Cada uma segura a linha durante todo o sign(), então cada uma espera todas as anteriores."}
```

Então a bilheteria vende no máximo um ingresso por show a cada 7 ms mais ou menos, o que dá
1000 ÷ 7,2 ≈ 139 por segundo, tenha o que tiver atrás. É o número medido, com uma cópia e com três.
**Uma máquina maior também não ajuda**: o `sign()` rodaria um pouco mais rápido num processador
mais rápido, e nada mais mudaria, porque o trabalho não está esperando um processador. Está
esperando a sua vez.

## A forma geral

Um **ponto quente** (*hot spot*) é um pedaço de estado que uma grande parte do trabalho precisa
mudar, um de cada vez: uma linha, um contador, uma chave, uma trava, um arquivo. Ele transforma
qualquer número de cópias numa única fila. É o motivo mais comum para um sistema que escalava nos
testes parar de escalar em produção, porque os testes espalham a carga por igual e os usuários de
verdade não: todo mundo quer o mesmo show, o mesmo produto em promoção, o mesmo post do momento.

Há três saídas, e cada uma custa alguma coisa:

- **Segurar por menos tempo.** Assinar não precisa da trava; só escolher o lugar precisa. Mover o
  `sign()` e o insert para depois do commit cortaria o tempo que cada venda segura a linha para uma
  fração de milissegundo. O preço é um momento em que o lugar está tomado e o ingresso ainda não
  existe, e o programa agora precisa tratar isso se falhar no meio.
- **Dividir.** Em vez de um contador por show, manter dez, cada um dono de um décimo dos lugares, e
  deixar cada venda escolher um. Dez linhas são dez filas. O preço é que "quantos restam" agora é
  uma soma, e os últimos lugares ficam espalhados pelos contadores. A aula 2 faz isso com tabelas
  inteiras e chama de sharding.
- **Parar de pedir tudo de uma vez.** Deixar os compradores numa fila do lado de fora da
  bilheteria, e admiti-los no ritmo que a linha consegue servir. É isso que as salas de espera dos
  sites de ingresso de verdade são, e a aula 9 constrói o mecanismo.

O que não funciona é acrescentar cópias, e esse é o ponto desta seção: **a escala horizontal divide
o trabalho que pode ser dividido**, e não faz nada pela parte que não pode.
