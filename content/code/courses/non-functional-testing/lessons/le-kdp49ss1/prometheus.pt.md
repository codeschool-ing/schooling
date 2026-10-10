---
title: O Prometheus, e como fazer perguntas a ele
version: 1
---

**O Prometheus coleta métricas pedindo por elas.** A cada poucos segundos ele manda um
`GET /metrics` a cada endereço da sua configuração, uma *coleta* (*scrape*), guarda o que volta como
séries temporais e responde consultas sobre elas em PromQL. A aplicação nunca manda nada para lugar
nenhum; ela só precisa responder quando perguntada, que é o que o `observed.py` agora faz. É a
metade de métricas daquilo que o Grafana desenha na maioria das equipes que usam o Grafana.

## Instalando

Ele vem do repositório do próprio Ubuntu, num comando:

```sh
sudo apt-get install -y prometheus
```

A máquina destas transcrições o tem instalado do mesmo jeito. Confira qual versão você recebeu:

```
ana@nft:~$ prometheus --version | head -1; promtool --version | head -1
prometheus, version 2.45.3+ds (branch: debian/sid, revision: 2.45.3+ds-2ubuntu0.3)
promtool, version 2.45.3+ds (branch: debian/sid, revision: 2.45.3+ds-2ubuntu0.3)
```

**Na sua VM, aquele `apt-get` também o iniciou**, como um serviço em segundo plano lendo
`/etc/prometheus/prometheus.yml`, e instalou e iniciou um segundo programa ao lado dele, o *node
exporter*, que responde na porta 9100 com os números da própria máquina: processadores, memória,
discos, rede. O node exporter é do que o USE precisa, e ele pode continuar rodando. O serviço do
Prometheus ocuparia a porta 9090 e coletaria uma configuração que não é a desta aula, então pare-o,
e impeça que ele suba no boot:

```sh
sudo systemctl disable --now prometheus
```

Essas duas linhas sobre os serviços não foram executadas aqui: a máquina das transcrições não tem
gerenciador de serviços, então o node exporter foi iniciado à mão, como `prometheus-node-exporter`,
que é o que o serviço executa. O seu já está rodando; `curl -s localhost:9100/metrics | head` o
mostra respondendo.

## A configuração

Tudo o que o Prometheus faz vem de um arquivo YAML. Esta aula guarda os arquivos de monitoramento
num diretório próprio:

```sh
mkdir -p ~/monitor && cd ~/monitor
```

Crie o `prometheus.yml` ali:

```yaml
# monitor/prometheus.yml
# What to scrape, and how often. Prometheus reads it once at start-up.
global:
  scrape_interval: 5s
  evaluation_interval: 5s

scrape_configs:
  - job_name: boxoffice
    static_configs:
      - targets: ["127.0.0.1:8000"]
  - job_name: node
    static_configs:
      - targets: ["127.0.0.1:9100"]
```

Dois jobs: a boxoffice na porta 8000 e o node exporter na 9100. **Cinco segundos é um intervalo de
aula**, escolhido para um teste de carga de um minuto dar pontos suficientes para ler; configurações
de produção coletam a cada 15 a 60 segundos, porque cada coleta é uma requisição que a aplicação
tem de responder e cada ponto é algo a guardar.

Suba o Prometheus em primeiro plano, num terceiro terminal, a partir de `~/monitor`:

```sh
cd ~/monitor
prometheus --config.file=prometheus.yml --storage.tsdb.path=data
```

Ele registra muita coisa, uma linha `chave=valor` por evento. As duas que importam são a primeira e
a que diz que ele está pronto:

```
ana@nft:~/monitor$ prometheus --config.file=prometheus.yml --storage.tsdb.path=data
ts=2026-10-10T07:34:52.129Z caller=main.go:563 level=info msg="Starting Prometheus Server" mode=server version="(version=2.45.3+ds, branch=debian/sid, revision=2.45.3+ds-2ubuntu0.3)"
ts=2026-10-10T07:34:52.146Z caller=main.go:989 level=info msg="Server is ready to receive web requests."
```

Os dados vão para `~/monitor/data`. O Prometheus também tem uma interface web em `localhost:9090`;
esta aula faz as perguntas pela API HTTP dele, porque uma resposta no terminal pode ser copiada,
comparada e posta num script.

## Perguntando

A API recebe uma expressão PromQL no parâmetro `query` de `/api/v1/query` e responde com JSON. Um
script curto poupa digitar o `curl` e o `jq` toda vez. Crie o `promql.sh` em `~/monitor`:

