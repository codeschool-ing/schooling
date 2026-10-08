---
title: A revisão, e quando fazê-la
version: 1
---

A última fase da resposta a incidentes é a mais pulada, e por um motivo compreensível: quando a recuperação
termina, os sistemas funcionam, as pessoas envolvidas estão cansadas, e o incidente parece encerrado. Não está.
**A fase de lições aprendidas é onde um incidente deixa de ser um custo e passa a ser um investimento**, e sem
ela a mesma fraqueza espera o próximo invasor.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"As seis fases da resposta a incidentes em sequência: preparação, identificação, contenção, erradicação, recuperação, lições aprendidas. Uma seta volta de lições aprendidas para preparação: o que a revisão acha vira a preparação do próximo incidente.\"><rect x=\"6\" y=\"40\" width=\"106\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"59\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">preparação</text><path d=\"M112 65 L124 65\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M124 65 L116.0 61.0 L116.0 69.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><rect x=\"124\" y=\"40\" width=\"106\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"177\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">identificação</text><path d=\"M230 65 L242 65\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M242 65 L234.0 61.0 L234.0 69.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><rect x=\"242\" y=\"40\" width=\"106\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"295\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">contenção</text><path d=\"M348 65 L360 65\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M360 65 L352.0 61.0 L352.0 69.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><rect x=\"360\" y=\"40\" width=\"106\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"413\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">erradicação</text><path d=\"M466 65 L478 65\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M478 65 L470.0 61.0 L470.0 69.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><rect x=\"478\" y=\"40\" width=\"106\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"531\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">recuperação</text><path d=\"M584 65 L596 65\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M596 65 L588.0 61.0 L588.0 69.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><rect x=\"596\" y=\"40\" width=\"106\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"649\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">lições aprendidas</text><path d=\"M653 90 L653 150 L59 150 L59 90\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M59 90 L55.0 98.0 L63.0 98.0 Z\" fill=\"var(--amber)\" stroke=\"none\"></path><text x=\"356\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">ações com dono e data</text></svg>", "caption": "A última fase escreve a primeira. Uma revisão cujas ações nunca chegam à preparação foi só uma reunião."}
```

O centro dela é uma reunião, a **revisão**, também chamada de **postmortem**. O NIST SP 800-61 recomenda
fazê-la **poucos dias** depois do fim do incidente: cedo o bastante para as pessoas lembrarem o que fizeram e
por quê, tarde o bastante para a recuperação já ter acabado. Para a quinta, a recuperação fechou em 2 de
outubro, e a revisão é em 6 de outubro.

Quem participa:

| quem | por quê |
|---|---|
| todos que trabalharam no incidente | sabem o que aconteceu, inclusive o que não está no registro |
| os donos dos sistemas envolvidos | decidem o que muda nos sistemas deles |
| um **facilitador** que não trabalhou no incidente | alguém cujo único trabalho é manter a reunião nas perguntas, não nas respostas |
| a patrocinadora executiva, pelo menos para as ações | algumas ações custam dinheiro, e só a patrocinadora pode aprovar isso |

As perguntas que o NIST sugere são uma boa pauta, nesta ordem: o que exatamente aconteceu, e quando; como a
equipe e os procedimentos se saíram; que informação era necessária mais cedo; se algum passo dificultou a
recuperação; o que a equipe faria diferente; e o que impediria um incidente parecido, ou o pegaria mais cedo.

**A reunião tem uma regra que faz todas as outras funcionarem: ela procura causas, não culpados.** A terceira
seção desta aula é sobre o porquê, e o que isso muda na prática.
