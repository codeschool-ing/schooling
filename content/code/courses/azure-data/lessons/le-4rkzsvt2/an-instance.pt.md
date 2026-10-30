---
title: Uma instância, não um banco
version: 1
---

**A Azure SQL Managed Instance aluga uma instância inteira do SQL Server, onde o Azure SQL Database
aluga um banco.** O motor é o mesmo. O que muda é a fronteira: dentro de uma instância, muitos bancos
ficam lado a lado, uma consulta pode nomear dois deles, o SQL Agent roda jobs numa agenda, e os logins
pertencem à instância e não a um banco. Tudo o que a lição 8 listou em "não há instância" volta aqui,
e continua rodado, atualizado e com backup feito pela Microsoft.

**Esta seção é ensinada a partir da documentação da Microsoft, e nada nela foi rodado contra o
Azure.** As duas seguintes rodam os próprios recursos de instância, no SQL Server do contêiner, que
também é uma instância inteira.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Duas fronteiras lado a lado. À esquerda, o Azure SQL Database: um servidor lógico com dois bancos, quitanda e delivery, cada um na sua caixa; uma consulta de quitanda que nomeia delivery.dbo.deliveries é recusada, e não há SQL Agent. À direita, a SQL Managed Instance, dentro de uma sub-rede da rede virtual da empresa: uma caixa de instância com os bancos quitanda, delivery e msdb, com o SQL Agent rodando jobs a partir do msdb, uma consulta de quitanda lendo delivery diretamente, e um linked server alcançando outro SQL Server.\" data-fig=\"l09-boundary\"><defs><marker id=\"arr-l09-boundary-phosphor\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M 0 0 L 10 5 L 0 10 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"arr-l09-boundary-wire\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M 0 0 L 10 5 L 0 10 z\" fill=\"var(--wire)\"></path></marker></defs><text x=\"30\" y=\"24\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">Azure SQL Database</text><rect x=\"20\" y=\"40\" width=\"300\" height=\"220\" rx=\"10\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 4\"></rect><text x=\"34\" y=\"58\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">servidor lógico</text><rect x=\"40\" y=\"90\" width=\"110\" height=\"70\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"95\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">quitanda</text><rect x=\"190\" y=\"90\" width=\"110\" height=\"70\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"245\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">delivery</text><line x1=\"150\" y1=\"125\" x2=\"186\" y2=\"125\" stroke=\"var(--amber)\" stroke-width=\"1.6\" stroke-dasharray=\"3 3\"></line><line x1=\"162\" y1=\"144\" x2=\"174\" y2=\"156\" stroke=\"var(--amber)\" stroke-width=\"1.8\"></line><line x1=\"174\" y1=\"144\" x2=\"162\" y2=\"156\" stroke=\"var(--amber)\" stroke-width=\"1.8\"></line><text x=\"170\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">recusado</text><text x=\"170\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">sem SQL Agent</text><text x=\"380\" y=\"24\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">SQL Managed Instance</text><rect x=\"370\" y=\"40\" width=\"330\" height=\"250\" rx=\"10\" fill=\"none\" stroke=\"var(--scan)\" stroke-width=\"1.2\" stroke-dasharray=\"2 3\"></rect><text x=\"384\" y=\"58\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">sua sub-rede</text><rect x=\"385\" y=\"70\" width=\"300\" height=\"160\" rx=\"8\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"397\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">instância</text><rect x=\"400\" y=\"100\" width=\"85\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"442\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">quitanda</text><rect x=\"500\" y=\"100\" width=\"85\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"542\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">delivery</text><rect x=\"600\" y=\"100\" width=\"70\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"635\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">msdb</text><line x1=\"485\" y1=\"125\" x2=\"496\" y2=\"125\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" marker-end=\"url(#arr-l09-boundary-phosphor)\"></line><rect x=\"590\" y=\"175\" width=\"90\" height=\"34\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"635\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">SQL Agent</text><line x1=\"635\" y1=\"175\" x2=\"635\" y2=\"154\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" marker-end=\"url(#arr-l09-boundary-phosphor)\"></line><path d=\"M 442 150 L 442 255 L 470 255\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#arr-l09-boundary-wire)\"></path><text x=\"476\" y=\"247\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">linked server</text><text x=\"476\" y=\"263\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">outro SQL Server</text></svg>", "caption": "O Azure SQL Database traça a fronteira em volta de cada banco, então um nome de três partes não tem para onde ir; a Managed Instance a traça em volta da instância, e os velhos hábitos voltam a funcionar.", "same": ["Azure SQL Database", "SQL Managed Instance", "linked server"]}
```

## O que a fronteira muda

| | Azure SQL Database | SQL Managed Instance |
|---|---|---|
| o que você aluga | um banco, ou uma parte de um pool | uma instância com muitos bancos |
| uma consulta que nomeia outro banco | recusada | permitida, pelo nome de três partes |
| SQL Agent | ausente; elastic jobs são o substituto | presente, com o `msdb` e o histórico de jobs |
| linked servers | ausentes | para outros SQL Servers e para o Azure SQL |
| CLR, Service Broker, Database Mail | ausentes | presentes |
| `RESTORE` de um arquivo `.bak` | ausente; os backups são do próprio serviço | do Blob Storage, pela URL |
| onde responde | um endpoint público atrás de um firewall, ou um private endpoint | dentro da sua rede virtual |
| `SERVERPROPERTY('EngineEdition')` | 5 | 8 |

**A coluna da direita é uma lista de motivos pelos quais uma aplicação escrita para o SQL Server não
vai para o Azure SQL Database sem mudanças.** Cada um é um recurso que alguém usou há quinze anos e
ninguém tirou: um job no SQL Agent que refaz uma tabela de resumo à noite, uma stored procedure que lê
o banco financeiro para conferir um reembolso, um linked server para um sistema antigo em que ninguém
ousa mexer. A Managed Instance existe para que uma empresa com essas coisas possa sair do armário
primeiro e tirá-las depois, ou nunca.

**A linha do `RESTORE` é a que a migração usa.** Um backup feito pelo próprio `BACKUP DATABASE` do
servidor antigo, copiado para um contêiner de blobs, pode ser restaurado direto numa Managed Instance
pela URL. Os block blobs da lição 2 e os tokens SAS da lição 6 são o que faz essa cópia funcionar, e a
última seção desta lição é o que a Microsoft monta em cima disso.

## O que continua igual à lição 8

A parte gerenciada é idêntica: a Microsoft aplica os patches e mantém o motor atualizado, os backups
são automáticos com restauração a um ponto no tempo dentro de um período de retenção, a alta
disponibilidade está dentro do preço, e o General Purpose e o Business Critical são construídos como a
lição 8 descreveu. O que continua sendo seu também é idêntico, o esquema, as consultas e o índice de
que a tela de atendimento precisava. Uma instância não deixa um índice que falta mais barato; ela o
transforma numa conta maior, porque a menor instância é muito maior que o menor banco.
