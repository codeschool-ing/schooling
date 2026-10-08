---
title: Pull, alvos, e o que uma coleta lê
version: 2
---

As aulas 2 a 4 fizeram cada serviço **mandar** seus spans ao Collector. O Prometheus funciona ao
contrário, e boa parte do seu desenho decorre disso. **Cada alvo publica seus números atuais num
endereço, e o Prometheus os pede num ritmo fixo.** O pedido se chama coleta (scrape), a cada quinze
segundos neste laboratório, e a lista de endereços vem do `prometheus.yml`. O Prometheus diz o que
está coletando e como foi a última tentativa.

Todo número desta aula precisa de tráfego, então comece de um laboratório iniciado de novo do zero e
ponha os clientes simulados para rodar antes: cinco requisições por segundo durante vinte e cinco
minutos. O `-d` os deixa rodando em segundo plano, e um minuto e quinze segundos depois há o que ler:

```sh
docker compose run -d --rm loadgen python -m loadgen.load 5 1500
```

Depois, os alvos:

```
ana@obs:~/shop$ curl -s localhost:9090/api/v1/targets | jq -r '.data.activeTargets[] | [.labels.job, .labels.instance, .health, .lastScrapeDuration] | @tsv' | sort
blackbox	http://storefront:8080/health	up	0.004616312
mailer	mailer:9102	up	0.003282747
node	node-exporter:9100	up	0.010842373
orders	orders:8081	up	0.004217575
otel-collector	otel-collector:8888	up	0.002619335
payments	payments:8082	up	0.002253304
postgres	postgres-exporter:9187	up	0.037808622
pushgateway	pushgateway:9091	up	0.002478841
rabbitmq	rabbitmq:15692	up	0.021289088
storefront	storefront:8080	up	0.003966553
```

Dez alvos, todos `up`, cada um respondendo em poucos milissegundos. O pull dá duas coisas de graça
ao Prometheus. Ele sabe quando um alvo **para de responder**, e registra isso como uma métrica
própria, `up`, que vale 1 ou 0 para todo alvo a cada coleta. Um serviço que empurra e depois morre
simplesmente fica quieto. E um alvo nunca precisa saber onde o Prometheus está, então um segundo
Prometheus, para testar uma mudança, pode coletar os mesmos alvos sem ninguém reconfigurar os
serviços.

O que ele lê é texto puro. As primeiras linhas da resposta da vitrine, para o seu contador de
requisições:

```
ana@obs:~/shop$ curl -s localhost:8080/metrics | grep -A3 '^# HELP http_server_requests_total'
# HELP http_server_requests_total HTTP requests answered, by route, method and status code.
# TYPE http_server_requests_total counter
http_server_requests_total{code="200",method="GET",route="/health"} 7.0
http_server_requests_total{code="200",method="GET",route="/products"} 38.0
```

Toda métrica vem com uma linha `# HELP`, dizendo o que ela conta, e uma linha `# TYPE`, aqui
`counter`. Depois vem uma linha por **série**: o nome da métrica, um conjunto de labels entre
chaves, e um valor. Os labels são o que transforma um nome em muitas séries, uma por combinação de
`code`, `method` e `route` que a vitrine já viu. O Prometheus acrescenta dois seus na entrada, `job`
e `instance`, a partir da configuração de coleta, e é assim que a mesma métrica vinda de dois
serviços fica separada.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" aria-label=\"Como o Prometheus coleta. O Prometheus, no meio, pede /metrics a cada alvo a cada quinze segundos: os serviços da loja, o Collector, e três exporters, node, postgres e blackbox, que traduzem uma máquina, um banco e uma sonda externa para o mesmo formato. O relatório noturno não pode ser consultado, porque já terminou antes da coleta seguinte, então ele empurra para o Pushgateway, que o Prometheus coleta como qualquer outro alvo. Regras avaliadas dentro do Prometheus mandam alertas ao Alertmanager, que os manda ao pager.\"><defs><marker id=\"pull-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"290\" y=\"110\" width=\"140\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"137.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Prometheus</text><text x=\"360.0\" y=\"153.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">coleta a cada 15 s</text><rect x=\"30\" y=\"30\" width=\"140\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"100.0\" y=\"47.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">storefront</text><path d=\"M288 145 L172 47\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pull-ah)\"></path><rect x=\"30\" y=\"75\" width=\"140\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"100.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">orders</text><path d=\"M288 145 L172 92\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pull-ah)\"></path><rect x=\"30\" y=\"120\" width=\"140\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"100.0\" y=\"137.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">payments</text><path d=\"M288 145 L172 137\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pull-ah)\"></path><rect x=\"30\" y=\"165\" width=\"140\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"100.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">mailer</text><path d=\"M288 145 L172 182\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pull-ah)\"></path><text x=\"100\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a loja: /metrics</text><rect x=\"550\" y=\"30\" width=\"150\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"625.0\" y=\"47.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">node-exporter</text><path d=\"M432 145 L548 47\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pull-ah)\"></path><rect x=\"550\" y=\"80\" width=\"150\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"625.0\" y=\"97.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">postgres-exporter</text><path d=\"M432 145 L548 97\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pull-ah)\"></path><rect x=\"550\" y=\"130\" width=\"150\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"625.0\" y=\"147.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">blackbox-exporter</text><path d=\"M432 145 L548 147\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pull-ah)\"></path><text x=\"625\" y=\"185\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">exporters: traduzem</text><rect x=\"550\" y=\"220\" width=\"150\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"625.0\" y=\"240.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Pushgateway</text><path d=\"M432 160 L548 240\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pull-ah)\"></path><rect x=\"550\" y=\"280\" width=\"150\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"625.0\" y=\"295.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">report</text><path d=\"M625 280 L625 262\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pull-ah)\"></path><text x=\"540\" y=\"296\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">empurra uma vez</text><rect x=\"290\" y=\"230\" width=\"140\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Alertmanager</text><path d=\"M360 182 L360 228\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pull-ah)\"></path><text x=\"372\" y=\"205\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">alertas</text><rect x=\"140\" y=\"255\" width=\"110\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"195.0\" y=\"272.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">pager</text><path d=\"M288 255 L252 268\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pull-ah)\"></path><text x=\"360\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">quem pergunta a quem</text></svg>", "caption": "O Prometheus pergunta; os alvos só respondem. A única exceção, uma tarefa que não vive o bastante para ser perguntada, passa por um gateway que vive.", "same": ["Alertmanager", "Prometheus", "Pushgateway", "blackbox-exporter", "mailer", "node-exporter", "orders", "pager", "payments", "postgres-exporter", "report", "storefront"]}
```
