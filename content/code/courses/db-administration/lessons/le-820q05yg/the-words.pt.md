---
title: As palavras, e as armadilhas nelas
version: 1
---

As partes são as mesmas; **as palavras para o jeito de agrupar os dados não são**, e é aí que um
DBA que passa de um motor para outro se perde. A mesma palavra, `database`, nomeia um nível
diferente em cada um.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 304\" role=\"img\" aria-label=\"Quatro colunas, uma por motor, cada uma uma pilha de caixas aninhadas. PostgreSQL: cluster, database, schema, table. MySQL: server, depois database, que é a mesma coisa que schema, depois table. SQL Server: instance, database, schema, table. Oracle: banco contêiner, banco plugável, schema, que é a mesma coisa que um usuário, depois table.\"><text x=\"93.0\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\" font-weight=\"600\">PostgreSQL</text><rect x=\"10\" y=\"52\" width=\"166\" height=\"230\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"93.0\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">cluster</text><rect x=\"22\" y=\"84\" width=\"142\" height=\"166\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"93.0\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">database</text><rect x=\"34\" y=\"116\" width=\"118\" height=\"102\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"93.0\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">schema</text><rect x=\"46\" y=\"148\" width=\"94\" height=\"38\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"93.0\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">table</text><text x=\"271.0\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\" font-weight=\"600\">MySQL</text><rect x=\"188\" y=\"52\" width=\"166\" height=\"230\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"271.0\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">server</text><rect x=\"200\" y=\"84\" width=\"142\" height=\"166\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"271.0\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">database = schema</text><rect x=\"212\" y=\"116\" width=\"118\" height=\"102\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"271.0\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">table</text><text x=\"449.0\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\" font-weight=\"600\">SQL Server</text><rect x=\"366\" y=\"52\" width=\"166\" height=\"230\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"449.0\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">instance</text><rect x=\"378\" y=\"84\" width=\"142\" height=\"166\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"449.0\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">database</text><rect x=\"390\" y=\"116\" width=\"118\" height=\"102\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"449.0\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">schema</text><rect x=\"402\" y=\"148\" width=\"94\" height=\"38\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"449.0\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">table</text><text x=\"627.0\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\" font-weight=\"600\">Oracle</text><rect x=\"544\" y=\"52\" width=\"166\" height=\"230\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"627.0\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">CDB</text><rect x=\"556\" y=\"84\" width=\"142\" height=\"166\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"627.0\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">PDB</text><rect x=\"568\" y=\"116\" width=\"118\" height=\"102\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"627.0\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">schema = user</text><rect x=\"580\" y=\"148\" width=\"94\" height=\"38\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"627.0\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">table</text></svg>", "caption": "O que contém o quê. A caixa de fora é um servidor rodando em todos os motores; as palavras para os níveis de dentro são onde a confusão começa.", "same": ["PostgreSQL", "MySQL", "SQL Server", "Oracle"]}
```

**No PostgreSQL** um servidor é um **cluster**. Ele guarda vários **bancos** (databases), e uma
conexão é sempre a exatamente um deles: uma consulta não junta uma tabela de `shop` com uma de `ana`.
Dentro de um banco ficam os **esquemas** (schemas), espaços de nomes para tabelas, e uma consulta
junta tabelas de esquemas diferentes à vontade.

**No MySQL** não há nível entre o servidor e as tabelas. O que o MySQL chama de `DATABASE` é, pelo
significado de todos os outros motores, um esquema, e as duas palavras são sinônimas lá:
`CREATE SCHEMA` cria um database. Uma consulta junta tabelas de dois deles, porque são espaços de
nomes num servidor só, e não bancos separados.

**No SQL Server** uma **instância** guarda **bancos** e cada banco guarda **esquemas**, o mesmo
formato do PostgreSQL. A diferença está nas pessoas: um **login** é uma conta na instância, e um
**user** é a identidade desse login dentro de um banco. Alguém pode fazer login e ainda assim ser
recusado por um banco em que o seu login não tem user.

**No Oracle** o **esquema** e o **usuário** são uma coisa só: criar um usuário cria um esquema vazio
com o mesmo nome, e uma tabela pertence ao usuário que é dono dela. Desde a versão 12 um banco Oracle
pode ser um **contêiner** (CDB) com vários **bancos plugáveis** (PDBs), que é o nível que se comporta
como um banco do PostgreSQL.

## A mesma tabela, quatro endereços

| motor | como uma consulta a nomeia |
|---|---|
| PostgreSQL | `billing.invoices`, a partir de uma conexão ao banco certo |
| MySQL | `billing.invoices`, a partir de qualquer conexão, sendo `billing` um database |
| SQL Server | `shop.billing.invoices` — banco, esquema, tabela — ou `billing.invoices` dentro de `shop` |
| Oracle | `billing.invoices`, sendo `billing` o usuário dono dela |

**Quando alguém disser "o banco", pergunte de qual nível está falando.** Um pedido para "criar um
banco para o serviço novo" quer dizer um banco novo no PostgreSQL, um database novo (isto é, um
esquema) no MySQL, e no Oracle provavelmente um usuário novo. Errar não é um desastre, mas decide o
que pode ter backup, ser restaurado e receber grants separadamente, assunto das lições 12 e 20.
