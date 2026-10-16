---
title: Mesmas lojas: o crescimento das lojas que você já tinha
version: 1
---

O varejo é o setor em que este curso está desde a aula 1, então as quatro perguntas da aula 17 têm
respostas que você já conhece pela metade. O que esta aula acrescenta é a parte que pertence ao
varejo e a nenhum outro setor:

| a pergunta da aula 17 | no varejo |
|---|---|
| as decisões tomadas sem parar | o que comprar, quanto, para qual loja, a que preço e o que promover |
| os indicadores que servem a elas | vendas nas mesmas lojas, vendas por m², dias de cobertura, giro da venda (sell-through), pedidos incrementais, o OTIF de um fornecedor |
| os dados, e o que eles têm de estranho | toda venda é registrada até o item e o minuto; **uma venda que não aconteceu não deixa registro nenhum** |
| a armadilha típica | dar às lojas, à campanha ou ao comprador o crédito de um crescimento que veio de outro lugar |

As quatro seções tratam de uma decisão cada: se as lojas estão melhorando, o que está na
prateleira, se uma campanha funcionou e se um fornecedor é confiável.

## A pergunta errada: as vendas cresceram?

As lojas da Varanda venderam R$ 82,39 milhões em 2025, contra R$ 77,95 milhões em 2024. É um
crescimento de 5,7%, e foi esse o número do e-mail de fim de ano. **Ele não diz quase nada sobre
as lojas terem ficado melhores em vender**, porque uma das nove não funcionou o ano de 2024
inteiro. Ipatinga abriu em julho de 2024: seis meses de vendas no primeiro ano, doze no segundo.

A resposta do varejo é o crescimento **nas mesmas lojas** (em inglês, *like-for-like* ou
*same-store*): o crescimento das lojas que funcionaram os dois períodos inteiros, e de mais
ninguém. Uma loja nova infla o crescimento total no primeiro ano completo por um motivo que não
tem nada a ver com vender melhor, e uma loja fechada o reduz. Comparar o igual com o igual tira as
duas da conta.

## A planilha

Digite as nove lojas numa planilha nova, em milhares de reais, com Ipatinga por último:

| | A | B | C |
|---|---|---|---|
| 1 | Loja | 2024 | 2025 |
| 2 | Savassi | 11520 | 11880 |
| 3 | Pampulha | 10610 | 10560 |
| 4 | Contagem | 12650 | 12480 |
| 5 | Betim | 8700 | 8840 |
| 6 | Nova Lima | 8980 | 9450 |
| 7 | Sete Lagoas | 6690 | 6720 |
| 8 | Divinópolis | 6540 | 6460 |
| 9 | Juiz de Fora | 8910 | 8960 |
| 10 | Ipatinga | 3350 | 7040 |

Em D1 digite `Cresc. %`, em D2 o crescimento da primeira loja, e copie até D10:

```localised
=ARRED((C2/B2-1)*100;1)      3,1
```

Depois, dois totais. Em A11 digite `Todas as lojas` e em A12 `Mesmas lojas`; o segundo soma só as
oito linhas acima de Ipatinga:

```localised
=SOMA(B2:B10)      77950
=SOMA(C2:C10)      82390
=ARRED((C11/B11-1)*100;1)      5,7
=SOMA(B2:B9)      74600
=SOMA(C2:C9)      75350
=ARRED((C12/B12-1)*100;1)      1
```

**Todas as lojas cresceram 5,7%; nas mesmas lojas, 1,0%.** Das oito lojas comparáveis, cinco
cresceram e três encolheram, Contagem entre elas, com −1,3%. Quanto dos 5,7 pontos veio da loja
nova é a venda a mais dela sobre o total de 2024:

```localised
=ARRED((C10-B10)/B11*100;1)      4,7
=ARRED((C12-B12)/B11*100;1)      1
```

O primeiro ano completo de Ipatinga responde por 4,7 dos 5,7 pontos. As outras oito lojas juntas,
por 1,0.

Olhe também para D10. **Ipatinga "cresceu" 110,1%**, e nada nesse número é verdade: ele compara um
ano com meio ano. O crescimento de uma loja no primeiro ano completo não entra em ranking nenhum de
lojas, e um relatório que o põe junto das outras vai colocá-la no topo todas as vezes.

## A regra tem de estar escrita

"Funcionou os dois períodos inteiros" parece óbvio até os casos aparecerem. Cada um destes
acontece num varejista do tamanho da Varanda em poucos anos:

- uma loja abre no meio do período comparado, como Ipatinga;
- uma loja fecha seis semanas para reforma, ou de vez;
- uma loja se muda para um prédio maior na mesma rua;
- um ano tem mais dias de venda que o outro. 2024 foi bissexto, com um 29 de fevereiro.

Os varejistas resolvem isso com uma regra escrita, e as regras variam: uns contam a loja como
comparável depois de doze meses completos de operação, outros depois de treze; uns tiram a loja
reformada só nos meses em que ficou fechada, outros no ano todo. **A regra importa menos do que
escrevê-la e aplicá-la do mesmo jeito todo ano**, que é a definição de BI da aula 1 aplicada a um
indicador. Um número de mesmas lojas sem a regra ao lado é um número que ninguém consegue
conferir.

A loja online levanta a última questão. Ela cresceu 5,8%, de R$ 14,75 milhões para R$ 15,61
milhões, e não é uma loja física. Alguns varejistas publicam o número de mesmas lojas só das lojas
físicas, com o canal online ao lado. Outros incluem a loja online, com o argumento de que o cliente
que comprou online depois de ver um sofá na Savassi foi atendido pela Savassi. O relatório da
Varanda mantém os dois separados, e diz isso numa nota de rodapé.

## O que o 1,0% muda

A aula 2 começou com Helena querendo ampliar Contagem porque é a loja que mais vende. O número de
mesmas lojas põe um segundo fato ao lado das vendas por m²: Contagem é a maior loja, e em 2025
vendeu menos que no ano anterior. Nenhum dos dois fatos decide a questão sozinho, mas um conselho
que só visse os 5,7% não teria perguntado por nenhum deles.
