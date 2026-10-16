---
title: Um processo para cada conexão
version: 1
---

Cada conexão ao PostgreSQL é atendida por um **processo próprio** no servidor, iniciado quando o
cliente se conecta e encerrado quando ele sai. Isso é simples e robusto, e sai caro nos dois pontos
que uma aplicação movimentada encontra primeiro: iniciar um processo leva milissegundos, e cada um
mantém a sua própria memória, então o servidor limita quantos podem existir com `max_connections`,
100 por padrão.

Uma aplicação com alguns servidores web, cada um abrindo vinte conexões, chega lá rápido. Uma
aplicação durante um failover também, quando todos os clientes se reconectam ao mesmo tempo. Peça mais:

```
ana@vm:~$ psql -XAt shop -c "SHOW max_connections"
100
ana@vm:~$ createdb bench && pgbench -q -i -s 10 bench > /dev/null 2>&1
ana@vm:~$ pgbench -c 120 -T 5 -n bench 2>&1 | tail -n 3
pgbench (16.15 (Ubuntu 16.15-0ubuntu0.24.04.1))
pgbench: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: FATAL:  sorry, too many clients already
pgbench: error: could not create connection for client 100
```

O 101º cliente, `client 100` contando a partir do zero, foi recusado com **`sorry, too many clients
already`**, e o `pgbench` desistiu. Para uma aplicação isso é um erro numa página, justo no momento
de maior carga.

Aumentar `max_connections` muda o muro de lugar sem removê-lo: mil processos, cada um querendo
memória e tempo de CPU numa máquina com quatro núcleos, passam mais tempo competindo do que
trabalhando. O que a aplicação precisa é de muitos **clientes**; o que o servidor faz bem é manter
poucas **conexões** ocupadas. Um **pooler de conexões** fica entre os dois.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"À esquerda, 120 clientes desenhados como uma coluna de caixinhas. Todos se conectam ao PgBouncer no meio, na porta 6433, que mantém uma fila de clientes esperando. Do PgBouncer, 20 conexões vão para o PostgreSQL à direita, na porta 5432, onde cada conexão é um processo do servidor. No modo transaction, um cliente segura uma das 20 só pelo tempo de uma transação.\"><rect x=\"20\" y=\"20\" width=\"70\" height=\"16\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><path d=\"M92 28 L258 115\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"20\" y=\"44\" width=\"70\" height=\"16\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><path d=\"M92 52 L258 115\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"20\" y=\"68\" width=\"70\" height=\"16\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><path d=\"M92 76 L258 115\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"20\" y=\"92\" width=\"70\" height=\"16\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><path d=\"M92 100 L258 115\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"20\" y=\"116\" width=\"70\" height=\"16\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><path d=\"M92 124 L258 115\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"20\" y=\"140\" width=\"70\" height=\"16\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><path d=\"M92 148 L258 115\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"20\" y=\"164\" width=\"70\" height=\"16\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><path d=\"M92 172 L258 115\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"20\" y=\"188\" width=\"70\" height=\"16\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><path d=\"M92 196 L258 115\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"55\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">120 clientes</text><rect x=\"260\" y=\"70\" width=\"160\" height=\"90\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"340\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">PgBouncer</text><text x=\"340\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">:6433</text><rect x=\"280\" y=\"124\" width=\"120\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"340\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">fila</text><rect x=\"560\" y=\"50\" width=\"140\" height=\"130\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"630\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">PostgreSQL</text><text x=\"630\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">:5432</text><text x=\"630\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">um processo cada</text><path d=\"M422 100 L558 100\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M422 112 L558 112\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M422 124 L558 124\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"490\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">20 conexões de servidor</text><text x=\"490\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">presa por uma transação</text></svg>", "caption": "Um pool no modo transaction: muitos clientes, uma fila, e poucas conexões de servidor que cada cliente pega emprestada por uma transação de cada vez."}
```
