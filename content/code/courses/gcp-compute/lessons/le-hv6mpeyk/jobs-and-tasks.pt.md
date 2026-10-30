---
title: Jobs, execuções e tarefas
version: 1
---

Um serviço do Cloud Run espera requisições. **Um job do Cloud Run não espera nada: ele roda até o
trabalho acabar e então para.** Os mesmos contêineres, o mesmo contrato sobre logs e sinais, mas
sem porta, sem endereço e sem requisição. É a resposta da plataforma ao script noturno que morava
numa tabela do cron numa máquina que ninguém tinha coragem de desligar.

## Três palavras

Um **job** é a definição: uma imagem, as configurações dela e em quantos pedaços o trabalho é
cortado. Sozinho ele não faz nada. Uma **execução** é uma rodada do job, iniciada à mão, por um
agendamento ou por uma chamada de API; um job que roda toda noite tem uma execução por noite. E uma
**tarefa** é um dos pedaços: uma execução de um job com `--tasks=3` sobe três contêineres, cada um
informado de qual pedaço é. A execução dá certo quando toda tarefa deu certo.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"Um job chamado invoices é uma definição. Uma execução dele, iniciada às duas da manhã, roda três tarefas com índices 0, 1 e 2, cada uma um contêiner. As tarefas 0 e 2 dão certo na primeira tentativa. A tarefa 1 falha na tentativa 0 e dá certo na tentativa 1. A execução dá certo quando as três tarefas deram certo.\"><defs><marker id=\"l10-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"110\" width=\"130\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"85.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">job</text><text x=\"85.0\" y=\"149.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">invoices</text><path d=\"M150 140 L190 140\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l10-ah)\"></path><rect x=\"190\" y=\"110\" width=\"150\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"265.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">execução</text><text x=\"265.0\" y=\"149.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">02:00, esta noite</text><path d=\"M340 128 L400 60\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l10-ah)\"></path><path d=\"M340 140 L400 140\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l10-ah)\"></path><path d=\"M340 152 L400 222\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l10-ah)\"></path><rect x=\"400\" y=\"36\" width=\"120\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"460.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">tarefa 0</text><text x=\"460.0\" y=\"69.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">tentativa 0</text><rect x=\"400\" y=\"116\" width=\"120\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"460.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">tarefa 1</text><text x=\"460.0\" y=\"149.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">tentativa 0</text><rect x=\"400\" y=\"198\" width=\"120\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"460.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">tarefa 2</text><text x=\"460.0\" y=\"231.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">tentativa 0</text><path d=\"M520 140 L560 140\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l10-ah)\"></path><text x=\"540\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">saída 1</text><rect x=\"560\" y=\"116\" width=\"140\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"630.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">tarefa 1</text><text x=\"630.0\" y=\"149.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">tentativa 1</text><text x=\"535\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">saída 0</text><text x=\"535\" y=\"222\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">saída 0</text><text x=\"630\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">saída 0</text><text x=\"360\" y=\"274\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a execução dá certo quando toda tarefa deu</text></svg>", "caption": "Um job é uma definição, uma execução é uma rodada dele, e uma tarefa é um pedaço dessa rodada. Uma nova tentativa é outra tentativa da mesma tarefa, com o mesmo índice.", "same": ["job"]}
```

## O job de faturas da loja

Toda noite a loja escreve uma fatura para cada pedido do dia anterior. **Crie uma pasta `job` em
`~/gcp` e salve isto como `job.py` dentro dela:**

```python
# job/job.py
"""The shop's nightly invoice job: each task invoices its share of the orders."""
import json
import os
import sys

ORDERS = list(range(1001, 1011))  # yesterday's ten orders

index = int(os.environ.get('CLOUD_RUN_TASK_INDEX', '0'))
count = int(os.environ.get('CLOUD_RUN_TASK_COUNT', '1'))
attempt = int(os.environ.get('CLOUD_RUN_TASK_ATTEMPT', '0'))


def log(severity, message):
    print(json.dumps({'severity': severity, 'message': message}), flush=True)


mine = ORDERS[index::count]
log('INFO', f'task {index} of {count}, attempt {attempt}: orders {mine}')

if os.environ.get('FAIL_TASK') == str(index) and attempt == 0:
    log('ERROR', f'task {index}: the invoice service timed out')
    sys.exit(1)

for order in mine:
    log('INFO', f'invoice for order {order} written')
```

E isto como o `Dockerfile`, na mesma pasta:

```dockerfile
# job/Dockerfile
FROM python:3.12.13-slim
WORKDIR /app
COPY job.py .
USER nobody
CMD ["python3", "job.py"]
```

Não há servidor web nele. O programa lê três variáveis que o Cloud Run define em toda tarefa, pega
**um a cada `count` pedidos a partir do próprio índice**, escreve as faturas deles e sai. O
`FAIL_TASK` está lá para a seção 04, para fazer uma tarefa falhar na primeira tentativa; ele não
faz nada se não for definido. Monte e rode uma vez, como faria um job de uma tarefa:

```
ana@laptop:~/gcp$ docker build -q -t invoices:1 job
sha256:57cabdcaa663070f9a42bf71fb523a25974a81107574b775d5aea29c0b03781f
ana@laptop:~/gcp$ docker run --rm invoices:1
{"severity": "INFO", "message": "task 0 of 1, attempt 0: orders [1001, 1002, 1003, 1004, 1005, 1006, 1007, 1008, 1009, 1010]"}
{"severity": "INFO", "message": "invoice for order 1001 written"}
{"severity": "INFO", "message": "invoice for order 1002 written"}
{"severity": "INFO", "message": "invoice for order 1003 written"}
{"severity": "INFO", "message": "invoice for order 1004 written"}
{"severity": "INFO", "message": "invoice for order 1005 written"}
{"severity": "INFO", "message": "invoice for order 1006 written"}
{"severity": "INFO", "message": "invoice for order 1007 written"}
{"severity": "INFO", "message": "invoice for order 1008 written"}
{"severity": "INFO", "message": "invoice for order 1009 written"}
{"severity": "INFO", "message": "invoice for order 1010 written"}
```

Sem variáveis definidas, o programa é a tarefa 0 de 1 e pega os dez pedidos. **O status de saída
0 é tudo que o Cloud Run lê**: uma tarefa que sai com 0 deu certo, e qualquer outro status falhou,
digam os logs o que disserem. Então o programa de um job precisa sair com status diferente de zero
quando falha, o contrário de um serviço, em que uma falha é um status HTTP e o processo continua
rodando.

## Para que serve um job

| o trabalho | um serviço | um job |
|---|---|---|
| responde uma requisição enquanto alguém espera | sim | não |
| roda até um trabalho acabar, e para | não | sim |
| iniciado por | uma requisição | um agendamento, um comando ou uma chamada de API |
| rodada mais longa | o tempo limite da requisição, no máximo 60 minutos | o tempo limite da tarefa, 10 minutos se nada for definido, e horas no máximo |
| cobrado | por requisição ou por instância, lição 11 | pelo tempo que cada tarefa roda, às taxas de instância da tabela |

A última coluna da tabela é a útil na hora de escolher. Uma migração de banco, uma exportação
noturna, um lote de redimensionamento de imagens, um relatório: qualquer coisa que tem fim e por que
ninguém está esperando é um job. Um serviço que recebe uma requisição e continua trabalhando depois
de responder, para não fazer quem chamou esperar, em geral é um job fingindo ser serviço, e a seção
03 da lição 11 mostra por que isso dá errado.
