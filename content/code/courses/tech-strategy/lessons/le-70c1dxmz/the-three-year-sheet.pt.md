---
title: A planilha de três anos
version: 1
---

A comparação que engana tem um ano de largura. **Faça a conta três anos à frente**, porque é tempo
suficiente para os custos de manter superarem os de montar, e curto o bastante para as estimativas
ainda significarem algo. Três anos é uma convenção, não uma lei, e esta seção termina mostrando o
que muda quando você mexe nele.

## Digite

Abra sua planilha, como montada na aula 1, acrescente uma aba e digite o custo anual de cada opção
a partir da tabela da seção anterior. O ano 1 é o trabalho feito uma vez mais um ano de operação; os
anos 2 e 3 são só operação, com a licença de comprar subindo 10% a cada ano.

| | A | B | C | D | E |
|---|---|---|---|---|---|
| 1 | Opção | Ano 1 | Ano 2 | Ano 3 | Três anos |
| 2 | Construir | 246000 | 102000 | 102000 | |
| 3 | Comprar | 157200 | 132000 | 143880 | |
| 4 | Adotar | 241200 | 169200 | 169200 | |

Confira uma linha à mão antes de confiar na coluna, como a aula 1 pediu. O ano 1 de construir são
960 horas a R$ 150 (R$ 144.000), mais um quarto do ano de um engenheiro (R$ 66.000), mais doze meses
de capacidade de banco (R$ 36.000): R$ 246.000. O ano 3 de comprar é a licença depois de dois
aumentos, R$ 130.680, mais um vigésimo do ano de um engenheiro, R$ 13.200: R$ 143.880.

Em E2 a E4, os totais de três anos:

```localised
E2   =SOMA(B2:D2)      450000
E3   =SOMA(B3:D3)      433080
E4   =SOMA(B4:D4)      579600
```

Depois, três fórmulas em células vazias. A opção mais barata em três anos, a mais barata só no ano
1, e quanto comprar sai mais barato do que construir:

```localised
=ÍNDICE(A2:A4;CORRESP(MÍNIMO(E2:E4);E2:E4;0))      Comprar
=ÍNDICE(A2:A4;CORRESP(MÍNIMO(B2:B4);B2:B4;0))      Comprar
=E2-E3                                              16920
```

`CORRESP` acha a posição do menor valor da coluna, e `ÍNDICE` devolve o nome nessa posição, então a
resposta continua certa se alguém editar um número.

## Lendo a planilha

