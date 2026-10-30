---
title: Workers, Streaming Engine, Prime e templates no Dataflow
version: 1
---

**Nada nesta seção foi rodado.** Não existe emulador do Dataflow nem substituto local para o que ele
acrescenta, que são máquinas: ligá-las, dimensioná-las, mover trabalho entre elas e desligá-las. O
que segue vem da documentação do Google, as páginas do Dataflow em
`cloud.google.com/dataflow/docs`, e os comandos são os que você digitaria com um projeto de verdade.
Nenhum deles tem saída nesta aula, porque nenhum teve para onde ir. As flags do `gcloud` foram
conferidas na ajuda do próprio Google Cloud CLI 591.0.0 do laboratório, que responde ao `--help` sem
rede e sem conta.

## Mandando o pipeline para o Dataflow

O programa não muda. O runner muda, e o runner precisa de um projeto, uma região e um bucket para os
arquivos dele:

```sh
pip install -q 'apache-beam[gcp]==2.76.0'
python3 orders_beam.py --subscription order-events-beam --topic order-totals --streaming \
  --runner=DataflowRunner --project=planner-dev --region=southamerica-east1 \
  --temp_location=gs://quitanda-dataflow-prod/tmp/ --job_name=order-totals \
  --enable_streaming_engine --max_num_workers=3
```

**O extra `gcp` é a primeira linha por um motivo**: o DataflowRunner é um cliente da API do
Dataflow, e as bibliotecas dele não estão no pacote simples. Com esse comando, o Beam monta o grafo no seu laptop exatamente como fez para o DirectRunner e
**prepara** o job: envia o programa, a descrição dele e os pacotes do próprio Beam para o
`--temp_location`. Depois pede ao Dataflow que crie um job em `southamerica-east1`. Daí em diante o laptop não é necessário: fechá-lo não para
o job. Os workers rodam como uma conta de serviço, por padrão a do Compute Engine do projeto, que
precisa do papel `roles/dataflow.worker` e de leitura na assinatura. Um pipeline cujos passos
importam bibliotecas além do Beam as lista em `--requirements_file`, para que cada worker as instale
ao ligar.

## O que o Dataflow faz com o grafo

**Primeiro ele funde passos.** `Parse`, `Placed` e `Key` olham cada um um elemento de cada vez,
então o Dataflow os roda como um estágio só, passando cada elemento de uma função para a próxima na
memória do mesmo worker, sem cópia no meio. Um estágio termina onde os elementos precisam mudar de
máquina, o que neste pipeline é o `Add`, a combinação. Essa fronteira é o **shuffle**, e o modo de
fazê-lo é a principal diferença entre os dois modos do Dataflow:

| | lote | streaming |
|---|---|---|
| o shuffle | **Dataflow Shuffle**, feito pelo serviço e não nos discos dos workers | **Streaming Engine**, que também guarda fora dos workers o estado das janelas |
| worker padrão | 1 vCPU, 3,75 GB, 25 GB de disco com Dataflow Shuffle | 4 vCPU, 15 GB, 30 GB de disco com Streaming Engine, 400 GB sem |
| como termina | quando a entrada foi lida e todo passo foi feito | nunca sozinho: **drain** ou **cancel** |
| escalonamento automático por | trabalho restante | acúmulo na assinatura e quão ocupados estão os workers |

Os padrões são os que a página de preços imprime. **O Streaming Engine é o que deixa um job de streaming rodar em menos workers, e menores.** Com as
janelas e o estado delas guardados pelo serviço, um worker guarda pouco e pode ser trocado sem
perder nada, e o job pode encolher sem mover estado de um disco para outro. Sem ele, cada worker carrega a sua parte do estado no próprio disco
persistente, e é por isso que o disco padrão tem 400 GB.

**O escalonamento automático é horizontal**: o Dataflow acrescenta e remove workers entre um e
`--max_num_workers`. Nunca passa desse número, que é a primeira coisa a definir em qualquer job que
você paga. **O Dataflow Prime** acrescenta o escalonamento vertical, mudando a memória de um worker
quando o job fica sem ela em vez de falhar, e cobra de outro jeito, em Data Compute Units, o assunto
da próxima seção. É escolhido por job com `--dataflow_service_options=enable_prime`.

## Parando um fluxo: drain ou cancel

**Cancelar para na hora e joga fora o que está em andamento**: as janelas ainda não fechadas se
perdem, junto com toda mensagem já confirmada dentro delas. **Drenar para de ler**, deixa cada
janela aberta fechar como se a hora dela tivesse chegado, emite o que ela guarda, e então termina.
Para este pipeline, um cancel às 19:00:40 perde os 40 segundos de totais já contados naquele minuto;
um drain os publica, antes da hora. Os comandos recebem o id do job, que `gcloud dataflow jobs list`
mostra:

```sh
gcloud dataflow jobs list --region=southamerica-east1 --status=active
gcloud dataflow jobs drain JOB_ID --region=southamerica-east1
gcloud dataflow jobs cancel JOB_ID --region=southamerica-east1
```

Uma terceira opção mantém o job rodando: o **update** troca o código de um job de streaming no
lugar, mantendo o estado e a assinatura dele, rodando o programa de novo com `--update` e o mesmo
`--job_name`. O Dataflow confere se o grafo novo é compatível com o antigo, e recusa o update se,
por exemplo, um passo do qual ele guarda estado foi renomeado. É mais um motivo para os passos do
`orders_beam.py` terem nome: `'Add' >> beam.CombinePerKey(add)` mantém o nome `Add` por mais que o
código ao redor mude.

## Templates

Rodar um pipeline de um laptop serve para quem o escreveu e não serve para um agendamento. Um
**template** prepara o pipeline uma vez para que ele seja lançado depois com parâmetros, por alguém
ou algo que não tem o código, como o Cloud Composer da aula 24 ou um job do Cloud Scheduler. Há dois
tipos:

- **Templates clássicos** guardam o próprio grafo no Cloud Storage. Os parâmetros só mudam o que o
  grafo foi montado para receber como valor de execução, e o formato do grafo fica fixo quando ele
  é preparado.
- **Flex Templates** empacotam o programa como uma imagem de contêiner no Artifact Registry, com um
  pequeno arquivo de metadados no Cloud Storage. Cada lançamento liga o contêiner, que monta o grafo
  nessa hora, então os parâmetros podem mudar o próprio grafo. O Google os recomenda para pipelines
  novos.

```sh
gcloud dataflow flex-template build gs://quitanda-dataflow-prod/templates/order-totals.json \
  --image-gcr-path=southamerica-east1-docker.pkg.dev/planner-dev/dataflow/order-totals:1 \
  --sdk-language=PYTHON --flex-template-base-image=PYTHON3 \
  --py-path=. --env=FLEX_TEMPLATE_PYTHON_PY_FILE=orders_beam.py
gcloud dataflow flex-template run order-totals-nightly --region=southamerica-east1 \
  --template-file-gcs-location=gs://quitanda-dataflow-prod/templates/order-totals.json \
  --parameters=input=gs://quitanda-raw-prod/raw/events/dt=2026-10-15/events.jsonl,output=gs://quitanda-curated-prod/order-totals/dt=2026-10-15/
```

O Google também publica templates prontos, como Pub/Sub para BigQuery e texto do Cloud Storage para
BigQuery, que cobrem as cópias comuns sem código nenhum seu. **Um template pronto é o equivalente,
no Dataflow, de um conector gerenciado**: vale procurar um antes de escrever um pipeline cujo
trabalho inteiro é levar registros de um serviço para outro sem mudá-los.
