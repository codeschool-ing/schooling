---
title: Para qual noite é uma execução, o catch-up, e qual dos dois escolher
version: 1
---

**Uma execução agendada no Airflow sabe para qual data ela é, e essa data não é o momento em que ela
começa.** Toda execução tem uma **logical date**, a partir da qual se fazem o `ds` e os outros valores
de template, e, na maioria dos agendamentos, um **intervalo de dados**, o trecho de tempo que a
execução deve processar. Um pipeline que lê "os pedidos de ontem" só está certo se calcula ontem a
partir disso, e não do relógio, para que uma execução que começou atrasada, ou que foi refeita uma
semana depois, ainda processe a noite para a qual era. Qual data uma execução recebe depende do
*timetable* do agendamento, e o Airflow 3 mudou o padrão.

## Dois timetables para a mesma expressão cron

**`schedule='0 3 * * *'` no Airflow 3 significa `CronTriggerTimetable`**: uma execução dispara a
cada 03:00, e a logical date dela é esse momento, então o intervalo dela não tem duração. O Airflow 2
lia a mesma string como `CronDataIntervalTimetable`: cada execução cobre o dia de uma 03:00 até a
seguinte e dispara quando esse dia termina, com o começo do intervalo como logical date. O arquivo de
DAG abaixo declara um DAG de cada, com `catchup=True`, e uma tarefa que imprime o que a execução
recebeu. Salve-o na pasta de DAGs como `two_clocks.py`:

`two_clocks.py`:

```python
import pendulum
from airflow.providers.standard.operators.bash import BashOperator
from airflow.sdk import DAG
from airflow.timetables.interval import CronDataIntervalTimetable

SAY = 'echo {{ dag.dag_id }} ds={{ ds }} start={{ data_interval_start }} end={{ data_interval_end }}'
START = pendulum.datetime(2026, 10, 26, tz='America/Sao_Paulo')

with DAG('clock_trigger', schedule='0 3 * * *', start_date=START, catchup=True):
    BashOperator(task_id='say', bash_command=SAY)

with DAG('clock_interval', start_date=START, catchup=True,
         schedule=CronDataIntervalTimetable('0 3 * * *', timezone='America/Sao_Paulo')):
    BashOperator(task_id='say', bash_command=SAY)
```

**Rodar um agendamento exige as duas partes de vida longa do Airflow**: o API server, para o qual as
tarefas informam, e o scheduler, que cria as execuções. Cada um roda em primeiro plano num terminal
próprio, com as três exportações de antes nesta aula digitadas lá também:

```sh
airflow api-server
```

```sh
airflow scheduler
```

Despause os dois DAGs, dê um minuto ao scheduler e pergunte o que ele fez. A captura abaixo foi feita
em 30 de outubro, à noite:

```
ana@laptop:~/gcp$ airflow dags reserialize > /dev/null 2>&1; airflow dags unpause clock_trigger > /dev/null 2>&1; airflow dags unpause clock_interval > /dev/null 2>&1
ana@laptop:~/gcp$ airflow dags list-runs clock_trigger -o plain 2>/dev/null | awk '{print $3, $4}'
state run_after
success 2026-10-30T06:00:00+00:00
success 2026-10-29T06:00:00+00:00
success 2026-10-28T06:00:00+00:00
success 2026-10-27T06:00:00+00:00
success 2026-10-26T06:00:00+00:00
ana@laptop:~/gcp$ airflow dags list-runs clock_interval -o plain 2>/dev/null | awk '{print $3, $4}'
state run_after
success 2026-10-30T06:00:00+00:00
success 2026-10-29T06:00:00+00:00
success 2026-10-28T06:00:00+00:00
success 2026-10-27T06:00:00+00:00
ana@laptop:~/gcp$ grep -rhoE '"event":"clock_[a-z]+ ds=[^"]*' $AIRFLOW_HOME/logs | cut -d'"' -f4 | sort
clock_interval ds=2026-10-26 start=2026-10-26 06:00:00+00:00 end=2026-10-27 06:00:00+00:00
clock_interval ds=2026-10-27 start=2026-10-27 06:00:00+00:00 end=2026-10-28 06:00:00+00:00
clock_interval ds=2026-10-28 start=2026-10-28 06:00:00+00:00 end=2026-10-29 06:00:00+00:00
clock_interval ds=2026-10-29 start=2026-10-29 06:00:00+00:00 end=2026-10-30 06:00:00+00:00
clock_trigger ds=2026-10-26 start=2026-10-26 06:00:00+00:00 end=2026-10-26 06:00:00+00:00
clock_trigger ds=2026-10-27 start=2026-10-27 06:00:00+00:00 end=2026-10-27 06:00:00+00:00
clock_trigger ds=2026-10-28 start=2026-10-28 06:00:00+00:00 end=2026-10-28 06:00:00+00:00
clock_trigger ds=2026-10-29 start=2026-10-29 06:00:00+00:00 end=2026-10-29 06:00:00+00:00
clock_trigger ds=2026-10-30 start=2026-10-30 06:00:00+00:00 end=2026-10-30 06:00:00+00:00
```

