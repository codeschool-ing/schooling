---
title: Um alerta que chega antes da parede
version: 1
---

Um alerta é a promessa de que alguém vai ser acordado a tempo. A maioria dos alertas de capacidade
quebra essa promessa do mesmo jeito: dispara num **percentual**. "Disco acima de 80%" parece
prudente e não diz nada sobre tempo. Num disco que levou cinco anos para chegar a 80%, é um aviso
para o orçamento do próximo trimestre; num que foi de 50% a 80% desde segunda-feira, o banco vai
parar antes de alguém ler o e-mail.

**O que um alerta deve medir é o tempo que resta**: a distância até a parede, dividida pela
velocidade com que se aproxima dela. A seção de crescimento fez essa conta uma vez, à mão, para o
disco. Um alerta a faz de hora em hora.

## Uma consulta para as paredes que o banco enxerga

Este arquivo lê, numa passada, cada parede que o banco enxerga de dentro, com quanto está usado, o
limite e o percentual:

```sql
-- capacity.sql: how close market is to each wall it can see from inside.
-- Run it on a schedule, keep the rows, and alert on the trend.
SELECT wall, used, lim, round(100 * used / lim, 2) AS pct
FROM (
  SELECT 'connections' AS wall,
         (SELECT count(*) FROM pg_stat_activity
           WHERE backend_type = 'client backend')::numeric AS used,
         current_setting('max_connections')::numeric AS lim
  UNION ALL
  SELECT 'transaction id age', age(datfrozenxid), 2000000000
    FROM pg_database WHERE datname = current_database()
  UNION ALL
  SELECT 'sequence ' || sequencename, last_value, max_value
    FROM pg_sequences WHERE last_value IS NOT NULL
  UNION ALL
  SELECT 'largest total_cents', max(total_cents), 2147483647 FROM orders
) AS walls
ORDER BY pct DESC;
```

Salve-o no seu diretório pessoal como `capacity.sql` e rode:

```
ana@vm:~$ psql market -f capacity.sql
           wall            |  used   |         lim         | pct  
---------------------------+---------+---------------------+------
 connections               |       1 |                 100 | 1.00
 transaction id age        |  526533 |          2000000000 | 0.03
 sequence customers_id_seq |  200000 |          2147483647 | 0.01
 sequence orders_id_seq    | 2016623 | 9223372036854775807 | 0.00
 sequence events_id_seq    | 5000000 | 9223372036854775807 | 0.00
 largest total_cents       |   50499 |          2147483647 | 0.00
 sequence sellers_id_seq   |    1000 |          2147483647 | 0.00
 sequence products_id_seq  |   50000 |          2147483647 | 0.00
(8 rows)

Time: 162.050 ms
EXIT 0
```

Tudo está longe da parede num banco que roda há uma tarde, e é por isso que vale lê-lo agora: os
números com que você vai comparar depois têm de ser anotados enquanto são entediantes. O
`transaction id age` é medido contra dois bilhões, o ponto em que o servidor recusa transações
novas, e não contra os 200 milhões em que o autovacuum entra — um alerta nesse aqui é sobre se o
congelamento está acompanhando, e o que importa é a tendência.

## De foto para tendência

Uma execução do `capacity.sql` é uma foto. O alerta precisa de duas fotos e do tempo entre elas, o
que quer dizer guardá-las: uma tabela num banco que não é o vigiado, preenchida por uma tarefa de
hora em hora, ou o sistema de monitoração que a sua empresa já tem, que quase certamente consegue
rodar uma consulta num horário e guardar o que volta. Então a regra para cada parede é a mesma conta:

```localised
tempo que resta  =  (limite − usado agora)  ÷  (crescimento por dia)
```

e o alerta dispara quando o tempo que resta cai abaixo de **quanto o conserto leva, mais uma
margem**. Essa última parte é o que torna cada limite diferente:

| parede | o conserto | alertar quando o tempo que resta for menor que |
|---|---|---|
| disco | comprar e ligar um disco maior, ou arquivar | duas a quatro semanas |
| conexões | um pooler, ou uma mudança de código na aplicação | dias, então um segundo sinal na taxa de conexões recusadas |
| contador de transações | achar o que impede o congelamento, e rodar o vacuum | uma semana antes dos 200 milhões em que o autovacuum o força |
| uma sequência `integer` | migrar a chave para `bigint` | um ano |

O ano da sequência não é erro de digitação. Mudar o tipo de uma chave reescreve a tabela e tudo o
que se refere a ela, e fazer isso com calma exige planejamento, testes e uma janela de manutenção: um
alerta que desse um mês de aviso seria um alerta que não deu aviso nenhum.

## Dois alertas que não são sobre paredes

O joelho da seção de folga não é uma parede, e precisa de outro alerta. **Alerte na latência que os
usuários veem** — o percentil 95 ou 99 das requisições da aplicação — em vez de em quão ocupado o
servidor está, porque o servidor rodava a nove décimos da taxa máxima quando as transações mais
lentas já esperavam dois terços de segundo. E alerte na **mudança**, não só no nível: uma consulta que
levava 10 milissegundos ontem e 40 hoje ainda não bateu em nada, e é o primeiro sinal de estatísticas
ficando velhas (aula 6) ou de uma tabela crescendo além do ponto em que o plano dela fazia sentido
(aula 4).

A aula 13 do `db-reliability` alerta no atraso de replicação do mesmo jeito, e a aula 14 do
`db-administration`, no autovacuum ficando para trás. O que elas têm em comum com esta aula é a regra:
**um alerta só vale o barulho que faz se chegar enquanto ainda há tempo de fazer algo com calma**.
