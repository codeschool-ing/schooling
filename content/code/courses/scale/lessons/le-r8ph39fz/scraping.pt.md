---
title: O Prometheus recolhe, perguntando
version: 1
---

O Prometheus **puxa** (*pull*). Ele não espera que os programas mandem números; a cada poucos
segundos pergunta a cada programa pela página `/metrics`, um pedido chamado **coleta** (*scrape*), e
guarda o que leu com a hora. Um programa só precisa responder essa página, e o Prometheus decide com
que frequência e a quem perguntar.

A configuração dele, salva como `prometheus.yml`, diz o que coletar:

```yaml
# prometheus.yml
global:
  scrape_interval: 5s

scrape_configs:
  - job_name: tickets
    dns_sd_configs:
      - names: [app]
        type: A
        port: 8000
        refresh_interval: 5s
```

`scrape_interval: 5s` é a frequência. A tarefa de coleta se chama `tickets`, e os alvos dela vêm do
**DNS**: todo endereço que o servidor de nomes do Docker dá para o nome `app`, na porta 8000,
consultado de novo a cada cinco segundos. Isso importa porque a bilheteria roda em várias cópias, e
o Prometheus precisa perguntar **a cada cópia** pelos números dela.

## Subindo

A imagem é reconstruída com a biblioteca nova, e a pilha sobe com uma cópia da bilheteria:

```
ana@lab:~/tickets$ docker compose build -q
 Image tickets-app Building 
 Image tickets-app Built 
ana@lab:~/tickets$ docker compose up -d
 Network tickets_default Creating 
 Network tickets_default Creating 
 Network tickets_replication Creating 
 Network tickets_replication Creating 
 Network tickets_default Created 
 Network tickets_default Created 
 Container tickets-prometheus-1 Creating 
 Network tickets_replication Created 
 Network tickets_replication Created 
 Container tickets-db-1 Creating 
 Container tickets-prometheus-1 Created 
 Container tickets-db-1 Created 
 Container tickets-replica-1 Creating 
 Container tickets-replica-1 Created 
 Container tickets-app-1 Creating 
 Container tickets-app-1 Created 
 Container tickets-lb-1 Creating 
 Container tickets-lb-1 Created 
 Container tickets-prometheus-1 Starting 
 Container tickets-db-1 Starting 
 Container tickets-prometheus-1 Started 
 Container tickets-db-1 Started 
 Container tickets-db-1 Waiting 
 Container tickets-db-1 Healthy 
 Container tickets-replica-1 Starting 
 Container tickets-replica-1 Started 
 Container tickets-db-1 Waiting 
 Container tickets-replica-1 Waiting 
 Container tickets-db-1 Healthy 
 Container tickets-replica-1 Healthy 
 Container tickets-app-1 Starting 
 Container tickets-app-1 Started 
 Container tickets-lb-1 Starting 
 Container tickets-lb-1 Started 
```

Uma leitura e uma venda, depois a página de métricas, filtrada para as linhas da própria bilheteria:

```
ana@lab:~/tickets$ curl -s localhost:8080/events/1 >/dev/null; curl -s -X POST localhost:8080/events/1/tickets >/dev/null
ana@lab:~/tickets$ curl -s localhost:8080/metrics | grep '^tickets_'
tickets_requests_total{method="GET",route="/events/{id}",status="200"} 1.0
tickets_requests_total{method="POST",route="/events/{id}/tickets",status="201"} 1.0
tickets_request_seconds_bucket{le="0.005",method="GET",route="/events/{id}"} 0.0
tickets_request_seconds_bucket{le="0.01",method="GET",route="/events/{id}"} 0.0
tickets_request_seconds_bucket{le="0.025",method="GET",route="/events/{id}"} 1.0
tickets_request_seconds_bucket{le="0.05",method="GET",route="/events/{id}"} 1.0
tickets_request_seconds_bucket{le="0.1",method="GET",route="/events/{id}"} 1.0
tickets_request_seconds_bucket{le="0.25",method="GET",route="/events/{id}"} 1.0
tickets_request_seconds_bucket{le="0.5",method="GET",route="/events/{id}"} 1.0
tickets_request_seconds_bucket{le="1.0",method="GET",route="/events/{id}"} 1.0
tickets_request_seconds_bucket{le="2.5",method="GET",route="/events/{id}"} 1.0
tickets_request_seconds_bucket{le="5.0",method="GET",route="/events/{id}"} 1.0
tickets_request_seconds_bucket{le="+Inf",method="GET",route="/events/{id}"} 1.0
tickets_request_seconds_count{method="GET",route="/events/{id}"} 1.0
tickets_request_seconds_sum{method="GET",route="/events/{id}"} 0.016301100000418955
tickets_request_seconds_bucket{le="0.005",method="POST",route="/events/{id}/tickets"} 0.0
tickets_request_seconds_bucket{le="0.01",method="POST",route="/events/{id}/tickets"} 0.0
tickets_request_seconds_bucket{le="0.025",method="POST",route="/events/{id}/tickets"} 1.0
tickets_request_seconds_bucket{le="0.05",method="POST",route="/events/{id}/tickets"} 1.0
tickets_request_seconds_bucket{le="0.1",method="POST",route="/events/{id}/tickets"} 1.0
tickets_request_seconds_bucket{le="0.25",method="POST",route="/events/{id}/tickets"} 1.0
tickets_request_seconds_bucket{le="0.5",method="POST",route="/events/{id}/tickets"} 1.0
tickets_request_seconds_bucket{le="1.0",method="POST",route="/events/{id}/tickets"} 1.0
tickets_request_seconds_bucket{le="2.5",method="POST",route="/events/{id}/tickets"} 1.0
tickets_request_seconds_bucket{le="5.0",method="POST",route="/events/{id}/tickets"} 1.0
tickets_request_seconds_bucket{le="+Inf",method="POST",route="/events/{id}/tickets"} 1.0
tickets_request_seconds_count{method="POST",route="/events/{id}/tickets"} 1.0
tickets_request_seconds_sum{method="POST",route="/events/{id}/tickets"} 0.02141379299973778
tickets_in_flight 1.0
```

