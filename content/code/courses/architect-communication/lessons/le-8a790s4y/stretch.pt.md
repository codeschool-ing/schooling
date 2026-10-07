---
title: Desafio, com rede de proteção
version: 1
---

**As pessoas crescem com trabalho um pouco além do que conseguem fazer sozinhas, com ajuda perto o
bastante para alcançar.** Fácil demais, e nada se aprende; longe demais, e a pessoa falha em público
e aprende a evitar o próximo desafio. A habilidade do mentor é escolher a distância e continuar ao
alcance.

## A zona onde o aprendizado acontece

O psicólogo Lev Vygotsky chamou de *zona de desenvolvimento proximal* o espaço entre o que um
aprendiz consegue fazer sozinho e o que consegue fazer com ajuda. O assunto dele eram crianças, e a
ideia se transfere bem: uma tarefa dentro da zona é uma que Diego ainda não conseguiria terminar
sozinho, mas consegue com uma ou duas perguntas na hora certa.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Três círculos aninhados. O de dentro, sozinho: o que o Diego já consegue, como escrever o código. O anel do meio, com ajuda: liderar a mudança de horários de entrega. O anel de fora, ainda não: redesenhar as cotas de todos.\"><defs><marker id=\"zpd-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><circle cx=\"300\" cy=\"135\" r=\"120\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></circle><circle cx=\"300\" cy=\"135\" r=\"78\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></circle><circle cx=\"300\" cy=\"135\" r=\"40\" fill=\"var(--ink)\" stroke=\"var(--wire)\"></circle><text x=\"300\" y=\"129\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">sozinho</text><text x=\"300\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">já consegue</text><text x=\"300\" y=\"77\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">com ajuda</text><text x=\"300\" y=\"37\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">ainda não</text><path d=\"M470 135 L326 135\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#zpd-ah)\"></path><text x=\"480\" y=\"135\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">escrever o código</text><path d=\"M470 80 L358 95\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#zpd-ah)\"></path><text x=\"480\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">liderar a mudança de horários</text><path d=\"M470 30 L392 59\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#zpd-ah)\"></path><text x=\"480\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">redesenhar as cotas de todos</text></svg>", "caption": "A zona de desenvolvimento proximal de Vygotsky, aplicada a três partes do trabalho do Diego. Uma tarefa de crescimento fica no anel do meio."}
```

Liderar a mudança de horários de entrega estava na zona de Diego. Escrever o código estava abaixo
dela: isso ele já sabia fazer. Desenhar a mudança nas cotas do banco de pedidos, que afeta todos os
times, estaria acima: havia incógnitas demais para uma pergunta só destravar.

## Quanto entregar

Dentro de uma tarefa de crescimento, o mentor decide quanto da decisão entregar, e isso pode mudar
passo a passo. Uma escada útil, do que entrega menos ao que entrega mais:

1. **"Faça isto, deste jeito."** Para as partes em que um erro sai caro e o aprendizado é pequeno.
2. **"Investigue e me diga o que você faria; eu decido."**
3. **"Decida, e me avise antes de agir."**
4. **"Decida e aja; me conte depois."**
5. **"Decida e aja; não precisa me contar."**

Na mudança de horários de entrega, Diego estava no 3 para o design e no 4 para o código. A migração
do banco ficou no 2, porque um erro ali chega à produção para todo mundo. **Dizer em voz alta qual
nível vale para qual parte evita as duas piores surpresas**: o júnior que espera uma permissão que já
tinha, e o que age sobre algo que deveria ter conferido.

## A rede

Um desafio sem rede é uma prova. A rede tem três partes:

- **disponibilidade**: Diego sabe que pode perguntar, e a regra das duas horas faz com que ele
  pergunte;
- **uma revisão antes de importar**: Lívia leu o documento de design antes do time, então a primeira
  versão pública já era boa;
- **uma falha que dá para sobreviver**: a mudança foi primeiro para 5% dos clientes. Um erro ali é
  uma lição, não um incidente.

## Quando dá errado

Vai dar, às vezes. A mudança de horários de entrega saiu com um bug na forma de mostrar horários
perto da meia-noite, encontrado no rollout de 5%. A reação de Lívia importa mais do que o bug.
**Pergunte o que aconteceu e o que ele faria diferente antes de dizer qualquer outra coisa**, e depois
ajude com a correção se ele pedir. São as mesmas perguntas de uma revisão sem culpados (aula 15), na
escala de uma pessoa.
