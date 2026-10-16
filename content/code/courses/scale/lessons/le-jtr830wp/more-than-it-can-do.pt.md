---
title: Mais do que ela dá conta
version: 1
---

Todo sistema tem uma taxa que consegue sustentar, e cedo ou tarde alguém pede mais: uma abertura de
vendas às dez da manhã, um robô comprando um show inteiro, uma tempestade de novas tentativas depois
de uma queda curta. A pergunta desta aula não é como deixar a bilheteria mais rápida. As aulas 1 a 3
fizeram isso. É **o que a bilheteria faz quando a demanda é maior que qualquer capacidade que ela
tenha**.

Comece vendo-a falhar. Esta é a bilheteria exatamente como a aula 8 a deixou, sem guarda nenhuma, e
o `load.py` da aula 1 comprando ingressos com 8, 32 e depois 128 trabalhadores:

```
ana@lab:~/tickets$ python3 load.py -m POST -d 10 'http://localhost:8080/events/{event}/tickets' --events 50 -c 8
requests  1129 in 10.0 s = 112.5 per second
latency   p50 70.1 ms  p95 102.9 ms  p99 134.7 ms  max 264.9 ms
status    201: 1129
ana@lab:~/tickets$ python3 load.py -m POST -d 10 'http://localhost:8080/events/{event}/tickets' --events 50 -c 32
requests  1073 in 10.2 s = 105.0 per second
latency   p50 295.3 ms  p95 487.5 ms  p99 595.8 ms  max 693.5 ms
status    201: 1073
ana@lab:~/tickets$ python3 load.py -m POST -d 10 'http://localhost:8080/events/{event}/tickets' --events 50 -c 128
requests  1149 in 11.0 s = 104.3 per second
latency   p50 950.8 ms  p95 2729.2 ms  p99 3928.7 ms  max 4936.2 ms
status    201: 1003  500: 146
ana@lab:~/tickets$ docker compose logs app --no-log-prefix | grep -m1 '"error"'
{"time": "2026-10-10T07:23:06.826+00:00", "level": "error", "message": "request failed", "host": "6e2c7859899e", "method": "POST", "route": "/events/{id}/tickets", "error": "OperationalError: connection failed: connection to server at \"172.19.0.5\", port 5432 failed: FATAL:  sorry, too many clients already", "trace_id": "5e0dd9e9d37e77e98439c79b0c1dbb15"}
ana@lab:~/tickets$ docker compose exec db psql -U tickets -tAc "SELECT count(*) FROM pg_stat_activity WHERE backend_type = 'client backend'"
52
```

Três coisas acontecem, e acontecem nesta ordem em todo sistema.

**A taxa para de crescer.** 112, 105 e 104 vendas por segundo: a única CPU da bilheteria já estava
ocupada com 8 trabalhadores. Mais trabalhadores não trazem mais vendas.

**A espera é que cresce.** Cada trabalhador espera a resposta antes de pedir de novo, então os pedidos
em andamento são sempre o número de trabalhadores, e cada um espera a sua vez. A venda mediana levou
70 ms com 8 trabalhadores, 295 ms com 32 e 951 ms com 128: mais ou menos o número de trabalhadores
dividido pela taxa, que é a lei de Little, e a aula 11 volta a ela. Nada quebrou ainda. Tudo só ficou
mais lento.

**Depois a sobrecarga vai para outro lugar.** Com 128 trabalhadores, 146 vendas falharam com um 500,
e o log diz por quê: **o PostgreSQL recusou conexões**, `too many clients already`. A bilheteria
atende cada conexão que o nginx abre numa thread própria, e cada thread abre a própria conexão com o
banco na primeira vez que precisa de uma. 128 trabalhadores fazem o nginx abrir umas 128 conexões
com a bilheteria, então umas 128 threads pedem conexões ao banco, e o limite padrão do PostgreSQL é
100. Depois da execução, com a maioria dessas threads encerradas, sobraram 52 conexões, contando a
do próprio `psql`.

Esse último passo é o que vale lembrar. **Uma bilheteria sem CPU virou um banco sem conexões**, e o
erro que um comprador viu não citava nenhum dos dois. A sobrecarga se espalha pelo que não tem
limite, e nesta bilheteria nada tinha: nem as threads, nem as conexões, nem a frequência com que um
comprador pode pedir. O resto da aula põe um limite em cada um.
