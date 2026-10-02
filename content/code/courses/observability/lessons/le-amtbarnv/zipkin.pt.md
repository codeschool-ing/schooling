---
title: O mesmo rastro no Zipkin
version: 1
---

O Zipkin é mais antigo: o Twitter o publicou em 2012, depois do artigo do Google sobre o Dapper, e o
Jaeger emprestou muito do modelo dele. O Collector do laboratório manda todo span para os dois, então o
mesmo checkout pode ser lido na API do Zipkin:

```
ana@obs:~/shop$ curl -s localhost:9411/api/v2/trace/2317d16ea481cf7a0350d6d965f983e9 | jq -r 'sort_by(.timestamp) | .[] | [.localEndpoint.serviceName, .kind // "-", .name, "\(.duration / 1000 | floor) ms"] | @tsv'
storefront	SERVER	post /checkout	439 ms
orders	SERVER	post /orders	436 ms
orders	CLIENT	insert	1 ms
orders	CLIENT	post	404 ms
payments	SERVER	post /charge	401 ms
payments	-	wait for the card network	400 ms
orders	CLIENT	update	1 ms
mailer	CONSUMER	orders.placed process	20 ms
mailer	-	send confirmation	20 ms
```

**Os mesmos nove spans com as mesmas durações**, na grafia do Zipkin: os nomes estão em minúsculas, e
cada span leva o seu tipo. O tipo é como o Zipkin sabe de que lado de uma chamada um span está:
`CLIENT` é o `orders` fazendo a chamada ao payments, `SERVER` é o payments respondendo a ela, e
`CONSUMER` é o mailer tirando uma mensagem. Um span sem tipo, `-` aqui, é trabalho interno, como a
espera que o código do payments abre à mão.

Que os dois armazenamentos concordem é o objetivo de exportar OTLP e deixar o Collector traduzir. **Os
serviços foram escritos uma vez**, e a escolha do armazenamento é uma linha num arquivo de
configuração, e é por isso que o laboratório consegue rodar os dois lado a lado.

A resposta característica do Zipkin é o **grafo de dependências**: a partir de todo rastro de uma janela,
ele conta qual serviço chamou qual, e quantas vezes:

```
ana@obs:~/shop$ curl -sG localhost:9411/api/v2/dependencies --data-urlencode endTs=$(date +%s000) --data-urlencode lookback=300000 | jq -r '.[] | [.parent, .child, .callCount, (.errorCount // 0)] | @tsv'
orders	payments	472	0
storefront	orders	452	0
```

O mapa da loja desenhado só a partir do tráfego: a vitrine chama o orders, o orders chama o payments,
de 450 a 470 vezes em cinco minutos, sem erros. Ninguém o escreveu, então ele não tem como estar
desatualizado, e é o que alguém recém-chegado lê para aprender como um sistema é montado.

**O mailer está faltando**, embora esteja em todo rastro acima. O grafo é construído a partir de pares de
spans de cliente e de servidor, e de spans de produtor e de consumidor que nomeiam o broker entre eles.
O span do mailer não nomeia broker nenhum e o `orders` não registra span de produtor, então a fila não
deixa aresta. Um mapa desenhado a partir de rastros mostra exatamente o que a instrumentação registra,
e uma aresta que falta nele é uma pergunta sobre a instrumentação antes de ser um fato sobre o sistema.
