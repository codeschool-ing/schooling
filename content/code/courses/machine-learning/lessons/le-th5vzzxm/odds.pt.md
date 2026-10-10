---
title: O que um peso logístico quer dizer
version: 1
---

Um peso na regressão logística não move a chance por um valor fixo, porque a curva faz o mesmo
empurrão valer mais no meio do que perto de 0 ou de 1. O que ele move por um valor fixo é a
**razão de chances** (*odds*): a chance de sair dividida pela chance de ficar. Uma chance de 0,2 são
odds de 0,25, um para quatro; uma chance de 0,5 são odds de 1.

**Cada peso, posto como expoente de e, é o fator pelo qual as odds são multiplicadas** quando aquela
coluna sobe uma unidade. O `logistic.py` imprimiu esse fator ao lado de cada peso, e como as colunas
foram padronizadas, uma unidade é um desvio-padrão da coluna:

| coluna | odds × | lido em voz alta |
|---|---|---|
| `rating_90d` | 0,45 | um desvio-padrão a mais de avaliação, cerca de meia estrela aqui, e as odds de sair caem mais da metade |
| `tenure_months` | 0,62 | um desvio-padrão a mais de casa, cerca de oito meses, e as odds caem um terço |
| `skips_90d` | 1,41 | um desvio-padrão a mais de pulos, cerca de uma caixa, e as odds sobem 41% |
| `late_90d` | 1,30 | mais ou menos uma entrega atrasada a mais, e as odds sobem 30% |

Para transformar um desses num fator por unidade original, divida o peso pelo desvio-padrão da coluna
antes de elevar; o padronizador ajustado os guarda em `scale.scale_`. A ordem acima é a leitura mais
útil, porque está em unidades comparáveis: **avaliação e tempo de casa movem as odds mais que
qualquer outra coisa no modelo.**

## A referência de uma categoria

`payment_card` e `payment_pix` têm os dois pesos de cerca de −0,24, e não existe `payment_boleto`.
Isso é o `drop_first=True` trabalhando: `boleto` vinha primeiro em ordem alfabética, então foi
descartado e virou a referência com que os outros dois se comparam. **Os dois pesos dizem a mesma
coisa: pagar com cartão ou Pix traz odds de sair menores que pagar com boleto.** Se a referência fosse
`card`, o modelo imprimiria um peso positivo para `boleto` e um quase zero para `pix`, com exatamente
as mesmas previsões. Os pesos de uma categoria só fazem sentido ao lado do nome da categoria que ficou
de fora.

## O que um peso não quer dizer

O mesmo aviso de antes, mais alto. **Aumentar a avaliação de um assinante não cortaria pela metade as
odds de ele sair**, porque ninguém consegue aumentar uma avaliação; a avaliação é um sintoma de quanto
ele gosta das caixas, e o peso diz o quanto esse sintoma anda junto com sair. Os pesos descrevem os
dados, mantendo fixas as outras colunas do modelo, e nada mais. A aula 19 leva bem mais longe a
pergunta sobre o que os pesos de um modelo podem e não podem dizer.