```sh
# monitor/promql.sh
# Asks Prometheus one PromQL question; prints one line per series it answers.
curl -s localhost:9090/api/v1/query --data-urlencode "query=$1" |
  jq -r '.data.result[] | "\(.metric | del(.__name__) | tostring)  \(.value[1])"'
```

O `--data-urlencode` cuida das chaves, aspas e espaços de que a PromQL está cheia, que um `?query=`
puro no endereço exigiria escapar à mão. A primeira pergunta é se as coletas estão funcionando. O
`up` é uma série que o próprio Prometheus escreve, 1 para cada alvo que ele alcançou na última
coleta e 0 para cada um que não alcançou:

```
ana@nft:~/monitor$ sh promql.sh up
{"instance":"127.0.0.1:8000","job":"boxoffice"}  1
{"instance":"127.0.0.1:9100","job":"node"}  1
```

**O `up` é o alerta mais barato que existe**, e o que menos informa: um processo pode responder o
`/metrics` perfeitamente enquanto falha em todas as reservas.

## Um pouco de tráfego para olhar

Uma métrica sem ninguém usando o sistema é uma linha reta. Este script, para o k6 que a aula 5
instalou, é um minuto de tráfego comum: dez usuários virtuais, cada um listando os espetáculos,
abrindo um, reservando um assento aleatório três vezes em dez e parando meio segundo. Crie o
`traffic.js` em `~/monitor`:

```javascript
// monitor/traffic.js
// A minute of ordinary traffic: mostly reading, now and then a booking.
import http from 'k6/http';
import { sleep } from 'k6';

export const options = { vus: 10, duration: '60s' };
const BASE = 'http://127.0.0.1:8000';

export default function () {
  const show = 981 + Math.floor(Math.random() * 20);
  http.get(`${BASE}/shows`);
  http.get(`${BASE}/shows/${show}`);
  if (Math.random() < 0.3) {
    const seat = 1 + Math.floor(Math.random() * 300);
    http.post(`${BASE}/bookings`, JSON.stringify({ show_id: show, seat, customer: `k6-${__VU}` }),
      { headers: { 'Content-Type': 'application/json' } });
  }
  sleep(0.5);
}
```

Rode-o no segundo terminal com `k6 run traffic.js` e, enquanto ele roda, faça ao Prometheus as três
perguntas do RED num quarto terminal, ou no segundo depois que o k6 terminar. Estas foram feitas uns
45 segundos depois do início:

```
ana@nft:~/monitor$ sh promql.sh 'sum by (route) (rate(boxoffice_requests_total[1m]))'
{"route":"/shows"}  12.089420833333334
{"route":"/shows/{id}"}  12.079215151515154
{"route":"other"}  0
{"route":"/bookings"}  3.7210931818181816
ana@nft:~/monitor$ sh promql.sh 'sum by (status) (rate(boxoffice_requests_total[1m]))'
{"status":"200"}  24.24826916666667
{"status":"404"}  0
{"status":"201"}  3.053846666666667
{"status":"409"}  0.6788383333333333
ana@nft:~/monitor$ sh promql.sh 'sum(rate(boxoffice_requests_total{status=~"5.."}[1m])) / sum(rate(boxoffice_requests_total[1m]))'
ana@nft:~/monitor$ sh promql.sh '(sum(rate(boxoffice_requests_total{status=~"5.."}[1m])) or vector(0)) / sum(rate(boxoffice_requests_total[1m]))'
{}  0
ana@nft:~/monitor$ sh promql.sh 'histogram_quantile(0.95, sum by (le, route) (rate(boxoffice_request_duration_seconds_bucket{route!="other"}[1m])))'
{"route":"/bookings"}  0.24216133272600035
{"route":"/shows"}  0.006216002317520896
{"route":"/shows/{id}"}  0.058429510856609614
ana@nft:~/monitor$ sh promql.sh '1 - avg(rate(node_cpu_seconds_total{mode="idle"}[1m]))'
{}  0.47410176750000166
```

Leia na ordem.

- **Taxa.** O `rate()` transforma um contador, que só cresce, em quão rápido ele cresceu:
  requisições por segundo, na média do último minuto. O `sum by (route)` soma as séries de cada
  rota. Listar e abrir um espetáculo rodaram a cerca de 12 por segundo cada, porque toda iteração faz
  os dois; reservas a 3,7, perto dos três em dez do script.
