---
title: Orquestração
version: 1
---

Numa saga **orquestrada** um componente guarda o plano. O `saga.py` é esse componente: uma lista de
passos e compensações, rodados em ordem, chamando cada serviço por HTTP. Os serviços não sabem que fazem
parte de um checkout; reservam, cobram ou agendam quando pedidos.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Orquestração. Uma caixa chamada saga.py no meio chama três serviços em sequência, estoque, pagamentos e entregas, com setas numeradas: 1 reservar, 2 cobrar, 3 agendar, 4 confirmar. Os serviços não falam entre si.\"><defs><marker id=\"l14-orchestration-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"230\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"280\" y=\"30\" width=\"160\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">saga.py</text><rect x=\"40\" y=\"170\" width=\"160\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"120\" y=\"195\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">estoque</text><rect x=\"280\" y=\"170\" width=\"160\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"195\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">pagamentos</text><rect x=\"520\" y=\"170\" width=\"160\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"600\" y=\"195\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">entregas</text><path d=\"M300 82 L140 168\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l14-orchestration-ah-phosphor)\"></path><text x=\"170\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">1 reservar, 4 confirmar</text><path d=\"M360 82 L360 168\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l14-orchestration-ah-phosphor)\"></path><text x=\"372\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">2 cobrar</text><path d=\"M420 82 L580 168\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l14-orchestration-ah-phosphor)\"></path><text x=\"560\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">3 agendar</text></svg>", "caption": "Um orquestrador guarda o plano e chama cada serviço; os serviços não sabem nada sobre o checkout."}
```

Um checkout que dá certo:

```
ana@vm:~/lab/saga$ $R saga.py o-1
o-1: saga started
  stock reserve: ok {'reserved': 1}
  payments charge: ok {'charged': 2490}
  shipping schedule: ok {'scheduled': 'Recife'}
  stock confirm: ok {'sold': 'o-1'}
o-1: completed
```

Um cartão recusado. A reserva já tinha sido feita, então é liberada:

```
ana@vm:~/lab/saga$ $R saga.py o-2 --card 4000-0002
o-2: saga started
  stock reserve: ok {'reserved': 1}
  payments charge: failed {'error': 'card declined'}
o-2: compensating
  stock release: ok {'released': 'o-2'}
o-2: failed, everything undone
```

Uma cidade que as entregas não atendem. A essa altura o cartão também já tinha sido cobrado, então os
dois passos anteriores são compensados, em ordem inversa: primeiro o reembolso, depois a liberação:

```
ana@vm:~/lab/saga$ $R saga.py o-3 --city Noronha
o-3: saga started
  stock reserve: ok {'reserved': 1}
  payments charge: ok {'charged': 2490}
  shipping schedule: failed {'error': 'no deliveries to Noronha'}
o-3: compensating
  payments refund: ok {'refunded': 'o-3'}
  stock release: ok {'released': 'o-3'}
o-3: failed, everything undone
```

E o que os serviços de estoque e de pagamentos guardam depois:

```
ana@vm:~/lab/saga$ curl -s localhost:8001; echo; curl -s localhost:8002; echo
{"shelf": {"coffee": 2}, "reservations": {"o-1": {"sku": "coffee", "units": 1, "status": "sold"}, "o-2": {"sku": "coffee", "units": 1, "status": "released"}, "o-3": {"sku": "coffee", "units": 1, "status": "released"}}}
{"o-1": {"cents": 2490, "status": "charged"}, "o-3": {"cents": 2490, "status": "refunded"}}
```

Todo pedido deixou um rastro. O o-1 está vendido e cobrado. O o-2 tem uma reserva liberada e nenhuma
cobrança. O o-3 tem uma reserva liberada **e uma cobrança marcada como reembolsada**: foi cobrado, de
verdade, e depois reembolsado. A prateleira tem dois pacotes, que é três menos o vendido.

## O estado do próprio orquestrador

O `saga.py` guarda a lista de passos completados em memória e a imprime. Se ele caísse entre a cobrança e
o agendamento, ninguém saberia que o o-3 precisava de reembolso. Um orquestrador de verdade **grava cada
passo num banco antes e depois de fazê-lo**, para depois de uma queda conseguir ler onde estava cada saga
e continuar, para a frente ou para trás. Esse registro também é a melhor resposta para a pergunta que
alguém do suporte faz, "o que aconteceu com este pedido?", num lugar só.

É a maior parte do que os produtos de orquestração de sagas vendem. O **Temporal** e o seu antecessor
Cadence registram cada passo de um workflow escrito como código comum e o reaplicam depois de uma queda.
O **AWS Step Functions** e o **Google Workflows** rodam uma máquina de estados descrita em JSON ou YAML. O
**Camunda** roda diagramas BPMN. Todos guardam o estado da saga para uma queda ser uma pausa, e não um
reembolso perdido.
