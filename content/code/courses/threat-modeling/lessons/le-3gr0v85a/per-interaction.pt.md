---
title: STRIDE por interação
version: 1
---

O **STRIDE por interação** aplica as letras a um fluxo junto com os dois elementos das pontas, e só
a fluxos que cruzam uma fronteira de confiança. É a variante por trás da Threat Modeling Tool
gratuita da Microsoft, e combina com o jeito como as ameaças de fato acontecem: através de uma
linha, entre um remetente e um destinatário que confiam um no outro de jeitos diferentes.

Para cada travessia, as perguntas vêm numa ordem fixa, do lado de quem manda para o lado de quem
recebe:

| | sobre | pergunta |
|---|---|---|
| **S** | a origem | quem manda é quem diz ser? |
| **T, I** | o fluxo | o dado pode ser mudado ou lido no caminho? |
| **D** | o fluxo e o destino | o destino pode ser inundado, ou o fluxo cortado? |
| **E** | o destino | o destino pode ser levado a fazer algo que quem manda não pode pedir? |
| **R** | os dois | se quem mandou negar depois, existe registro? |

### O fluxo 7, interação por interação

O webhook de pagamento vai do gateway (zona dos fornecedores) para o portal (nuvem da Vereda), e
muda um agendamento de não pago para pago.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" data-fig=\"l03-webhook-letters\" aria-label=\"STRIDE por interação no webhook de pagamento. Na origem, o gateway: S, é mesmo o gateway? No fluxo: T e I, pode ser mudado ou lido no caminho, e D, pode ser mandado vezes demais? No destino, o portal: E, um pedido anônimo consegue marcar um agendamento como pago? E R nas duas pontas: o original fica guardado?\"><defs><marker id=\"l03-webhook-letters-tm-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"35.0\" y=\"75.0\" width=\"150.0\" height=\"50.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"110.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Gateway de pagamento</text><circle cx=\"600.0\" cy=\"100.0\" r=\"52\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"600.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Portal</text><path d=\"M185.0 100.0 L548.0 100.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03-webhook-letters-tm-ah-paper-dim)\"></path><text x=\"366.0\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">webhook de pagamento</text><path d=\"M290.0 30.0 L290.0 170.0\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" stroke-dasharray=\"6 4\"></path><text x=\"296.0\" y=\"30.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--amber)\">fornecedores | Vereda</text><text x=\"110.0\" y=\"155.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">S</text><text x=\"110.0\" y=\"173.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">é o gateway?</text><text x=\"366.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">T  I  D</text><text x=\"366.0\" y=\"158.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">mudado, lido, inundado?</text><text x=\"600.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">E</text><text x=\"600.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">mais do que um anônimo pode?</text><text x=\"366.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">R nas duas pontas: o webhook original fica guardado?</text></svg>", "caption": "S e E descrevem a mesma falha das duas pontas: o portal não pergunta quem mandou o pedido, e depois o deixa fazer o que só o gateway deveria.", "same": ["Portal"]}
```

- S, a origem: o pedido é do gateway? O portal não confere. **Esta é a T01**, e é a ameaça de
  onde a aula 1 partiu. O gateway assina cada chamada; a correção é verificar a assinatura.
- T, o fluxo: o valor ou o id do agendamento poderiam ser mudados no caminho? Ele viaja por
  HTTPS a partir do gateway, então no caminho, não. Quando qualquer um pode mandar o pedido, a
  pergunta perde o sentido: ele escreve o que quiser.
- I, o fluxo: o webhook carrega um id de agendamento e um status, nada que valha a pena ler.
- D: uma enxurrada de webhooks falsos poderia carregar o portal; a mesma resposta de qualquer
  endereço público.
- E, o destino: marcar um agendamento como pago é mais do que um pedido anônimo deveria
  conseguir fazer. São S e E descrevendo a mesma falha pelas duas pontas.
- R: se o gateway e o portal discordarem sobre uma sessão ter sido paga, a Vereda guarda o
  webhook original? Ninguém sabe, e isso já vale anotar.

Seis perguntas, uma ameaça séria, dois "conferir isto" e três respondidas. Essa proporção é normal.
O valor de percorrer as letras em ordem é que **a única ameaça séria não pôde se esconder numa
categoria que ninguém perguntou.**

### Qual variante usar

Por elemento numa primeira passada pelo sistema inteiro, porque é rápido e cobre tudo. Por
interação nos fluxos que cruzam as fronteiras que mais importam, porque é lá que as ameaças sérias
se concentram. A maioria dos modelos reais usa as duas, nessa ordem.