- **Erros.** Por status, toda resposta foi 200, 201 ou 409. Os 409 são assentos que outra pessoa já
  tinha, e são a bilheteria funcionando: recusar vender um assento duas vezes é uma funcionalidade.
  Então a razão de erro conta só `5..`, as falhas do próprio servidor. **A primeira resposta é
  resposta nenhuma**: nunca houve um 5xx, então não há série para dividir, e a PromQL devolve um
  resultado vazio em vez de um zero. O `or vector(0)` escreve o zero. Um alerta construído na
  primeira forma simplesmente nunca dispara enquanto a série não existe, o que está certo aqui e
  surpreende da primeira vez.
- **Duração.** O `histogram_quantile(0.95, …)` lê o percentil 95 dos baldes, por rota: 6 ms para
  listar os espetáculos, 58 ms para abrir um, 242 ms para reservar. Reservas são a rota lenta porque
  cada uma espera a sua vez pelo `booking_lock`, que é a saturação de que fala o USE. A figura mais
  abaixo mostra como um percentil sai dos baldes.
- **Utilização.** A última consulta é do USE, do node exporter: a fração do tempo em que os
  processadores não estavam ociosos, 0,47, quase metade. Esta máquina é dividida com o gerador de
  carga, que responde por boa parte disso.

Este é o final do que o k6 imprimiu quando o minuto acabou:

```
ana@nft:~/monitor$ k6 run traffic.js
…
  █ TOTAL RESULTS 

    HTTP
    http_req_duration..............: avg=52.91ms  min=799.32µs med=60.67ms  max=895.7ms p(90)=112.69ms p(95)=139.94ms
      { expected_response:true }...: avg=51.76ms  min=799.32µs med=59.69ms  max=895.7ms p(90)=111.73ms p(95)=139.55ms
    http_req_failed................: 3.00%  67 out of 2233
    http_reqs......................: 2233   36.835368/s

    EXECUTION
    iteration_duration.............: avg=627.35ms min=559.08ms med=579.15ms max=1.66s   p(90)=722.6ms  p(95)=767.75ms
    iterations.....................: 962    15.869066/s
    vus............................: 10     min=10         max=10
    vus_max........................: 10     min=10         max=10

    NETWORK
    data_received..................: 2.1 MB 35 kB/s
    data_sent......................: 202 kB 3.3 kB/s
```

Dois números discordam do Prometheus, e vale conhecer as duas discordâncias. **O k6 diz que o
`http_req_failed` foi de 3,00%**, 67 requisições de 2233, porque o k6 conta todo 4xx como falha; o
log abaixo tem exatamente 67 respostas 409, e o k6 não tem como saber que um 409 é o sistema fazendo
o seu trabalho. Quais status contam como erro é uma decisão que você escreve na consulta, e o alerta
da aula 24 depende dela. E **as durações do k6 são maiores que as do servidor**: uns 40 ms de cada
resposta que o k6 cronometrou são gastos fora da aplicação, e a aula 9 descobre onde. Monitorar de
dentro do servidor mede o servidor; o que o cliente esperou se mede de fora, que é o assunto da
próxima aula.

## Lendo um percentil a partir dos baldes

Quando a execução acabou, os baldes de `/shows/{id}` estavam assim:

