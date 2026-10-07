---
title: A fatura, e descartar o que não se pode pagar
version: 2
---

No seu próprio Prometheus, cardinalidade custa memória e disco. **Num serviço gerenciado ela custa
dinheiro direto.** A maioria dos produtos hospedados de métricas cobra pelo número de séries ativas,
ou pelo número de amostras ingeridas, que é séries vezes coletas. A conta não precisa da tabela de
preços de fornecedor nenhum. Um label transformou 3782 séries em 43805: seja quanto for que uma
série custa numa fatura, esse label multiplicou a parte de métricas dela por mais de onze. Se o
experimento fosse um serviço real rodando em cinquenta cópias, cada cópia teria acrescentado as suas
quarenta mil.

Quando uma métrica dessas já está em produção, o primeiro remédio fica na coleta. Uma regra de
**reetiquetagem de métrica** (metric relabeling) na configuração do job roda em toda amostra coletada
antes de ela ser guardada, e pode descartar uma métrica pelo nome. Acrescente estas quatro linhas
no fim do `prometheus.yml`, embaixo do job `logins`, que é o último do arquivo, como o `tail` abaixo
mostra:

```
ana@obs:~/shop$ tail -8 prometheus/prometheus.yml
      - targets: [localhost:9090]
  - job_name: logins
    static_configs:
      - targets: [logins:8000]
    metric_relabel_configs:
      - source_labels: [__name__]
        regex: demo_logins_total
        action: drop
ana@obs:~/shop$ curl -s -X POST localhost:9090/-/reload && echo reloaded
reloaded
```

```
ana@obs:~/shop$ ./promq 'scrape_samples_scraped{job="logins"}'
__name__=scrape_samples_scraped instance=logins:8000 job=logins  40016
ana@obs:~/shop$ ./promq 'scrape_samples_post_metric_relabeling{job="logins"}'
__name__=scrape_samples_post_metric_relabeling instance=logins:8000 job=logins  20016
ana@obs:~/shop$ ./promq 'count(demo_logins_total)'
```

**A coleta ainda trouxe 40016 amostras, e 20016 sobreviveram.** A regra descartou
`demo_logins_total`, então a consulta por ele agora não devolve nada. Mas ela nomeava só essa
métrica, e as vinte mil séries `_created` passaram intactas. Esse é o estado honesto de um remendo
rápido. Ele barra a parte que alguém escreveu, ao custo de coletar e interpretar tudo antes, e é tão
completo quanto a sua expressão regular.

**O conserto é no código**: contar por `plan`, ou por nada, e pôr o id do usuário no span do login,
onde a aula 2 diz que ele não custa nada. Uma regra de reetiquetagem é como uma equipe estanca o
sangramento numa sexta à noite. Uma mudança na instrumentação é como ela impede que aconteça de
novo. Pare o experimento e devolva o `prometheus.yml` ao que era:

```sh
docker stop logins
cp /tmp/prometheus.yml.orig prometheus/prometheus.yml
curl -s -X POST localhost:9090/-/reload
```
