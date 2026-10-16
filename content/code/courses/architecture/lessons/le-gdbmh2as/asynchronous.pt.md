---
title: Assíncrono: diga e siga em frente
version: 1
---

No estilo **assíncrono** quem manda entrega uma mensagem e segue sem esperar que o destinatário aja
sobre ela. Algo no meio, em geral um **broker de mensagens** com uma fila dentro, guarda a mensagem até o
destinatário pegá-la. Quem mandou sabe que a mensagem foi aceita pelo broker, não que alguém já fez algo
com ela.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Um produtor à esquerda põe mensagens numa fila no meio; um consumidor à direita as tira. O consumidor aparece parado, e quatro mensagens esperam na fila; o produtor continua trabalhando mesmo assim.\"><defs><marker id=\"l5-queue-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l5-queue-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"210\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"30\" y=\"80\" width=\"150\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"105\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">pedidos</text><text x=\"105\" y=\"127\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">produtor, rodando</text><rect x=\"250\" y=\"80\" width=\"220\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">fila</text><rect x=\"262\" y=\"96\" width=\"42\" height=\"38\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"283\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">m1</text><rect x=\"312\" y=\"96\" width=\"42\" height=\"38\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"333\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">m2</text><rect x=\"362\" y=\"96\" width=\"42\" height=\"38\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"383\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">m3</text><rect x=\"412\" y=\"96\" width=\"42\" height=\"38\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"433\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">m4</text><rect x=\"540\" y=\"80\" width=\"150\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"615\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" font-weight=\"600\">e-mail</text><text x=\"615\" y=\"127\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">consumidor, parado</text><path d=\"M182 115 L248 115\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l5-queue-ah-phosphor)\"></path><path d=\"M472 115 L538 115\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l5-queue-ah-wire)\"></path><text x=\"360\" y=\"185\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">as mensagens esperam; ninguém antes delas fica travado</text></svg>", "caption": "Uma fila desacopla os dois lados no tempo. O produtor não precisa que o consumidor esteja de pé; as mensagens esperam até ele estar.", "same": ["e-mail"]}
```

A crença comum é que assíncrono quer dizer mais rápido. **Quer dizer desacoplado no tempo**, que é outra
propriedade. Mandar um e-mail de confirmação por uma fila não faz o e-mail chegar antes; faz o pedido
dar certo estando ou não o serviço de e-mail de pé naquele momento. O trabalho continua levando o tempo
que leva, em outro lugar.

## O que isso compra

| propriedade | a versão síncrona | a versão assíncrona |
| --- | --- | --- |
| o destinatário está fora do ar | quem manda falha também | as mensagens esperam na fila; quem manda segue |
| o destinatário está lento | quem manda espera | a fila cresce; quem manda segue |
| uma rajada de trabalho | cada requisição espera a vez no destinatário | a fila absorve a rajada e o destinatário a percorre no próprio ritmo |
| acrescentar um segundo destinatário | quem manda precisa chamá-lo também | ele se inscreve, e quem manda nunca muda |

A terceira linha tem nome nos padrões de projeto em nuvem: **nivelamento de carga por fila** (*queue-based
load leveling*). Uma fila entre uma fonte com picos e um trabalhador constante deixa o trabalhador ser
dimensionado pela média e não pelo pico. A aula 12 volta a isso, junto com o que fazer quando a própria
fila enche.

## O que isso custa

Tudo o que o estilo síncrono dava de graça precisa ser pensado de novo:

- **Nenhuma resposta no mesmo fôlego.** Quem manda não consegue dizer ao seu próprio chamador "feito", só
  "aceito". Se alguém precisa saber o resultado, ele chega depois, por outra mensagem ou perguntando, a
  próxima seção.
- **Entrega.** Um broker pode perder uma mensagem, entregá-la duas vezes, ou entregá-la depois de uma
  posterior, conforme a configuração e o jeito como o destinatário a confirma. A aula 7 é inteira sobre
  isso.
- **Consistência.** Enquanto a mensagem espera, o dado de quem mandou e o de quem recebe discordam. A
  aula 9 mostra um cliente olhando para essa discordância.
- **Seguir uma requisição.** Uma chamada síncrona tem um stack trace. Uma mensagem processada três
  serviços depois, dez segundos depois de enviada, tem o id de correlação que quem mandou lembrou de pôr
  nela.

A aula 6 monta os próprios brokers, RabbitMQ e Kafka, no seu laboratório. O resto desta aula fica no
HTTP simples, porque um dos padrões assíncronos mais úteis não precisa de mais nada.
