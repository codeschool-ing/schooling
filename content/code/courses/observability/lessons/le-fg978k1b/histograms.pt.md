---
title: Histogramas, e o que um bucket não sabe dizer
version: 1
---

Durações não cabem num counter nem num gauge: a pergunta não é *quantas* mas *como se espalharam*.
Um **histograma** responde contando cada observação nos buckets sob cujo limite superior ela cabe,
`le` de *less than or equal*, menor ou igual, e todo bucket inclui os de baixo. O histograma de
checkout da vitrine, saudável:

```
ana@obs:~/shop$ curl -s localhost:8080/metrics | grep 'request_duration_seconds_bucket{.*checkout'
http_server_request_duration_seconds_bucket{le="0.005",method="POST",route="/checkout"} 0.0
http_server_request_duration_seconds_bucket{le="0.01",method="POST",route="/checkout"} 0.0
http_server_request_duration_seconds_bucket{le="0.025",method="POST",route="/checkout"} 16.0
http_server_request_duration_seconds_bucket{le="0.05",method="POST",route="/checkout"} 270.0
http_server_request_duration_seconds_bucket{le="0.1",method="POST",route="/checkout"} 271.0
http_server_request_duration_seconds_bucket{le="0.25",method="POST",route="/checkout"} 271.0
http_server_request_duration_seconds_bucket{le="0.5",method="POST",route="/checkout"} 271.0
http_server_request_duration_seconds_bucket{le="1.0",method="POST",route="/checkout"} 271.0
http_server_request_duration_seconds_bucket{le="2.5",method="POST",route="/checkout"} 271.0
http_server_request_duration_seconds_bucket{le="5.0",method="POST",route="/checkout"} 271.0
http_server_request_duration_seconds_bucket{le="+Inf",method="POST",route="/checkout"} 271.0
```

Lidos por subtração, os buckets dizem: 16 checkouts levaram entre 10 e 25 milissegundos, 254 entre
25 e 50, um entre 50 e 100, e nada mais lento.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Os 271 checkouts da captura saudável, por bucket. Cada barra é o número de requisições que caiu entre o limite anterior e este: nenhuma até 0,01 segundo, 16 entre 0,01 e 0,025, 254 entre 0,025 e 0,05, 1 entre 0,05 e 0,1, e nenhuma acima. Dentro de um bucket o histograma não sabe nada, então o percentil 99 é posto perto do topo do bucket de 0,025 a 0,05 supondo que as 254 se espalham por igual.\"><defs><marker id=\"bk-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"110.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">0</text><text x=\"110.0\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0.005</text><text x=\"170.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">0</text><text x=\"170.0\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0.01</text><rect x=\"206\" y=\"228.66141732283464\" width=\"48\" height=\"11.338582677165354\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"230.0\" y=\"218.66141732283464\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">16</text><text x=\"230.0\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0.025</text><rect x=\"266\" y=\"60.0\" width=\"48\" height=\"180.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"290.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">254</text><text x=\"290.0\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0.05</text><rect x=\"326\" y=\"239.29133858267716\" width=\"48\" height=\"0.7086614173228346\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"350.0\" y=\"229.29133858267716\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">1</text><text x=\"350.0\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0.1</text><text x=\"410.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">0</text><text x=\"410.0\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0.25</text><text x=\"470.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">0</text><text x=\"470.0\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0.5</text><text x=\"530.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">0</text><text x=\"530.0\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1</text><text x=\"590.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">0</text><text x=\"590.0\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">2.5</text><text x=\"650.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">0</text><text x=\"650.0\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">5</text><path d=\"M80 240 L680 240\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"360\" y=\"282\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">limite superior do bucket, segundos</text><text x=\"360\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">271 checkouts, contados por bucket</text></svg>", "caption": "O que o histograma da vitrine de fato guarda: uma contagem por bucket, lida das linhas cumulativas por subtração. Tudo o que for mais fino que um bucket é suposição."}
```

O `histogram_quantile()` transforma essas contagens num percentil, como a aula 1 fez:

```
ana@obs:~/shop$ ./promq 'histogram_quantile(0.5, sum by (le) (rate(http_server_request_duration_seconds_bucket{job="storefront",route="/checkout"}[1m])))'
  0.03683862433862434
ana@obs:~/shop$ ./promq 'histogram_quantile(0.99, sum by (le) (rate(http_server_request_duration_seconds_bucket{job="storefront",route="/checkout"}[1m])))'
  0.049866402116402114
```

Uma mediana de 37 milissegundos e um percentil 99 de 50, os dois dentro do bucket onde caiu a maior
parte dos checkouts. **Os dois são interpolados**: o histograma sabe que 254 requisições caíram entre
25 e 50 milissegundos, e o Prometheus supõe que se espalharam por igual nessa faixa. Agora o payments
fica 300 milissegundos mais lento, e todo checkout leva um pouco mais de um terço de segundo:

```
ana@obs:~/shop$ echo '{"latency_ms": 300}' > faults/payments.json
ana@obs:~/shop$ ./promq 'histogram_quantile(0.5, sum by (le) (rate(http_server_request_duration_seconds_bucket{job="storefront",route="/checkout"}[1m])))'
  0.375
ana@obs:~/shop$ ./promq 'histogram_quantile(0.99, sum by (le) (rate(http_server_request_duration_seconds_bucket{job="storefront",route="/checkout"}[1m])))'
  0.4975
```

**0,375 e 0,4975**: o meio e quase o topo do bucket entre 0,25 e 0,5, porque esse bucket agora guarda
todos os checkouts e não há nada mais fino para ler. Os checkouts reais levaram todos mais ou menos o
mesmo tempo; uma mediana de 375 milissegundos é o ponto médio do bucket, não uma medida. Os 2,485
segundos da aula 1 eram o mesmo efeito num bucket mais largo.

Duas consequências decidem como histogramas são usados. **Escolha buckets em volta dos valores que
importam**: se a meta é *checkouts abaixo de 300 milissegundos*, um limite de bucket em 0,3 torna
essa pergunta exata, e nenhuma interpolação o substitui. E **faça a pergunta que um histograma
responde com exatidão**, que não é um percentil mas uma fração abaixo de um limite:

```
ana@obs:~/shop$ ./promq 'sum(rate(http_server_request_duration_seconds_bucket{job="storefront",route="/checkout",le="0.5"}[1m])) / sum(rate(http_server_request_duration_seconds_count{job="storefront",route="/checkout"}[1m]))'
  1
```

*Que fração dos checkouts terminou em meio segundo?* Todos, 1, sem interpolação nenhuma, porque 0,5 é
um limite de bucket. A aula 15 constrói o objetivo de latência da loja sobre essa forma. O arquivo de
falhas foi removido depois destas consultas.
