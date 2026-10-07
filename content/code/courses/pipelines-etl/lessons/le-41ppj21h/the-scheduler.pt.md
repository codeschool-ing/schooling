---
title: Entregando o DAG ao agendador
version: 1
---

Na lição 8 toda execução foi iniciada à mão, com o `dags test`. **Esta lição entrega o DAG ao
agendador**, que cria execuções sozinho, e a primeira coisa que ele faz é uma surpresa.

Antes de tirar a pausa, a Ana pergunta ao Airflow quando é a próxima execução:

```
ana@vm:~/etl$ airflow dags next-execution shop_nightly 2>/dev/null
2026-10-07T05:00:00+00:00
ana@vm:~/etl$ airflow dags unpause shop_nightly
dag_id       | is_paused
=============+==========
shop_nightly | True     
                        
ana@vm:~/etl$ airflow dags list-runs shop_nightly -o plain
dag_id        run_id                                state    run_after                  logical_date               start_date                        end_date
shop_nightly  scheduled__2026-10-07T05:00:00+00:00  success  2026-10-07T05:00:00+00:00  2026-10-07T05:00:00+00:00  2026-10-07T05:17:06.862828+00:00  2026-10-07T05:17:15.159934+00:00
ana@vm:~/etl$ psql -d wh -c "SELECT order_date, count(*) FROM marts.fact_sales GROUP BY 1 ORDER BY 1"
 order_date | count 
------------+-------
(0 rows)

ana@vm:~/etl$ airflow dags pause shop_nightly
dag_id       | is_paused
=============+==========
shop_nightly | False
```

Quatro coisas nessa transcrição merecem uma parada.

**A próxima execução estava no passado.** O `next-execution` respondeu com as 02:00 em São Paulo
mais recentes antes do momento da gravação. Com `catchup=False`, o agendador não cria uma execução
para cada 02:00 desde a data de início; ele cria de uma vez a última que perdeu, e espera a próxima.

**As tabelas impressas pelo `unpause` e pelo `pause` mostram o DAG como ele estava *antes* do
comando**: `True` depois de tirar a pausa, `False` depois de pausar. Parece o contrário do que
aconteceu, e da primeira vez que você vê, vale saber que é um hábito do Airflow e não um erro seu.

**A execução deu certo.** Ela rodou as seis tarefas, cada comando saiu com 0, e o estado é
`success`.

**E ela não carregou nada.** A execução de outubro carrega o dia anterior, de outubro, e a loja do
laboratório vive em março: não houve pedido nenhum naquele dia, então a tabela fato não tem linhas.
Nada falhou, porque não havia nada de errado com o código. **Uma execução que carrega um dia vazio é um
sucesso para o Airflow**, e num sistema de produção o mesmo formato aparece quando uma origem para de
mandar dados em silêncio: toda noite verde, toda noite vazia. A lição 16 acrescenta a verificação que
transforma "zero linhas" numa falha.

A Ana pausa o DAG de novo. O resto desta lição trata do que o agendador faz com as datas, e de como
fazê-lo carregar os dias que o laboratório de fato tem.
