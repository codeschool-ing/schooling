---
title: O registro de decisão, escrito para uma decisão de verdade
version: 1
---

Você conheceu o registro de decisão de arquitetura no curso `architecture`, aula 20, como um jeito
de registrar uma escolha e defendê-la. Esta seção olha para ele do outro lado: **como arquiteto,
cabe a você garantir que as decisões que atravessam times fiquem registradas**, e que os registros
sejam bons o bastante para que alguém que não estava na sala consiga acompanhá-los daqui a dois anos. Isso
é mais fácil de mostrar do que de descrever, então aqui vai um, inteiro.

## O formato, rapidamente

Michael Nygard propôs a forma em 2011, num artigo curto chamado "Documenting Architecture
Decisions". Um registro é uma decisão, uma ou duas páginas de texto simples, guardado no repositório
e numerado em sequência, com cinco partes:

| parte | o que guarda |
|---|---|
| título | a decisão, numa frase curta depois do número |
| status | em que ponto da vida ele está: proposto, aceito, substituído ou obsoleto |
| contexto | as forças em jogo: o que é verdade, o que restringe a escolha, o que puxa para cada lado |
| decisão | o que será feito, em frases completas e na voz ativa |
| consequências | o que passa a ser verdade quando ela vale, o bom e o ruim |

Muitos times acrescentam uma lista das opções consideradas, e o modelo da Carreto faz isso, dentro do
contexto. `architecture-modeling` aula 5 se demora nas opções e em como compará-las; aqui elas fazem
parte do contexto porque explicam a decisão.

## Um registro, inteiro

A decisão é a que a aula 4 deixou em aberto: como o Payments fica sabendo que uma entrega foi
provada, para poder pagar o motorista em até 24 horas. Bruno Farias, do Payments, escreveu o
registro, com o tech lead do Tracking, depois da sessão de trabalho que a Renata conduziu. Ele mora
no repositório do Payments porque é o sistema que ele mais muda. O registro aparece em inglês, como todo
bloco de código deste curso.

```
# 7. Payments learns that a delivery was proved from an event

Status: Accepted

## Context

Carreto will pay drivers within 24 hours of delivery. Today Payments
pays once a week, from a batch that reads the deliveries table in the
monolith's database.

A delivery is proved when Tracking holds the driver's photo, the
receiver's signature and a GPS position near the destination. Tracking
owns that rule and its own database.

Forces:
- A delivery must be paid once: never twice, and never missed.
- The payout budget leaves 7 of its 24 hours as slack.
- Proof can reach Tracking up to 4 hours after unloading.
- Tracking deploys several times a day; Payments twice a week.
- Payments must not read Tracking's database.
- Both teams already use the company's message broker.

Options considered:
1. Payments asks Tracking's API every 5 minutes for new proofs.
2. Tracking calls a Payments endpoint when a delivery is proved.
3. Tracking publishes a DeliveryProved event; Payments consumes it.

## Decision

Tracking will publish a DeliveryProved event to the broker for every
proved delivery, carrying the delivery id, the CT-e key and the time
of proof. Payments will consume it, store it keyed by delivery id, so
that a repeated event changes nothing, and schedule the payout for the
end of the contest window.

Payments will also check Tracking's API every night for proved
deliveries it has not received, and alert if it finds one.

## Consequences

- Tracking finishes a proof whether or not Payments is up.
- Payments must accept events that arrive late, twice or out of order.
- The event's fields are a contract between two teams. Changing them
  needs both teams and a new version of the event.
- The nightly check is a second path to maintain. It is also the only
  way we will notice an event that was lost.
- Option 1 was rejected: it adds up to 5 minutes of delay and a steady
  load on Tracking's API for every open delivery.
- Option 2 was rejected: Tracking's proof step would fail whenever
  Payments was down, and Tracking would need to know about Payments.
```

## O que faz dele um bom registro

**O contexto está escrito como forças, com números.** "Payments must not read Tracking's database"
(o Payments não pode ler o banco do Tracking) e "a prova chega até 4 horas atrasada" são fatos que um
leitor confere, e cada um descarta alguma coisa. Um contexto que dissesse "queremos um desenho
robusto e desacoplado" não descartaria nada, e um leitor futuro não saberia dizer se as forças
mudaram.

**A decisão é uma frase pela qual alguém pode ser cobrado.** "Tracking will publish", "Payments will
consume", "store it keyed by delivery id". Cada uma diz quem faz o quê. Uma decisão escrita na voz
passiva ("uma abordagem orientada a eventos será adotada") deixa o leitor perguntando quem adota, e
num registro entre times essa pergunta é justamente o ponto.

**As consequências incluem os custos.** O time do Bruno agora precisa lidar com duplicatas e
atrasos, e assumiu um job noturno. Escrever isso não é pessimismo. **Um registro que lista só
benefícios parece um anúncio**, e o leitor que mais tarde descobre os custos por conta própria deixa
de confiar no resto do log.

