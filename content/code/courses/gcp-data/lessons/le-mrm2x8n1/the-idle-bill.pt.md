---
title: Quanto um ambiente custa enquanto espera
version: 1
---

**Um ambiente Composer é cobrado por toda hora em que existe, e não há como pausá-lo.** Ele não tem
estado parado: o scheduler, o DAG processor, o servidor web, o banco e pelo menos um worker rodam o
tempo todo, porque o scheduler precisa estar acordado para perceber que chegaram as três da manhã. O
único jeito de parar de pagar é apagar o ambiente, o que apaga o banco e, com ele, o histórico de todas as execuções. O Composer consegue salvar antes um *snapshot* no Cloud Storage e criar depois um
ambiente novo a partir dele, o que é uma restauração, não uma pausa. Então a pergunta honesta sobre o
Composer não é quanto um pipeline custa quando roda, e sim quanto o ambiente custa quando nada roda.

## Duas gerações, dois jeitos de cobrar

A página de preços do Composer, lida em 2026-10-30, dá preço a duas gerações atuais, e em São Paulo:

| geração | o que é cobrado | preço |
|---|---|---|
| Composer 3 | DCU-horas, tudo o que o ambiente roda | $0.0954 por DCU-hora |
| Composer 3 | o armazenamento do banco do Airflow | $0.000370274 por GiB-hora |
| Composer 2 | taxa de ambiente small | $0.56 por hora |
| Composer 2 | vCPU, memória e armazenamento dos componentes do Airflow | $0.072 por vCPU-hora, $0.008 por GiB-hora, $0.0003 por GiB-hora |
| Composer 2 | o armazenamento do banco do Airflow | $0.000369863 por GiB-hora |

**O Composer 3 junta tudo numa unidade**, a DCU, uma Data Compute Unit que representa os
processadores, a memória e o armazenamento das partes do ambiente e da infraestrutura gerenciada por
baixo delas. Um ambiente é cobrado pelo valor em DCUs ao longo do tempo, e a parte dos workers
acompanha a autoescala. **O que a página não diz é quantas DCUs um ambiente Composer 3 small usa sem
fazer nada**; o único exemplo calculado dela usa 12 DCUs por cinco dias, e o programa abaixo adota
esse exemplo como número, identificado como tal. **O Composer 2 é detalhado**, e a página lista
exatamente com o que o preset small começa, o que deixa calcular um mês ocioso em vez de pegá-lo
emprestado: um scheduler, um servidor web e um worker com 0,5 vCPU, 1,875 GiB de memória e 1 GiB de
disco cada, mais a taxa. As duas gerações cobram um banco de pelo menos 10 GiB.

## O que cresce com o trabalho, e o que não cresce

**A parte de um ambiente que acompanha o trabalho são os workers**, e só entre limites que você
define. Um ambiente Composer escala os workers entre um mínimo e um máximo pelo número de tarefas
esperando, e o mínimo nunca é zero, porque algo precisa estar pronto para rodar a primeira tarefa da
noite. Os limites, o tamanho de cada worker e os pacotes que as tarefas importam são configurações do
ambiente, mudadas com um comando. **Não rodado aqui:**

```sh
gcloud composer environments update quitanda --location=southamerica-east1 \
  --min-workers=1 --max-workers=3
gcloud composer environments update quitanda --location=southamerica-east1 \
  --update-pypi-package=holidays==0.105
```

**O segundo comando é motivo para planejar o primeiro.** Instalar um pacote reconstrói a imagem do
ambiente e reinicia os componentes dele, o que demora o bastante para um time fazer isso numa hora
calma, e não no meio das execuções de uma noite. E nenhum dos dois comandos muda a parte da conta que
não se mexe: o scheduler, o DAG processor, o servidor web, o banco e o worker mínimo estão lá às
quatro da tarde como às três da manhã, e é isso que o programa abaixo põe em preço.

## Um mês, fazendo quase nada

O pipeline da Quitanda é o job da aula 23 e os três vizinhos, cerca de uma hora por noite. Salve a
conta como `composer_bill.py`:

