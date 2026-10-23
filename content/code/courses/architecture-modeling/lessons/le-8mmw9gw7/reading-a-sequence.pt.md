---
title: Lendo uma sequência em busca de esperas e falhas
version: 1
---

**Um diagrama de sequência é o único desenho em que dá para contar quanto tempo algo leva e ver onde
pode quebrar**, porque cada seta síncrona é uma espera, e cada espera é um lugar onde uma falha pode
cair. Ler assim é uma habilidade por si só, e revisões de arquitetura a usam o tempo todo.

## Contando as esperas

Pegue a metade do pagamento na compra. Cada mensagem síncrona segura tudo o que está acima dela até
a resposta voltar, então o passageiro espera a soma da cadeia. As medições da Carcará no percentil
95, o tempo abaixo do qual ficam dezenove pedidos em vinte, foram:

| passo | p95 |
| --- | --- |
| do app para a API, por rede móvel | 120 ms |
| da API para o gateway de pagamento, cobrança no cartão | 1.400 ms |
| da API para o banco de reservas, marcar como paga | 8 ms |
| da API de volta para o app | 120 ms |

Somando, dá cerca de 1.650 ms, e a tabela confirma o que o diagrama já mostrava: **o gateway é quase
tudo**. Ganhar tempo na escrita no banco não mudaria nada que um passageiro pudesse perceber. Um
diagrama com o tempo nele deixa você ver isso antes que alguém otimize o passo errado.

(Somar percentis não é exato: o vigésimo mais lento de um passo nem sempre coincide com o vigésimo
mais lento de outro. Para uma primeira olhada em onde o tempo vai, é perto o bastante, e o número de
verdade vem de um trace.)

## Achando as falhas

Agora pergunte, em cada seta síncrona: *e se isto nunca responder?* Três perguntas por seta:

1. **Quem está esperando, e por quanto tempo?** Tem que haver um timeout, e o diagrama é onde você
   decide onde ele fica. O app espera a API; a API espera o gateway. Se o timeout da API para o
   gateway for maior que o timeout do app para a API, o app desiste primeiro e a API continua
   trabalhando num pedido que ninguém está esperando.
2. **O que já aconteceu?** Quando o gateway é chamado, o assento já está bloqueado e a reserva já foi
   gravada como *aguardando pagamento*. Uma falha aqui deixa as duas coisas para trás, o que só não é
   problema porque o bloqueio expira sozinho depois de dez minutos.
3. **O outro lado pode ter dado certo mesmo assim?** Essa é a cara. Se a chamada ao gateway estoura
   o timeout, o cartão pode ter sido cobrado mesmo assim: o que se perdeu foi a resposta, não a
   cobrança. Chamar de novo pode cobrar duas vezes.

## O que a terceira pergunta mudou na Carcará

