---
title: O quadrante de Fowler
version: 1
---

Perguntar "esta dívida é boa ou ruim?" rende uma discussão e nenhuma resposta. Martin Fowler, num
ensaio curto de 2009, dividiu a pergunta em duas e desenhou as respostas como um quadrado. **A dívida
foi tomada de propósito, ou sem o time perceber? E foi prudente, ou imprudente?** Duas perguntas com
duas respostas cada dão quatro tipos de dívida, e cada tipo pede uma resposta diferente.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 390\" role=\"img\" aria-label=\"Um quadrado de dois por dois. Colunas: deliberada e inadvertida. Linhas: imprudente e prudente. Imprudente e deliberada: não temos tempo para desenho; a suíte ponta a ponta instável da Coreto. Imprudente e inadvertida: o que é separar em camadas; a réplica antiga de relatórios da Coreto. Prudente e deliberada: precisamos entregar agora e lidar com as consequências; o gerador de ingressos em PDF feito à mão da Coreto. Prudente e inadvertida: agora sabemos como deveríamos ter feito; o travamento das reservas de assento da Coreto. Embaixo: como a dívida foi tomada, não quanto ela custa.\"><text x=\"257.5\" y=\"44\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"14\" font-weight=\"600\" fill=\"var(--paper)\">Deliberada</text><text x=\"562.5\" y=\"44\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"14\" font-weight=\"600\" fill=\"var(--paper)\">Inadvertida</text><text x=\"70\" y=\"130.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"14\" font-weight=\"600\" fill=\"var(--paper)\" transform=\"rotate(-90 70 130.0)\">Imprudente</text><text x=\"70\" y=\"280.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"14\" font-weight=\"600\" fill=\"var(--paper)\" transform=\"rotate(-90 70 280.0)\">Prudente</text><rect x=\"110\" y=\"60\" width=\"295\" height=\"140\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"257.5\" y=\"96\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">“Não temos tempo</text><text x=\"257.5\" y=\"114\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">para desenho.”</text><path d=\"M150 136 L365 136\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"257.5\" y=\"160\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">Coreto: a suíte ponta</text><text x=\"257.5\" y=\"177\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">a ponta instável</text><rect x=\"415\" y=\"60\" width=\"295\" height=\"140\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"562.5\" y=\"96\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">“O que é separar em camadas?”</text><path d=\"M455 136 L670 136\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"562.5\" y=\"160\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">Coreto: a réplica antiga</text><text x=\"562.5\" y=\"177\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">de relatórios</text><rect x=\"110\" y=\"210\" width=\"295\" height=\"140\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"257.5\" y=\"246\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">“Precisamos entregar agora e</text><text x=\"257.5\" y=\"264\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">lidar com as consequências.”</text><path d=\"M150 286 L365 286\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"257.5\" y=\"310\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">Coreto: o gerador de</text><text x=\"257.5\" y=\"327\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">ingressos em PDF feito à mão</text><rect x=\"415\" y=\"210\" width=\"295\" height=\"140\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"562.5\" y=\"246\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">“Agora sabemos como</text><text x=\"562.5\" y=\"264\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">deveríamos ter feito.”</text><path d=\"M455 286 L670 286\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"562.5\" y=\"310\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">Coreto: o travamento das</text><text x=\"562.5\" y=\"327\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">reservas de assento</text><text x=\"410\" y=\"378\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">como a dívida foi tomada, não quanto ela custa</text></svg>", "caption": "O quadrante de dívida técnica de Fowler, com as quatro dívidas da Coreto posicionadas. As duas caixas imprudentes são as que um time consegue parar de produzir; a caixa prudente e inadvertida é o preço de aprender."}
```

A frase em cada caixa é de Fowler, e é a frase que se ouviria na sala quando aquele tipo de dívida
foi tomado:

| | deliberada | inadvertida |
|---|---|---|
| imprudente | "Não temos tempo para desenho." | "O que é separar em camadas?" |
| prudente | "Precisamos entregar agora e lidar com as consequências." | "Agora sabemos como deveríamos ter feito." |

O quadrante classifica **como uma dívida passou a existir**. Ele não diz nada sobre quanto a dívida
custa, que é o assunto da aula 5, e uma dívida em qualquer caixa pode ser barata ou ruinosa.

## As quatro da Coreto, uma em cada caixa

Davi pegou as quatro dívidas do registro e perguntou a quem estava lá como cada uma começou.

**O travamento das reservas de assento: prudente e inadvertida.** Nos primeiros anos da Coreto, os
clientes eram teatros pequenos, e segurar um assento travando a linha dele no banco era o desenho
simples e correto para aquela carga. Ninguém naquele time poderia saber do que precisaria a abertura
de vendas de um festival esgotado, porque nenhuma abertura assim tinha acontecido ainda. "Agora
sabemos como deveríamos ter feito" é exatamente o que os relatórios de incidente dizem hoje. O ponto
de Fowler sobre esta caixa é o que mais importa: **até um time excelente produz esse tipo de
dívida**, porque o entendimento chega depois do código. É o custo de aprender, e nenhum processo o
elimina.

O que transformou uma lacuna modesta de desenho no primeiro problema da empresa não foi o começo.
Foram nove anos de todos os times construindo funcionalidades em cima dela, sem dono. Isso são juros
crescendo, e a aula 5 mede a que velocidade.

**O gerador de ingressos em PDF: prudente e deliberada.** Antes da primeira temporada de festivais
da Coreto, a biblioteca que ela usava não conseguia imprimir os layouts de ingresso que os festivais
pediam. O time escreveu o próprio gerador às pressas, sabendo que era um atalho, e anotou no ticket
que ele deveria ser trocado por uma biblioteca mantida depois da temporada. Foi um empréstimo sensato:
a temporada pagou por ele muitas vezes. **A falha veio depois.** A temporada acabou, a prioridade
seguinte chegou, e a anotação ficou num ticket fechado. É o caso contra o qual Cunningham alertou —
um empréstimo prudente nunca pago.

**A suíte ponta a ponta instável: imprudente e deliberada.** A suíte foi escrita contra dados
compartilhados de homologação, com esperas fixas em vez de verificar se a página estava pronta.
Quando os testes começaram a falhar ao acaso, o time sabia por quê, e acrescentou novas tentativas
automáticas em vez de consertar os testes, porque "não tinha tempo nesta sprint". Isso se repetiu,
sprint após sprint. Todos os envolvidos sabiam escrever um teste confiável; a escolha foi feita, de
novo e de novo, de não escrever.

**A réplica de relatórios: imprudente e inadvertida.** Nos primeiros tempos da empresa, o time de
Dados montou seus relatórios consultando direto uma réplica de leitura do banco de produção, juntando
as tabelas do próprio monólito. Ninguém no time tinha construído antes um armazenamento separado para
análise, e ninguém perguntou a quem tinha. Hoje, cada mudança numa tabela do `coreto-core` arrisca
quebrar um relatório de que alguém em finanças depende. "O que é separar em camadas?" é indelicado, e
também é exato: o time não sabia que havia uma decisão a tomar.

## O que cada caixa pede

Classificar a dívida só é útil porque muda o que você faz em seguida. **Pagar a dívida resolve o
passado; a caixa diz o que mudar para que se tome menos do tipo ruim no futuro.**

| caixa | o que pede | na Coreto |
|---|---|---|
| prudente, inadvertida | aceitá-la como custo de aprender, e reservar tempo para retrabalhar desenhos conforme o entendimento cresce | revisar o desenho da reserva depois de cada grande abertura, agora que existe um teste de carga |
| prudente, deliberada | registrar o empréstimo com um gatilho de pagamento, e cumpri-lo | uma linha no registro com data, lida em cada revisão trimestral |
| imprudente, deliberada | mudar a regra que tornou o atalho barato | um teste que precisou de nova tentativa para passar conta como falho |
| imprudente, inadvertida | trazer o conhecimento que faltava: revisão, pareamento, contratação | o próximo armazenamento de Dados desenhado com um revisor da Plataforma |

As duas caixas imprudentes merecem mais atenção, porque são as que um time consegue parar de
produzir. A imprudência deliberada costuma ser resposta a uma pressão contra a qual ninguém
argumentou: a aula 13 do curso `architect-communication` trata de negociar prazo, escopo, qualidade e
dívida, para que o atalho seja uma decisão que alguém assina, e não um hábito. A imprudência
inadvertida é uma lacuna de conhecimento, e o remédio é o conhecimento, não uma regra.

## O quadrante julga decisões, não pessoas

O mesmo código pode cair em caixas diferentes conforme quem conta a história. A engenheira que
escreveu o gerador de PDF lembra de um empréstimo prudente com plano; o engenheiro que o herdou, sem
plano à vista, vê imprudência. Os dois descrevem algo real.

Então classifique com as pessoas que estavam lá, anote o que elas dizem, e trate a caixa como um fato
sobre **a decisão e as circunstâncias dela**. Um registro que se lê como lista de culpados para de
receber respostas honestas na primeira vez em que alguém é culpado nele, e aí o quadrante não tem
mais nada verdadeiro para classificar.
