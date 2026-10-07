---
title: Por que o sim é a resposta cara
version: 1
---

**Todo sim gasta uma capacidade que já estava prometida a outra coisa, então um sim também é um não,
dito em silêncio a quem perde.** Quem pede vê só o sim. As pessoas cujo trabalho atrasa descobrem
depois, quase sempre sem ninguém explicar por quê, e quem disse sim não é quem vai explicar.

Na terça-feira, 10 de novembro, Otávio, o CEO da Marola, passa pela área do time de checkout. Um
concorrente anunciou "ofertas relâmpago" para a Black Friday, em 27 de novembro: produtos com
desconto grande durante uma hora, uma contagem regressiva na tela inicial e estoque reservado para
quem colocar o item na cesta primeiro. "Dá para a gente ter isso até a Black Friday?" Todo mundo
olha para Bruna, e Bruna olha para Lívia.

## A conta que ninguém faz no corredor

O time de Bruna tem cinco engenheiros. De 10 de novembro até a véspera da Black Friday, são doze
dias úteis para cada um, descontado o feriado nacional de 20 de novembro: **60 dias-engenheiro**.
Já comprometido para esses dias, antes de Otávio aparecer:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Uma barra horizontal de dias-engenheiro. Já comprometidos: teste de carga 20, pagamentos 8, fluxo de substituição 15, plantão 12, somando 55. Uma linha vertical marca a capacidade de 60 dias-engenheiro. Um trecho tracejado de 30 para as ofertas relâmpago, se a resposta for sim, leva o total a 85, bem além da linha.\"><defs><marker id=\"capacity-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"30\" y=\"60\" width=\"137\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"98.5\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">20</text><text x=\"32\" y=\"116\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">teste de carga</text><rect x=\"170\" y=\"60\" width=\"53\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"196.5\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">8</text><text x=\"172\" y=\"132\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">pagamentos</text><rect x=\"226\" y=\"60\" width=\"102\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"277.0\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">15</text><text x=\"228\" y=\"116\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">substituição</text><rect x=\"331\" y=\"60\" width=\"81\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"371.5\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">12</text><text x=\"333\" y=\"132\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">plantão</text><rect x=\"415\" y=\"60\" width=\"207\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"5 3\"></rect><text x=\"518.5\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">30</text><text x=\"419\" y=\"116\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">ofertas relâmpago, se sim</text><path d=\"M450 30 L450 57\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></path><path d=\"M450 140 L450 160\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></path><text x=\"450\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">capacidade: 60 dias-engenheiro</text><text x=\"30\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">já comprometidos: 55</text><text x=\"625\" y=\"170\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">85</text><text x=\"30\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">dias-engenheiro do time de checkout, de 10 de novembro à Black Friday</text></svg>", "caption": "O sim do corredor, desenhado. O que o Otávio vê é o bloco tracejado; o que escorrega é tudo à esquerda dele, no mês mais movimentado do ano."}
```

- o teste de carga da Black Friday e as correções que ele revelar, porque todo ano revela alguma
  coisa: uns 20 dias-engenheiro;
- a atualização obrigatória do provedor de pagamentos, com prazo em 30 de novembro: uns 8;
- a última etapa do fluxo de substituição, prometida às lojas para dezembro: uns 15;
- plantão, dúvidas do suporte e as interrupções normais de um time no seu mês mais cheio: uns 12.

São 55 dos 60 antes de qualquer coisa nova.

A estimativa de Lívia para as ofertas relâmpago completas, com reserva de estoque, é de **uns 30
dias-engenheiro**. E a lógica de reserva é o tipo de mudança que mais precisa de teste sob carga,
justamente o que tem menos tempo para acontecer. Um sim no corredor põe o time com 85 dias de
trabalho em 60, muito acima da sua capacidade, no mês em que um incidente custa mais caro.

## Por que as pessoas dizem sim mesmo assim

- **O não parece uma recusa à pessoa**, ainda mais quando é o CEO, e o sim parece lealdade.
- **O custo do sim chega depois**, numa data que escorrega em outro lugar; o custo do não chega
  agora, num silêncio constrangedor.
- **O sim é fácil de dizer de forma vaga** ("vamos fazer o possível"), enquanto o não precisa ser
  explicado.

O terceiro motivo é o perigoso. **Um sim vago é a pior resposta de todas**: quem pediu planeja em
cima dele, o time não consegue entregar, e a decepção chega no dia que mais importa, quando já não
há o que fazer. Um não claro em 10 de novembro deixa dezessete dias para fazer outra coisa; um
"vamos tentar" que falha em 26 de novembro não deixa nenhum.

## O trabalho não é dizer não

Nada disso é um argumento para recusar. O pedido de Otávio é razoável: um concorrente tem uma
funcionalidade, a Black Friday é o maior dia do ano, e o CEO quer que a Marola dispute. **O trabalho
é tornar a troca visível, para que a pessoa com autoridade para escolher escolha entre opções
reais**, e não entre um sim que não dá para cumprir e um não que soa como obstrução. O resto desta
aula é sobre como fazer isso.
