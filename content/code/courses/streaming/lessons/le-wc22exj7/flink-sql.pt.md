---
title: A mesma contagem em Flink SQL
version: 1
---

O Flink tem uma API em Java, uma em Python e uma em SQL. **O SQL é o caminho mais curto para a
mesma contagem**: uma tabela sobre o tópico, uma tabela sobre a saída, e um `INSERT` que roda
enquanto o cluster rodar. O watermark, que a lição 12 declarou com `withWatermark`, aqui faz parte
da definição da tabela, ao lado das colunas.

Salve isto como `~/work/sales.sql`:

```sql
SET 'execution.checkpointing.interval' = '10 s';
SET 'execution.checkpointing.dir' = 'file:///home/ubuntu/flink-checkpoints';

CREATE TABLE sales (
  sale STRING,
  shop STRING,
  book STRING,
  qty INT,
  cents BIGINT,
  `at` STRING,
  ts AS TO_TIMESTAMP(REPLACE(SUBSTRING(`at`, 1, 19), 'T', ' ')),
  WATERMARK FOR ts AS ts - INTERVAL '2' MINUTE
) WITH (
  'connector' = 'kafka',
  'topic' = 'sales',
  'properties.bootstrap.servers' = 'localhost:9092',
  'properties.group.id' = 'flink-sales',
  'scan.startup.mode' = 'earliest-offset',
  'format' = 'json'
);

CREATE TABLE sales_per_window (
  window_start TIMESTAMP(3),
  window_end TIMESTAMP(3),
  sales BIGINT,
  cents BIGINT
) WITH (
  'connector' = 'kafka',
  'topic' = 'flink-sales-per-window',
  'properties.bootstrap.servers' = 'localhost:9092',
  'format' = 'json'
);

INSERT INTO sales_per_window
SELECT window_start, window_end, COUNT(*), SUM(cents)
FROM TABLE(TUMBLE(TABLE sales, DESCRIPTOR(ts), INTERVAL '5' MINUTE))
GROUP BY window_start, window_end;
```

Leia de baixo para cima. O `INSERT` é a consulta: uma **janela fixa** de cinco minutos sobre `ts`,
que a lição 10 desenhou, agrupada e contada. Os dois `CREATE TABLE` não criam nada no Kafka; eles
dizem ao Flink como ler um tópico como tabela e como escrever em outro. O `at` é lido como texto, e `ts` é uma **coluna calculada** a partir dos primeiros
dezenove caracteres dele, a hora do relógio da loja. O `-03:00` do fim é descartado, o que é seguro
porque as cinco lojas estão no mesmo fuso. A
linha `WATERMARK` diz que `ts` é o tempo do evento e que uma venda pode chegar até dois minutos
atrasada, o mesmo limite da lição 12. As duas linhas `SET` do topo são assunto da seção 07.

Submeta. O cliente SQL repete cada comando enquanto o executa, e a única linha que vale guardar é o
id do job, então o `grep` fica com ela:

```
ubuntu@stream:~/work$ ~/flink/bin/sql-client.sh -f sales.sql 2>/dev/null | grep "Job ID"
Job ID: 28d4b45557a9e6ff9b7385f48a63751f
```

O cliente foi embora, e o job não: ele roda no cluster agora, e vai rodar até alguém pará-lo. Os
resultados vão para `flink-sales-per-window`, então leia esse tópico:

```
ubuntu@stream:~/work$ kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic flink-sales-per-window --from-beginning --timeout-ms 10000 2>/dev/null
```

## Nada, e por quê

**Dez segundos, e nenhuma janela**, embora o Spark tenha impresso seis a partir das mesmas vendas
com o mesmo watermark. O job está rodando:

```
ubuntu@stream:~/work$ ~/flink/bin/flink list
Waiting for response...
------------------ Running/Restarting Jobs -------------------
15.10.2026 22:22:56 : 28d4b45557a9e6ff9b7385f48a63751f : insert-into_default_catalog.default_database.sales_per_window (RUNNING)
--------------------------------------------------------------
No scheduled jobs.
```

O motivo é a fonte ociosa da lição 11. O Flink mantém **um watermark por partição** e move o
watermark do job para o menor deles, para que as vendas atrasadas de nenhuma partição sejam
atropeladas. O tópico `sales` tem três partições e a partição 2 está vazia: a chave de nenhuma loja
cai nela. Uma partição sem registros não tem watermark nenhum, então o menor é nada, e nenhuma
janela fecha nunca. O Spark, com um watermark só para a consulta inteira, não esperou; o Flink
espera, o que é correto quando a partição quieta está só lenta e errado quando ela está vazia.

A correção é declarar quanto tempo uma partição pode ficar quieta antes de deixar de contar.
Cancele o job, com o id que o `flink list` imprimiu:

```
ubuntu@stream:~/work$ ~/flink/bin/flink cancel 28d4b45557a9e6ff9b7385f48a63751f
Cancelling job 28d4b45557a9e6ff9b7385f48a63751f.
Cancelled job 28d4b45557a9e6ff9b7385f48a63751f.
```

Depois acrescente uma linha no topo do `sales.sql`, dizendo que uma partição calada por cinco
segundos está ociosa, e submeta de novo:

```
ubuntu@stream:~/work$ sed -i "1i SET 'table.exec.source.idle-timeout' = '5 s';" sales.sql
```

```
ubuntu@stream:~/work$ ~/flink/bin/sql-client.sh -f sales.sql 2>/dev/null | grep "Job ID"
Job ID: 1b14e9a9a838ec156cb32b72b8c46fd7
```

```
ubuntu@stream:~/work$ kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic flink-sales-per-window --from-beginning --timeout-ms 10000 2>/dev/null
{"window_start":"2026-03-02 09:00:00","window_end":"2026-03-02 09:05:00","sales":30,"cents":337340}
{"window_start":"2026-03-02 09:05:00","window_end":"2026-03-02 09:10:00","sales":28,"cents":241740}
{"window_start":"2026-03-02 09:10:00","window_end":"2026-03-02 09:15:00","sales":28,"cents":204680}
{"window_start":"2026-03-02 09:15:00","window_end":"2026-03-02 09:20:00","sales":29,"cents":240130}
{"window_start":"2026-03-02 09:20:00","window_end":"2026-03-02 09:25:00","sales":23,"cents":209180}
{"window_start":"2026-03-02 09:25:00","window_end":"2026-03-02 09:30:00","sales":25,"cents":237180}
```

**Seis janelas, as mesmas seis do modo append da lição 12**, com as mesmas contagens: 30 vendas a
partir de 09:00, 28 a partir de 09:05, até 25 a partir de 09:25. As janelas de 09:30 e 09:35 ficam
retidas pelo mesmo motivo de lá: o watermark está dois minutos atrás da última venda, 09:36:41, e a
janela de 09:30 termina às 09:35. O Flink escreve uma janela uma vez só, quando ela fecha, como o
modo append do Spark, então este tópico de saída pode ser lido por qualquer coisa que some
registros.

Os dois motores concordam porque a definição é a mesma: tempo do evento a partir de `at`, janelas
de cinco minutos, um limite de dois minutos. O que mudou foi uma regra sobre partições, e uma regra
assim vem junto com o motor que você escolhe.
