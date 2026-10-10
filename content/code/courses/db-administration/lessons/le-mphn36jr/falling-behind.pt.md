---
title: Uma transação aberta, e nada é removido
version: 1
---

Quando uma tabela continua crescendo embora o autovacuum esteja ligado, o primeiro palpite é que o
autovacuum está lento demais e precisa de mais workers. **Em geral ele está rodando bem e não tem
permissão para remover nada.** Uma versão morta só pode sair quando nenhuma transação ainda puder
vê-la, e o servidor responde isso com um número: o snapshot mais antigo que alguma sessão ainda
mantém. Tudo o que morreu depois desse ponto fica, em todas as tabelas do banco, enquanto esse
snapshot continuar aberto.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 256\" role=\"img\" aria-label=\"Uma linha de ids de transação, dos mais antigos à esquerda aos mais novos à direita. Uma linha tracejada marca o snapshot mais antigo ainda aberto, mantido por uma sessão parada dentro de uma transação. Versões de linha que morreram à esquerda dela são removíveis e o VACUUM as recupera. Versões que morreram à direita dela ficam, porque aquela sessão ainda poderia lê-las. Quando a sessão faz commit, a linha vai para o presente e essas versões também ficam removíveis.\"><defs><marker id=\"arr\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L10,5 L0,10 z\" fill=\"var(--wire)\"></path></marker></defs><text x=\"20\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">ids de transação</text><line x1=\"20\" y1=\"150\" x2=\"690\" y2=\"150\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#arr)\"></line><text x=\"20\" y=\"168\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">mais antigos</text><text x=\"690\" y=\"168\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">mais novos</text><rect x=\"40\" y=\"60\" width=\"290\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"56\" y=\"78\" width=\"22\" height=\"16\" rx=\"2\" fill=\"none\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><rect x=\"88\" y=\"78\" width=\"22\" height=\"16\" rx=\"2\" fill=\"none\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><rect x=\"120\" y=\"78\" width=\"22\" height=\"16\" rx=\"2\" fill=\"none\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><rect x=\"152\" y=\"78\" width=\"22\" height=\"16\" rx=\"2\" fill=\"none\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><rect x=\"184\" y=\"78\" width=\"22\" height=\"16\" rx=\"2\" fill=\"none\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><rect x=\"216\" y=\"78\" width=\"22\" height=\"16\" rx=\"2\" fill=\"none\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><rect x=\"248\" y=\"78\" width=\"22\" height=\"16\" rx=\"2\" fill=\"none\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><rect x=\"280\" y=\"78\" width=\"22\" height=\"16\" rx=\"2\" fill=\"none\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><text x=\"185\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">morreram antes da linha</text><text x=\"185\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">o VACUUM as remove</text><line x1=\"370\" y1=\"40\" x2=\"370\" y2=\"160\" stroke=\"var(--amber)\" stroke-width=\"2\" stroke-dasharray=\"6 4\"></line><text x=\"370\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\" font-weight=\"600\">snapshot mais antigo ainda aberto</text><text x=\"370\" y=\"184\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">(a sessão parada na transação)</text><rect x=\"410\" y=\"60\" width=\"290\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"426\" y=\"78\" width=\"22\" height=\"16\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"458\" y=\"78\" width=\"22\" height=\"16\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"490\" y=\"78\" width=\"22\" height=\"16\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"522\" y=\"78\" width=\"22\" height=\"16\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"554\" y=\"78\" width=\"22\" height=\"16\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"586\" y=\"78\" width=\"22\" height=\"16\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"618\" y=\"78\" width=\"22\" height=\"16\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"650\" y=\"78\" width=\"22\" height=\"16\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"555\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">morreram depois da linha</text><text x=\"555\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\" font-weight=\"600\">ficam: aquela sessão ainda pode lê-las</text><path d=\"M370 200 Q 520 222 680 200\" stroke=\"var(--wire)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#arr)\"></path><text x=\"20\" y=\"240\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">depois do COMMIT a linha salta para o presente, e tudo à esquerda dela pode sair</text></svg>", "caption": "O VACUUM só pode remover uma versão morta se ela morreu antes do snapshot mais antigo que alguém ainda mantém. Uma transação parada segura essa linha para o banco inteiro."}
```

Quem mais faz isso é uma aplicação que abre uma transação, lê alguma coisa e depois espera: por uma
pessoa, por uma chamada remota, por um bug que a solte. Dá para criar uma com dois terminais. No
primeiro, abra uma transação em `REPEATABLE READ` e leia a cópia uma vez, o que fixa o snapshot, e
depois deixe esse terminal em paz:

@@2@@

No segundo, altere 100.000 linhas, descubra quem mantém um snapshot e rode o vacuum:

@@3@@

**`100000 are dead but not yet removable`** é a linha que você precisa conhecer. O VACUUM rodou,
leu as páginas, não removeu nada e disse por quê: `removable cutoff: 805` quer dizer que ele só
podia remover o que morreu antes da transação 805, e o `pg_stat_activity` mostra de quem é esse
número. A sessão em `idle in transaction` tem `backend_xmin` 805, o id de transação que seria o
próximo quando o snapshot dela foi tirado. O 806 é do próprio segundo terminal, tirado pelo
`SELECT` que estava perguntando.

O autovacuum recebe exatamente a mesma resposta. Num servidor movimentado ele continua visitando a
tabela, porque o `n_dead_tup` continua acima da linha, e cada visita lê as páginas e deixa as
mesmas versões mortas para trás. **Mais workers só leriam as mesmas páginas mais vezes.** A
correção está no primeiro terminal:

@@4@@

De volta ao segundo terminal, ninguém mais está parado dentro de uma transação, e o mesmo VACUUM
faz o seu trabalho:

@@5@@

`100000 removed`, e `index scans: 1` porque desta vez havia entradas na chave primária para tirar.
Nada na tabela mudou entre as duas execuções. Só o snapshot foi embora.

## O que mais segura a linha

Uma transação parada é a que você mais vai encontrar, e a consulta acima a encontra: `state` igual
a `idle in transaction` e um `xact_start` antigo. A lição 10 mostra como encerrar uma sessão assim e
o `idle_in_transaction_session_timeout`, que a encerra por você; a lição 15 de db-performance trata
de transações longas a fundo.

Uma consulta longa segura a linha do mesmo jeito enquanto roda, inclusive um relatório que leva três
horas. Duas coisas que nem são sessões também seguram, e o `pg_stat_activity` não as mostra: **uma
transação preparada** que ninguém confirmou nem desfez, listada em `pg_prepared_xacts`, e **um slot
de replicação** cujo consumidor parou, listado em `pg_replication_slots` com um `xmin` antigo. A
lição 11 de db-reliability explica os slots. Aqui basta saber que, quando o VACUUM diz `not yet
removable` e nenhuma sessão é antiga, essas duas views são onde olhar em seguida.
