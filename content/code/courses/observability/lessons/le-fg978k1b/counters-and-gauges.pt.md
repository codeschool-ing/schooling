---
title: Counters e gauges
version: 2
---

Toda métrica declara um **tipo** na linha `# TYPE`, e o tipo decide que perguntas a métrica consegue
responder. A página da vitrine lista todas, as dela e as que a biblioteca cliente de Python
acrescenta de graça. Esta aula lê uma loja sob carga, então comece de um laboratório iniciado de
novo do zero, ponha os clientes simulados para rodar por meia hora e dê a eles um minuto:

```sh
docker compose run -d --rm loadgen python -m loadgen.load 5 1800
```

Depois, os tipos:

```
ana@obs:~/shop$ curl -s localhost:8080/metrics | grep '^# TYPE'
# TYPE python_gc_objects_collected_total counter
# TYPE python_gc_objects_uncollectable_total counter
# TYPE python_gc_collections_total counter
# TYPE python_info gauge
# TYPE process_virtual_memory_bytes gauge
# TYPE process_resident_memory_bytes gauge
# TYPE process_start_time_seconds gauge
# TYPE process_cpu_seconds_total counter
# TYPE process_open_fds gauge
# TYPE process_max_fds gauge
# TYPE http_server_requests_total counter
# TYPE http_server_requests_created gauge
# TYPE http_server_request_duration_seconds histogram
# TYPE http_server_request_duration_seconds_created gauge
```

Dois tipos cobrem quase toda a lista. Um **counter** (contador) só sobe, ou volta a zero quando o
processo reinicia: requisições respondidas, coletas de lixo, segundos de processador usados. O nome
dele termina em `_total` por convenção, e a aula 5 mostrou que o valor dele diz pouco e o `rate()`
diz muito. Um **gauge** sobe e desce e o valor atual é a resposta: memória em uso, descritores de
arquivo abertos, mensagens esperando numa fila. Dois gauges e um counter da vitrine:

```
ana@obs:~/shop$ curl -s localhost:8080/metrics | grep -E '^process_(resident_memory_bytes|open_fds) '
process_resident_memory_bytes 4.8697344e+07
process_open_fds 11.0
ana@obs:~/shop$ ./promq 'rate(process_cpu_seconds_total{job="storefront"}[1m])'
instance=storefront:8080 job=storefront  0.01933333333333333
```

48,7 MB de memória e onze arquivos abertos, lidos como estão. O tempo de processador é um counter de
segundos, então a taxa dele é *segundos de processador por segundo*: 0,019, cerca de dois por cento
de um núcleo.

**O tipo errado quebra a conta em silêncio.** O `rate()` de um gauge trata toda queda como reinício
e produz absurdos. Um gauge informando *requisições até agora* perde tudo num reinício e não pode
ser somado entre instâncias. A regra prática: se a pergunta é *quantos aconteceram*, é um counter;
se é *quantos há agora*, é um gauge.

As linhas `_created` são uma terceira coisa: gauges que a biblioteca cliente acrescenta ao lado de
cada counter e histograma. Cada um guarda a hora em que a série foi criada, o que permite a um
backend distinguir um reinício de um contador que sempre foi zero. Vale reparar nelas agora, porque
o experimento desta aula tropeça nelas.
