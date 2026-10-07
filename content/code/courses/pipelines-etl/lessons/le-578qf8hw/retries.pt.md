---
title: Retries, e a espera entre eles
version: 1
---

O `retries` é o número de tentativas que o Airflow pode fazer **depois** da primeira, então
`retries: 4` são cinco tentativas ao todo. O `retry_delay` é quanto ele espera antes do primeiro
retry, e o `retry_exponential_backoff` multiplica a espera a cada vez que ela é usada de novo.

**No Airflow 3.3 o backoff é um número, não um interruptor.** A documentação dele o chama de
multiplicador, com `0` querendo dizer espera constante e `2.0` querendo dizer *dobrar a cada vez*;
DAGs mais antigos escreviam `True` ali, e o Python conta `True` como `1`, então eles ganham uma
espera multiplicada por um — os mesmos quinze segundos antes de cada tentativa, sem nada em log
nenhum dizendo que o backoff não está acontecendo. A Ana escreve `2.0` e um comentário com as esperas
que isso deve produzir. O Airflow ainda soma até o mesmo tanto, uma quantia tirada de um hash da
tarefa, da data lógica da execução e do número da tentativa, para que cem tarefas que falharam
juntas não voltem todas no mesmo segundo.

Por que esperar mais a cada vez? Porque o motivo de uma falha passageira costuma ser algo que precisa
de um tempo para passar — uma implantação, um reinício, um servidor sobrecarregado — e um cliente que
pergunta de novo a cada quinze segundos é mais um cliente mantendo aquele servidor sobrecarregado.
**A espera crescente é educação e aritmética ao mesmo tempo**: o primeiro retry pega um soluço, e o
último ainda tem chance contra uma queda de vários minutos.

A API do laboratório pode ser desligada. A Ana a desliga, tira a pausa do DAG — o que cria uma
execução na hora, para as últimas 03:00 que já passaram, como a lição 9 mostrou — e a liga de novo
depois que a segunda tentativa falhou:

```
#!/bin/sh
# Every try of one task in one run, from Airflow's API: when it ran and how it ended.
curl -s "http://127.0.0.1:8080/api/v2/dags/$1/dagRuns/$2/taskInstances/$3/tries" |
  python -c 'import json, sys
for t in json.load(sys.stdin)["task_instances"]:
    print("try", t["try_number"], t["state"], (t["start_date"] or "")[11:19], "to", (t["end_date"] or "")[11:19])'
```

```
ana@vm:~/etl$ airflow dags unpause prices_daily
dag_id       | is_paused
=============+==========
prices_daily | True     
                        
ana@vm:~/etl$ airflow dags list-runs prices_daily -o plain | cut -c1-118
dag_id        run_id                                state    run_after                  logical_date               sta
prices_daily  scheduled__2026-10-07T06:00:00+00:00  success  2026-10-07T06:00:00+00:00  2026-10-07T06:00:00+00:00  202
ana@vm:~/etl$ sh tries.sh prices_daily $(airflow dags list-runs prices_daily -o plain | grep -o "scheduled__[^ ]*") fetch
try 1 failed 06:08:39 to 06:08:43
try 2 failed 06:09:01 to 06:09:01
try 3 success 06:09:36 to 06:09:36
ana@vm:~/etl$ cat alerts.log
cat: alerts.log: No such file or directory
```

A execução deu certo. **Duas tentativas falharam, a terceira achou a API de volta, e ninguém foi
avisado**, porque não havia nada a fazer: o `alerts.log` nem existe ainda. Os intervalos entre as
tentativas mostram o backoff funcionando, cada espera mais ou menos o dobro da anterior.

Esse último ponto é todo o desenho. **Um retry transforma uma falha passageira num sucesso mais
lento**, e um sucesso mais lento não é notícia. Notícia é a falha que os retries não conseguiram
absorver, que é a próxima seção.

Os retries têm uma condição, e é fácil esquecê-la porque ela nem é sobre o Airflow: **uma tarefa
precisa poder rodar duas vezes sem estrago**. Uma tentativa que carregou metade das linhas e depois
falhou vai ser seguida por uma que carrega todas; se a primeira metade ainda estiver lá, ela é
carregada duas vezes. O `fetch` reescreve o arquivo inteiro a cada tentativa, então uma segunda
tentativa deixa o mesmo arquivo que uma só deixaria. A lição 15 faz dessa propriedade o assunto.
