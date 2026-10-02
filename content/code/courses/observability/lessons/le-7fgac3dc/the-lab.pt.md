---
title: O laboratório em que este curso roda
version: 1
---

Todo comando deste curso foi executado, e toda linha de saída é o que ele imprimiu. **O
laboratório é um computador Linux rodando Docker**: uma pequena loja online, escrita para o curso,
e o software de código aberto que a vigia, cada um no seu contêiner. A usuária é `ana` e o trabalho
acontece em `~/shop`:

```
ana@obs:~/shop$ docker compose ps --format 'table {{.Service}}\t{{.Image}}' | sort
SERVICE             IMAGE
alertmanager        prom/alertmanager:v0.34.1
blackbox-exporter   prom/blackbox-exporter:v0.28.0
grafana             grafana/grafana:13.0.10
jaeger              jaegertracing/jaeger:2.21.0
loki                grafana/loki:3.7.8
mailer              shop:1.4.0
node-exporter       prom/node-exporter:v1.12.1
orders              shop:1.4.0
otel-collector      otel/opentelemetry-collector-contrib:0.161.0
pager               shop:1.4.0
payments            shop:1.4.0
postgres            postgres:16.15
postgres-exporter   prometheuscommunity/postgres-exporter:v0.20.1
prometheus          prom/prometheus:v3.15.0
rabbitmq            rabbitmq:4.2-management
storefront          shop:1.4.0
zipkin              openzipkin/zipkin:3.6.1
```

**A loja é a parte escrita para o curso**, todo contêiner cuja imagem é `shop:1.4.0`. Um checkout
chega ao `storefront`, que pede ao `orders` para guardá-lo. O `orders` pede ao `payments` para
cobrar o cartão e, depois de pago, põe uma mensagem numa fila do RabbitMQ que o `mailer` retira
para mandar a confirmação. O `pager` é onde os alertas chegam na aula 16, e mais dois programas da
mesma imagem só rodam quando chamados: `report`, a tarefa noturna da aula 4, e `loadgen`, que faz
o papel dos clientes. A loja é pequena de propósito, e **tem as formas que sistemas de produção
têm**: HTTP entre serviços, um banco de dados, uma fila e uma tarefa agendada, que são exatamente
os lugares onde sinais se perdem.

::: track networks-infra
Os serviços são escritos em Python, que esta trilha já ensinou. Lê-los é ler um código que você
conhece, e as aulas 2 a 4 os modificam.
:::

::: track data-platform
Os serviços são escritos em Python, que a trilha de dados que esta continua já ensinou. Lê-los é
ler um código que você conhece, e as aulas 2 a 4 os modificam.
:::

::: track software-architecture
Os serviços são escritos em Python, que esta trilha não ensinou, e você não vai precisar escrevê-lo.
Todo trecho de código que este curso mostra traz uma nota dizendo o que faz, e o que você muda nele
é uma ou duas linhas que a aula entrega prontas.
:::

::: track *
Os serviços são escritos em Python. Você precisa conseguir lê-lo, não escrevê-lo. Todo trecho de
código que este curso mostra traz uma nota dizendo o que faz, e o que você muda nele é uma ou duas
linhas que a aula entrega prontas.
:::

Todo o resto é software real, sem modificação, na sua imagem oficial. O OpenTelemetry Collector
recebe rastros e logs e os encaminha. O Prometheus guarda métricas e o Alertmanager roteia os
alertas que ele dispara. O Loki guarda logs, o Jaeger e o Zipkin guardam rastros, e o Grafana
desenha todos eles. Os exporters transformam a máquina, o banco de dados e uma sonda externa em
métricas. As aulas 9, 14 e 19 acrescentam Elasticsearch, Graylog, um cluster Kubernetes e o Envoy,
e dizem quando o fazem.

**Toda porta é publicada só em `127.0.0.1`**, então `localhost:8080` é a loja e `localhost:9090`
é o Prometheus, a partir do shell da `ana` e de nenhum outro lugar.

Para montar o mesmo laboratório você precisa de uma máquina Linux, sendo uma máquina virtual o
mais fácil, com o Docker Engine e o plugin Compose, quatro processadores e 8 GB de memória. O
script que o constrói é o `lab.sh`, publicado com o código-fonte deste curso. Rodar `sudo bash lab.sh up`
escreve `~/shop`, constrói a imagem da loja e sobe tudo, e `sudo bash lab.sh reset` joga tudo fora
e recomeça do zero. As transcrições de toda aula começam de um reset, então **o que você vê na sua
máquina depois de um reset é o que a aula mostra**. As exceções são as partes que mudam a cada execução:
datas, durações no milissegundo e os ids aleatórios que todo rastro recebe.

**Quando algo não responde**, pergunte ao Docker antes de perguntar ao programa: `docker compose ps`
diz se o contêiner está rodando, e `docker compose logs <serviço>` diz o que ele imprimiu ao subir.
