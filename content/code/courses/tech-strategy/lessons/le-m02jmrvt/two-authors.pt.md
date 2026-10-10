---
title: Um roadmap, dois autores
version: 1
---

Até este ano, a Coreto tinha dois roadmaps. O roadmap de produto da Júlia Sato ia para o conselho e
para o time de vendas. A engenharia mantinha um roadmap técnico em outro documento, que o produto
tinha visto uma vez. **Os dois contavam com os mesmos 52 engenheiros**, e cada um parecia viável
sozinho. Juntos, pediam muito mais do que a empresa tinha, e ninguém conseguia ver isso, porque
ninguém lia os dois.

## Por que dois roadmaps falham em silêncio

Um roadmap técnico separado parece um avanço: o trabalho da engenharia está escrito e tem lugar. O
problema é o que vem depois. O produto planeja contando com o time inteiro, porque o roadmap dele
não menciona mais nada. A engenharia planeja o investimento dela contando com o mesmo time. O
conflito aparece sprint a sprint, numa discussão item a item atrás da outra, que a seção anterior
mostrou a engenharia perdendo.

Há também um problema de leitura. A aula 2 separou roadmap de estratégia: o roadmap diz o quê e em
que ordem. Um roadmap que deixa de fora metade do trabalho em andamento responde isso mal, e um
conselho que lê só a metade de produto conclui que a engenharia entrega menos do que entrega.

## Um documento, duas raias

