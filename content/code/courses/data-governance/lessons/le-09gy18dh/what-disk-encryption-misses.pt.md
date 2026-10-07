---
title: Onde a criptografia de disco termina
version: 1
---

A criptografia de volume termina no sistema operacional. No momento em que o PostgreSQL lê um
bloco, lê texto claro; toda consulta, toda réplica, toda exportação e todo backup feito pelo banco
recebem texto claro também. O jeito mais rápido de ver isso é o backup:

```
ana@lab:~/gov$ sudo -u postgres pg_dump -d ipe -t sales.customers | grep -m 1 "paula.cavalcanti"
1	Paula Cavalcanti Silva	paula.cavalcanti@example.com	372.874.168-09	1998-03-27	F	01589-076	São Paulo	SP	2025-01-07 12:04:18-03	t	2025-01-07 20:54:32-03
```

`pg_dump` é como a maioria dos backups de PostgreSQL é feita, e ele produziu a linha da Paula em
claro — nome, e-mail, CPF, data de nascimento — **numa máquina cujo disco podia estar inteiramente
cifrado**. O dump é um arquivo novo, fora do volume cifrado, e vai para onde os backups vão: outro
servidor, um object store, um notebook para um teste de restauração. Ele costuma viver mais que o
banco de onde veio e é lido por menos controles.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" data-fig=\"l3-where-it-ends\" aria-label=\"O banco no meio, num volume cifrado. Setas saem dele para quatro cópias que são texto claro a menos que cifradas à parte: um backup do pg_dump, uma réplica, uma exportação CSV para outro time, e o log do servidor. Só o que está dentro do volume é coberto pela criptografia do volume.\"><defs><marker id=\"dg-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"250.0\" y=\"60.0\" width=\"220.0\" height=\"140.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"360.0\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">volume cifrado</text><rect x=\"285.0\" y=\"100.0\" width=\"150.0\" height=\"70.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"127.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">PostgreSQL</text><text x=\"360.0\" y=\"143.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">ipe</text><rect x=\"20.0\" y=\"30.0\" width=\"160.0\" height=\"54.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"100.0\" y=\"49.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">backup do pg_dump</text><text x=\"100.0\" y=\"65.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">texto claro</text><rect x=\"20.0\" y=\"170.0\" width=\"160.0\" height=\"54.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"100.0\" y=\"189.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">uma réplica</text><text x=\"100.0\" y=\"205.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">texto claro</text><rect x=\"540.0\" y=\"30.0\" width=\"160.0\" height=\"54.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"620.0\" y=\"49.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">uma exportação CSV</text><text x=\"620.0\" y=\"65.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">texto claro</text><rect x=\"540.0\" y=\"170.0\" width=\"160.0\" height=\"54.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"620.0\" y=\"189.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">o log do servidor</text><text x=\"620.0\" y=\"205.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">texto claro</text><path d=\"M285.0 115.0 L182.0 64.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dg-ah-amber)\"></path><path d=\"M285.0 155.0 L182.0 196.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dg-ah-amber)\"></path><path d=\"M435.0 115.0 L538.0 64.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dg-ah-amber)\"></path><path d=\"M435.0 155.0 L538.0 196.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dg-ah-amber)\"></path></svg>", "caption": "Um disco cifrado cobre uma cópia. Toda cópia feita pelo banco começa em claro.", "same": ["PostgreSQL"]}
```

Então o inventário de cópias em texto claro é mais longo que o inventário de bancos:

- **backups e dumps**, que precisam ser cifrados como arquivos, com uma chave que não fica guardada
  ao lado deles — a aula 4 faz isso com uma chave de um serviço de gestão de chaves;
- **réplicas**, que precisam da mesma criptografia de volume e do mesmo TLS do primário;
- **exportações**: o CSV que um pipeline escreve para outro time, a planilha que um analista salva,
  o cache de resultados de uma ferramenta de BI;
- **logs**, que podem carregar valores, como a próxima seção mostra;
- **arquivos temporários**, que o PostgreSQL escreve quando uma ordenação não cabe na memória,
  dentro do diretório de dados e portanto no volume cifrado — o único item desta lista que o
  volume cobre.

Nada disso é motivo para não cifrar o disco. Cada item é um motivo para não parar ali, e para
tratar "cifrado em repouso" como uma afirmação sobre uma cópia, que precisa ser repetida para cada
outra.

## E as pessoas de dentro

A ameaça contra a qual o volume não faz nada é a que tem login. Um papel com `SELECT` numa coluna
a lê em claro, com disco cifrado ou não; o superusuário também, e também quem consegue ler a
memória do servidor ou os arquivos de log dele. As aulas 1 e 2 trataram de estreitar quem tem
`SELECT`. A próxima seção pergunta o que seria preciso para até o próprio banco guardar uma coluna
que ele não consegue ler.
