---
title: Uma métrica: quantas, e quão lentas
version: 1
---

Todo serviço da loja mantém alguns contadores em memória e os publica em `/metrics`, no formato de
texto que o Prometheus lê. Um deles é um **histograma** de quanto tempo a vitrine levou para
responder, mantido por rota. Estas são as linhas dele para `/checkout`, alguns dos buckets e os
dois totais:

```
ana@obs:~/shop$ curl -s localhost:8080/metrics | grep -E '^http_server_request_duration_seconds_(bucket|count|sum)\{.*route="/checkout"' | grep -E 'le="(0.1|0.5|1.0|2.5|\+Inf)"|_count|_sum'
http_server_request_duration_seconds_bucket{le="0.1",method="POST",route="/checkout"} 2.0
http_server_request_duration_seconds_bucket{le="0.5",method="POST",route="/checkout"} 2.0
http_server_request_duration_seconds_bucket{le="1.0",method="POST",route="/checkout"} 2.0
http_server_request_duration_seconds_bucket{le="2.5",method="POST",route="/checkout"} 111.0
http_server_request_duration_seconds_bucket{le="+Inf",method="POST",route="/checkout"} 111.0
http_server_request_duration_seconds_count{method="POST",route="/checkout"} 111.0
http_server_request_duration_seconds_sum{method="POST",route="/checkout"} 167.5032239500007
```

Cada linha `bucket` conta as requisições que levaram **no máximo** o tempo em `le`, "menor ou
igual". Dois checkouts levaram menos de 0,1 segundo: os dois enviados antes de o payments ficar
lento. Todos os 111 levaram menos de 2,5 segundos, então 109 caíram entre um segundo e dois e meio.
`_count` é quantos foram e `_sum` quantos segundos eles somaram, então a média é 167,50 / 111,
cerca de 1,51 segundo.

Essa é a forma de uma métrica: **um punhado de números que crescem, seja qual for o tráfego.** Mil
checkouts ou um milhão custam as mesmas sete linhas. O Prometheus as lê a cada quinze segundos e
guarda o histórico, que é o que permite responder *quão lentos foram os checkouts nos últimos dois
minutos*:

```
ana@obs:~/shop$ curl -s localhost:9090/api/v1/query --data-urlencode 'query=histogram_quantile(0.99, sum by (le) (rate(http_server_request_duration_seconds_bucket{job="storefront",route="/checkout"}[2m])))' | jq -r '.data.result[0].value[1]'
2.485
```

A consulta pede o percentil 99: o tempo abaixo do qual 99 checkouts em cem terminaram. A resposta,
2,485 segundos, **não é um tempo que alguma requisição levou.** O checkout cronometrado com o `curl` levou
1,54, e todo checkout lento esperou o mesmo segundo e meio no payments. Um histograma só sabe em que bucket uma requisição caiu, então o Prometheus supõe que as 109
requisições entre 1 e 2,5 se espalharam por igual nessa faixa e lê o percentil a partir dessa
suposição. A aula 5 escreve esta consulta passo a passo, e a aula 6 trata de escolher os buckets
para que a suposição custe menos.

Mesmo com esse erro, a métrica cumpriu seu papel: **os checkouts passaram de milissegundos para
segundos**, e um alerta escrito sobre este número teria disparado. O que ela não sabe dizer é por
quê. Os labels são rota e método, então todo checkout parece igual para ela. Nenhuma linha aqui
menciona o payments, e nenhuma consegue apontar para uma requisição em particular. Esse é o
trabalho dos dois sinais seguintes.