**Comprar é o mais barato em três anos, por R$ 16.920 contra construir e R$ 146.520 contra adotar.**
Também é o mais barato no ano 1, e por muito mais: R$ 157.200 contra os R$ 246.000 de construir, uma
diferença de R$ 88.800. Desenhe os totais acumulados e o formato é o argumento.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 760 345\" role=\"img\" aria-label=\"Um gráfico de linhas do gasto acumulado com busca em três anos, para três opções. Construir chega a R$ 246.000 depois do ano 1, R$ 348.000 depois do ano 2 e R$ 450.000 depois do ano 3. Comprar chega a R$ 157.200, R$ 289.200 e R$ 433.080. Adotar chega a R$ 241.200, R$ 410.400 e R$ 579.600. Abaixo do eixo, a vantagem de comprar sobre construir: R$ 88.800, R$ 58.800 e R$ 16.920.\"><path d=\"M150 290 L600 290\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"140\" y=\"294\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><path d=\"M150 210 L600 210\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"140\" y=\"214\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">200.000</text><path d=\"M150 130 L600 130\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"140\" y=\"134\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">400.000</text><path d=\"M150 50 L600 50\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"140\" y=\"54\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">600.000</text><text x=\"150\" y=\"30\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">gasto acumulado, R$</text><text x=\"150\" y=\"310\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">início</text><text x=\"300\" y=\"310\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">ano 1</text><text x=\"450\" y=\"310\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">ano 2</text><text x=\"600\" y=\"310\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">ano 3</text><text x=\"140\" y=\"334\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">comprar à frente por, R$</text><text x=\"300\" y=\"334\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">88.800</text><text x=\"450\" y=\"334\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">58.800</text><text x=\"600\" y=\"334\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">16.920</text><path d=\"M150 290 L300 191.6 L450 150.8 L600 110\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></path><circle cx=\"150\" cy=\"290\" r=\"3.5\" fill=\"var(--phosphor)\"></circle><circle cx=\"300\" cy=\"191.6\" r=\"3.5\" fill=\"var(--phosphor)\"></circle><circle cx=\"450\" cy=\"150.8\" r=\"3.5\" fill=\"var(--phosphor)\"></circle><circle cx=\"600\" cy=\"110\" r=\"3.5\" fill=\"var(--phosphor)\"></circle><path d=\"M150 290 L300 227.12 L450 174.32 L600 116.768\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"2\"></path><circle cx=\"150\" cy=\"290\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"300\" cy=\"227.12\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"450\" cy=\"174.32\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"600\" cy=\"116.768\" r=\"3.5\" fill=\"var(--amber)\"></circle><path d=\"M150 290 L300 193.52 L450 125.84 L600 58.16\" fill=\"none\" stroke=\"var(--paper)\" stroke-width=\"2\"></path><circle cx=\"150\" cy=\"290\" r=\"3.5\" fill=\"var(--paper)\"></circle><circle cx=\"300\" cy=\"193.52\" r=\"3.5\" fill=\"var(--paper)\"></circle><circle cx=\"450\" cy=\"125.84\" r=\"3.5\" fill=\"var(--paper)\"></circle><circle cx=\"600\" cy=\"58.16\" r=\"3.5\" fill=\"var(--paper)\"></circle><text x=\"612\" y=\"106\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">Construir</text><text x=\"692\" y=\"106\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">450.000</text><text x=\"612\" y=\"128\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">Comprar</text><text x=\"692\" y=\"128\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">433.080</text><text x=\"612\" y=\"62\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Adotar</text><text x=\"692\" y=\"62\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">579.600</text></svg>", "caption": "Gasto acumulado com busca, opção por opção. Comprar é o mais barato em todo ponto, mas a vantagem sobre construir cai de R$ 88.800 depois do ano 1 para R$ 16.920 depois do ano 3, porque a licença sobe todo ano e o custo de manter o que foi construído não sobe."}
```

A vantagem encolhe todo ano. Do ano 2 em diante, construir custa R$ 102.000 por ano e comprar custa
R$ 132.000, depois R$ 143.880, porque a licença sobe e o custo de manter o que foi construído não.
Comprar estava R$ 88.800 à frente depois do ano 1, R$ 58.800 depois do ano 2, e R$ 16.920 depois do
ano 3.

**Leve a planilha um ano adiante e a resposta se inverte.** A licença do ano 4 seria R$ 130.680 ×
1,10 = R$ 143.748; some os R$ 13.200 de pessoas e o quarto ano de comprar fica em R$ 156.948, contra
R$ 102.000 de construir. Em quatro anos, construir soma R$ 552.000 e comprar, R$ 590.028. O horizonte
é portanto uma escolha que decide o resultado, e por isso precisa ser declarado ao lado dele — e
"três anos" numa proposta deveria vir com uma frase dizendo por que três.

## Qual o tamanho de R$ 16.920?

Pequeno. A R$ 150 por hora, são cerca de 113 horas de engenharia, e só a estimativa de construir é
de 960 horas. **Uma estimativa que estourasse 12% apagaria toda a diferença**, e a aula 6 precificou
uma reescrita estourando 50%. Quando duas opções terminam tão perto, o veredito da planilha é "o
dinheiro não decide isto" — e a decisão passa para o que a planilha não contém.

## O que a planilha deixa de fora

A planilha guarda o que era fácil pôr numa célula. Cinco coisas não eram, e cada uma pende para um
lado:

| de fora | para que lado pende | onde é tratada |
|---|---|---|
| consultas de busca no mesmo banco das reservas de assento | contra construir | abaixo |
| quanto custaria sair do fornecedor | contra comprar | aula 9 |
| o risco de ficar preso às condições do fornecedor | contra comprar | aula 10 |
| o que as 960 horas teriam feito no caminho de reservas | contra construir | aula 13 |
| quão cedo os compradores ganham uma busca melhor | a favor de comprar | abaixo |

A primeira merece uma frase própria. Construir põe a busca no banco Postgres que também guarda os
bloqueios de assento diagnosticados na aula 1, e uma abertura de vendas concorrida é justamente
quando os compradores mais buscam. **Uma opção que põe carga no único caminho que a estratégia
protege custa mais do que a linha dela diz.** A última é a mais simples: a integração de comprar
leva 240 horas contra 960 de construir, então os compradores ganham uma busca melhor em semanas e
não em meses.

A nota do Davi para a Helena, depois que o time de Catálogo conferiu os números:

> **Busca: recomendação.** Comprar o serviço hospedado. Em três anos é a opção mais barata por
> R$ 16.920 — pouco demais para decidir — e a mais barata no ano 1 por R$ 88.800. Tira a carga de
> busca do banco de que o caminho de reservas depende, e deixa as horas do time de Catálogo para o
> trabalho que só a Coreto sabe fazer. Antes de assinar: precificar quanto custaria sair, começando
> pelas cláusulas de exportação de dados do contrato, e pedir um teto para o aumento anual de 10%,
> porque no ano 4 ele faria de construir a opção mais barata.

A recomendação não afirma mais do que a planilha mostra. Ela dá o valor, admite que a margem é
estreita e diz quais itens sem preço fizeram a balança pender.
