---
title: Escolhendo uma das três
version: 1
---

A escolha costuma ser posta como "REST é o produto completo, HTTP é a barata", o que faz a REST
parecer o padrão seguro. **O padrão mais seguro é a HTTP API, e uma REST API é escolhida por um
recurso com nome que só ela tem.** Se ninguém no time consegue dizer qual é o recurso, a API está
pagando 4,25 em vez de 1,59 por milhão de requisições por nada. Uma WebSocket API é outra pergunta:
se o servidor precisa falar primeiro.

## O que cada uma tem

As linhas são as que decidem uma escolha, tiradas da própria comparação da AWS entre as duas APIs
de requisição. Um travessão quer dizer que a API não oferece aquilo.

| | REST API | HTTP API |
|---|---|---|
| preço por milhão de requisições, primeira faixa (16 de outubro de 2026) | 4,25 | 1,59 |
| implantação | à mão, num stage com nome | sozinha, com `$default` |
| autorizador JWT embutido | — | sim |
| autorizadores IAM e Lambda | sim | sim |
| chaves de API e usage plans por cliente | sim | — |
| cache de respostas | sim | — |
| mapping templates e validação de requisição | sim | — |
| AWS WAF na frente | sim | — |
| endpoint privado, acessível só de uma VPC | sim | — |

Três linhas mandam a maioria dos times para a REST: **um usage plan por cliente**, para uma API
vendida a parceiros com uma cota para cada um; **o AWS WAF**, para regras contra tráfego abusivo na
frente de uma API pública; e um **endpoint privado**, para uma API que não pode ter endereço
público nenhum. O cache é a quarta, e a próxima parte desta seção diz quanto custa experimentá-lo.
Se nenhuma das quatro se aplica, uma HTTP API resolve.

## Limites de taxa, que toda API tem

**Os três tipos dividem um limite por conta e por região**: na AWS, por padrão, 10.000 requisições
por segundo em regime constante, com picos de até 5.000 requisições absorvidos de uma vez. Esse
limite é da conta, então um teste de carga contra uma API pode limitar todas as outras APIs em São
Paulo. Abaixo dele você pode definir limites menores num stage ou numa rota, e uma REST API
acrescenta os limites por cliente dos usage plans. Uma requisição acima de qualquer limite recebe
`429 Too Many Requests` e a integração nunca a vê. O que o cliente faz em seguida é a mesma
pergunta que a aula 16 fez sobre a limitação do próprio Lambda: tentar de novo com espera
crescente, ou falhar.

O moto guarda os ajustes e não conta nada, então nenhuma requisição aqui foi limitada.

## Um timeout, e para onde vai o trabalho longo

Uma integração precisa responder rápido. **Uma REST API espera 29 segundos por padrão e uma HTTP
API no máximo 30**; passado isso o cliente recebe um `504`, mesmo que a função ainda esteja
trabalhando e termine um minuto depois. Desde 2024, uma REST API regional ou privada pode pedir à
AWS uma espera maior por aumento de cota, ao custo de menos requisições por segundo para a conta.
Nenhum dos dois números é do moto: ele nunca chama a integração.

Então uma requisição que inicia um trabalho de minutos não deve esperar o trabalho. A API recebe a
requisição, entrega o trabalho a algo que o roda, e responde `202 Accepted` com um id que o cliente
pode consultar depois. A aula 20 constrói esse algo com Step Functions, e a aula 21 a fila na frente
dele.

## O cache, que só a REST tem

Um stage REST pode guardar respostas num cache próprio por um tempo de vida que você escolhe, 300
segundos por padrão, para que `GET`s repetidos nunca cheguem à integração. Ele é ligado por stage,
com um tamanho:

```
ana@laptop:~/aws$ aws apigateway update-stage --rest-api-id "$API" --stage-name prod --patch-operations op=replace,path=/cacheClusterEnabled,value=true op=replace,path=/cacheClusterSize,value=0.5 --query "{cacheClusterEnabled: cacheClusterEnabled, cacheClusterSize: cacheClusterSize, cacheClusterStatus: cacheClusterStatus}"
{
    "cacheClusterEnabled": true,
    "cacheClusterSize": "0.5",
    "cacheClusterStatus": "AVAILABLE"
}
```

O moto diz `AVAILABLE` na hora. **A AWS documenta cerca de quatro minutos para criar um cache**,
durante os quais o status é `CREATE_IN_PROGRESS`, e os tamanhos vão de 0,5 GB a 237 GB. Um cache é
cobrado por hora enquanto existir, haja acerto ou não, e o preço dele não está na tabela deste
curso: consulte a página de preços do API Gateway antes de ligar um. Um cache na frente de uma
função que responde em 50 ms economiza algumas invocações e pouco tempo; na frente de um banco de
dados lento ele economiza segundos a cada acerto, e é aí que ele paga o preço por hora.

## WebSocket, ou não

A pergunta para uma WebSocket API não é sobre recursos. **O servidor precisa contar ao cliente, em
segundos, algo que o cliente não perguntou?** Um status de pedido ao vivo, um chat, um painel de
preços: sim. Um formulário que salva e uma página que carrega: não, e uma HTTP API é mais simples
de montar, de testar com `curl` e de pôr em cache num navegador. A conta da seção anterior é a
outra metade da decisão: um WebSocket paga por mensagem e por minuto, o polling paga por
requisição, e qual sai mais barato depende de quantas vezes há novidade.
