---
title: Seis partes, e a cadeia que elas formam
version: 1
---

**O Data Factory move dados e roda o trabalho de outros serviços num horário; ele é o job que precisa
rodar às três da manhã, não o motor que faz o trabalho pesado.** Um pipeline do Data Factory copia um
arquivo, chama uma stored procedure, inicia um notebook do Databricks, espera uma pasta encher e
decide o que fazer quando uma dessas coisas falha. Quase toda a computação acontece em outro lugar.
Esta seção e quase toda esta lição são ensinadas a partir da documentação da Microsoft e não foram
executadas; a quarta e a quinta seções conferem declarações com o Terraform, offline, e avisam.

## As seis partes

Uma factory é um recurso do Azure, criado numa assinatura e numa região, e todo o resto vive dentro
dela:

- **um linked service** é uma conexão: onde está um armazenamento e como entrar nele. Um para a conta
  de armazenamento, um para o banco de pedidos, um para o Databricks. É a única parte que conhece uma
  credencial, ou melhor, qual identidade usar.
- **um dataset** é uma visão com nome de dados dentro de um linked service: este contêiner e esta
  pasta, como CSV com cabeçalho; aquela tabela naquele banco. Um dataset pode receber parâmetros, e
  assim um dataset cobre o export de todos os dias.
- **uma atividade** é um passo: `Copy`, que move dados de um dataset de origem para um de destino;
  `Lookup`, que lê algumas linhas; `ForEach`, `If Condition` e `Until`, que controlam o fluxo; e
  atividades que entregam o trabalho a outro serviço, como uma stored procedure, um notebook do
  Databricks ou uma Azure Function.
- **um pipeline** é um grupo de atividades e as setas entre elas: rode isto depois que aquilo der
  certo, rode aquilo só se isto falhar. Pipelines recebem parâmetros e podem chamar uns aos outros.
- **um gatilho** (trigger) decide quando um pipeline roda: num relógio, para cada janela de tempo
  desde uma data de início, ou quando um arquivo chega. A seção dele é a quinta.
- **um integration runtime** é a computação que roda as atividades, ou seja, onde a cópia acontece e
  de que rede ela alcança os armazenamentos. A próxima seção é sobre ele.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 310\" role=\"img\" aria-label=\"As partes da factory da Quitanda como uma cadeia de referências. O gatilho tr_orders_nightly inicia o pipeline pl_orders_nightly, que contém a atividade CopyOrders. A entrada da atividade é o dataset ds_raw_orders e a saída é o dataset ds_curated_orders. Os dois datasets citam o linked service ls_lake, que aponta para a conta de armazenamento stquitandalakeprd e roda no integration runtime AutoResolveIntegrationRuntime.\" data-fig=\"l19-chain\"><defs><marker id=\"l19-ah\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L10,5 L0,10 z\" fill=\"var(--paper-dim)\"/></marker></defs><rect x=\"20\" y=\"30\" width=\"150\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"/><text x=\"95\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">gatilho</text><text x=\"95\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">tr_orders_nightly</text><rect x=\"200\" y=\"30\" width=\"150\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"275\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">pipeline</text><text x=\"275\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">pl_orders_nightly</text><rect x=\"380\" y=\"30\" width=\"150\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"455\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">atividade</text><text x=\"455\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">CopyOrders</text><line x1=\"170\" y1=\"55\" x2=\"197\" y2=\"55\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" marker-end=\"url(#l19-ah)\"/><line x1=\"350\" y1=\"55\" x2=\"377\" y2=\"55\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" marker-end=\"url(#l19-ah)\"/><rect x=\"300\" y=\"120\" width=\"160\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"380\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">dataset</text><text x=\"380\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">ds_raw_orders</text><rect x=\"480\" y=\"120\" width=\"160\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"560\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">dataset</text><text x=\"560\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">ds_curated_orders</text><line x1=\"430\" y1=\"80\" x2=\"385\" y2=\"117\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" marker-end=\"url(#l19-ah)\"/><line x1=\"480\" y1=\"80\" x2=\"555\" y2=\"117\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" marker-end=\"url(#l19-ah)\"/><text x=\"392\" y=\"100\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">entrada</text><text x=\"528\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">saída</text><rect x=\"390\" y=\"210\" width=\"160\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"470\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">linked service</text><text x=\"470\" y=\"245\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">ls_lake</text><line x1=\"380\" y1=\"170\" x2=\"440\" y2=\"207\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" marker-end=\"url(#l19-ah)\"/><line x1=\"560\" y1=\"170\" x2=\"500\" y2=\"207\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" marker-end=\"url(#l19-ah)\"/><rect x=\"150\" y=\"210\" width=\"170\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"/><text x=\"235\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">integration runtime</text><text x=\"235\" y=\"245\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">AutoResolveIntegrationRuntime</text><line x1=\"390\" y1=\"235\" x2=\"323\" y2=\"235\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" marker-end=\"url(#l19-ah)\"/><text x=\"355\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">roda em</text><rect x=\"580\" y=\"210\" width=\"125\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"/><text x=\"642\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o armazenamento</text><text x=\"642\" y=\"245\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">stquitandalakeprd</text><line x1=\"550\" y1=\"235\" x2=\"577\" y2=\"235\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" marker-end=\"url(#l19-ah)\"/><text x=\"360\" y=\"292\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">cada seta é uma referência por nome; só o linked service sabe como entrar</text></svg>", "caption": "A carga noturna da Quitanda, parte por parte. O gatilho só conhece o pipeline, a atividade só os datasets dela, e só o linked service sabe onde estão os dados e como chegar a eles.", "same": ["pipeline", "dataset", "linked service", "integration runtime"]}
```

**Cada seta dessa figura é uma referência por nome.** Um pipeline cita os datasets dele, um dataset
cita o linked service, um linked service cita o runtime. É o que deixa um linked service servir
cinquenta datasets, e é também como uma factory quebra: renomeie um dataset e todo pipeline que o
citava falha na próxima execução, que é o argumento da lição 1 sobre nomes em outro cenário.

## O que um pipeline não faz

**Uma atividade de cópia copia; não limpa.** Ela consegue mapear colunas e converter um CSV em
Parquet, e nada mais interessante que isso. Tirar duplicados, consertar um total escrito com vírgula,
juntar os pedidos aos clientes: isso é transformação, e o Data Factory a entrega a um motor, um
mapping data flow ou um notebook, que é a escolha da lição 20. O formato comum de uma noite é então um
pipeline de três ou quatro atividades, uma cópia para a camada raw, uma transformação rodada em outro
lugar, uma verificação e uma mensagem quando algo falha, com o Data Factory decidindo a ordem e as
novas tentativas.

**É a mesma ideia de uma DAG do Airflow**, escrita como documentos JSON em vez de Python e rodada pela
Microsoft em vez de por um agendador que você mantém ligado. O Fabric tem os mesmos pipelines dentro
dele, como a lição 17 mencionou, cobrados em unidades de capacidade em vez de por execução.
