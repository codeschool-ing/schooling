---
title: Nenhum emulador para o Composer, e um Airflow de verdade no lugar
version: 1
---

**Nada imita o Cloud Composer.** O Google não publica emulador para ele, o fake-gcs-server não sabe
nada de ambientes, e um ambiente é um cluster Kubernetes e uma instância Cloud SQL que nenhum
notebook conseguiria fingir ser. Mas **o que o Composer roda é o Apache Airflow, e o Apache Airflow
se instala com pip**, com um arquivo SQLite como banco de metadados. Então esta seção instala o
mesmo Airflow na sua máquina e roda o DAG da Quitanda com ele, de verdade. O que você ganha é o
motor, não o serviço: nada de ambiente, nada de bucket sincronizado com um scheduler, nada de conta
do Google, e todo comando que criaria essas coisas aparece no fim e não foi rodado.

## O Airflow, num ambiente virtual só dele

**O Airflow fixa centenas de pacotes, e ganha um ambiente virtual só dele** para que nenhum deles
mude uma versão de que o ambiente do curso depende. O projeto Airflow publica um *arquivo de
constraints* por versão e por versão do Python, com as versões exatas com que foi testado, e
instalar contra ele é o jeito que o projeto indica:

```sh
python3 -m venv ~/gcp/airflow-venv
curl -sSLO https://raw.githubusercontent.com/apache/airflow/constraints-3.3.2/constraints-3.12.txt
~/gcp/airflow-venv/bin/pip install -q apache-airflow==3.3.2 --constraint constraints-3.12.txt
```

Depois, três linhas para todo terminal em que você o usar. **A primeira põe o `airflow` no fim do
caminho**, depois do ambiente do curso, para que `python3` e `spark-submit` numa tarefa continuem
sendo os da aula 23. A segunda diz onde o Airflow guarda os arquivos, desliga os DAGs de exemplo que
ele carregaria e silencia um aviso sobre o graphviz, uma biblioteca de desenho que nada aqui usa. A
terceira move o API server do Airflow para a porta 8090, porque a padrão, 8080, é a porta que o
emulador do Firestore da aula 10 usa:

```sh
export PATH="$PATH:$HOME/gcp/airflow-venv/bin"
export AIRFLOW_HOME=$HOME/gcp/airflow AIRFLOW__CORE__LOAD_EXAMPLES=False PYTHONWARNINGS=ignore::UserWarning
export AIRFLOW__API__PORT=8090 AIRFLOW__CORE__EXECUTION_API_SERVER_URL=http://localhost:8090/execution/
```

```
ana@laptop:~/gcp$ python3 -m venv ~/gcp/airflow-venv
ana@laptop:~/gcp$ ~/gcp/airflow-venv/bin/pip install -q apache-airflow==3.3.2 --constraint constraints-3.12.txt
ana@laptop:~/gcp$ airflow version
3.3.2
```

**Toda configuração do Airflow é uma linha do `airflow.cfg` e uma variável de ambiente ao mesmo
tempo**: `AIRFLOW__CORE__LOAD_EXAMPLES` é a opção `load_examples` da seção `[core]`, com dois
sublinhados de cada lado do nome da seção. O Composer funciona do mesmo jeito, e o ambiente dele tem
uma lista dessas substituições no lugar de um arquivo que você edita.

## O banco de metadados e a pasta de DAGs

O `airflow db migrate` cria o banco de metadados, um arquivo SQLite em `$AIRFLOW_HOME`, e a pasta de
DAGs é um diretório dentro dele. Salve nela o DAG da seção anterior:

```
ana@laptop:~/gcp$ airflow db migrate 2>&1 | tail -1
2026-10-30T18:59:10.700653Z [info     ] Database migration done!       [airflow.cli.commands.db_command] loc=db_command.py:152
ana@laptop:~/gcp$ mkdir -p $AIRFLOW_HOME/dags && cp quitanda_nightly.py $AIRFLOW_HOME/dags/
ana@laptop:~/gcp$ airflow dags reserialize > /dev/null 2>&1; airflow dags list -o plain 2>/dev/null | awk '{print $1, $4}'
dag_id is_paused
quitanda_nightly True
```

**`is_paused` está `True`, e isso é o Airflow sendo cuidadoso.** Um DAG novo começa pausado, então
um arquivo largado na pasta por engano não agenda nada até alguém despausá-lo. O Composer mantém o
mesmo padrão.

## Renderize uma tarefa, depois rode o DAG inteiro

**Antes de rodar qualquer coisa, pergunte ao Airflow o que uma tarefa faria.** O `airflow tasks
render` preenche os templates de uma tarefa para uma logical date dada e imprime o resultado, sem
rodá-la. A logical date aqui é 06:00 UTC do dia 30, que são três da manhã em São Paulo, o momento em
que o agendamento dispara:

```
ana@laptop:~/gcp$ airflow tasks render quitanda_nightly export_orders 2026-10-30T06:00:00+00:00 2>/dev/null | grep -A2 'property: bash_command'
# property: bash_command
# ----------------------------------------------------------
python3 make_orders.py 2026-10-29
```

**O `{DAY}` virou 2026-10-29**: a execução do dia 30 processa o dia 29, que é o dia que terminou.
Depois rode o DAG uma vez, as quatro tarefas em ordem, com o `airflow dags test`, que roda cada
tarefa no próprio processo do terminal, sem scheduler, e registra a execução no banco de metadados
como qualquer outra. O Airflow escreve muita coisa enquanto isso, então vai para um arquivo:

```
ana@laptop:~/gcp$ airflow dags test quitanda_nightly 2026-10-30T06:00:00+00:00 > test.log 2>&1; echo "exit $?"
exit 0
ana@laptop:~/gcp$ grep -o 'Running command: .*' test.log | cut -c1-110
Running command: ['/usr/bin/bash', '-c', 'python3 make_orders.py 2026-10-29'] [airflow.task.hooks.airflow.prov
Running command: ['/usr/bin/bash', '-c', "spark-submit --master 'local[2]' daily_orders.py --dt 2026-10-29 2> 
Running command: ['/usr/bin/bash', '-c', 'python3 check_daily.py 2026-10-29'] [airflow.task.hooks.airflow.prov
Running command: ['/usr/bin/bash', '-c', 'gcloud storage cp curated/daily_orders/dt=2026-10-29/* gs://quitanda
ana@laptop:~/gcp$ grep -oE '([0-9]+ orders read|│ +[0-9]).*' test.log | sed 's/ *\[airflow.*//'
20000 orders read, 500 customers written
│  20000 │   412139132 │
│       500 │  20000 │   412139132 │
ana@laptop:~/gcp$ gcloud storage ls gs://quitanda-curated-prod/daily_orders/
gs://quitanda-curated-prod/daily_orders/dt=2026-10-29/
ana@laptop:~/gcp$ airflow dags list-runs quitanda_nightly -o plain 2>/dev/null | cut -c1-120
dag_id            run_id                                    state    run_after                         logical_date     
quitanda_nightly  manual__2026-10-30T18:59:22.101271+00:00  success  2026-10-30T18:59:22.101271+00:00  2026-10-30T06:00:
```

**Quatro comandos rodaram, na ordem das setas**, cada um com o dia 29 preenchido, e a checagem
imprimiu as mesmas contagens e os mesmos totais da aula 23. Os dois últimos comandos mostram o
resultado da última tarefa, o Parquet do dia no bucket curated do emulador, e a execução de que o
Airflow guardou registro: uma execução, `manual` porque foi o `dags test` que a iniciou, e não o
agendamento.

**Esta é a parte do Composer que o laboratório consegue mostrar, e é a maior parte do que você
escreve.** Um arquivo de DAG, os templates dele, a ordem e as novas tentativas se comportam igual no
seu notebook e num ambiente, porque os dois são o mesmo Airflow. O que muda é o que fica rodando:
aqui nada fica depois que o comando termina, e a próxima seção é sobre quanto custa manter tudo
rodando.

## O que este laboratório não consegue mostrar

**Tudo o que é do próprio Composer não foi rodado aqui.** Criar um ambiente, o que demora o bastante
para as pessoas irem fazer outra coisa; o scheduler pegar um arquivo novo do bucket do ambiente; um
worker no cluster do Google rodar as tarefas; a interface web; os logs no Cloud Logging. Os
comandos, **não rodados aqui**:

```sh
gcloud composer environments create quitanda \
  --location=southamerica-east1 --environment-size=small
gcloud composer environments storage dags import \
  --environment=quitanda --location=southamerica-east1 --source=quitanda_nightly.py
```

**O `--environment-size` é o tamanho da infraestrutura, não dos workers**: ele decide quanto do
banco, da fila e das outras partes gerenciadas o ambiente tem, e os workers escalam sozinhos entre
limites que você define. Deixar de fora o `--image-version` dá a imagem padrão do Composer, que nomeia
uma versão do Composer e uma do Airflow juntas, e o DAG acima, escrito contra `airflow.sdk`, precisa
de uma imagem com Airflow 3. Quais imagens o Google oferece em São Paulo num dado dia está na lista de
versões da documentação, que este laboratório não conseguiu ler. O segundo comando é uma cópia para
a pasta `dags/` do bucket do ambiente, e o scheduler percebe o arquivo na próxima passada pela pasta.