```schooling-example
{"language": "python", "file": "composer_bill.py", "parts": [{"code": "# USD, southamerica-east1, read on 2026-10-30, from cloud.google.com/composer/pricing.\nC3_DCU = 0.0954            # Composer 3, a DCU-hour (the page: $0.0954 per 1,000 milli DCU-hours)\nC3_DB = 0.000370274        # Composer 3, database storage, a GiB-hour\nC2_SMALL = 0.56            # Composer 2, small environment fee, an hour\nC2_VCPU = 0.072            # Composer 2, a vCPU-hour (the page: $0.072 per 1,000 mCPU-hours)\nC2_GIB = 0.008             # Composer 2, a GiB-hour of memory\nC2_DISK = 0.0003           # Composer 2, a GiB-hour of storage\nC2_DB = 0.000369863        # Composer 2, database storage, a GiB-hour\nDB_GIB, HOURS = 10, 730    # the smallest database the page allows, and an average month\n\n", "note": "Sete preços de uma página, duas gerações do mesmo produto. As unidades são as da própria página, convertidas nos comentários: mil milli DCU-horas são uma DCU-hora, e mil mCPU-horas são uma vCPU-hora."}, {"code": "c3 = (12 * C3_DCU + DB_GIB * C3_DB) * HOURS\nc2 = (C2_SMALL + 1.5 * C2_VCPU + 5.625 * C2_GIB + 3 * C2_DISK + DB_GIB * C2_DB) * HOURS\nfor name, usd in [('Composer 3, 12 DCUs', c3), ('Composer 2, small, idle', c2)]:\n    print(f'{name:<25}{usd:8.2f} a month {usd * 12:9.2f} a year')\n\n", "note": "**Dois ambientes que rodam o mês inteiro, façam o que fizerem.** O Composer 3 nas 12 DCUs do exemplo da própria página. O Composer 2 no preset small com um worker, que a página descreve como um scheduler, um servidor web e um worker com 0,5 vCPU, 1,875 GiB e 1 GiB de disco cada."}, {"code": "WORK = 30                  # Quitanda's pipeline: about an hour a night, thirty nights\nprint(f'per hour of work: {c3 / WORK:.2f} and {c2 / WORK:.2f}')\n\n", "note": "Os mesmos dois meses divididos pelas horas em que o pipeline trabalha neles."}, {"code": "# cloud.google.com/workflows/pricing and cloud.google.com/scheduler/pricing, read 2026-10-30\nSTEPS, FREE_STEPS, PER_1000 = 100 * 30, 5000, 0.01    # a generous 100 steps a run\nJOBS, FREE_JOBS, PER_JOB = 1, 3, 0.10\nworkflows = max(0, -(-(STEPS - FREE_STEPS) // 1000)) * PER_1000\nscheduler = max(0, JOBS - FREE_JOBS) * PER_JOB\nprint(f'Workflows, {STEPS} steps: {workflows:.2f}  Cloud Scheduler, {JOBS} job: {scheduler:.2f}')\n", "note": "**A dupla mais leve, para o mesmo pipeline.** O Workflows cobra passos internos em blocos de mil além de 5.000 grátis por mês, e o Cloud Scheduler $0.10 por job além de três grátis por conta de faturamento. Cem passos por noite é folgado para quatro passos e a verificação periódica de um batch."}]}
```

```
ana@laptop:~/gcp$ python3 composer_bill.py
Composer 3, 12 DCUs        838.41 a month  10060.88 a year
Composer 2, small, idle    523.85 a month   6286.16 a year
per hour of work: 27.95 and 17.46
Workflows, 3000 steps: 0.00  Cloud Scheduler, 1 job: 0.00
```

**523.85 por mês para o menor ambiente Composer 2, e 838.41 para o Composer 3 no exemplo da
página.** As duas linhas são o que o ambiente custa sem nenhum DAG rodando, porque nada nelas depende
do trabalho. Divididas pelas trinta horas por mês em que o pipeline de fato trabalha, a orquestração
sai por 17.46 e 27.95 por hora de trabalho, antes de uma única DCU do Dataproc, que é cobrada à
parte. O bucket do ambiente, as operações nele e os logs no Cloud Logging são cobrados nas próprias
páginas e ficaram de fora.

**A última linha é a outra resposta, e ela é zero.** Cem passos de workflow por noite são 3.000 passos
por mês, dentro dos 5.000 que o Workflows dá de graça; um job do Cloud Scheduler está dentro dos três
grátis por conta de faturamento. Grátis é uma propriedade deste pipeline, não dos produtos: uma
plataforma com quarenta workflows de cem passos por noite roda 120.000 passos por mês, o que além dos
5.000 grátis dá 115 blocos de mil a $0.01, $1.15.

## O formato da conta, comparado com tudo o mais neste curso

**O Composer cobra por esperar e quase nada a mais por trabalhar**, o contrário do Dataflow, do
Dataproc Serverless e do BigQuery sob demanda, que cobram pelo trabalho e nada pela espera. Isso o
torna barato por pipeline quando há muitos pipelines e caro por pipeline quando há poucos. Quarenta
DAGs dividindo um ambiente Composer 2 small custam 523.85 ÷ 40 = 13.10 por mês cada, e ninguém
chamaria isso de caro para um agendador com novas tentativas, backfills, sensores e interface web. Um
DAG sozinho paga os 523.85 inteiros.

## Quando a espera vale a pena

**O Composer vale o preço quando o próprio Airflow é o objetivo.** Muitos DAGs, escritos por vários
times, com dependências entre eles; backfills, em que rodar de novo a terça passada é um comando;
sensores que esperam um arquivo ou uma tabela aparecer; operadores para dezenas de serviços além dos
do Google; e um time que já conhece o Airflow, ou um pipeline que talvez tenha de mudar de nuvem um
dia, onde o Airflow também roda. Para isso, quinhentos a oitocentos dólares por mês é um preço
razoável para não operar sozinho um agendador, um banco e uma frota de workers.

**Ele não vale para um punhado de pipelines simples**, cada um uma cadeia curta de chamadas rodada
num horário. Esse caso tem uma resposta mais barata, feita de dois serviços que não custam nada
enquanto esperam, e a próxima seção a constrói.
