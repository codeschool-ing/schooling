---
title: O disjuntor
version: 1
---

Um timeout limita quanto uma chamada pode desperdiçar. Quando o payments fica fora por minutos, toda
venda ainda gasta o segundo inteiro para descobrir isso, segura uma vaga enquanto isso, e acrescenta
mais um pedido a um serviço que já está falhando. **Um disjuntor** (*circuit breaker*) **para de
chamar.** Depois de falhas suficientes seguidas ele abre, e por um tempo toda chamada falha na hora,
sem ser feita.

O nome vem do disjuntor elétrico, e os estados também: **fechado** quer dizer que a corrente passa e
as chamadas seguem; **aberto** quer dizer que não.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"Três estados de um disjuntor. Fechado, em que as chamadas passam: cinco falhas seguidas o levam a aberto. Aberto, em que toda chamada falha na hora: depois da espera de dez segundos ele vai para meio aberto. Meio aberto, em que uma chamada de teste passa: se ela der certo o disjuntor volta a fechado, se falhar volta a aberto.\"><rect x=\"40\" y=\"40\" width=\"180\" height=\"50\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"130\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">fechado</text><text x=\"130\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">as chamadas passam</text><rect x=\"500\" y=\"40\" width=\"180\" height=\"50\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"590\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">aberto</text><text x=\"590\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">falham na hora</text><rect x=\"270\" y=\"130\" width=\"180\" height=\"50\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">meio aberto</text><text x=\"360\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">uma chamada de teste</text><path d=\"M220 55 L498 55\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M498 55 L491.7 58.0 L491.7 52.0 Z\" fill=\"var(--amber)\" stroke=\"none\"></path><text x=\"360\" y=\"45\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">5 falhas seguidas</text><path d=\"M525 90 L454 136\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M454 136 L457.6 130.0 L460.9 135.1 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><text x=\"470\" y=\"108\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">depois de 10 s</text><path d=\"M452 168 L636 93\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M636 93 L631.3 98.2 L629.0 92.6 Z\" fill=\"var(--amber)\" stroke=\"none\"></path><text x=\"560\" y=\"155\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">teste falha</text><path d=\"M268 145 L160 93\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M160 93 L167.0 93.0 L164.4 98.5 Z\" fill=\"var(--phosphor)\" stroke=\"none\"></path><text x=\"200\" y=\"140\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">teste dá certo</text></svg>", "caption": "Fechado, aberto, meio aberto: o disjuntor volta testando."}
```

O disjuntor da bilheteria abre depois de cinco falhas seguidas e fica aberto por dez segundos. O
payments ainda leva cinco segundos por cobrança; mais oito vendas, cada uma de um comprador diferente
para o limite de taxa não atrapalhar:

```
ana@lab:~/tickets$ for i in $(seq 2 9); do curl -s -w ' %{http_code} in %{time_total} s\n' -X POST -H "X-Buyer: fan-$i" localhost:8080/events/1/tickets; done
{"error": "payment failed"} 502 in 1.006585 s
{"error": "payment failed"} 502 in 1.005113 s
{"error": "payment failed"} 502 in 1.005369 s
{"error": "payment failed"} 502 in 1.005703 s
{"error": "payments unavailable"} 503 in 0.001858 s
{"error": "payments unavailable"} 503 in 0.001599 s
{"error": "payments unavailable"} 503 in 0.001738 s
{"error": "payments unavailable"} 503 in 0.001636 s
ana@lab:~/tickets$ curl -s localhost:8080/metrics | grep ^tickets_breaker
tickets_breaker_open 1.0
```

**Quatro vendas falharam depois de um segundo inteiro cada**: com a venda da seção 07, são cinco
falhas seguidas, e o disjuntor abriu. **As quatro seguintes falharam em menos de 2 ms**, com um `503`
que diz que o payments está indisponível, e sem tocar no payments. O medidor diz que o disjuntor está
aberto, que é o que um painel ou um alerta leria.

O que isso comprou, para a bilheteria: uma venda que não tem como dar certo não segura mais uma vaga
por um segundo, então as leituras e todo o resto mantêm a sua capacidade. Para o payments: nenhuma
chamada nova enquanto ele sofre, que muitas vezes é a diferença entre um serviço que se recupera e um
que é mantido no chão pelo tráfego de quem fica tentando de novo. E para o comprador: uma resposta em
milissegundos em vez de um indicador de carregamento, que a seção 10 e a aula 11 transformam em algo
mais útil que um erro.

## O que conta como falha

Só o que diz que a dependência não está saudável: um timeout, uma conexão recusada, um `5xx`. Um
cartão recusado é o serviço de pagamento funcionando direito, e um disjuntor que contasse isso
abriria numa noite movimentada de cartões vencidos. O disjuntor da bilheteria conta qualquer exceção
do `charge`, que aqui quer dizer um erro de rede ou um timeout; um de verdade olharia também o código
de status.
