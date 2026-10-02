---
title: Seguindo um erro até onde ele começou
version: 1
---

Uma requisição que falha raramente falha num span só. **O erro começa num lugar e todo chamador
acima dele relata uma falha própria.** Então o rastro de uma falha é uma coluna de vermelho, e o
trabalho é achar o fundo dela.

Durante um minuto, uma em cada dez cobranças falha, como o arquivo de falhas manda o payments do
laboratório fazer. Depois o Zipkin é consultado pelos rastros dos últimos dois minutos em que o payments
leva um erro:

```
ana@obs:~/shop$ curl -sG localhost:9411/api/v2/traces --data-urlencode serviceName=payments --data-urlencode annotationQuery=error --data-urlencode lookback=120000 --data-urlencode limit=3 | jq -r '.[] | .[] | select(.tags.error) | [.traceId, .localEndpoint.serviceName, .name, .tags.error] | @tsv'
70a7acd463caea04147d020de13d469b	payments	post /charge	true
70a7acd463caea04147d020de13d469b	orders	post	true
70a7acd463caea04147d020de13d469b	orders	post /orders	true
70a7acd463caea04147d020de13d469b	storefront	post /checkout	true
71f1310c041b565a43af2c6e8cc17d74	payments	post /charge	true
71f1310c041b565a43af2c6e8cc17d74	orders	post	true
71f1310c041b565a43af2c6e8cc17d74	orders	post /orders	true
71f1310c041b565a43af2c6e8cc17d74	storefront	post /checkout	true
ae566ae9a7ae0a72437884091daea92c	payments	post /charge	true
ae566ae9a7ae0a72437884091daea92c	orders	post	true
ae566ae9a7ae0a72437884091daea92c	orders	post /orders	true
ae566ae9a7ae0a72437884091daea92c	storefront	post /checkout	true
```

Três checkouts que falharam, e **quatro spans marcados como erro em cada um**. Leia-os pela
profundidade, e não pela ordem em que aparecem:

| span | por que está vermelho |
|---|---|
| `post /charge` do payments | ele definiu o status de erro: *card network unavailable*, e respondeu 503 |
| `post` do orders | o lado cliente dessa chamada, que recebeu o 503 |
| `post /orders` do orders | ele desistiu do pedido e respondeu com um erro próprio |
| `post /checkout` da vitrine | ele recebeu esse erro e o passou ao cliente |

**A origem é o span de erro mais profundo sem filho com erro**, aqui o `POST /charge` do payments.
Todo span acima dele está correto e nenhum deles é a causa. Na interface do Jaeger a mesma busca é a
tag `error=true`, e a visão do rastro desenha um ícone em todo span que falhou. O de baixo é por
onde começar a ler, e os atributos e as linhas de log dele são onde está o motivo.

Dois cuidados:

- **Um span vermelho é um span que alguém marcou de vermelho.** A vitrine, o orders e o payments definem
  um status de erro na falha porque a instrumentação deles faz isso: a instrumentação automática do
  Flask marca todo 5xx no `orders`, e os spans escritos à mão da vitrine e do payments definem o status
  explicitamente. Um serviço que captura uma exceção e devolve 200 não deixa vermelho em lugar nenhum.
- **O erro pode estar fora do rastro.** O span do payments nomeia uma rede de cartões que ele não
  alcança, e a rede de cartões não é instrumentada por ninguém aqui. O span vermelho mais profundo é o
  lugar mais profundo que *você* consegue ver, e a falha pode estar um passo além dele.
