---
title: RabbitMQ: exchanges, filas e ligações
version: 1
---

O RabbitMQ implementa o AMQP 0-9-1, e o modelo dele tem uma surpresa para quem chega: **um publicador
nunca manda para uma fila.** Ele manda para uma **exchange**, com uma **chave de roteamento** (*routing
key*), e a exchange decide que filas recebem uma cópia, segundo **ligações** (*bindings*) que conectam
filas a ela.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Um publicador manda uma mensagem com a chave de roteamento order.placed para a exchange orders. A exchange tem duas ligações com o padrão order.*, uma para a fila email e outra para a fila warehouse, então uma cópia da mensagem vai para cada fila. Uma terceira fila, refunds, está ligada com order.refunded e não recebe nada.\"><defs><marker id=\"l6-exchange-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l6-exchange-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l6-exchange-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"240\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"30\" y=\"100\" width=\"130\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"95\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">publicador</text><text x=\"95\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">order.placed</text><rect x=\"240\" y=\"95\" width=\"140\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"310\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">exchange</text><text x=\"310\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">orders</text><path d=\"M162 125 L238 125\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l6-exchange-ah-amber)\"></path><rect x=\"540\" y=\"40\" width=\"150\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"615\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">email</text><path d=\"M382 125 L538 62\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l6-exchange-ah-phosphor)\"></path><text x=\"460\" y=\"82.35\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">order.*</text><rect x=\"540\" y=\"110\" width=\"150\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"615\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">warehouse</text><path d=\"M382 125 L538 132\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l6-exchange-ah-phosphor)\"></path><text x=\"460\" y=\"120.85\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">order.*</text><rect x=\"540\" y=\"180\" width=\"150\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"615\" y=\"202\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">refunds</text><path d=\"M382 125 L538 202\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l6-exchange-ah-wire)\"></path><text x=\"460\" y=\"159.35\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">order.refunded</text></svg>", "caption": "Publicadores mandam para uma exchange, nunca para uma fila. As ligações decidem que filas recebem uma cópia, e uma mensagem que nenhuma ligação aceita não vai para lugar nenhum.", "same": ["exchange"]}
```

| peça | o que é |
| --- | --- |
| exchange | um roteador com nome; não guarda mensagens |
| fila | onde as mensagens esperam um consumidor; é o único lugar que as guarda |
| ligação | uma regra que conecta uma fila a uma exchange, com um padrão para a chave de roteamento |
| chave de roteamento | uma string curta que o publicador põe em cada mensagem, como `order.placed` |

O **tipo** da exchange diz como as ligações são comparadas:

| tipo | entrega a toda fila ligada com | exemplo na Quitanda |
| --- | --- | --- |
| direct | exatamente a chave de roteamento da mensagem | `payment.declined` para a fila que trata recusas |
| topic | um padrão, em que `*` é uma palavra e `#` é qualquer número de palavras | `order.*` recebe `order.placed` e `order.refunded` |
| fanout | toda fila ligada, qualquer que seja a chave | uma mudança de preço que todo cache precisa ouvir |
| headers | uma comparação nos cabeçalhos da mensagem em vez da chave | raramente necessário |

## Por que o desvio

O publicador de `OrderPlaced` conhece a exchange `orders` e mais nada. **Cada serviço interessado cria a
própria fila e a liga**: o serviço de e-mail uma fila `email`, o depósito uma fila `warehouse`.
Acrescentar um terceiro serviço é mais uma fila e mais uma ligação, e o publicador não é tocado, que é o
argumento da aula 5 sobre eventos, embutido no broker.

Dentro de uma fila, os consumidores competem; entre filas, cada fila recebe a sua cópia. Então "todo
serviço recebe todo pedido" e "os três trabalhadores do depósito dividem os pedidos" são dois arranjos
das mesmas peças: uma fila por serviço, e vários consumidores numa fila.

## O caso que perde mensagens

O outro lado do desvio é uma perda silenciosa. **Uma mensagem que nenhuma ligação aceita é descartada pela
exchange**, e por padrão o publicador não fica sabendo. Se a fila do serviço de e-mail ainda não foi
declarada quando os primeiros pedidos são publicados, esses pedidos nunca chegam a ele. A próxima seção
mostra isso acontecendo, e a aula 7 mostra as duas configurações que fazem um publicador descobrir:
confirmações do publicador, e a opção `mandatory`.
