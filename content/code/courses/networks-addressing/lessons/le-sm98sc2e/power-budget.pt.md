---
title: O orçamento de energia
version: 1
---

Um "switch PoE de 24 portas" não promete 24 portas com potência máxima. **Um switch PoE tem um
orçamento de energia, um total em watts dividido entre todas as portas**, e ele vem impresso na
folha de dados ao lado do número de portas, em geral menor do que o número de portas sugere. Ficar
sem ele não é uma pane: o switch recusa energia a uma porta, e um telefone que funcionava ontem fica
apagado hoje com o cabo conectado.

Os números abaixo são um exemplo calculado, não uma captura de laboratório: um switch hipotético de
24 portas com um orçamento PoE de **370 W**, e os números por porta da tabela da seção anterior.

## Fazendo as contas

Comece pelo teto. Se as 24 portas alimentassem um dispositivo Type 1 no máximo, precisariam de
24 × 15,4 W = **369,6 W**, logo abaixo do orçamento. Então este switch consegue dar potência
802.3af completa a todas as portas ao mesmo tempo, e nem um watt a mais. Vinte e quatro dispositivos
Type 2 a 30 W precisariam de 720 W, quase o dobro do que ele tem.

Agora uma planta de verdade. O switch alimenta:

| dispositivos | cada um reserva | quantidade | total |
| --- | --- | --- | --- |
| telefones de mesa, classe 2 | 7 W | 10 | 70 W |
| pontos de acesso, Type 2 (classe 4) | 30 W | 6 | 180 W |
| câmeras externas, Type 3 | 60 W | 2 | 120 W |
| **todos juntos** | | **18** | **370 W** |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"Duas barras numa escala de 0 a 400 watts, com uma linha de orçamento em 370 W. A primeira barra, o plano, são 10 telefones de mesa a 7 W cada, 70 W; 6 pontos de acesso a 30 W cada, 180 W; e 2 câmeras a 60 W cada, 120 W; juntos, exatamente 370 W. A segunda barra acrescenta um sétimo ponto de acesso, mais 30 W, que leva o total a 400 W e passa da linha do orçamento em 30 W.\"><text x=\"30\" y=\"34\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o plano: 18 dispositivos, 370 W</text><rect x=\"30.0\" y=\"46\" width=\"105.0\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"82.5\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">telefones, 70 W</text><rect x=\"135.0\" y=\"46\" width=\"270.0\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"270.0\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">6 pontos de acesso, 180 W</text><rect x=\"405.0\" y=\"46\" width=\"180.0\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"495.0\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">2 câmeras, 120 W</text><text x=\"30\" y=\"106\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">com um sétimo ponto de acesso: 400 W</text><rect x=\"30.0\" y=\"118\" width=\"105.0\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"82.5\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">telefones, 70 W</text><rect x=\"135.0\" y=\"118\" width=\"270.0\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"270.0\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">6 pontos de acesso, 180 W</text><rect x=\"405.0\" y=\"118\" width=\"180.0\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"495.0\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">2 câmeras, 120 W</text><rect x=\"585.0\" y=\"118\" width=\"45.0\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"607.5\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">+30 W</text><path d=\"M585.0 22 L585.0 164\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"579.0\" y=\"14\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\" font-weight=\"600\">orçamento 370 W</text><path d=\"M30 176 L630.0 176\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M30.0 176 L30.0 181\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"30.0\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0 W</text><path d=\"M180.0 176 L180.0 181\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"180.0\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">100 W</text><path d=\"M330.0 176 L330.0 181\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"330.0\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">200 W</text><path d=\"M480.0 176 L480.0 181\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"480.0\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">300 W</text><path d=\"M630.0 176 L630.0 181\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"630.0\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">400 W</text></svg>", "caption": "Um exemplo calculado, não uma captura. O plano usa o orçamento inteiro de 370 W do switch hipotético com seis portas ainda livres, então mais um dispositivo de 30 W é um dispositivo que o switch se recusa a alimentar.", "same": ["+30 W"]}
```

Dezoito dispositivos usam os 370 W inteiros, com seis portas ainda livres. **Portas e energia acabam
separadamente**, e aqui a energia acaba primeiro. Um sétimo ponto de acesso levaria o total a 400 W,
30 W acima, e alguma coisa ficaria sem energia.

Os telefones mostram por que as classes importam. Se eles anunciassem classe 0, ou classe 3, cada um
reservaria 15,4 W em vez de 7 W: 154 W para os dez em vez de 70 W, e o plano acima ficaria 84 W
acima do orçamento.

## O que o switch faz quando o orçamento não basta

Duas decisões ficam na configuração do switch, e vale tomar as duas de propósito.

**Como a energia é contada.** Um switch pode reservar o que a classe de cada porta permite, como a
tabela fez, ou contar o que cada dispositivo está puxando de fato naquele momento. Contar o consumo
real encaixa mais dispositivos no mesmo orçamento, já que um telefone que reserva 7 W pode puxar
menos. O risco é o dia em que o consumo sobe de uma vez: câmeras ligando os aquecedores numa noite
fria pedem o que sempre tiveram direito de pedir, e o orçamento que parecia folgado ao meio-dia fica
curto à meia-noite.

**Quais portas perdem.** As portas podem receber uma prioridade, e quando o orçamento é excedido o
switch recusa ou corta a energia das portas de menor prioridade primeiro. **Decida de antemão o que
se apaga.** Telefones que fazem chamadas de emergência, e os pontos de acesso das áreas que precisam
de cobertura, ficam no topo; uma tela decorativa, embaixo. Sem prioridades, o resultado é o que a
regra padrão do switch fizer, o que não é um plano.

Duas conferências práticas fecham o trabalho. Some os dispositivos planejados, com as classes, antes
de comprar o switch, e guarde parte do orçamento para o dispositivo que alguém acrescenta no ano que
vem. E lembre da fonte do próprio switch: o orçamento PoE vem além do que o switch precisa para
funcionar, e em alguns modelos é uma segunda fonte que aumenta o orçamento.
