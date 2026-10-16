---
title: Detecção, e declarar um incidente
version: 1
---

Um incidente não é um evento técnico; é uma decisão. Os erros sobem, um alarme dispara, um cliente
escreve, e em algum momento alguém diz **"isto é um incidente"**, e a partir dali o jeito de a equipe
trabalhar muda: uma pessoa no comando, um lugar para conversar, atualizações com hora marcada. A falha
mais comum não é consertar devagar. É **declarar devagar**: quarenta minutos de três pessoas
investigando em conversas particulares, cada uma achando que outra está avisando os clientes.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"Uma linha com seis estágios de um incidente: impacto começa, detectado, declarado, mitigado, resolvido, revisado. Acima da linha, o intervalo do impacto à detecção tem o rótulo tempo para detectar, e da detecção à declaração tempo para declarar. Abaixo, o trecho do impacto à mitigação tem o rótulo tempo para mitigar, o que o cliente sente. Sob revisado: o próximo incidente começa aqui.\"><defs><marker id=\"lc-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"84\" width=\"100\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"70.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">impacto começa</text><path d=\"M121 110 L135 110\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lc-ah)\"></path><rect x=\"136\" y=\"84\" width=\"100\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></rect><text x=\"186.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">detectado</text><path d=\"M237 110 L251 110\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lc-ah)\"></path><rect x=\"252\" y=\"84\" width=\"100\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></rect><text x=\"302.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">declarado</text><path d=\"M353 110 L367 110\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lc-ah)\"></path><rect x=\"368\" y=\"84\" width=\"100\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"418.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">mitigado</text><path d=\"M469 110 L483 110\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lc-ah)\"></path><rect x=\"484\" y=\"84\" width=\"100\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"534.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">resolvido</text><path d=\"M585 110 L599 110\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lc-ah)\"></path><rect x=\"600\" y=\"84\" width=\"100\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></rect><text x=\"650.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">revisado</text><path d=\"M70 60 L186 60\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\"></path><text x=\"128.0\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">tempo para detectar</text><path d=\"M186 60 L302 60\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\"></path><text x=\"244.0\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">tempo para declarar</text><path d=\"M70 162 L418 162\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\"></path><text x=\"244.0\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">tempo para mitigar: o que o cliente sente</text><text x=\"650\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o próximo incidente</text><text x=\"650\" y=\"174\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">começa aqui</text></svg>", "caption": "Os clientes sentem o tempo até a mitigação. A resolução e a revisão vêm depois de o gráfico ficar verde."}
```

## Quem percebeu primeiro

A primeira pergunta de toda revisão é como o incidente foi detectado, e as respostas honestas caem em
três grupos, do melhor ao pior:

1. **um alerta num sintoma** (o composto da lição 10, a taxa de queima da lição 12) chamou quem estava
   de plantão;
2. **uma pessoa da equipe** percebeu um gráfico, uma linha de log, um deploy que falhou;
3. **um cliente** avisou.

O tempo do início do impacto até a detecção é o **tempo para detectar**, e o terceiro grupo é onde ele é
maior e onde a confiança se perde. Todo incidente que um cliente avisou primeiro é uma falha nos
alertas, e fechá-la é uma ação da revisão.

## Severidade, decidida rápido

Uma escala de severidade deixa quem declara dizer o tamanho sem reunião. Mantenha-a curta e defina-a
pelo impacto nos clientes, nunca pelo componente que quebrou:

| severidade | o impacto | o que vem depois |
|---|---|---|
| SEV1 | checkout ou login fora para a maioria dos clientes, ou dados em risco | chamar o comandante do incidente, página de status em 15 minutos |
| SEV2 | uma funcionalidade fora, ou o serviço inteiro degradado | chamar o plantão, página de status se os clientes perceberem |
| SEV3 | uma funcionalidade menor quebrada, com contorno | um chamado, resolvido em horário comercial |

**Na dúvida, declare a mais alta**: rebaixar custa uma mensagem, enquanto um incidente declarado abaixo
custa a hora em que ninguém estava no comando.

## Declare num lugar fixo

A declaração é uma mensagem num lugar combinado: um canal de incidente criado para ele, com um nome que
diz o quê e quando. Tudo sobre o incidente acontece ali, para quem chega no minuto quarenta ler o canal
em vez de interromper quem está consertando.
