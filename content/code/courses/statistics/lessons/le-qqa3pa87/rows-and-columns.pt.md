---
title: Linhas, colunas e variáveis
version: 1
---

A estatística começa por uma tabela, e vale fixar agora os nomes das partes dela, porque o resto do
curso usa esses nomes sem parar para explicar.

Aqui estão doze pedidos da **Horta**, a pequena mercearia online que este curso acompanha. Ela entrega
frutas, legumes e mercearia em Campinas, e todo número do curso vem dos registros dela. A empresa é
inventada, assim como os pedidos; o que se faz com eles, não.

| pedido | bairro | pagamento | itens | cesta (R$) | minutos | nota | CEP |
|---|---|---|---|---|---|---|---|
| H-1041 | Cambuí | pix | 7 | 86,40 | 34,5 | 5 | 13025-320 |
| H-1042 | Taquaral | cartão | 3 | 31,90 | 41,0 | 4 | 13076-010 |
| H-1043 | Barão Geraldo | pix | 12 | 154,75 | 52,5 | 3 | 13084-180 |
| H-1044 | Cambuí | dinheiro | 2 | 18,50 | 29,0 | 5 | 13025-120 |
| H-1045 | Centro | cartão | 5 | 62,30 | 38,5 | 4 | 13013-050 |
| H-1046 | Taquaral | pix | 9 | 118,20 | 44,0 | 2 | 13076-210 |
| H-1047 | Cambuí | pix | 4 | 47,80 | 31,5 | 5 | 13024-040 |
| H-1048 | Barão Geraldo | cartão | 15 | 212,60 | 61,0 | 4 | 13083-300 |
| H-1049 | Centro | pix | 6 | 74,10 | 36,0 | 4 | 13010-110 |
| H-1050 | Taquaral | cartão | 1 | 12,90 | 27,5 | 1 | 13076-150 |
| H-1051 | Cambuí | pix | 8 | 95,00 | 39,0 | 5 | 13025-200 |
| H-1052 | Centro | dinheiro | 3 | 35,60 | 33,0 | 3 | 13015-020 |

**Cada linha é uma observação**: uma coisa que foi examinada, aqui um pedido. **Cada coluna é uma
variável**: uma propriedade registrada para todas as observações. Chama-se variável porque varia de
linha para linha. Uma coluna com o mesmo valor em todas as linhas não diria nada sobre nenhuma delas.

A célula onde uma linha encontra uma coluna guarda um **valor**. O pedido H-1043 tem o valor
`Barão Geraldo` na variável *bairro* e o valor `52,5` na variável *minutos*.

## Uma tabela, um tipo de observação

Uma tabela funciona quando toda linha é o mesmo tipo de coisa. Se a Horta misturasse pedidos e
clientes numa planilha só, a linha de um cliente não teria *cesta* e a linha de um pedido não teria
*data de nascimento*. Toda contagem feita depois contaria duas coisas diferentes juntas.

Então a primeira pergunta sobre qualquer conjunto de dados é **o que é uma linha**. "Um pedido" e "um
cliente" dão respostas diferentes à mesma pergunta. Peça a cesta média por pedido e você recebe um
número. Peça o gasto médio por cliente e recebe outro, porque um cliente que pede quatro vezes é uma
linha na segunda tabela e quatro na primeira.

## A coluna decide o que você pode fazer

Olhe de novo o cabeçalho. *bairro* guarda nomes de lugares. *cesta* guarda quantias de dinheiro.
*CEP* guarda dígitos, mas ninguém soma dois CEPs.

São **tipos** diferentes de variável, e o tipo decide quais resumos fazem sentido. Dá para somar as
cestas: R$ 950,05 nos doze pedidos é o dinheiro que a Horta recebeu. Não dá para somar os bairros, e
não se deve somar os CEPs, mesmo que a planilha deixe.

As três próximas seções separam as colunas nas duas famílias com que todo curso de estatística
começa, e depois olham as colunas que fingem pertencer à família errada.
