---
title: O circuit breaker
version: 1
---

Um retry supõe que a próxima chamada pode funcionar. Quando as últimas várias chamadas a um serviço
falharam todas, essa suposição provavelmente está errada, e cada chamada a mais é carga sobre um serviço
que já está se afogando. Um **circuit breaker** age sobre isso: depois de falhas suficientes em
sequência ele **abre**, e por um tempo toda chamada falha na hora, sem ser enviada. Depois ele deixa
passar uma única chamada, **meio aberto**, para ver se o serviço voltou; se voltou, o breaker **fecha** e
o tráfego volta a fluir. Michael Nygard deu nome ao padrão em *Release It!*, em 2007, por causa do
disjuntor elétrico, que corta um circuito antes de a fiação pegar fogo.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Os três estados de um circuit breaker. Fechado: as chamadas passam, as falhas são contadas. Depois de cinco falhas seguidas ele vai para aberto: as chamadas falham na hora sem chegar ao serviço. Depois de dois segundos ele vai para meio aberto: uma chamada passa. Se ela der certo o breaker volta para fechado; se falhar, volta para aberto.\"><defs><marker id=\"l11-breaker-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l11-breaker-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l11-breaker-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"240\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"30\" y=\"40\" width=\"180\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"120\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">fechado</text><text x=\"120\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">chamadas passam</text><rect x=\"510\" y=\"40\" width=\"180\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"600\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\" font-weight=\"600\">aberto</text><text x=\"600\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">chamadas falham na hora</text><rect x=\"270\" y=\"160\" width=\"180\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"184\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">meio aberto</text><text x=\"360\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">uma chamada passa</text><path d=\"M212 60 L508 60\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l11-breaker-ah-amber)\"></path><text x=\"360\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">5 falhas seguidas</text><path d=\"M600 112 L600 195 L452 195\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l11-breaker-ah-paper-dim)\"></path><text x=\"612\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">após 2 s</text><path d=\"M268 195 L120 195 L120 112\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l11-breaker-ah-phosphor)\"></path><text x=\"195\" y=\"185\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">deu certo</text><path d=\"M400 158 L540 112\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l11-breaker-ah-amber)\"></path><text x=\"505\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">falhou</text></svg>", "caption": "Um circuit breaker para de chamar um serviço que está claramente falhando, e confere de vez em quando, com uma única chamada, se ele voltou."}
```

O breaker do cliente abre depois de cinco falhas seguidas e fica aberto por dois segundos. O mesmo
congelamento, com os mesmos três retries e jitter, e o breaker ligado:

```
ana@vm:~/lab/resilience$ $C --freeze-at 6 --retries 3 --backoff jitter --breaker
 second      ok  failed   calls
  0-2       120       0     120
  2-4       120       0     120
  4-6       120       0     120
  6-8         3     117      40
  8-10       49      71      49
 10-12      120       0     120
 12-14      120       0     120
 14-16      120       0     120
 16-18      120       0     120
 18-20      120       0     120
 20-22      120       0     120
 22-24      120       0     120
 24-26      120       0     120
 26-28      120       0     120
 28-30      120       0     120
the stock service answered 1649 calls, 37 of them after the caller had given up
```

**Recuperado no segundo 10**, um segundo depois de o congelamento acabar, e seis segundos antes do que sem
retry nenhum. Olhe a coluna de chamadas durante o congelamento: 40 e 49 chamadas em janelas de dois
segundos em que os retries simples mandaram 470. Com o breaker aberto, as requisições do cliente falharam
na hora e o serviço não recebeu quase nada, então a fila dele esvaziou em vez de crescer, e a sondagem do
meio aberto o encontrou saudável. De 1.649 respostas, 37 chegaram atrasadas.

Esse é o trabalho de verdade do breaker, e é fácil descrevê-lo como outra coisa. Ele não faz um serviço
que falha dar certo; as requisições durante o congelamento falharam com ele como falharam sem ele. **Ele
protege o serviço dos próprios chamadores**, para que possa se recuperar, e protege os chamadores de
esperar por algo que não vai responder: uma requisição rejeitada por um breaker aberto falha em
microssegundos em vez de meio segundo.

## Escolhendo as configurações

| configuração | o laboratório | o que pesar |
| --- | --- | --- |
| quando abrir | 5 falhas seguidas | poucas demais e um segundo ruim o abre; bibliotecas também oferecem uma taxa de falhas numa janela |
| quanto tempo ficar aberto | 2 segundos | o bastante para o serviço se recuperar, pouco o bastante para não falhar requisições que ele atenderia |
| o que conta como falha | um timeout ou um `5xx` | um `404` é uma resposta, não uma falha do serviço |
| o que fazer enquanto aberto | falhar na hora | falhar na hora, ou responder com uma alternativa: uma contagem de estoque em cache, "disponibilidade desconhecida" |

**Um breaker por dependência**, nunca um para tudo: o serviço de estoque fora do ar não deveria impedir o
checkout de chamar pagamentos.