O contador diz que um `GET` respondeu 200 e um `POST` respondeu 201. O histograma tem uma linha por
faixa, cada uma contando os pedidos que levaram **até** aquele número de segundos, então as contagens
só crescem de cima para baixo: a leitura levou mais de 10 ms e menos de 25, e a venda também. `_count`
e `_sum` são o número de observações e o total delas, 16 ms para a leitura e 24 ms para a venda.
`tickets_in_flight` é 1: o pedido que pedia a página estava ele mesmo em andamento.

## Três cópias, três alvos

Agora três cópias, e o nginx reiniciado para vê-las, como na aula 1:

```
ana@lab:~/tickets$ docker compose up -d --scale app=3
 Container tickets-replica-1 Running 
 Container tickets-app-1 Running 
 Container tickets-prometheus-1 Running 
 Container tickets-lb-1 Running 
 Container tickets-db-1 Running 
 Container tickets-app-2 Creating 
 Container tickets-app-3 Creating 
 Container tickets-app-2 Created 
 Container tickets-app-3 Created 
 Container tickets-db-1 Waiting 
 Container tickets-db-1 Healthy 
 Container tickets-db-1 Waiting 
 Container tickets-replica-1 Waiting 
 Container tickets-replica-1 Healthy 
 Container tickets-db-1 Healthy 
 Container tickets-app-3 Starting 
 Container tickets-app-3 Started 
 Container tickets-app-2 Starting 
 Container tickets-app-2 Started 
ana@lab:~/tickets$ docker compose restart lb
 Container tickets-lb-1 Restarting 
 Container tickets-lb-1 Started 
```

Alguns segundos depois, o Prometheus as encontrou. `up` é uma série que o Prometheus escreve para
todo alvo, 1 se a última coleta funcionou e 0 se não. O `promtool`, dentro da imagem do Prometheus,
manda uma consulta e imprime a resposta:

```
ana@lab:~/tickets$ docker compose exec prometheus promtool query instant http://localhost:9090 'up'
up{instance="172.18.0.5:8000", job="tickets"} => 1 @[1791612577.701]
up{instance="172.18.0.7:8000", job="tickets"} => 1 @[1791612577.701]
up{instance="172.18.0.8:8000", job="tickets"} => 1 @[1791612577.701]
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"O Prometheus à esquerda pergunta ao DNS do Docker os endereços de app, recebe três, e a cada cinco segundos manda GET /metrics a cada cópia diretamente. O nginx, que espalha os pedidos dos usuários, não está no caminho das coletas.\"><rect x=\"20\" y=\"85\" width=\"140\" height=\"60\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"90\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">Prometheus</text><text x=\"90\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a cada 5 s</text><rect x=\"20\" y=\"175\" width=\"140\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"90\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">DNS: app → 3 endereços</text><path d=\"M90 145 L90 175\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 3\"></path><rect x=\"330\" y=\"30\" width=\"150\" height=\"44\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"405\" y=\"45\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">tickets-app-1</text><text x=\"405\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">/metrics</text><path d=\"M160 115 L328 52\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M328 52 L323.2 57.1 L321.0 51.4 Z\" fill=\"var(--amber)\" stroke=\"none\"></path><rect x=\"330\" y=\"100\" width=\"150\" height=\"44\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"405\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">tickets-app-2</text><text x=\"405\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">/metrics</text><path d=\"M160 115 L328 122\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M328 122 L321.6 124.8 L321.8 118.7 Z\" fill=\"var(--amber)\" stroke=\"none\"></path><rect x=\"330\" y=\"170\" width=\"150\" height=\"44\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"405\" y=\"185\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">tickets-app-3</text><text x=\"405\" y=\"202\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">/metrics</text><path d=\"M160 115 L328 192\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M328 192 L321.0 192.1 L323.5 186.6 Z\" fill=\"var(--amber)\" stroke=\"none\"></path><rect x=\"600\" y=\"92\" width=\"100\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"650\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">lb (nginx)</text><path d=\"M600 114 L482 52\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M600 114 L482 122\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M600 114 L482 192\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"650\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">pedidos dos usuários</text></svg>", "caption": "O Prometheus acha toda cópia pelo nome e coleta de cada uma; os usuários passam pelo nginx.", "same": ["Prometheus"]}
```

Três alvos, um por cópia, cada um coletado diretamente no próprio endereço e não pelo nginx.
**Perguntar pelo balanceador teria respondido com os números de uma cópia**, uma diferente a cada
vez, o que é inútil para um contador. Esse é o motivo de um sistema que puxa precisar de
**descoberta de serviços**, um jeito de conhecer o endereço de toda cópia, e o motivo de o `up` ser a
primeira coisa a alertar: uma cópia que para de responder às coletas é uma cópia cujos números
saíram em silêncio de todo gráfico.