**O catch-up criou de uma vez todas as execuções perdidas.** Os DAGs começam no dia 26 e o arquivo
apareceu na noite do dia 30, então, com `catchup=True`, o scheduler criou uma execução para cada noite
que tinha perdido, assim que leu o arquivo, e rodou todas. **Os dois DAGs discordam sobre que noites
eram essas.** O `clock_trigger` fez cinco execuções, uma para cada 03:00 do dia 26 ao 30, e o `ds` de
cada uma é a noite em que disparou, com começo e fim no mesmo momento. O `clock_interval` fez quatro,
e o `ds` de cada uma é o dia que ela cobre: a execução que disparou às 03:00 do dia 30 tem `ds`
2026-10-29 e um intervalo do dia 29 ao 30. A execução do dia 30 ainda não existe, porque o dia 30 só
termina às 03:00 do dia 31.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 285\" role=\"img\" aria-label=\"Duas linhas do tempo em cinco noites, de 26 a 30 de outubro às 03:00 de São Paulo. Na primeira, o agendamento cron padrão do Airflow 3, uma execução começa a cada 03:00 e recebe a data daquela noite: ds=26 no dia 26 até ds=30 no dia 30, cinco execuções. Na segunda, o timetable CronDataInterval, cada execução cobre um dia de uma 03:00 até a seguinte e começa quando esse dia acaba: a execução de ds=26 começa no dia 27, e a última, ds=29, no dia 30, quatro execuções.\" data-fig=\"l24-clocks\"><line x1=\"190.0\" y1=\"40.0\" x2=\"190.0\" y2=\"250.0\" stroke=\"var(--wire)\" stroke-width=\"0.8\" stroke-dasharray=\"2 3\"></line><text x=\"190.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">26/10, 03:00</text><line x1=\"300.0\" y1=\"40.0\" x2=\"300.0\" y2=\"250.0\" stroke=\"var(--wire)\" stroke-width=\"0.8\" stroke-dasharray=\"2 3\"></line><text x=\"300.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">27/10, 03:00</text><line x1=\"410.0\" y1=\"40.0\" x2=\"410.0\" y2=\"250.0\" stroke=\"var(--wire)\" stroke-width=\"0.8\" stroke-dasharray=\"2 3\"></line><text x=\"410.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">28/10, 03:00</text><line x1=\"520.0\" y1=\"40.0\" x2=\"520.0\" y2=\"250.0\" stroke=\"var(--wire)\" stroke-width=\"0.8\" stroke-dasharray=\"2 3\"></line><text x=\"520.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">29/10, 03:00</text><line x1=\"630.0\" y1=\"40.0\" x2=\"630.0\" y2=\"250.0\" stroke=\"var(--wire)\" stroke-width=\"0.8\" stroke-dasharray=\"2 3\"></line><text x=\"630.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">30/10, 03:00</text><text x=\"20.0\" y=\"95.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">padrão do Airflow 3</text><text x=\"20.0\" y=\"112.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">uma execução a cada 03:00</text><circle cx=\"190.0\" cy=\"100\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"190.0\" y=\"122.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">ds=26</text><circle cx=\"300.0\" cy=\"100\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"300.0\" y=\"122.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">ds=27</text><circle cx=\"410.0\" cy=\"100\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"410.0\" y=\"122.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">ds=28</text><circle cx=\"520.0\" cy=\"100\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"520.0\" y=\"122.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">ds=29</text><circle cx=\"630.0\" cy=\"100\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"630.0\" y=\"122.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">ds=30</text><text x=\"20.0\" y=\"185.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">CronDataInterval</text><text x=\"20.0\" y=\"202.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">uma execução quando o dia acaba</text><rect x=\"193.0\" y=\"180\" width=\"104\" height=\"12\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"245.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">ds=26</text><circle cx=\"300.0\" cy=\"186\" r=\"5\" fill=\"var(--amber)\"></circle><rect x=\"303.0\" y=\"180\" width=\"104\" height=\"12\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"355.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">ds=27</text><circle cx=\"410.0\" cy=\"186\" r=\"5\" fill=\"var(--amber)\"></circle><rect x=\"413.0\" y=\"180\" width=\"104\" height=\"12\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"465.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">ds=28</text><circle cx=\"520.0\" cy=\"186\" r=\"5\" fill=\"var(--amber)\"></circle><rect x=\"523.0\" y=\"180\" width=\"104\" height=\"12\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"575.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">ds=29</text><circle cx=\"630.0\" cy=\"186\" r=\"5\" fill=\"var(--amber)\"></circle><text x=\"642.0\" y=\"230.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">a captura rodou no dia 30</text><text x=\"360.0\" y=\"268.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">um ponto é quando uma execução começa; ds é a data que ela recebe</text></svg>", "caption": "A mesma expressão cron, dois timetables: o padrão dá a uma execução a noite em que ela começa, o de intervalo dá o dia que acabou de terminar.", "same": ["CronDataInterval"]}
```

**É por isso que o DAG da Quitanda diz `macros.ds_add(ds, -1)`.** No padrão do Airflow 3, a execução
das 03:00 do dia 30 tem `ds` 2026-10-30, um dia com três horas de vida, e o job precisa receber o dia
anterior. No `CronDataIntervalTimetable`, o mesmo DAG usaria o `ds` direto, que é o que a documentação
do Airflow 2 e a maioria dos DAGs que você vai ler supõem. Os dois estão certos, desde que o DAG saiba
qual timetable tem; um DAG levado do Airflow 2 para o 3 sem essa linha processa, toda noite, um dia
que mal começou.

**O `catchup=False`, a configuração do DAG da Quitanda, cria só a execução mais recente** quando um
DAG é despausado tarde, em vez de uma para cada noite desde a data de início. É o padrão seguro para
um pipeline cujas noites antigas foram processadas de outro jeito, e o errado para um pipeline novo
que deveria preencher o próprio histórico.

## Backfill: o catch-up de propósito

**Um backfill cria execuções para um intervalo de datas passadas, diga o `catchup` o que disser.** No
Airflow 3 ele é um comando, e o `--dry-run` lista as execuções que criaria, sem criá-las:

```
ana@laptop:~/gcp$ airflow backfill create --dag-id clock_interval --from-date 2026-10-20 --to-date 2026-10-23 --dry-run 2>/dev/null | grep -A20 "Runs to be"
Runs to be attempted:
+---------------------------+-----------------+------------------+
| logical_date              | partition_key   | partition_date   |
+===========================+=================+==================+
| 2026-10-20 06:00:00+00:00 |                 |                  |
+---------------------------+-----------------+------------------+
| 2026-10-21 06:00:00+00:00 |                 |                  |
+---------------------------+-----------------+------------------+
| 2026-10-22 06:00:00+00:00 |                 |                  |
+---------------------------+-----------------+------------------+
```

**Foram pedidos quatro dias, e voltaram três execuções.** Os dias 20, 21 e 22 rodaram a partir de
06:00 UTC, três da manhã em São Paulo; o dia 23 não, porque `--to-date 2026-10-23` significa
meia-noite UTC do dia 23, seis horas antes de a execução daquela noite começar. As datas de um
backfill são momentos, não dias, e um intervalo que deve incluir uma noite precisa ir além das 03:00
dessa noite. Sem o `--dry-run`, o mesmo comando cria as três execuções e o scheduler as roda, poucas
de cada vez, cada uma com o próprio intervalo. É assim que uma semana de noites que falharam porque
um bucket estava vazio é refeita num comando só depois que o bucket é preenchido.

**Este é o recurso de que os times sentem falta primeiro quando saem do Airflow.** Nada no Workflows
nem no Cloud Scheduler sabe o que significa "a execução do dia 22": o workflow da seção anterior
calculava o dia pelo relógio, então refazer o dia 22 ali significa iniciá-lo passando o dia à mão.

## Composer, ou Workflows e Cloud Scheduler

**Escolha pelo número e pelo formato dos pipelines, não pelo tamanho dos dados**, porque nenhum dos
dois faz o trabalho pesado: os dois iniciam Dataproc, BigQuery ou Dataflow e esperam.

| | Composer | Workflows com Cloud Scheduler |
|---|---|---|
| custo parado | 523.85 a 838.41 por mês, os dois ambientes da seção sobre a conta ociosa | nada entre execuções |
| para qual dia é uma execução | logical date e intervalo de dados | o relógio |
| catch-up e backfill | embutidos | uma execução por dia, à mão |
| pipeline escrito como | Python | YAML |
| serviços fora do Google | muitos operadores | uma chamada HTTP |
| o que você opera | o tamanho do ambiente, os pacotes, as atualizações | as definições |

**Para a Quitanda hoje, com um pipeline de quatro passos, a resposta é Workflows com Cloud
Scheduler**: a mesma ordem, uma política de novas tentativas onde fizer falta e nenhum quinhentos
dólares por mês por um agendador que espera. No dia em que houver trinta DAGs, três times e o hábito
de refazer a semana passada, a tabela vira, e mudar para o Composer é um trabalho que o time vai
agradecer, e não um custo de que vai reclamar. Escrever o primeiro pipeline de modo que cada passo
seja um job próprio com a data como argumento, como o `daily_orders.py` recebe `--dt`, é o que mantém
essa mudança barata: os jobs ficam, e só muda o que os inicia.
