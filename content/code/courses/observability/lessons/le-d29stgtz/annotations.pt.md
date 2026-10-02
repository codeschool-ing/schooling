---
title: Anotações: marcando o que as pessoas fizeram
version: 1
---

Um gráfico mostra o que o sistema fez. **Uma anotação marca o que as pessoas fizeram**: um deploy,
uma mudança de configuração, o começo de um incidente. Sem elas, a primeira pergunta sobre qualquer
calombo em qualquer gráfico é *alguém mudou alguma coisa?*, e a resposta mora num histórico de chat.
O robô da esteira de deploy, com o seu token, marca uma versão do payments:

```
ana@obs:~/shop$ curl -s -H "Authorization: Bearer $(cat .grafana-token)" -H 'Content-Type: application/json' -d '{"dashboardUID": "shop", "tags": ["deploy"], "text": "payments 1.4.1"}' localhost:3000/api/annotations | jq -c .
{"id":1,"message":"Annotation added"}
```

A versão deixa toda cobrança 600 milissegundos mais lenta, o arquivo de falhas do laboratório fazendo
o papel de uma versão ruim. Dois minutos depois ela é revertida, e a reversão também é marcada:

```
ana@obs:~/shop$ curl -s -H "Authorization: Bearer $(cat .grafana-token)" -H 'Content-Type: application/json' -d '{"dashboardUID": "shop", "tags": ["deploy", "rollback"], "text": "payments back to 1.4.0"}' localhost:3000/api/annotations | jq -c .
{"id":2,"message":"Annotation added"}
```

As duas ficam guardadas com hora e tags, e todo painel que desenha anotações `deploy`, como o da
loja, as põe em todo painel. O `jq` imprime os horários em UTC:

```
ana@obs:~/shop$ curl -s -H "Authorization: Bearer $(cat .grafana-token)" 'localhost:3000/api/annotations?tags=deploy' | jq -r '.[] | [(.time/1000 | strftime("%H:%M:%S")), .text, (.tags | join(","))] | @tsv'
10:31:09	payments back to 1.4.0	deploy,rollback
10:29:09	payments 1.4.1	deploy
```

O percentil 99 do checkout nos mesmos minutos foi então pedido ao Prometheus como uma **consulta de
intervalo** (range query), um valor a cada quinze segundos, de dois minutos antes do deploy a quatro
depois:

```sh
curl -sG localhost:9090/api/v1/query_range \
  --data-urlencode 'query=histogram_quantile(0.99, sum by (le) (rate(http_server_request_duration_seconds_bucket{job="storefront",route="/checkout"}[1m])))' \
  --data-urlencode start=$START --data-urlencode end=$END --data-urlencode step=15
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" aria-label=\"O percentil 99 do checkout, a partir da consulta de intervalo do Prometheus que a transcrição imprimiu, um ponto a cada 15 segundos, com as duas anotações desenhadas como linhas verticais. Antes da anotação de deploy, em 0 segundo, a linha fica em 0,05 segundo. Quinze segundos depois, ela salta para 0,98 e fica perto de 0,995. A anotação de rollback está em 120 segundos, mas a linha continua alta até 165 segundos e só cai para 0,05 em 180, porque cada ponto é uma taxa sobre o minuto anterior a ele.\"><defs><marker id=\"ann-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M90 260 L680 260\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M90 260 L90 50\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"82\" y=\"260.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0 s</text><text x=\"82\" y=\"160.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0.5 s</text><text x=\"82\" y=\"60.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1 s</text><text x=\"155.55555555555554\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0 s</text><text x=\"286.66666666666663\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">60 s</text><text x=\"417.77777777777777\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">120 s</text><text x=\"548.8888888888889\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">180 s</text><text x=\"680.0\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">240 s</text><path d=\"M90.0 250.06 L122.77777777777777 250.06 L155.55555555555554 250.06 L188.33333333333331 64.42000000000002 L221.11111111111111 61.76000000000002 L253.88888888888889 61.099999999999994 L286.66666666666663 61.0 L319.44444444444446 61.0 L352.22222222222223 61.0 L385.0 61.0 L417.77777777777777 61.0 L450.5555555555556 61.29999999999998 L483.3333333333333 62.25999999999999 L516.1111111111111 68.91999999999999 L548.8888888888889 250.06 L581.6666666666667 250.02 L614.4444444444445 246.76 L647.2222222222222 246.74 L680.0 246.76\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M155.55555555555554 260 L155.55555555555554 40\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"159.55555555555554\" y=\"34\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">deploy: payments 1.4.1</text><path d=\"M417.77777777777777 260 L417.77777777777777 40\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"421.77777777777777\" y=\"34\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">rollback: de volta a 1.4.0</text><text x=\"385\" y=\"296\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">segundos desde a anotação de deploy</text><text x=\"360\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">p99 do checkout em volta de um deploy e do seu rollback</text></svg>", "caption": "Desenhado com os números acima. As anotações dizem quando alguém agiu; a linha diz quando os usuários sentiram, uma janela depois em cada ponta.", "same": ["deploy: payments 1.4.1"]}
```

**As anotações dizem quando alguém agiu; a linha diz quando os usuários sentiram.** O deploy em 0
segundo aparece na linha quinze segundos depois, no ponto seguinte. O rollback em 120 segundos só
aparece em 180: por um minuto inteiro o painel disse que os checkouts ainda estavam lentos quando já
estavam rápidos de novo. Cada ponto é uma taxa sobre o minuto anterior a ele, e esse minuto ainda
guardava checkouts lentos. Quem reverteu e ficou olhando o painel teria passado esse minuto se
perguntando se o rollback tinha funcionado.

Esse atraso é a janela, e a seção seguinte trata de escolhê-la. A anotação é o que torna o atraso
legível: **com a linha e a marca num painel só, causa e efeito ficam a uma olhada de distância**. A
linha do tempo de um incidente na aula 17 começa exatamente destas marcas.
