---
title: O que os outros pedidos veem
version: 1
---

Uma transação de banco é **isolada**: até ela confirmar, ninguém mais vê as mudanças dela. Uma saga não é.
Cada passo dela confirma, então entre o primeiro e o último passo, todo outro cliente e toda outra saga
veem um checkout pela metade. O catálogo de padrões de saga de Chris Richardson chama uma saga de **ACD**:
atômica no sentido de que se completa ou é compensada, consistente, durável, e **não isolada**.

A reserva do serviço de estoque é a resposta do laboratório, e é uma **trava semântica**: as unidades
saem do que pode ser vendido no momento em que são reservadas, antes de alguém saber se o pedido vai se
completar. É ela que impede duas sagas de venderem as duas o último pacote. Ela também tem um custo, e o
laboratório consegue mostrá-lo. O pedido o-4 reserva os dois últimos pacotes e depois espera cinco
segundos antes de cobrar um cartão que vai ser recusado; dois segundos depois, o o-5 pede um pacote:

```
ana@vm:~/lab/saga$ $R saga.py o-4 --units 2 --card 4000-0002 --pause 5 & sleep 2; $R saga.py o-5; wait
o-4: saga started
  stock reserve: ok {'reserved': 2}
o-5: saga started
  stock reserve: failed {'error': 'only 0 coffee left'}
o-5: compensating
o-5: failed, everything undone
  payments charge: failed {'error': 'card declined'}
o-4: compensating
  stock release: ok {'released': 'o-4'}
o-4: failed, everything undone
ana@vm:~/lab/saga$ curl -s localhost:8001; echo
{"shelf": {"coffee": 2}, "reservations": {"o-1": {"sku": "coffee", "units": 1, "status": "sold"}, "o-2": {"sku": "coffee", "units": 1, "status": "released"}, "o-3": {"sku": "coffee", "units": 1, "status": "released"}, "o-4": {"sku": "coffee", "units": 2, "status": "released"}}}
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"Dois pedidos ao longo do tempo. O pedido o-4 reserva os dois últimos pacotes de café e espera cinco segundos antes de cobrar o cartão. Nesses segundos o pedido o-5 pede um pacote e é recusado, porque nenhum está livre. Depois o cartão do o-4 é recusado e os dois pacotes são liberados, de volta à prateleira, depois de o o-5 ter ido embora.\"><defs><marker id=\"l14-lock-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"220\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"30\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">o-4</text><text x=\"30\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">o-5</text><path d=\"M70 92 L690 92\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#l14-lock-ah-wire)\"></path><path d=\"M70 182 L690 182\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#l14-lock-ah-wire)\"></path><rect x=\"100\" y=\"40\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"160\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">reserva 2</text><rect x=\"230\" y=\"40\" width=\"220\" height=\"40\" rx=\"4\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"340\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">segurando os 2 últimos</text><rect x=\"460\" y=\"40\" width=\"110\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"515\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">recusado</text><rect x=\"580\" y=\"40\" width=\"100\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"630\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">libera 2</text><rect x=\"280\" y=\"130\" width=\"140\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"350\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">recusado: restam 0</text><text x=\"360\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o o-5 foi recusado por café que nunca foi vendido</text></svg>", "caption": "Uma reserva é uma trava que outras sagas conseguem ver. Ela impede vender demais, e pode recusar um cliente por estoque que acaba não vendido."}
```

**O o-5 foi recusado por café que nunca foi vendido.** O o-4 segurou os dois pacotes enquanto o cartão
era tentado, o cartão foi recusado, os pacotes voltaram para a prateleira, e a essa altura o cliente do
o-5 já tinha ouvido "restam 0". Sem a reserva, teria acontecido o contrário: o o-5 teria levado um pacote
com que o o-4 contava, e se o cartão do o-4 tivesse sido aceito, dois clientes teriam comprado o mesmo
café.

Nenhum dos resultados é de graça, e escolher entre eles é uma decisão de negócio vestida de decisão
técnica:

| contramedida | o que outras sagas veem | o custo |
| --- | --- | --- |
| **trava semântica** (reservar primeiro) | as unidades como tomadas, como o laboratório fez | um cliente recusado por estoque que acaba livre |
| **reler o valor** antes do pivô | nada até o fim; a saga confere de novo antes de confirmar | a conferência pode falhar tarde, depois de o cartão ser cobrado |
| **atualizações comutativas** | mudanças que se aplicam em qualquer ordem, como "somar 2 ao estoque" | só algumas operações podem ser escritas assim |
| **visão pessimista** | o passo mais arriscado por último, o mais provável de falhar primeiro | janelas menores e mais curtas; nem sempre é possível |

A loja da Quitanda, como a maioria, reserva: um cliente recusado pode ouvir que tente de novo em um
minuto, e um a quem se vendeu demais precisa de um pedido de desculpas e de um reembolso. **Segurar uma
reserva pelo menor tempo possível** é o que mantém o custo pequeno: reservar no checkout, não quando o
item entra na cesta, e liberar com um temporizador se a saga empacar.