Foi desenhando o pagamento assim que a Carcará achou a cobrança em dobro antes de um passageiro. A
correção aparece como duas mudanças no diagrama:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 360\" role=\"img\" data-fig=\"l02-sequence-webhook\" aria-label=\"O pagamento de novo, depois da correção, com quatro linhas de vida: app do passageiro, API de passagens, banco de reservas e gateway de pagamento. A API manda cobrar cartão com a chave B-4471 ao gateway. A resposta se perde: um x a marca, com o rótulo timeout. A API repete a mesma cobrança com a mesma chave, e o gateway responde já cobrado: aprovado, sem cobrar de novo. Mais tarde, fora de qualquer pedido, o gateway manda pagamento aprovado para B-4471 ao webhook da API, uma mensagem assíncrona, e a API marca a reserva como paga.\"><defs><marker id=\"l02-sequence-webhook-am-fill-paper\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" markerUnits=\"userSpaceOnUse\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker><marker id=\"l02-sequence-webhook-am-open-paper\" viewBox=\"0 0 10 8\" refX=\"9.5\" refY=\"4\" markerWidth=\"9\" markerHeight=\"8\" markerUnits=\"userSpaceOnUse\" orient=\"auto-start-reverse\"><path d=\"M0 0.5 L9.5 4 L0 7.5\" fill=\"none\" stroke=\"var(--paper)\" stroke-width=\"1.3\"></path></marker></defs><rect x=\"10.0\" y=\"11.0\" width=\"140.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"80.0\" y=\"28.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">App do passageiro</text><path d=\"M80.0 45.0 L80.0 345.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 4\"></path><rect x=\"190.0\" y=\"11.0\" width=\"140.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"260.0\" y=\"28.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">API de passagens</text><path d=\"M260.0 45.0 L260.0 72.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 4\"></path><path d=\"M260.0 210.0 L260.0 280.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 4\"></path><path d=\"M260.0 330.0 L260.0 345.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 4\"></path><rect x=\"370.0\" y=\"11.0\" width=\"140.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"440.0\" y=\"28.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">Banco de reservas</text><path d=\"M440.0 45.0 L440.0 345.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 4\"></path><rect x=\"550.0\" y=\"11.0\" width=\"140.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"620.0\" y=\"28.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">Gateway de pagamento</text><path d=\"M620.0 45.0 L620.0 345.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 4\"></path><rect x=\"255.0\" y=\"72.0\" width=\"10.0\" height=\"138.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><path d=\"M86.0 76.0 L254.0 76.0\" stroke=\"var(--paper)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l02-sequence-webhook-am-fill-paper)\"></path><text x=\"170.0\" y=\"69.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">POST /payments</text><path d=\"M266.0 102.0 L614.0 102.0\" stroke=\"var(--paper)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l02-sequence-webhook-am-fill-paper)\"></path><text x=\"440.0\" y=\"95.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">cobra cartão, chave = B-4471</text><path d=\"M614 128 L380 128\" stroke=\"var(--paper)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 3\"></path><path d=\"M372.0 121.0 L386.0 135.0\" stroke=\"var(--amber)\" stroke-width=\"1.8\" fill=\"none\"></path><path d=\"M372.0 135.0 L386.0 121.0\" stroke=\"var(--amber)\" stroke-width=\"1.8\" fill=\"none\"></path><text x=\"400.0\" y=\"140.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">timeout: a resposta se perde</text><path d=\"M266.0 164.0 L614.0 164.0\" stroke=\"var(--paper)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l02-sequence-webhook-am-fill-paper)\"></path><text x=\"440.0\" y=\"157.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">cobra cartão, mesma chave = B-4471</text><path d=\"M614.0 192.0 L266.0 192.0\" stroke=\"var(--paper)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 3\" marker-end=\"url(#l02-sequence-webhook-am-open-paper)\"></path><text x=\"440.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">já cobrado: aprovado</text><path d=\"M254.0 206.0 L86.0 206.0\" stroke=\"var(--paper)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 3\" marker-end=\"url(#l02-sequence-webhook-am-open-paper)\"></path><text x=\"170.0\" y=\"217.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">passagem</text><path d=\"M30.0 240.0 L700.0 240.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"2 4\"></path><text x=\"36.0\" y=\"254.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">mais tarde, fora do pedido</text><rect x=\"255.0\" y=\"280.0\" width=\"10.0\" height=\"50.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><path d=\"M614.0 284.0 L266.0 284.0\" stroke=\"var(--paper)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l02-sequence-webhook-am-open-paper)\"></path><text x=\"440.0\" y=\"277.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">webhook: pagamento aprovado, B-4471</text><path d=\"M266.0 316.0 L434.0 316.0\" stroke=\"var(--paper)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l02-sequence-webhook-am-fill-paper)\"></path><text x=\"350.0\" y=\"309.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">marca como paga, se ainda não estiver</text></svg>", "caption": "A chave torna a nova tentativa segura; o webhook torna inofensiva a resposta perdida. As duas coisas só aparecem num desenho que mostra o momento entre enviado e respondido."}
```

- A cobrança leva uma **chave de idempotência**, o id da reserva, para que uma nova tentativa da
  mesma cobrança seja reconhecida pelo gateway e não seja cobrada de novo.
- O gateway também avisa a Carcará do resultado de forma **assíncrona**, chamando um webhook. Isso
  aparece no diagrama como uma seta de ponta aberta do gateway para a API, fora do pedido original.
  Se a resposta síncrona se perde, o webhook chega assim mesmo e marca a reserva como paga.

O curso `architecture`, na aula sobre entrega garantida, explica idempotência a fundo. O ponto aqui
é mais estreito: **um diagrama de sequência desenhado com honestidade, com as pontas de seta
certas, é onde esse tipo de falha fica visível**, porque é o único desenho que mostra o momento
entre *enviado* e *respondido*.
