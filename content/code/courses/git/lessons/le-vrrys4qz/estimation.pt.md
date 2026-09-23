---
title: Estimando, e para que serve o número
version: 1
---

Quando um ticket fica pronto para começar, a maioria das equipes dá um tamanho a ele. O tamanho ajuda a
planning (aula 18) a decidir quanto cabe num sprint, e diz ao product owner quanto um ticket custa antes de
ele decidir quão importante é.

## Pontos, não horas

Muitas equipes estimam em **story points**, uma unidade sem significado a não ser em relação a outros
tickets. Um 2 é mais ou menos o dobro de um 1; um 5 é visivelmente maior que um 3. A escala de costume é
**1, 2, 3, 5, 8, 13**: os intervalos crescem porque a incerteza cresce, e ninguém consegue honestamente
separar um 9 de um 10.

Por que não horas? Porque as pessoas são ruins em prever quanto algo vai levar e razoavelmente boas em dizer
se é maior ou menor que algo que já fizeram. *"Como o aviso de feriado, mas com um formulário"* é uma
estimativa que qualquer um faz. *"Onze horas"* é um palpite vestido de medida, e vira prazo no momento em
que alguém anota.

Um **13 é um sinal, não um tamanho**: em geral quer dizer que o ticket está grande ou vago demais, e ele
volta para o refinamento para ser dividido.

## Planning poker

O jeito mais conhecido de estimar é o **planning poker**. Todo mundo que vai construir ou testar o ticket
segura uma carta com cada número, lê o ticket, e **todo mundo mostra ao mesmo tempo**. Mostrar junto é o
ponto inteiro: ninguém se ancora no primeiro número dito em voz alta, e a preocupação de uma pessoa quieta
tem o mesmo peso que o palpite de uma pessoa confiante.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Uma rodada de planning poker no ticket pagar com Pix. Na primeira rodada, a Ana mostra 3, o Bruno 13, a Carla 3 e o Diego 5. Depois da conversa, em que o Bruno explica que um estorno é um formulário manual no banco, a segunda rodada é 8, 8, 8 e 8.\"><defs><marker id=\"pk-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">primeira rodada</text><rect x=\"220\" y=\"30\" width=\"56\" height=\"60\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"248\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"18\" font-weight=\"600\" fill=\"var(--paper)\">3</text><text x=\"248\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Ana</text><rect x=\"330\" y=\"30\" width=\"56\" height=\"60\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"358\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"18\" font-weight=\"600\" fill=\"var(--amber)\">13</text><text x=\"358\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Bruno</text><rect x=\"440\" y=\"30\" width=\"56\" height=\"60\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"468\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"18\" font-weight=\"600\" fill=\"var(--paper)\">3</text><text x=\"468\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Carla</text><rect x=\"550\" y=\"30\" width=\"56\" height=\"60\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"578\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"18\" font-weight=\"600\" fill=\"var(--paper)\">5</text><text x=\"578\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Diego</text><text x=\"20\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">depois da conversa</text><rect x=\"220\" y=\"170\" width=\"56\" height=\"60\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"248\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"18\" font-weight=\"600\" fill=\"var(--paper)\">8</text><text x=\"248\" y=\"244\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Ana</text><rect x=\"330\" y=\"170\" width=\"56\" height=\"60\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"358\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"18\" font-weight=\"600\" fill=\"var(--paper)\">8</text><text x=\"358\" y=\"244\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Bruno</text><rect x=\"440\" y=\"170\" width=\"56\" height=\"60\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"468\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"18\" font-weight=\"600\" fill=\"var(--paper)\">8</text><text x=\"468\" y=\"244\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Carla</text><rect x=\"550\" y=\"170\" width=\"56\" height=\"60\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"578\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"18\" font-weight=\"600\" fill=\"var(--paper)\">8</text><text x=\"578\" y=\"244\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Diego</text><path d=\"M358 118 L358 164\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pk-ah)\"></path><text x=\"372\" y=\"141\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">o Bruno sabia que estorno é um formulário manual no banco</text></svg>", "caption": "O número que discordou trazia a informação. Sem a rodada, o 13 do Bruno teria sido uma preocupação calada.", "same": ["Ana", "Bruno", "Carla", "Diego"]}
```

A primeira rodada em *pagar com Pix* foi 3, 13, 3, 5. A equipe não tira a média. Quem deu o maior e o menor
explica o número, e o 13 do Bruno era uma informação que ninguém mais tinha: estorno é um formulário manual
no banco, então todo pagamento por Pix precisa de um jeito de ser desfeito à mão. Depois de dois minutos de
conversa, a segunda rodada concorda em 8, e o ticket ganha um critério de aceite sobre estorno.

## Uma estimativa não é uma promessa

Os pontos somados ao longo de um sprint dão a **velocidade** (*velocity*) da equipe: mais ou menos quanto
ela termina em duas semanas. É útil para a equipe planejar o próximo sprint, e prejudicial no momento em que
é usada para comparar equipes ou julgar pessoas, porque os pontos são relativos a uma equipe e qualquer um
pode inflá-los. Algumas equipes dispensam números e só conferem se cada ticket é pequeno, e planejam igual.

O que toda versão compartilha é a conversa. **Uma equipe que estima em silêncio não aprende nada; uma
equipe que discute um 3 e um 13 acha o problema do estorno na terça, não em produção.**
