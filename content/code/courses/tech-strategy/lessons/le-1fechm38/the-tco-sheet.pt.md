---
title: A planilha de TCO
version: 1
---

Uma planilha de TCO é curta: quatro linhas, uma coluna por opção, um total. **Todo o valor dela
está em cada linha estar presente e na mesma unidade**, então vale montá-la mesmo quando você acha
que já sabe a resposta.

## Digite

Na sua planilha, como montada na aula 1, acrescente uma aba para a decisão de observabilidade. Cada
valor é um número de três anos das duas seções anteriores, em reais:

| | A | B | C |
|---|---|---|---|
| 1 | Linha | Hospedado | Auto-hospedado |
| 2 | Licença | 275400 | 151200 |
| 3 | Integração | 48000 | 0 |
| 4 | Operação | 79200 | 475200 |
| 5 | Saída | 49650 | 0 |
| 6 | TCO | | |

Digite os zeros. Uma célula vazia e um zero somam igual, mas um zero diz que alguém decidiu que a
linha não custa nada, e uma célula vazia diz que ninguém olhou.

Confira uma célula à mão antes, como a aula 1 pediu. B2 são R$ 7.650 por mês durante 36 meses:
R$ 275.400. C4 são 60% de R$ 264.000, três vezes: R$ 475.200.

Em B6 e C6, os totais:

```localised
B6   =SOMA(B2:B5)      452250
C6   =SOMA(C2:C5)      626400
```

Depois, três fórmulas em células vazias. A diferença só de licença, a diferença inteira e a fatia
do total auto-hospedado que é operação:

```localised
=B2-C2                    124200
=C6-B6                    174150
=ARRED(C4/C6*100;0)       76
```

## Lendo a planilha

