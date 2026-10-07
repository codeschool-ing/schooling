---
title: A data lógica, e o dia sendo carregado
version: 1
---

Toda execução de um DAG existe *para* um momento, e o Airflow chama esse momento de **data lógica**.
Não é a hora em que a execução por acaso começa. Uma execução agendada para as 02:00 de 3 de março
tem essa data lógica quer comece às 02:00:01, depois de duas horas fora do ar, ou seis meses depois
quando alguém a roda de novo à mão. **É isso que deixa um pipeline reprocessar o passado**: uma
tarefa que pergunta à execução para que data ela existe, em vez de perguntar ao relógio, faz o mesmo
trabalho sempre que for rodada.

O `day_to_load` é essa regra em quatro linhas: ele pega a data lógica da execução, a põe no horário
de São Paulo e subtrai um dia. A execução das 02:00 de 3 de março carrega o dia 2 de março, hoje ou no
ano que vem:

```
ana@vm:~/etl$ airflow dags list-runs shop_nightly -o plain
dag_id        run_id                                    state    run_after                         logical_date               start_date                 end_date
shop_nightly  manual__2026-10-07T04:01:19.094015+00:00  success  2026-10-07T04:01:19.094015+00:00  2026-03-03T03:00:00+00:00  2026-03-03T03:00:00+00:00  2026-10-07T04:01:24.970007+00:00
```

O `logical_date` é `2026-03-03T03:00:00+00:00` — meia-noite de 3 de março em São Paulo, escrita em
UTC — porque o `dags test` recebeu a data `2026-03-03` sem hora. O `run_after`, o momento em que a
execução pôde começar, é o relógio de verdade da gravação, em outubro. **Os dois não têm nada a ver um
com o outro**, e uma tarefa que usasse o `run_after`, ou `datetime.now()`, teria carregado um dia de
outubro.

## A data de execução, e o que o Airflow 3 mudou

O Airflow 2 chamava esse campo de **data de execução** (*execution date*), e o nome causou uma década
de confusão, porque uma execução diária não executava na sua data de execução. As execuções dele
cobriam um intervalo — um dia inteiro — e rodavam quando o intervalo acabava: a execução de 2 de março
executava no começo de 3 de março. Toda equipe aprendeu isso do jeito difícil uma vez.

O Airflow 3 renomeou o campo para *data lógica*, e mudou o que um agendamento cron simples significa.
Por padrão, `schedule="0 2 * * *"` agora é um **gatilho**: uma execução acontece às 02:00, a data
lógica dela *é* 02:00, e ela não tem intervalo por trás. O comportamento antigo continua disponível,
declarando um agendamento que tem intervalos, e a lição 9 mostra os dois lado a lado. **O DAG da Ana
fica com a regra mais simples e diz no próprio código qual dia carrega**: a data lógica menos um dia.
Nada nele depende de lembrar qual convenção a versão do Airflow à sua frente usa.

A lição 9 acrescenta a outra metade: o que o agendador faz com essas datas quando é ele, e não o
`dags test`, quem cria as execuções.
