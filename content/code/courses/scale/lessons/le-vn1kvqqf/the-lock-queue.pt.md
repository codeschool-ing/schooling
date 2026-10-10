---
title: A fila de travas
version: 1
---

Acrescentar uma coluna que aceita nulo é uma das mudanças mais rápidas que existem: o PostgreSQL a
registra no catálogo e não toca em linha nenhuma. Ainda assim ela precisa de `ACCESS EXCLUSIVE`
naquele instante. Aqui está o que acontece quando ela não consegue a trava na hora.

Três terminais. No primeiro, uma transação longa que leu a tabela: um relatório lento, ou uma sessão
que alguém deixou aberta com `BEGIN` e foi embora. Aqui ela conta os ingressos e depois dorme vinte
segundos antes de confirmar:

```
ana@lab:~/tickets$ docker compose exec db psql -U tickets -c 'BEGIN' -c 'SELECT count(*) FROM tickets' -c 'SELECT pg_sleep(20)' -c 'COMMIT'
BEGIN
  count  
---------
 2000000
(1 row)

 pg_sleep 
----------
 
(1 row)

COMMIT
```

Num segundo terminal, dois segundos depois, a coluna, com `\timing` para o psql dizer quanto levou:

```
ana@lab:~/tickets$ docker compose exec db psql -U tickets -c '\timing on' -c 'ALTER TABLE tickets ADD COLUMN gate text'
Timing is on.
ALTER TABLE
Time: 18057.004 ms (00:18.057)
```

E num terceiro, um segundo depois disso, oito segundos de vendas:

```
ana@lab:~/tickets$ python3 load.py -m POST -c 4 -d 8 --events 100 'http://localhost:8080/events/{event}/tickets'
requests  4 in 10.0 s = 0.4 per second
status    TimeoutError: 4
```

**Quatro pedidos, todos com tempo esgotado, e nenhum ingresso vendido em dez segundos.** O próprio
`ALTER TABLE` informou **18,1 segundos**, para uma mudança que leva alguns milissegundos de
trabalho.

## Quem esperava quem

Enquanto os três rodavam, um quarto comando perguntou ao PostgreSQL o que cada conexão ativa estava
fazendo:

```
ana@lab:~/tickets$ docker compose exec db psql -U tickets -c "SELECT pid, wait_event_type, wait_event, left(query, 40) AS query FROM pg_stat_activity WHERE datname = 'tickets' AND state = 'active' AND pid <> pg_backend_pid() ORDER BY backend_start"
 pid | wait_event_type | wait_event |                  query                   
-----+-----------------+------------+------------------------------------------
 201 | Timeout         | PgSleep    | SELECT pg_sleep(20)
 217 | Lock            | relation   | ALTER TABLE tickets ADD COLUMN gate text
 218 | Lock            | relation   | INSERT INTO tickets (event_id, seat, cod
 219 | Lock            | relation   | INSERT INTO tickets (event_id, seat, cod
 220 | Lock            | relation   | INSERT INTO tickets (event_id, seat, cod
 221 | Lock            | relation   | INSERT INTO tickets (event_id, seat, cod
(6 rows)
```

Leia de cima para baixo. A transação longa dorme, segurando `ACCESS SHARE` em `tickets` desde o seu
`SELECT`. O `ALTER TABLE` espera um `Lock` do tipo `relation`: ele quer `ACCESS EXCLUSIVE`, que
conflita com aquele `ACCESS SHARE`. E **quatro `INSERT`s esperam atrás do `ALTER`**, embora a trava
de um `INSERT` não conflite em nada com a transação longa.

Essa é a **fila de travas**. O PostgreSQL concede travas na ordem em que são pedidas, e um pedido que
conflita com outro **que já está esperando** também espera, para que o `ALTER` não seja preterido
por um fluxo de recém-chegados. A consequência é que uma mudança de esquema esperando uma trava
**bloqueia todos que chegam depois dela**, enquanto espera, mesmo sem ter feito nada ainda.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"A fila de travas da tabela tickets. Na frente, a transação longa segura ACCESS SHARE. Atrás dela, o ALTER TABLE espera ACCESS EXCLUSIVE, que conflita com ela. Atrás do ALTER, quatro INSERTs esperam ROW EXCLUSIVE: a trava deles não conflita com a transação longa, mas conflita com o ALTER que espera na frente, então eles também entram na fila.\"><rect x=\"20\" y=\"90\" width=\"150\" height=\"70\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"95\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">transação longa</text><text x=\"95\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ACCESS SHARE</text><text x=\"95\" y=\"144\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">segura</text><rect x=\"230\" y=\"90\" width=\"170\" height=\"70\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"315\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">ALTER TABLE</text><text x=\"315\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ACCESS EXCLUSIVE</text><text x=\"315\" y=\"144\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">espera 18 s</text><path d=\"M230 125 L172 125\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M172 125 L178.3 122.0 L178.3 128.0 Z\" fill=\"var(--amber)\" stroke=\"none\"></path><rect x=\"470\" y=\"30\" width=\"150\" height=\"38\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"545\" y=\"43\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">INSERT</text><text x=\"545\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">ROW EXCLUSIVE</text><path d=\"M470 49 L402 125\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M402 125 L403.9 118.3 L408.5 122.3 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><rect x=\"470\" y=\"80\" width=\"150\" height=\"38\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"545\" y=\"93\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">INSERT</text><text x=\"545\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">ROW EXCLUSIVE</text><path d=\"M470 99 L402 125\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M402 125 L406.8 119.9 L409.0 125.6 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><rect x=\"470\" y=\"130\" width=\"150\" height=\"38\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"545\" y=\"143\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">INSERT</text><text x=\"545\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">ROW EXCLUSIVE</text><path d=\"M470 149 L402 125\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M402 125 L409.0 124.2 L406.9 130.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><rect x=\"470\" y=\"180\" width=\"150\" height=\"38\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"545\" y=\"193\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">INSERT</text><text x=\"545\" y=\"208\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">ROW EXCLUSIVE</text><path d=\"M470 199 L402 125\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M402 125 L408.5 127.6 L404.0 131.7 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><text x=\"545\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">esperam atrás do ALTER</text><text x=\"95\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">SELECT, depois dorme 20 s</text></svg>", "caption": "Uma mudança esperando a trava bloqueia todos que chegam depois dela, embora ainda não tenha feito nada."}
```

Então o perigo não é a mudança; é a **combinação** de uma trava forte com qualquer coisa demorada
rodando na tabela, cujo fim ninguém controla. A próxima seção é a defesa.
