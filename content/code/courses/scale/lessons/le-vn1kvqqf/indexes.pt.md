---
title: Construindo um índice sem parar as escritas
version: 1
---

Um índice é a mudança mais comum feita numa tabela já em uso, geralmente porque uma consulta ficou
lenta. O `CREATE INDEX` lê a tabela inteira para construí-lo, e enquanto isso segura uma trava
`SHARE`, que deixa as leituras passarem e **bloqueia toda escrita**. Aqui ele constrói um índice em
`code` com vendas rodando em outro terminal:

```
ana@lab:~/tickets$ docker compose exec db psql -U tickets -c '\timing on' -c 'CREATE INDEX tickets_code ON tickets (code)'
Timing is on.
CREATE INDEX
Time: 4408.653 ms (00:04.409)
ana@lab:~/tickets$ python3 load.py -m POST -c 4 -d 8 --events 100 'http://localhost:8080/events/{event}/tickets'
requests  558 in 8.0 s = 69.7 per second
latency   p50 10.2 ms  p95 76.7 ms  p99 95.1 ms  max 4453.8 ms
status    201: 558
```

O índice levou **4,4 segundos**, e as vendas mostram isso: **558 em oito segundos, a pior com 4,45
segundos**. Toda venda que chegou durante a construção esperou ela terminar.

O `CREATE INDEX CONCURRENTLY` constrói o mesmo índice sem bloquear escritas. Ele toma a trava mais
fraca `SHARE UPDATE EXCLUSIVE`, lê a tabela uma vez, depois espera as transações que possam tê-la
mudado, e lê de novo para alcançar:

```
ana@lab:~/tickets$ docker compose exec db psql -U tickets -c '\timing on' -c 'CREATE INDEX CONCURRENTLY tickets_code ON tickets (code)'
Timing is on.
CREATE INDEX
Time: 5075.775 ms (00:05.076)
ana@lab:~/tickets$ python3 load.py -m POST -c 4 -d 8 --events 100 'http://localhost:8080/events/{event}/tickets'
requests  1275 in 8.1 s = 158.3 per second
latency   p50 15.2 ms  p95 71.9 ms  p99 79.6 ms  max 148.3 ms
status    201: 1275
```

**5,1 segundos em vez de 4,4**, e **1275 vendas com o pior caso em 148 ms**, o mesmo que sem nada
acontecendo. Mais lento para construir, invisível para a bilheteria.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"Duas rodadas de oito segundos de vendas enquanto um índice é construído sobre dois milhões de ingressos. Durante o CREATE INDEX, passaram 558 vendas e a mais lenta levou 4,45 segundos, o tempo da construção. Durante o CREATE INDEX CONCURRENTLY, passaram 1275 vendas e a mais lenta levou 148 milissegundos.\"><text x=\"240\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">vendas em 8 s</text><text x=\"540\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">venda mais lenta</text><text x=\"20\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">CREATE INDEX</text><rect x=\"150\" y=\"50\" width=\"72.96923076923078\" height=\"28\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"230.96923076923076\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">558</text><rect x=\"450\" y=\"50\" width=\"168.25466666666668\" height=\"28\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"626.2546666666667\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">4.45 s</text><text x=\"20\" y=\"144\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">… CONCURRENTLY</text><rect x=\"150\" y=\"130\" width=\"166.73076923076923\" height=\"28\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"324.7307692307692\" y=\"144\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">1275</text><rect x=\"450\" y=\"130\" width=\"5.602444444444445\" height=\"28\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"463.6024444444445\" y=\"144\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">148 ms</text></svg>", "caption": "O mesmo índice, construído de dois jeitos, medido do lado da bilheteria."}
```

## O que o concurrently custa

- **Ele é mais lento e faz mais trabalho**, duas passagens pela tabela e esperas no meio, o que numa
  tabela movimentada pode significar muito mais tempo que a construção comum.
- **Ele não roda dentro de um bloco de transação**, então uma ferramenta de migração que embrulha
  toda migração numa transação precisa ser avisada para deixar esta de fora.
- **Ele pode falhar no meio**, por exemplo quando um índice único encontra uma duplicata. Ele então
  deixa para trás um **índice inválido**, marcado `INVALID` no `\d tickets`, que deixa toda escrita
  mais lenta e não serve consulta nenhuma. Descarte-o com `DROP INDEX CONCURRENTLY` e construa de
  novo.
- **Ele espera transações antigas.** A transação longa da seção 03 também o seguraria, sem bloquear
  mais ninguém.

O `REINDEX CONCURRENTLY` reconstrói um índice existente do mesmo jeito, e o `DROP INDEX
CONCURRENTLY` remove um sem a trava `ACCESS EXCLUSIVE` que um `DROP INDEX` comum toma.