**As opções rejeitadas ficam, com o motivo.** Daqui a um ano alguém vai propor consulta periódica de
novo, porque é mais simples, e o registro vai mostrar que ela foi considerada e por que perdeu. Se o
motivo não vale mais, isso é razão para escrever um registro novo, que é a próxima parte desta seção.

**Ele é curto.** Cerca de 360 palavras. O Bruno escreveu numa tarde, e a revisão no pull request levou
um dia para os dois times. Um registro que leva uma semana para ser escrito acaba escrito depois do
código, como papelada, e para de registrar qualquer coisa.

## O status, e por que um registro aceito não é editado

Um registro começa como **proposto** enquanto os times discutem, e passa a **aceito** quando eles se
comprometem. Depois disso, **o texto não muda**. Se a decisão mudar, escreve-se um registro novo que
**substitui** o antigo: o novo diz qual substitui, e a linha de status do antigo é a única editada,
para apontar o sucessor. Um registro cuja decisão simplesmente deixa de valer, sem nada no lugar, é
marcado como **obsoleto**.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Dois registros lado a lado. À esquerda, o registro 3, pagamentos rodam num lote semanal a partir do banco do monólito, escrito depois, de memória, com o status mudado para substituído pelo 7. À direita, o registro 7, o Payments sabe que uma entrega foi provada por um evento, status aceito, com uma linha dizendo que substitui o 3. Uma seta vai do 7 de volta ao 3. Embaixo, os quatro status em fila: proposto, aceito, e depois substituído ou obsoleto.\"><defs><marker id=\"adr7-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"adr7-bh\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"300\" height=\"120\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"36\" y=\"46\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper-dim)\">3</text><text x=\"56\" y=\"46\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper-dim)\">Pagamentos rodam num lote semanal</text><text x=\"56\" y=\"64\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper-dim)\">a partir do banco do monólito</text><text x=\"36\" y=\"94\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">escrito depois, de memória</text><text x=\"36\" y=\"122\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">Status: substituído pelo 7</text><rect x=\"400\" y=\"20\" width=\"300\" height=\"120\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"416\" y=\"46\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--phosphor)\">7</text><text x=\"436\" y=\"46\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">O Payments sabe que uma entrega</text><text x=\"436\" y=\"64\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">foi provada por um evento</text><text x=\"416\" y=\"94\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Substitui o 3</text><text x=\"416\" y=\"122\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">Status: aceito</text><path d=\"M396 80 L326 80\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#adr7-ah)\"></path><rect x=\"20\" y=\"180\" width=\"140\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"90\" y=\"205\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">proposto</text><path d=\"M162 200 L196 200\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#adr7-bh)\"></path><rect x=\"200\" y=\"180\" width=\"140\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"270\" y=\"205\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--phosphor)\">aceito</text><path d=\"M342 200 L376 200\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#adr7-bh)\"></path><rect x=\"380\" y=\"180\" width=\"140\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"450\" y=\"205\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--amber)\">substituído</text><text x=\"540\" y=\"205\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">ou</text><rect x=\"560\" y=\"180\" width=\"140\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"630\" y=\"205\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper-dim)\">obsoleto</text></svg>", "caption": "O registro 7 substituiu o registro 3. O antigo mantém o texto, e a linha de status é a única coisa que mudou; o novo diz o que substituiu. Quem cair em qualquer um dos dois consegue seguir a decisão nas duas direções."}
```

O registro 3 da Carreto mostra por quê. Quando a Renata começou o log, ela pediu ao Bruno que
escrevesse o lote semanal como ele era, reconstruído a partir do que as pessoas que o construíram
lembravam. Ele dizia por que um lote semanal tinha sido certo quando a Carreto era pequena: uma
pessoa do financeiro conciliava os pagamentos à mão às sextas, e o banco do monólito era a única
fonte de entregas. **Para aquela empresa, a decisão estava certa**, e o registro 3 diz isso. Quando o
registro 7 o substituiu, o Bruno mudou uma linha do registro 3, o status. Reescrevê-lo para descrever
eventos teria apagado o motivo de o lote existir, e a próxima pessoa a ler o código concluiria que
alguém um dia fez uma bobagem.

`tech-strategy` aula 17 acompanha um log assim ao longo de um ano inteiro, com numeração e tudo. O que
você precisa desta aula é a regra e o motivo: **um registro aceito é a declaração do que foi decidido
e por quê, num momento, e o momento não muda depois.**

## A sua parte como arquiteto

A Renata não escreveu o registro 7, e isso foi de propósito. **O arquiteto garante que o registro
exista, que as pessoas afetadas o revisaram e que ele seja encontrável**; quem digita importa menos,
e registros escritos pelos times ensinam os times a pensar em decisões, assunto ao qual a aula 11
volta. O que ela fez foi perguntar, no fim da sessão de trabalho, "quem escreve isto, e até quando?",
e ler o rascunho no pull request com uma pergunta na cabeça: alguém que não estava aqui conseguiria
acompanhar?
