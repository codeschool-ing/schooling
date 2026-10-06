---
title: A quantos perguntar
version: 1
---

A margem de erro depende de três coisas: o nível de confiança, a dispersão dos dados e o tamanho da amostra.
O primeiro se escolhe, o segundo é uma propriedade do que se mede, e o terceiro é o que você controla. Então
a fórmula da margem pode ser invertida para dizer de que tamanho uma amostra precisa ser.

## Para uma proporção

A margem para uma proporção é 1,96 × √(*p*(1 − *p*) ÷ *n*). Isolando *n*:

```localised
n = 1,96² × p × (1 − p) ÷ margem²
```

Antes da pesquisa, *p* é desconhecido, então use o pior caso, 0,5:

- para uma margem de **5 pontos**: 1,96² × 0,25 ÷ 0,05² = 384,2, portanto **385 pessoas**;
- para uma margem de **3 pontos**: 1,96² × 0,25 ÷ 0,03² = 1.067,1, portanto **1.068 pessoas**.

Arredonde sempre **para cima**: 384,2 pessoas significa 385, porque 384 deixaria a margem um pouco acima de
5 pontos.

Esses 1.068 são o motivo de tantas pesquisas nacionais de opinião entrevistarem cerca de mil pessoas. A aula
10 explicou por que o tamanho do país quase não importa: a margem depende da amostra, não da população.

## Para uma média

Para uma média, a fórmula precisa de um palpite para o desvio padrão, de dados anteriores ou de uma
amostra-piloto:

```localised
n = (1,96 × s ÷ margem)²
```

As cestas da Horta têm desvio padrão de uns R$ 59. Para estimar a cesta média com precisão de **R$ 10**, a
Horta precisa de (1,96 × 59 ÷ 10)² = 133,7, portanto **134 pedidos**. Com precisão de **R$ 5**, precisa de
(1,96 × 59 ÷ 5)² = 534,9, portanto **535 pedidos**.

Cortar a margem pela metade quadruplicou a amostra: a raiz quadrada da aula 11 aparecendo no orçamento.

## Um plano de pesquisa em quatro linhas

1. Decida a margem que mudaria uma decisão: ±5 pontos bastam para saber se a satisfação caiu, ou é preciso
   ±3?
2. Decida o nível de confiança, quase sempre 95%.
3. Calcule *n*, e arredonde para cima.
4. Aumente-o pela não resposta: se a experiência diz que um convite em quatro é respondido, convide quatro
   vezes *n*, e lembre que as respostas continuam vindo de quem escolheu responder, como a aula 10 avisou.

A ordem importa. Uma pesquisa que coleta o que conseguir e depois informa uma margem deixou o orçamento
decidir a precisão. Uma pesquisa que decide a precisão primeiro consegue dizer, antes de gastar qualquer
dinheiro, se a pergunta vale a pena.