**Só pela licença, auto-hospedar sai R$ 124.200 mais barato. Pelo TCO, hospedar sai R$ 174.150 mais
barato.** As duas comparações apontam para lados opostos, e a distância entre elas,
R$ 124.200 + R$ 174.150 = R$ 298.350 em três anos, é o que uma comparação de preço de cinco minutos
teria errado.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Duas barras empilhadas do custo total de propriedade em três anos. Hospedado: licença R$ 275.400, integração R$ 48.000, operação R$ 79.200, saída R$ 49.650, total R$ 452.250. Auto-hospedado: licença R$ 151.200 e operação R$ 475.200, total R$ 626.400. Uma linha tracejada no topo de cada segmento de licença marca o que uma comparação só de licença enxerga.\"><rect x=\"190\" y=\"189.84\" width=\"110\" height=\"110.16\" rx=\"0\" fill=\"var(--amber)\"></rect><text x=\"180\" y=\"248.92\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">licença 275.400</text><rect x=\"190\" y=\"170.64\" width=\"110\" height=\"19.2\" rx=\"0\" fill=\"var(--phosphor-dim)\"></rect><text x=\"180\" y=\"184.24\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">integração 48.000</text><rect x=\"190\" y=\"138.96\" width=\"110\" height=\"31.68\" rx=\"0\" fill=\"var(--phosphor)\"></rect><text x=\"180\" y=\"158.8\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">operação 79.200</text><rect x=\"190\" y=\"119.1\" width=\"110\" height=\"19.86\" rx=\"0\" fill=\"var(--paper-dim)\"></rect><text x=\"180\" y=\"133.03\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">saída 49.650</text><text x=\"245\" y=\"109.1\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">TCO 452.250</text><path d=\"M186 189.84 L304 189.84\" fill=\"none\" stroke=\"var(--paper)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></path><rect x=\"430\" y=\"239.52\" width=\"110\" height=\"60.48\" rx=\"0\" fill=\"var(--amber)\"></rect><text x=\"550\" y=\"273.76\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">licença 151.200</text><rect x=\"430\" y=\"49.44\" width=\"110\" height=\"190.08\" rx=\"0\" fill=\"var(--phosphor)\"></rect><text x=\"550\" y=\"148.48\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">operação 475.200</text><text x=\"485\" y=\"39.44\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">TCO 626.400</text><path d=\"M426 239.52 L544 239.52\" fill=\"none\" stroke=\"var(--paper)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></path><path d=\"M150 300 L590 300\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"245\" y=\"320\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">hospedado</text><text x=\"485\" y=\"320\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">auto-hospedado</text></svg>", "caption": "Três anos de observabilidade, linha por linha. Comparado só pela licença, o auto-hospedado sai R$ 124.200 mais barato; comparado inteiro, o hospedado sai R$ 174.150 mais barato, e a operação é 76% do total auto-hospedado."}
```

A figura mostra de onde vem a inversão. A barra do hospedado é quase toda licença. A barra do
auto-hospedado é quase toda operação: **76% dela**, R$ 475.200 de R$ 626.400. O segmento de licença
do auto-hospedado é menor que o do hospedado, e esse é o único segmento que uma página de preços
mostra.

## A planilha pende para o auto-hospedado, e o hospedado ainda ganha

A planilha da Coreto faz duas simplificações, e as duas favorecem a opção auto-hospedada.

**A integração dela é zero** porque a pilha já existe. Isso é verdade, e também esconde que a pilha
foi integrada uma vez, a um custo que alguém pagou anos atrás; uma pilha auto-hospedada nova teria
sua própria linha de integração.

**A saída dela é zero**, o que nenhum sistema tem de verdade. Sair de uma pilha auto-hospedada
também exige levar painéis e alertas. A planilha não põe nada ali porque ninguém está propondo
sair dela.

As duas simplificações empurram o total auto-hospedado para baixo, e hospedar ainda sai R$ 174.150
mais barato. **Uma conclusão que sobrevive às premissas que jogam contra ela é uma conclusão
forte**, e vale uma frase na recomendação dizendo isso: ela conta ao leitor para que lado os erros
correm.

## Quanto a estimativa de operação teria de estar errada?

O número com mais chance de ser contestado são as 1.056 horas. O time da Rafaela as mediu, mas
alguém vai dizer que estão infladas. A planilha consegue responder quão infladas elas teriam de
estar.

Auto-hospedar só ganha se a linha de operação cair mais do que a diferença de R$ 174.150: de
R$ 475.200 para menos de R$ 301.050 em três anos. São R$ 100.350 por ano, o que a R$ 150 por hora
dá **669 horas por ano, cerca de 38% de um engenheiro** (669 ÷ 1.760). Então a pergunta para a
reunião fica concreta: alguém consegue mostrar que a pilha leva menos de 669 horas por ano para
rodar, quando o registro de horas diz 1.056? Um ponto de equilíbrio assim transforma uma discussão
sobre a estimativa "parecer alta" numa discussão sobre um número que alguém pode ir conferir.

## O que vai na recomendação

O Davi ajudou a Rafaela a escrevê-la para a Helena. A decisão cabe num parágrafo:

> **Observabilidade: ir para o serviço hospedado.** Em três anos o custo total dele é R$ 452.250,
> contra R$ 626.400 da nossa pilha, R$ 174.150 a menos. Só pela licença nossa pilha parece
> R$ 124.200 mais barata; a diferença é a operação, que é 76% do que auto-hospedar nos custa — 1.056
> horas por ano do tempo da Plataforma, medidas. Auto-hospedar só ganharia abaixo de 669 horas por
> ano. A planilha não conta integração nem saída para a nossa pilha, o que a favorece, e a opção
> hospedada ainda ganha. As horas liberadas da Plataforma vão para o teste de carga de abertura de
> vendas.

A última frase importa tanto quanto os números. Horas economizadas só são economia se forem gastas
em alguma coisa, e dizer em quê — aqui, uma das quatro ações da estratégia da aula 1 — é o que torna
o dinheiro real.
