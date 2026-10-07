---
title: Limpar uma tarefa, e rodá-la de novo
version: 1
---

Uma execução que falhou não é refeita disparando uma nova. Uma nova seria uma segunda execução para
a mesma noite, com id e histórico próprios, e a que falhou continuaria na lista dizendo que a noite
falhou. **O jeito do Airflow é limpar a tarefa** (*clear*): o estado dela é apagado, a execução volta
para `running`, e o agendador dá à tarefa mais uma tentativa como se a falha tivesse sido só mais um
retry.

O `airflow tasks clear` escolhe instâncias de tarefa pelo DAG, pela tarefa (`-t`, uma expressão
regular) e pela data lógica (`-s` e `-e`). O `--only-failed` deixa em paz tudo o que deu certo, o
que importa num DAG com muitas tarefas: limpar a execução inteira refaria trabalho que estava bom.

```
ana@vm:~/etl$ airflow tasks clear prices_daily -t fetch -s 2026-03-10T03:00:00-03:00 -e 2026-03-10T03:00:00-03:00 --only-failed -y 2>&1 | tail -n 3 | cut -c1-118
ana@vm:~/etl$ airflow dags list-runs prices_daily -o plain | cut -c1-118
dag_id        run_id                                    state    run_after                         logical_date       
prices_daily  manual__2026-10-07T08:41:45.770719+00:00  success  2026-10-07T08:41:45.770719+00:00  2026-03-10T06:00:00
prices_daily  scheduled__2026-10-07T06:00:00+00:00      success  2026-10-07T06:00:00+00:00         2026-10-07T06:00:00
ana@vm:~/etl$ RUN=$(airflow dags list-runs prices_daily -o plain | grep -o "manual__[^ ]*"); sh tries.sh prices_daily $RUN fetch
try 1 failed 08:41:46 to 08:41:46
try 2 failed 08:42:09 to 08:42:09
try 3 failed 08:43:00 to 08:43:00
try 4 failed 08:44:35 to 08:44:35
try 5 failed 08:47:31 to 08:47:31
try 6 success 08:47:51 to 08:47:52
ana@vm:~/etl$ wc -l < landing/prices.jsonl; cat alerts.log
932
2026-10-07 05:43:47 LATE prices_daily run=manual__2026-10-07T08:41:45.770719+00:00 state=running
2026-10-07 05:47:31 FAILED prices_daily.fetch run=manual__2026-10-07T08:41:45.770719+00:00 try=5 error=HTTPError('503 Server Error: Service Unavailable for url: http://127.0.0.1:8081/v1/prices?page_size=200')
```

Com `-y` e nada a perguntar, o comando não imprime nada. A execução está em `success` agora, e continua sendo **a mesma execução**: o mesmo id, a mesma data
lógica e o histórico guardado — cinco tentativas falhas, depois uma sexta que funcionou. Ninguém que
leia a execução depois precisa adivinhar o que aconteceu naquela noite. Os preços estão em
`landing/prices.jsonl`, e o `alerts.log` não cresceu: nem o prazo nem o callback de falha tinham
nada de novo a dizer.

## O que limpar pressupõe

Limpar roda a tarefa de novo **com a mesma data lógica**, e tudo neste curso que lê a data lógica lê
o mesmo dia. O `fact_sales` do `shop_nightly`, limpo, carrega o mesmo dia que não conseguiu carregar,
não o de hoje. É por isso que a lição 8 insistiu que uma tarefa calcule o seu dia a partir da
execução e nunca do relógio: **uma tarefa que lê o relógio não pode ser refeita**, porque a nova
rodada carrega o dia que estiver fazendo.

E pressupõe, como um retry, que rodar a tarefa de novo é seguro. Limpar é um retry que uma pessoa
pediu. Tudo o que a seção de retries disse sobre rodar duas vezes vale, com uma diferença: um retry
vem segundos depois de uma falha, e uma limpeza pode vir dias depois, quando a fonte talvez já tenha
dados novos. Uma busca que pede à API *tudo agora* pode ser limpa sem medo; uma que pede *o que mudou
desde a última execução* precisa ser informada de qual última execução se trata.

Limpar também as tarefas seguintes é `--downstream`: no `shop_nightly`, limpar o `transform` com ele
refaria as três cargas depois dele, que é o que uma correção numa consulta de staging pede.
