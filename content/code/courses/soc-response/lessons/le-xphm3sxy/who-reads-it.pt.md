---
title: Quem lê, e para que serve
version: 1
---

O postmortem da aula 15 foi escrito para quem opera os sistemas, para mudar coisas. O **relatório do incidente** é
escrito para todo o resto, para explicar: a sócia-diretora e os sócios, os clientes cujos dados podem estar
envolvidos, a seguradora, o auditor, e se chegar a isso, a ANPD ou um juiz. É o documento que sobrevive ao
incidente, e daqui a um ano vai ser o único relato da quinta que a maioria dos leitores vai ver.

Isso impõe três requisitos:

- **Ele se sustenta sozinho.** Um leitor que não estava lá, e nunca ouviu as palavras `gw` ou SIEM, consegue
  acompanhar. Detalhe técnico vai para os apêndices, onde um especialista pode conferir.
- **Toda afirmação pode ser conferida.** Um fato tem uma fonte que o leitor poderia pedir para ver; um número tem a
  consulta que o produziu. O relatório é escrito supondo que alguém vai pedir.
- **Ele diz o quanto tem certeza.** O que está confirmado, o que é provável, o que não se sabe. A incerteza não é
  uma fraqueza do relatório; deixá-la de fora é.

O corpo dele segue uma cadeia, e cada elo se apoia só no anterior:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 170\" role=\"img\" aria-label=\"Quatro caixas ligadas da esquerda para a direita: fatos, cada um com uma fonte; impacto, o que os fatos significam para a empresa e para as pessoas; causa, por que foi possível; recomendação, o que impediria que acontecesse de novo. Cada caixa se apoia só na anterior.\"><rect x=\"10\" y=\"40\" width=\"160\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"90.0\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">fatos</text><text x=\"90.0\" y=\"83.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">cada um com fonte</text><path d=\"M170 75 L190 75\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M190 75 L182.0 71.0 L182.0 79.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><rect x=\"190\" y=\"40\" width=\"160\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"270.0\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">impacto</text><text x=\"270.0\" y=\"83.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o que os fatos significam</text><path d=\"M350 75 L370 75\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M370 75 L362.0 71.0 L362.0 79.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><rect x=\"370\" y=\"40\" width=\"160\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"450.0\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">causa</text><text x=\"450.0\" y=\"83.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">por que foi possível</text><path d=\"M530 75 L550 75\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M550 75 L542.0 71.0 L542.0 79.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><rect x=\"550\" y=\"40\" width=\"160\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"630.0\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">recomendação</text><text x=\"630.0\" y=\"83.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o que impede da próxima vez</text></svg>", "caption": "Uma recomendação sem causa por trás, ou um impacto sem fato, é uma opinião."}
```

Fatos, depois o que significam, depois por que aconteceu, depois o que fazer. Uma recomendação sem causa por trás
é um desejo; um impacto sem fato embaixo é um medo. O resto desta aula percorre os quatro elos em ordem, para a
quinta.
