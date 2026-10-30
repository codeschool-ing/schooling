---
title: "Unity Catalog: um lugar para dizer quem pode ler o quê"
version: 1
---

**O Unity Catalog é o catálogo de tabelas do Databricks e as permissões sobre elas, guardado acima dos
workspaces e não dentro de um.** Ele responde à pergunta que a lição 6 respondeu para um contêiner e a
lição 17 para um workspace, no nível de uma tabela, uma coluna ou uma linha: quem pode ler isto, e por
qual computação. Esta seção é ensinada a partir da documentação do Databricks e da Microsoft e não foi
executada; o SQL dela é o formato dos comandos, não uma transcrição.

## Três níveis, sob um metastore

**Toda tabela tem um nome de três partes, `catalog.schema.table`**, e os níveis são onde as
permissões são concedidas:

- **o metastore** é o topo: um por região, ligado a todo workspace dessa região que o usa, para que
  dois workspaces vejam os mesmos catálogos e os mesmos grants.
- **um catálogo** é o primeiro nível do nome, em geral um por ambiente ou por área do negócio:
  `quitanda_prd`, `quitanda_dev`.
- **um schema** agrupa tabelas, views, volumes de arquivos e funções: `quitanda_prd.sales`.
- **uma tabela** é a tabela Delta da lição 18, com um nome: `quitanda_prd.sales.orders`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 284\" role=\"img\" aria-label=\"O Unity Catalog desenhado como caixas aninhadas. Um metastore, um por região, guarda o catálogo quitanda_prd, que guarda o schema sales, que guarda a tabela externa orders e a tabela gerenciada tmp_afternoon; o nome completo da primeira é quitanda_prd.sales.orders, o nome que um grant cita. Os arquivos da tabela externa estão numa external location, curated em stquitandalakeprd, que usa uma storage credential, o access connector dbac-quitanda-prd, que lê o lago, o contêiner curated de stquitandalakeprd.\" data-fig=\"l21-uc\"><defs><marker id=\"l21u-ah\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L10,5 L0,10 z\" fill=\"var(--paper-dim)\"/></marker></defs><rect x=\"20\" y=\"20\" width=\"420\" height=\"250\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"/><text x=\"32\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">metastore: um por região</text><rect x=\"40\" y=\"54\" width=\"380\" height=\"200\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"/><text x=\"52\" y=\"72\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">catálogo</text><text x=\"408\" y=\"72\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">quitanda_prd</text><rect x=\"60\" y=\"88\" width=\"340\" height=\"150\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"/><text x=\"72\" y=\"106\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">schema</text><text x=\"388\" y=\"106\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">sales</text><rect x=\"240\" y=\"122\" width=\"150\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"315\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">tabela externa</text><text x=\"315\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">orders</text><rect x=\"80\" y=\"122\" width=\"150\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"/><text x=\"155\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">tabela gerenciada</text><text x=\"155\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">tmp_afternoon</text><text x=\"230\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">quitanda_prd.sales.orders</text><text x=\"230\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o nome de três partes que um grant cita</text><rect x=\"470\" y=\"30\" width=\"230\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"585\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">external location</text><text x=\"585\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">curated@stquitandalakeprd</text><rect x=\"470\" y=\"110\" width=\"230\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"585\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">storage credential</text><text x=\"585\" y=\"144\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">dbac-quitanda-prd</text><rect x=\"470\" y=\"190\" width=\"230\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"/><text x=\"585\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o lago</text><text x=\"585\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">stquitandalakeprd/curated</text><line x1=\"585\" y1=\"76\" x2=\"585\" y2=\"107\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" marker-end=\"url(#l21u-ah)\"/><line x1=\"585\" y1=\"156\" x2=\"585\" y2=\"187\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" marker-end=\"url(#l21u-ah)\"/><line x1=\"390\" y1=\"145\" x2=\"467\" y2=\"55\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\" marker-end=\"url(#l21u-ah)\"/><text x=\"645\" y=\"94\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">usa</text><text x=\"595\" y=\"174\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">lê como</text></svg>", "caption": "Nomes à esquerda, acesso à direita. Um grant é feito sobre um nome; os arquivos são alcançados por uma external location e pela identidade do connector, nunca com uma chave.", "same": ["schema", "external location", "storage credential"]}
```

**Tabelas gerenciadas e tabelas externas diferem em quem é dono dos arquivos.** Os arquivos de uma
tabela gerenciada vivem num armazenamento que o Unity Catalog escolhe e gerencia, e dar drop na tabela
os apaga. Uma tabela externa aponta para um caminho que você gerencia, numa external location, e dar
drop nela remove o nome e deixa os arquivos. Os pedidos curados da Quitanda, gravados pelo job noturno
no próprio lago, são externos; uma tabela que uma analista cria para a pergunta de uma tarde é
gerenciada, e vai embora quando recebe o drop.

## Chegando ao lago sem chave

**O Unity Catalog lê o armazenamento do Azure como uma identidade gerenciada, por dois objetos.** Uma
**storage credential** embrulha a identidade do access connector declarado na terceira seção. Uma
**external location** junta um caminho, como o contêiner curated de `stquitandalakeprd`, a essa
credencial, e é ela mesma algo sobre o que se concedem permissões. Nenhuma chave de armazenamento fica
escrita em lugar nenhum, e um cluster que lê a tabela de pedidos nunca segura uma credencial da conta:
o Unity Catalog confere o grant, e o acesso acontece pela identidade.

## Grants

**As permissões são concedidas em SQL e herdadas para baixo.** Para deixar as analistas lerem os
pedidos, elas precisam poder entrar no catálogo e no schema, e fazer select na tabela:

```sql
GRANT USE CATALOG ON CATALOG quitanda_prd TO `analysts`;
GRANT USE SCHEMA ON SCHEMA quitanda_prd.sales TO `analysts`;
GRANT SELECT ON TABLE quitanda_prd.sales.orders TO `analysts`;
```

`analysts` é um grupo, sincronizado do Entra ID; conceder a grupos e nunca a pessoas é o mesmo conselho
que a lição 9 de `azure-foundations` dá para os papéis do próprio Azure. Um `SELECT` concedido no
schema alcançaria toda tabela dele, presente e futura, o que é cômodo e também é como uma tabela nova
de endereços de clientes fica legível para as analistas no dia em que é criada.

**Abaixo de uma tabela, um filtro de linhas e uma máscara de coluna** deixam uma tabela mostrar linhas
diferentes ou uma coluna mascarada a grupos diferentes: o time de entregas vê os pedidos da região
dele, e só o grupo de finanças vê o CPF de um cliente sem máscara. São funções presas à tabela, e todo
motor que a lê pelo Unity Catalog as aplica.

## O que ele registra

**O Unity Catalog guarda uma auditoria de quem acessou o quê, e a linhagem das tabelas**: que
notebook ou job leu que tabelas para escrever quais, até a coluna, capturada enquanto os jobs rodam. O
Databricks expõe as duas como tabelas de sistema que um time pode consultar. Linhagem é a pergunta que
o Purview da lição 25 responde para a empresa inteira; o Unity Catalog a responde para tudo o que roda
no Databricks.

**O catálogo só é tão completo quanto o que passa por ele.** Um cluster ou uma ferramenta que lê a
conta de armazenamento direto, com uma chave ou um SAS da lição 6, vê todo arquivo e toda coluna, e o
Unity Catalog nunca fica sabendo. Os grants acima só são uma garantia quando nada lê o lago por fora
deles, o que para a Quitanda quer dizer tirar todas as outras entradas: as chaves da conta desligadas,
como a lição 6 recomenda, e a identidade do access connector como o único principal com papel de dados
no contêiner curated.
