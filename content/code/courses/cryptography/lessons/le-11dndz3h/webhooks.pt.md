---
title: Conferindo um webhook direito
version: 1
---

**Um webhook é uma requisição que um serviço manda para o seu servidor quando algo acontece, e o
seu servidor precisa tratá-la como hostil até a assinatura conferir.** A URL é pública, ou pelo
menos adivinhável; qualquer um na internet pode mandar JSON para ela. O HMAC é a única coisa que
separa as mensagens do gateway das de todo mundo.

## O cabeçalho que o gateway manda

Cada entrega traz um cabeçalho ao lado do corpo. O laboratório o guarda num arquivo `.sig`:

```
ana@lab:~/lab$ cat data/webhooks/evt-1.sig
t=1781535558,v1=6c7cdc5299209a4260988b908954ed6dcd8c3809dff59fa053eb98a6114ab61f
```

Dois campos. `t` é quando o gateway assinou, em segundos desde 1970, e `v1` é a etiqueta
HMAC-SHA256. O que o gateway assina não é o corpo sozinho, mas **o carimbo de tempo, um ponto e o
corpo**. A etiqueta pode ser recalculada à mão a partir dessas três partes, e ela bate:

```
ana@lab:~/lab$ printf '%s.' 1781535558 | cat - data/webhooks/evt-1.json | openssl dgst -sha256 -mac HMAC -macopt hexkey:$(cat keys/webhook.hex) -r
6c7cdc5299209a4260988b908954ed6dcd8c3809dff59fa053eb98a6114ab61f *stdin
```

Esse é o mesmo esquema que a maioria dos gateways de pagamento e muitos produtos SaaS usam, com
pequenas diferenças no nome do cabeçalho. A documentação deles sempre diz exatamente quais bytes são
assinados, e errar isso é o motivo de costume para uma implementação correta recusar todas as
mensagens.

## Quatro entregas

O laboratório tem quatro entregas, e o `vcrypt webhook` confere cada uma como o portal deveria, com
o relógio do receptor passado em `--now`:

```
ana@lab:~/lab$ vcrypt webhook --key keys/webhook.hex --now 1781535600 data/webhooks/*.json
evt-1.json   ACCEPT  signature valid, timestamp within the window
evt-2.json   REJECT  signature does not match the body
evt-3.json   REJECT  signed 86400 s ago, outside the 300 s window
evt-4.json   REJECT  signature does not match the body
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"As verificações do receptor sobre um webhook, em ordem. Primeiro, separar o cabeçalho em t e v1; um cabeçalho ausente ou malformado é recusado. Segundo, recalcular o HMAC-SHA256 com a chave compartilhada sobre t, um ponto e o corpo bruto. Terceiro, comparar com v1 em tempo constante; uma diferença é recusada, o que pega a evt-2 e a evt-4. Quarto, conferir se t está a até 300 segundos do relógio do receptor; fora disso é repetição, o que pega a evt-3. Só então interpretar o JSON e agir, como com a evt-1.\"><defs><marker id=\"wh-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"wh-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"40\" y=\"20\" width=\"360\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"56\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">1  ler t e v1 do cabeçalho</text><polyline points=\"220,56 220,72\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#wh-ah-wire)\"></polyline><polyline points=\"400,38 488,38\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#wh-ah-amber)\"></polyline><rect x=\"490\" y=\"20\" width=\"200\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"506\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">RECUSA: malformado</text><rect x=\"40\" y=\"74\" width=\"360\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"56\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">2  HMAC-SHA256(chave, t + &quot;.&quot; + corpo bruto)</text><polyline points=\"220,110 220,126\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#wh-ah-wire)\"></polyline><rect x=\"40\" y=\"128\" width=\"360\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"56\" y=\"146\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">3  comparar com v1, em tempo constante</text><polyline points=\"220,164 220,180\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#wh-ah-wire)\"></polyline><polyline points=\"400,146 488,146\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#wh-ah-amber)\"></polyline><rect x=\"490\" y=\"128\" width=\"200\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"506\" y=\"146\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">RECUSA: evt-2, evt-4</text><rect x=\"40\" y=\"182\" width=\"360\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"56\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">4  |agora - t| no máximo 300 s</text><polyline points=\"220,218 220,234\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#wh-ah-wire)\"></polyline><polyline points=\"400,200 488,200\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#wh-ah-amber)\"></polyline><rect x=\"490\" y=\"182\" width=\"200\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"506\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">RECUSA: evt-3, repetição</text><rect x=\"40\" y=\"236\" width=\"360\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"56\" y=\"254\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">5  interpretar o JSON e agir</text><text x=\"506\" y=\"254\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">evt-1: ACEITA</text></svg>", "caption": "Todas as verificações antes da primeira que lê os campos do corpo."}
```

- **evt-1** é genuína e chegou 42 segundos depois de assinada. Aceita.
- **evt-2** teve o valor alterado depois de assinada. A etiqueta não bate mais com o corpo.
  Recusada.
- **evt-3** é a evt-1 de novo, byte a byte, com sua etiqueta original e perfeitamente válida,
  entregue um dia depois. A assinatura está certa; o carimbo de tempo não. Recusada como repetição.
- **evt-4** foi assinada, mas com uma chave que não é a do gateway. Recusada, com o mesmo motivo da
  evt-2: do lado de quem recebe, uma chave errada e um corpo alterado parecem iguais.

## Por que o carimbo de tempo fica dentro da assinatura

Sem o carimbo de tempo, a evt-3 seria aceita: uma mensagem válida continua válida para sempre,
então quem gravasse um "pagamento confirmado" poderia mandá-lo de novo quando quisesse. Pôr o `t`
**dentro** dos bytes assinados significa que ele não pode ser alterado sem quebrar a etiqueta, e
recusar tudo o que foi assinado há mais de cinco minutos fecha a janela. Cinco minutos dão conta de
relógios que discordam um pouco e das novas tentativas do gateway. Sistemas mais rígidos também
lembram os ids dos eventos que já processaram e recusam uma repetição dentro da janela, que é a
defesa completa contra repetição.

## A comparação em si

O último passo, comparar a etiqueta calculada com a recebida, precisa ser em **tempo constante**.
Uma comparação comum retorna no primeiro caractere diferente, então uma requisição cuja etiqueta
começa com o caractere certo leva um pouco mais para ser recusada do que uma que não começa. Ao
longo de muitas requisições essa diferença pode ser medida, e ela permitiria a alguém achar uma
etiqueta válida um caractere por vez, sem a chave. O `hmac.compare_digest` do Python e o
`crypto/subtle.ConstantTimeCompare` do Go levam o mesmo tempo quaisquer que sejam as entradas; o
verificador do laboratório usa o primeiro. Aqui, diferente do que ocorre com hashes de senha, o
atacante escolhe a entrada, então isso não é opcional.

A ordem das verificações também importa: confira a etiqueta **antes** de interpretar o JSON ou agir
sobre qualquer campo dele. Um interpretador alimentado por um estranho não autenticado é superfície
de ataque, e um tratador que lê o valor antes de conferir a etiqueta já confiou nele.
