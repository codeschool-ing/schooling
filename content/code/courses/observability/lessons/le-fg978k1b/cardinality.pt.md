---
title: Cardinalidade: os mesmos logins, por usuário
version: 1
---

Os mesmos vinte mil logins, agora com o label `user_id`:

```
ana@obs:~/shop$ docker compose run -d --rm --name logins sandbox python logins.py user_id
 Container shop-otel-collector-1 Running 
 Container logins Creating 
 Container logins Created 
3f0addda312ad842af41899934b362433ce339a2b9272ebd0eb14d8ac4bada86
ana@obs:~/shop$ ./promq 'count(demo_logins_total)'
  20000
ana@obs:~/shop$ ./promq 'prometheus_tsdb_head_series'
__name__=prometheus_tsdb_head_series instance=localhost:9090 job=prometheus  43805
```

**20000 séries para um contador, e a memória ativa foi de 3782 para 43805.** As vinte mil do
contador ganharam a companhia de vinte mil gauges `_created`, um por série. Um único label
acrescentou quarenta mil séries, dez vezes tudo o que o resto do laboratório guarda. O número de
valores distintos que um label assume se chama **cardinalidade**, e é isto que *alta cardinalidade*
custa:

```
ana@obs:~/shop$ ./promq 'scrape_samples_scraped{job="logins"}'
__name__=scrape_samples_scraped instance=logins:8000 job=logins  40016
ana@obs:~/shop$ curl -s localhost:9090/api/v1/targets | jq -r '.data.activeTargets[] | select(.labels.job == "logins") | [.health, .lastScrapeDuration] | @tsv'
up	0.456697839
```

40016 amostras a cada coleta, e a coleta agora leva **457 milissegundos**, contra 3,5 para o mesmo
contador por plano. E o próprio Prometheus:

```
ana@obs:~/shop$ ./promq 'process_resident_memory_bytes{job="prometheus"}'
__name__=process_resident_memory_bytes instance=localhost:9090 job=prometheus  158539776
```

**158 MB, contra 96**, por um contador de um experimento, antes de um único painel ter pedido
qualquer coisa. Cada uma dessas séries vive em memória enquanto está ativa, é escrita em disco, e é
indexada para que uma consulta a ache. Cada uma custa pouco, e são quarenta mil. Sistemas reais
cometem o mesmo erro com um id de requisição, um endereço de e-mail, uma URL inteira com a query
string ou um timestamp num label. As séries então se multiplicam com o tráfego até o Prometheus
ficar sem memória.

**A regra é a da aula 2, ao contrário.** Num span, um id de usuário está no lugar certo para
detalhe, porque um span é guardado uma vez digam o que disserem seus atributos. Numa métrica, está
no lugar errado: um valor de label é uma série nova que continua existindo. Labels devem assumir um
conjunto pequeno e conhecido de valores, e tudo o que identifica uma requisição, um usuário ou um
pedido vai num rastro ou numa linha de log.