```
ana@nft:~/monitor$ curl -s localhost:8000/metrics | grep 'shows/{id}'
boxoffice_requests_total{method="GET",route="/shows/{id}",status="200"} 963
boxoffice_request_duration_seconds_bucket{route="/shows/{id}",le="0.005"} 0
boxoffice_request_duration_seconds_bucket{route="/shows/{id}",le="0.01"} 0
boxoffice_request_duration_seconds_bucket{route="/shows/{id}",le="0.025"} 586
boxoffice_request_duration_seconds_bucket{route="/shows/{id}",le="0.05"} 887
boxoffice_request_duration_seconds_bucket{route="/shows/{id}",le="0.1"} 952
boxoffice_request_duration_seconds_bucket{route="/shows/{id}",le="0.25"} 963
boxoffice_request_duration_seconds_bucket{route="/shows/{id}",le="0.5"} 963
boxoffice_request_duration_seconds_bucket{route="/shows/{id}",le="1.0"} 963
boxoffice_request_duration_seconds_bucket{route="/shows/{id}",le="2.5"} 963
boxoffice_request_duration_seconds_bucket{route="/shows/{id}",le="+Inf"} 963
boxoffice_request_duration_seconds_sum{route="/shows/{id}"} 26.788998
boxoffice_request_duration_seconds_count{route="/shows/{id}"} 963
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" data-fig=\"l22-buckets\" aria-label=\"Seis barras, uma por balde de GET /shows/{id} depois da execução, cada uma da altura do número de requisições que levaram no máximo aquele tempo: 0 abaixo de 5 ms, 0 abaixo de 10 ms, 586 abaixo de 25 ms, 887 abaixo de 50 ms, 952 abaixo de 100 ms e todas as 963 abaixo de 250 ms. Uma linha tracejada em 915, que é 95% de 963, fica abaixo de uma barra pela primeira vez no balde de 100 ms, então o percentil 95 está entre 50 e 100 ms. Supondo que as requisições daquele balde se espalham por igual, a estimativa é de cerca de 71 ms; o balde só sabe que está em algum lugar daqueles 50 ms.\"><path d=\"M70.0 250.0 L666.0 250.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"128.0\" y=\"240.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0</text><text x=\"128.0\" y=\"266.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">le 5 ms</text><text x=\"224.0\" y=\"240.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0</text><text x=\"224.0\" y=\"266.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">le 10 ms</text><rect x=\"286.0\" y=\"128.3\" width=\"68.0\" height=\"121.7\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.1\"></rect><text x=\"320.0\" y=\"118.3\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">586</text><text x=\"320.0\" y=\"266.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">le 25 ms</text><rect x=\"382.0\" y=\"65.8\" width=\"68.0\" height=\"184.2\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.1\"></rect><text x=\"416.0\" y=\"55.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">887</text><text x=\"416.0\" y=\"266.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">le 50 ms</text><rect x=\"478.0\" y=\"52.3\" width=\"68.0\" height=\"197.7\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"512.0\" y=\"42.3\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">952</text><text x=\"512.0\" y=\"266.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">le 100 ms</text><rect x=\"574.0\" y=\"50.0\" width=\"68.0\" height=\"200.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.1\"></rect><text x=\"608.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">963</text><text x=\"608.0\" y=\"266.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">le 250 ms</text><path d=\"M70.0 60.0 L666.0 60.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"66.0\" y=\"60.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">915</text><text x=\"76.0\" y=\"48.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">95% de 963</text><text x=\"360.0\" y=\"20.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">requisições que levaram no máximo isto</text><text x=\"360.0\" y=\"296.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">o percentil 95 está entre 50 e 100 ms; espalhado por igual, cerca de 71 ms</text></svg>", "caption": "Um histograma guarda contagens abaixo de limites, nunca durações. O percentil só pode ser posto dentro de um balde.", "same": ["le 10 ms", "le 100 ms", "le 25 ms", "le 250 ms", "le 5 ms", "le 50 ms"]}
```

A figura lê o percentil 95 da execução inteira a partir dessas contagens. 95% de 963 requisições é a
915ª, e a 915ª cai entre as 887 abaixo de 50 ms e as 952 abaixo de 100 ms, o que a põe em cerca de
71 ms. A consulta durante a execução disse 58 ms porque olhou só o último minuto.

**Um histograma nunca guarda uma duração isolada.** Ele guarda quantas requisições ficaram abaixo
de cada limite, então o percentil 95 só pode ser situado entre dois limites, e o
`histogram_quantile` supõe que as requisições daquele balde se espalham por igual nele. A resposta é
uma estimativa cuja precisão é a largura do balde. Se o requisito é 200 ms, ponha um limite de balde
em 200 ms: aí a pergunta "quantas requisições responderam dentro do requisito" tem uma resposta
exata, diga o que disser a estimativa no meio.

## Buscando no log

O log JSON juntou uma linha por requisição durante toda a execução, e o `jq` busca nele do jeito que
o Kibana busca num índice:

```
ana@nft:~/boxoffice$ wc -l requests.log
2236 requests.log
ana@nft:~/boxoffice$ jq -s -c 'group_by(.status) | map({status: .[0].status, requests: length})' requests.log
[{"status":200,"requests":1925},{"status":201,"requests":243},{"status":404,"requests":1},{"status":409,"requests":67}]
ana@nft:~/boxoffice$ jq -c 'select(.request_id == "ana-test-1")' requests.log
{"ts":"2026-10-10T07:34:51.901+00:00","level":"info","request_id":"ana-test-1","method":"POST","route":"/bookings","path":"/bookings","status":201,"ms":67.6}
```

O primeiro comando conta as linhas. O segundo as agrupa por status, que é a mesma resposta que as
métricas deram, recalculada a partir dos eventos crus: métricas são o que você guarda por meses, e o
log é aonde você volta quando um número precisa de explicação. O terceiro acha uma requisição pelo
id, que é como uma reclamação vira uma linha.
