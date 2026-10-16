---
title: Carga completa, captura de mudanças, e as duas juntas
version: 1
---

**Uma migração não é uma cópia, porque o banco que está sendo copiado não para.** A loja da Quitanda
ainda roda no PostgreSQL com que começou, numa máquina num rack alugado em `198.51.100.20`, e pedidos
chegam nele a todo minuto do dia. Copiar as tabelas leva horas. Quando a última tabela chega à AWS, a
primeira já está horas desatualizada, e parar a loja por essas horas é o que o negócio não aceita.
Mudar um banco vivo de lugar são, portanto, dois problemas: copiar o que está lá, e depois acompanhar o
que continua mudando.

**O AWS Database Migration Service, o DMS, resolve isso com três tipos de tarefa**, e o tipo é a
primeira decisão:

| tipo de migração | o que faz | quando é a resposta |
|---|---|---|
| `full-load` | copia uma vez cada tabela selecionada, como ela está quando é lida | a origem pode parar de escrever durante a cópia, ou a cópia é um retrato avulso |
| `cdc` | lê as mudanças da origem de um ponto no tempo em diante e as aplica | as tabelas já estão no destino, carregadas de outro jeito |
| `full-load-and-cdc` | copia as tabelas, depois aplica toda mudança feita desde o início da cópia, e continua aplicando | um banco vivo mudando de lugar quase sem parada |

**Captura de mudanças, CDC, é ler o registro que o próprio banco faz das suas mudanças.** Todo banco
sério escreve cada mudança num log antes de mudar as tabelas, para poder se recuperar depois de uma
queda: o PostgreSQL o chama de write-ahead log, o MySQL de binary log, o Oracle de redo log, o SQL
Server de transaction log. O CDC lê esse log de fora e o transforma de volta em linhas: este pedido
foi inserido, aquele total foi alterado, esta linha foi apagada. Ele nunca consulta as tabelas para
saber o que mudou, e é por isso que custa pouco à origem e não perde nada que foi confirmado. A lição
12 mostrou o DynamoDB entregando as suas mudanças a um stream; esta é a mesma ideia para um banco que
nunca foi feito para compartilhá-las, e a seção sobre o PostgreSQL faz um deles fazer isso de verdade.

## Como ficam a carga completa e o CDC juntos

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Uma linha do tempo de uma tarefa full-load-and-cdc em quatro faixas. No início a posição no log da origem é anotada. A origem continua recebendo inserções, alterações e exclusões até o cutover, e fica só leitura depois dele. A carga completa copia as tabelas no primeiro trecho. Durante esse trecho as mudanças são capturadas e retidas; quando a cópia termina elas são aplicadas, e daí em diante aplicadas conforme acontecem. O destino enche durante a cópia, depois fica segundos atrás da origem, e recebe as escritas depois do cutover.\" data-fig=\"l26-timeline\"><defs><marker id=\"ah-l26-timeline\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L10,5 L0,10 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">origem</text><text x=\"20\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">carga completa</text><text x=\"20\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">mudanças</text><text x=\"20\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">destino</text><rect x=\"140\" y=\"47\" width=\"450\" height=\"26\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"365.0\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">as escritas continuam: inserções, alterações, exclusões</text><rect x=\"590\" y=\"47\" width=\"120\" height=\"26\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"650.0\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">só leitura</text><rect x=\"140\" y=\"97\" width=\"190\" height=\"26\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"235.0\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">tabelas copiadas</text><rect x=\"140\" y=\"137\" width=\"190\" height=\"26\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"235.0\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">capturadas, retidas</text><rect x=\"330\" y=\"137\" width=\"55\" height=\"26\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"357.5\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">aplicadas</text><rect x=\"385\" y=\"137\" width=\"205\" height=\"26\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"487.5\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">aplicadas conforme acontecem</text><rect x=\"140\" y=\"187\" width=\"245\" height=\"26\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"262.5\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">enchendo</text><rect x=\"385\" y=\"187\" width=\"205\" height=\"26\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"487.5\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">segundos atrás da origem</text><rect x=\"590\" y=\"187\" width=\"120\" height=\"26\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"650.0\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">recebe as escritas</text><line x1=\"140\" y1=\"30\" x2=\"140\" y2=\"225\" stroke=\"var(--paper)\" stroke-width=\"0.9\" stroke-dasharray=\"2 3\"></line><line x1=\"590\" y1=\"30\" x2=\"590\" y2=\"225\" stroke=\"var(--paper)\" stroke-width=\"0.9\" stroke-dasharray=\"2 3\"></line><text x=\"140\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">início: posição do log anotada</text><text x=\"590\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">cutover</text><line x1=\"140\" y1=\"245\" x2=\"710\" y2=\"245\" stroke=\"var(--wire)\" stroke-width=\"1.2\" marker-end=\"url(#ah-l26-timeline)\"></line><text x=\"425.0\" y=\"260\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">tempo: horas de carga completa, depois dias ou semanas de CDC</text></svg>", "caption": "A posição do log é anotada antes de ler a primeira tabela, então nenhuma mudança feita durante a cópia cai entre o copiado e o capturado.", "same": ["cutover"]}
```

**A ordem dessas barras é o que a torna segura.** Quando a tarefa começa, o DMS primeiro anota onde está o
log da origem, e só então começa a copiar tabelas. Toda mudança feita enquanto uma tabela está sendo
copiada é capturada e retida; quando a cópia dessa tabela termina, as mudanças retidas são aplicadas
a ela, e daí em diante as mudanças passam conforme acontecem. Como o ponto de partida foi anotado
antes da cópia, nada que mudou durante ela pode cair no vão entre "copiado" e "capturado". A tarefa
então roda pelo tempo que você deixar, dias ou semanas, com o destino alguns segundos atrás da
origem, até o momento que você escolher para levar as aplicações para lá. Esse momento é o cutover, e
a última seção desta lição trata dele.

## Onde o trabalho roda

**O DMS precisa de um lugar para rodar a tarefa, e há dois tipos de lugar.** Uma **instância de
replicação** é uma máquina de uma classe escolhida, `dms.t3.medium` ou `dms.c5.large` na tabela deste
curso, que você cria, dimensiona e paga por hora, rodando tarefa ou não; várias tarefas podem
dividir uma. O **DMS Serverless** troca a instância por uma *replication config* que indica um mínimo
e um máximo de unidades de capacidade do DMS, DCUs, e o DMS escala entre eles conforme a carga pede,
cobrando as DCU-horas usadas. A próxima seção cria uma instância no laboratório, e tenta a config
serverless também, que é onde o moto para de responder.

**De um jeito ou de outro, a máquina fica entre os dois bancos e precisa alcançar os dois.** Para a
Quitanda isso quer dizer um caminho de rede da AWS até o rack, uma VPN ou um link Direct Connect, que é
o assunto da lição 24 de `aws-foundations`, e um usuário no PostgreSQL antigo com permissão para ler
as tabelas e o log e nada mais.