A correção é um roadmap só, com dois autores. **A Júlia escreve os temas de produto e o Davi escreve
os temas de engenharia**, no mesmo documento, nas mesmas três colunas.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 736 344\" role=\"img\" aria-label=\"O roadmap da Coreto como uma grade de três colunas, Agora, Depois e Mais tarde, e duas raias. Temas de produto, escritos pela Júlia: agora, Pix parcelado e a descoberta dos mapas de festival; depois, a construção dos mapas de festival; mais tarde, API para parceiros. Temas de engenharia, escritos pelo Davi: agora, reservas sem travas de linha, com a capacidade inteira do time de Reservas, e o teste de carga da abertura; depois, um portão de teste de carga no lugar do congelamento, e levar a busca para o serviço hospedado; mais tarde, rever a divisão do monólito e o framework de front-end. Uma seta vai de reservas sem travas de linha, na raia de engenharia, até a construção dos mapas de festival, na coluna depois da raia de produto.\"><defs><marker id=\"road-pt-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><text x=\"214.0\" y=\"32\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"14\" font-weight=\"600\" fill=\"var(--phosphor)\">Agora</text><text x=\"416.0\" y=\"32\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"14\" font-weight=\"600\" fill=\"var(--phosphor)\">Depois</text><text x=\"618.0\" y=\"32\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"14\" font-weight=\"600\" fill=\"var(--phosphor)\">Mais tarde</text><text x=\"60\" y=\"98\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Temas de</text><text x=\"60\" y=\"114\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">produto</text><text x=\"60\" y=\"138\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">Júlia</text><path d=\"M10 190 L726 190\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"4 4\"></path><text x=\"60\" y=\"246\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Temas de</text><text x=\"60\" y=\"262\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">engenharia</text><text x=\"60\" y=\"286\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">Davi</text><rect x=\"122\" y=\"58\" width=\"184\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"214.0\" y=\"89\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Pix parcelado</text><rect x=\"122\" y=\"120\" width=\"184\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"214.0\" y=\"142\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Mapas de festival:</text><text x=\"214.0\" y=\"160\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">descoberta</text><rect x=\"324\" y=\"58\" width=\"184\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"416.0\" y=\"80\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Mapas de festival:</text><text x=\"416.0\" y=\"98\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">a construção</text><rect x=\"526\" y=\"58\" width=\"184\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"618.0\" y=\"89\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">API para parceiros</text><rect x=\"122\" y=\"206\" width=\"184\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"214.0\" y=\"228\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Reservas sem travas de linha</text><text x=\"214.0\" y=\"246\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">Reservas: time inteiro</text><rect x=\"122\" y=\"268\" width=\"184\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"214.0\" y=\"299\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Teste de carga da abertura</text><rect x=\"324\" y=\"206\" width=\"184\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"416.0\" y=\"228\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Portão de teste de carga</text><text x=\"416.0\" y=\"246\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">no lugar do congelamento</text><rect x=\"324\" y=\"268\" width=\"184\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"416.0\" y=\"290\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Levar a busca para</text><text x=\"416.0\" y=\"308\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">o serviço hospedado</text><rect x=\"526\" y=\"206\" width=\"184\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"618.0\" y=\"228\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Rever a divisão</text><text x=\"618.0\" y=\"246\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">do monólito</text><rect x=\"526\" y=\"268\" width=\"184\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"618.0\" y=\"299\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Framework de front-end</text><path d=\"M308 232 C320 232, 310 84, 321 84\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#road-pt-ah)\"></path></svg>", "caption": "Um roadmap, duas raias, três colunas e nenhuma data. A seta entre as raias é o motivo de os mapas de festival estarem em depois: eles precisam do caminho de reserva que a raia de engenharia está corrigindo agora.", "same": ["Júlia", "Davi"]}
```

Três escolhas dão forma a ele.

**Temas, não funcionalidades.** "Organizadores de festival conseguem vender áreas reservadas" é um
tema. "Um componente de mapa de assentos para festivais" é uma funcionalidade, uma resposta possível
a ele. Um tema enuncia um problema que vale resolver e deixa a descoberta livre para achar a
solução; a seção anterior desta aula mostrou por que essa liberdade importa. Os temas de engenharia
seguem a mesma regra: "As reservas de assento aguentam uma abertura de vendas" é um tema, e reservar
assentos sem travas de linha é a resposta que o ADR-0006 escolheu.

**Agora, depois, mais tarde, e sem datas.** Agora é o que os times estão fazendo neste trimestre.
Depois é o que eles esperam começar quando algo do agora terminar. Mais tarde é intenção real, sem
compromisso. **As colunas são uma ordem, não um cronograma.** Quando alguém precisa de uma data para um
item, a resposta honesta é um intervalo com uma confiança associada, e a aula 11 de
`delivery-metrics` trata de como produzi-lo e de como ter essa conversa. Esta aula para por aí.

**Setas entre as raias.** A seta de "Reservas sem travas de linha" para "Mapas de festival" é a
linha mais útil do documento. Ela diz a quem lê do lado do produto por que os mapas
de festival estão em depois e não em agora, e diz isso numa forma que dispensa um engenheiro para
explicar. Antes, a mesma dependência morava na cabeça do Mateus e teria aparecido numa data perdida.

## As proporções seguem a divisão

A raia de engenharia não é livre para crescer. Seus temas precisam caber na fatia de capacidade
acordada na seção anterior, e a raia de produto preenche o resto. Se a raia do Davi tiver mais do
que a fatia aguenta, o roadmap mostra isso num relance, e a conversa acontece na revisão trimestral,
e não no meio de uma sprint.

A exceção também fica visível. Os dois trimestres do time de Reservas no caminho de reserva ocupam a
raia de engenharia marcados como a capacidade de um time inteiro, porque a estratégia os pôs fora da divisão. Quem conhece o
acordo consegue conferir o desenho contra ele.

## Como dois autores trabalham juntos

Dois autores precisam de regras para discordar, ou o roadmap volta a ser dois documentos num
arquivo. As da Coreto são curtas.

1. Cada autor é dono da sua raia. A Júlia não reordena temas de engenharia, e o Davi não reordena
   temas de produto.
2. Um tema muda de coluna só quando os dois concordam, porque uma mudança numa raia altera o que a
   outra consegue fazer.
3. Uma seta entre as raias é acrescentada por quem descobre a dependência, e removida só pelo autor
   do tema de onde ela parte.
4. Quando não chegam a acordo, a discordância vai para a Helena Prates e o CEO juntos, com o argumento
   de cada lado por escrito.

Eles o apresentam juntos na revisão trimestral, a Júlia primeiro. **O conselho vê um roadmap e duas
pessoas respondendo por ele**, e quando alguém pergunta por que os mapas de festival não estão em
agora, a resposta vem do lado do produto, apontando para um tema de engenharia.

## O que muda para a engenharia

A engenharia abre mão de algo nesse arranjo. Um roadmap técnico escrito só por ela era um lugar onde
cabia todo investimento que ela queria. No documento compartilhado, cada tema de engenharia disputa
um lugar numa raia de largura fixa, e o produto lê os motivos. Alguns temas que passaram um ano
parados no roadmap técnico antigo caíram na primeira revisão, porque ninguém conseguia dizer que
problema eles resolviam.

O que ela ganha em troca é maior. O trabalho de engenharia passa a fazer parte do plano com que a
empresa se compromete, em vez de uma lista que perde toda sprint. E quando o caminho de reserva for
corrigido e os mapas de festival forem lançados, o roadmap mostra que um tornou o outro possível. A
aula 19 parte daqui: dizer não a um pedido fica mais fácil quando o roadmap já mostra o que o sim
desalojaria.
