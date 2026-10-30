---
title: Backfill, captura de mudanças, e os dois juntos
version: 1
---

**Tirar dados de um banco vivo não é uma cópia, porque o banco que está sendo copiado não para.** A
loja da Quitanda ainda roda no PostgreSQL com que começou, numa máquina num rack alugado em
`198.51.100.20`, e os pedidos chegam nele a cada minuto do dia. Copiar as tabelas leva horas. Quando
a última tabela chega ao Google Cloud, a primeira já está horas desatualizada, e parar a loja por
essas horas é justamente o que o negócio não aceita. Então o problema tem duas metades: copiar o que
existe, e depois acompanhar o que continua mudando.

**O Google Cloud tem três serviços que trazem dados para dentro, e eles respondem perguntas
diferentes.**

| serviço | o que faz | quando é a resposta |
|---|---|---|
| Datastream | copia as tabelas de um banco e depois transmite cada mudança, para o BigQuery ou o Cloud Storage | o warehouse ou o lake deve acompanhar um banco vivo em segundos |
| Database Migration Service | leva um banco para o Cloud SQL ou o AlloyDB, copiando e depois replicando até o cutover | o próprio banco está se mudando, e as aplicações vão junto |
| BigQuery Data Transfer Service | carrega dados no BigQuery num horário, a partir do Cloud Storage, de outras nuvens, de outros warehouses e de produtos SaaS | uma carga por noite ou por hora basta, e ninguém precisa de cada mudança |

Esta aula trata sobretudo do primeiro, porque é o de que a Quitanda precisa primeiro: os relatórios
deveriam parar de ler o próprio banco da loja, e o BigQuery, das aulas 13 a 18, é onde deveriam ler.
Os outros dois ganham uma seção própria depois da prática.

**Captura de mudanças, CDC, é ler o registro que o próprio banco faz das suas mudanças.** Todo banco
sério escreve cada mudança num log antes de mudar as tabelas, para conseguir se recuperar depois de
uma queda: o PostgreSQL chama isso de write-ahead log, o MySQL de binary log, o Oracle de redo log, o
SQL Server de transaction log. O CDC lê esse log de fora e o transforma de volta em linhas: este
pedido foi inserido, aquele total foi alterado, esta linha foi apagada. Ele nunca consulta as tabelas
para saber o que mudou, e é por isso que custa pouco à origem e não perde nada que foi confirmado. Os
tópicos da aula 19 carregavam eventos que alguém escolheu publicar; o CDC é a mesma ideia para um
banco que nunca foi feito para compartilhá-los, e a seção depois da próxima faz o PostgreSQL fazer
isso de verdade.

## Backfill e CDC juntos

**O Datastream chama as duas metades de backfill e CDC**, e um stream faz uma, a outra ou as duas.
O *backfill* é a cópia do que as tabelas guardam quando o stream começa. O *CDC* é cada mudança a
partir de um ponto do log. Um stream criado com `--backfill-all` faz os dois, a escolha mais comum
para um banco vivo; um criado com `--backfill-none` só transmite mudanças, para tabelas já
carregadas de outro jeito.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Uma linha do tempo de um stream do Datastream com backfill e captura de mudanças, em quatro faixas. No início, a posição no log da origem é anotada. A origem continua recebendo inserções, alterações e exclusões até o cutover, e fica só leitura depois dele. O backfill copia as tabelas no primeiro trecho. Durante esse trecho, as mudanças são capturadas e retidas; quando a cópia termina, elas são aplicadas, e daí em diante aplicadas conforme acontecem. O destino enche durante a cópia, depois fica segundos atrás da origem, e recebe as escritas depois do cutover.\" data-fig=\"l25g-timeline\"><defs><marker id=\"ah-l25g-timeline\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L10,5 L0,10 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">origem</text><text x=\"20\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">backfill</text><text x=\"20\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">mudanças</text><text x=\"20\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">destino</text><rect x=\"140\" y=\"47\" width=\"450\" height=\"26\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"365.0\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">as escritas continuam: inserções, alterações, exclusões</text><rect x=\"590\" y=\"47\" width=\"120\" height=\"26\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"650.0\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">só leitura</text><rect x=\"140\" y=\"97\" width=\"190\" height=\"26\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"235.0\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">tabelas copiadas</text><rect x=\"140\" y=\"137\" width=\"190\" height=\"26\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"235.0\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">capturadas, retidas</text><rect x=\"330\" y=\"137\" width=\"55\" height=\"26\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"357.5\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">aplicadas</text><rect x=\"385\" y=\"137\" width=\"205\" height=\"26\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"487.5\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">aplicadas conforme acontecem</text><rect x=\"140\" y=\"187\" width=\"245\" height=\"26\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"262.5\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">enchendo</text><rect x=\"385\" y=\"187\" width=\"205\" height=\"26\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"487.5\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">segundos atrás da origem</text><rect x=\"590\" y=\"187\" width=\"120\" height=\"26\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"650.0\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">recebe as escritas</text><line x1=\"140\" y1=\"30\" x2=\"140\" y2=\"225\" stroke=\"var(--paper)\" stroke-width=\"0.9\" stroke-dasharray=\"2 3\"></line><line x1=\"590\" y1=\"30\" x2=\"590\" y2=\"225\" stroke=\"var(--paper)\" stroke-width=\"0.9\" stroke-dasharray=\"2 3\"></line><text x=\"140\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">início: posição do log anotada</text><text x=\"590\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">cutover</text><line x1=\"140\" y1=\"245\" x2=\"710\" y2=\"245\" stroke=\"var(--wire)\" stroke-width=\"1.2\" marker-end=\"url(#ah-l25g-timeline)\"></line><text x=\"425.0\" y=\"260\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">tempo: horas de backfill, depois dias ou semanas de CDC</text></svg>", "caption": "A posição do log é anotada antes de ler a primeira tabela, então nenhuma mudança feita durante o backfill cai entre o copiado e o capturado.", "same": ["backfill", "cutover"]}
```

**A ordem dessas barras é o que torna isso seguro.** Quando o stream começa, o leitor primeiro anota
onde está o log da origem, e só então começa a copiar as tabelas. Toda mudança feita enquanto uma
tabela está sendo copiada é capturada e retida; quando a cópia daquela tabela termina, as mudanças
retidas são aplicadas a ela, e daí em diante as mudanças fluem conforme acontecem. Como o ponto de
partida foi anotado antes da cópia, nada que mudou durante ela pode cair no vão entre "copiado" e
"capturado". O stream então roda pelo tempo que você deixar, dias ou meses, com o destino alguns
segundos atrás da origem.

## Onde o stream escreve

**Um destino do Datastream é o BigQuery ou o Cloud Storage**, e os dois são produtos diferentes para
as mesmas mudanças. **No BigQuery**, o Datastream mantém uma tabela por tabela de origem e aplica as
mudanças a ela, para que uma consulta veja o estado atual de cada linha, atualizado dentro de uma defasagem que você define. Ou, no modo *append-only*, escreve cada mudança como linha nova, o que
guarda o histórico e deixa o estado atual para uma consulta. **No Cloud Storage**, ele escreve as
mudanças como arquivos, Avro ou JSON, num caminho por tabela e por horário, passando para um arquivo
novo por tamanho ou por intervalo; outra coisa, um job do Dataflow ou uma tabela externa do BigQuery
da aula 17, os lê de lá.

**Para a Quitanda o destino é o BigQuery, em modo merge**: os relatórios querem os pedidos como estão
agora, e alguns minutos de defasagem são um preço que pagam com gosto para nunca mais consultar a
loja. A próxima seção monta o stream e diz o que é cada peça dele.
