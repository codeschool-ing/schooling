---
title: O registro de riscos
version: 1
---

As aulas 3 a 11 produziram um conjunto de arquivos: ameaças, requisitos, riscos, controles, um plano.
Um **registro de riscos** é como uma organização chama o lugar onde tudo isso se junta, uma linha por
risco, com **quem é dono, o que foi decidido, e quando vai ser revisto**. A maioria das organizações
mantém um, muitas numa planilha que ninguém abre desde a auditoria.

### O que uma linha guarda

| campo | por que está ali | na Vereda |
|---|---|---|
| **id e descrição** | para ser apontado a partir de todo o resto | T14, um PDF preparado atacando um computador da clínica |
| **dono** | uma pessoa, com nome, que responde por ele | daniel |
| **estimativa** | perda esperada, e o ano ruim quando importa | R$ 9.000 por ano; R$ 388.419 um ano em cem |
| **decisão** | mitigar, eliminar, transferir ou aceitar | aceitar |
| **o registro da decisão** | onde o raciocínio mora | RA-001 |
| **data de revisão** | quando alguém precisa olhar de novo | 2027-04-01 |
| **situação** | aberto, decidido, feito, fechado | decidido |

O campo do dono é o que faz o trabalho. **Um risco cujo dono é "a TI" ou "a equipe" não tem dono**, e
quando a data de revisão chega não há ninguém cujo trabalho seja perceber.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" data-fig=\"l12-lifecycle\" aria-label=\"A vida de um risco no registro. Identificado, depois estimado, depois decidido: mitigar, eliminar, transferir ou aceitar. Uma mitigação é construída e verificada; uma transferência é assinada num contrato; um aceite é assinado pelo dono com data de revisão. Todos chegam à revisão, e uma revisão manda o risco de volta para ser estimado de novo ou o fecha.\"><defs><marker id=\"l12-lifecycle-tm-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l12-lifecycle-tm-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"30.0\" width=\"110.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"75.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">identificado</text><rect x=\"160.0\" y=\"30.0\" width=\"110.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"215.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">estimado</text><rect x=\"300.0\" y=\"30.0\" width=\"110.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"355.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">decidido</text><rect x=\"450.0\" y=\"10.0\" width=\"250.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"575.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">mitigar ou eliminar: construído, verificado</text><rect x=\"450.0\" y=\"60.0\" width=\"250.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"575.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">transferir: um contrato assinado</text><rect x=\"450.0\" y=\"110.0\" width=\"250.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"575.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">aceitar: assinado, com data de revisão</text><rect x=\"300.0\" y=\"190.0\" width=\"110.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"355.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">revisado</text><rect x=\"160.0\" y=\"190.0\" width=\"110.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"215.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">fechado</text><path d=\"M130.0 50.0 L160.0 50.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-lifecycle-tm-ah-paper-dim)\"></path><path d=\"M270.0 50.0 L300.0 50.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-lifecycle-tm-ah-paper-dim)\"></path><path d=\"M410.0 45.0 L430.0 45.0 L430.0 30.0 L450.0 30.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-lifecycle-tm-ah-paper-dim)\"></path><path d=\"M410.0 50.0 L450.0 80.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-lifecycle-tm-ah-paper-dim)\"></path><path d=\"M410.0 58.0 L430.0 58.0 L430.0 130.0 L450.0 130.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-lifecycle-tm-ah-paper-dim)\"></path><path d=\"M575.0 150.0 L575.0 210.0 L410.0 210.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-lifecycle-tm-ah-paper-dim)\"></path><path d=\"M300.0 210.0 L270.0 210.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-lifecycle-tm-ah-paper-dim)\"></path><path d=\"M355.0 190.0 L355.0 160.0 L215.0 160.0 L215.0 70.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l12-lifecycle-tm-ah-amber)\"></path><text x=\"285.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--amber)\">estimar de novo</text></svg>", "caption": "Todo caminho pelo registro termina numa revisão. Um risco que chegou a \"decidido\" e parou ali é um risco que ninguém está olhando."}
```

### O registro da Vereda é o repositório

A Vereda não mantém uma planilha separada. O registro dela são os arquivos das aulas anteriores:
`threats.csv` para os ids e descrições, `risks.csv` para as estimativas, e uma pasta de registros de
decisão para o dono, a decisão, o raciocínio e a data de revisão. Cada mudança é um commit com data e
autor. A vantagem sobre uma planilha não é o formato; é que **o registro muda no mesmo lugar, e na
mesma revisão, que o sistema que ele descreve**. A aula 15 usa exatamente isso.

### Todo risco tem uma decisão, inclusive "ainda não"

Um registro com células de decisão em branco é uma lista de preocupações. A regra na Vereda é que todo
risco nele tem uma das quatro decisões, ou a entrada explícita *não decidido, prazo* uma data, com um
dono. Essa última forma é permitida e útil: diz que alguém sabe que a decisão falta e quando ela vai
ser tomada.
