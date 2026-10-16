---
title: Sorteando de uma distribuição
version: 1
---

**Um Generator sorteia de dezenas de distribuições, cada uma com os parâmetros que a descrevem.**
Você escolhe o formato que combina com o comportamento do que está simulando, e o gerador fornece
valores com esse formato. Quatro fazem a maior parte do trabalho em ciência de dados.

```python
rng = np.random.default_rng(2025)
heights = rng.normal(loc=170, scale=8, size=10_000)
heights.mean().round(2), heights.std().round(2)
```

```
(np.float64(170.03), np.float64(8.04))
```

**Normal**, a curva em sino: `loc` é a média e `scale` o desvio-padrão. Dez mil sorteios voltam
com média e dispersão perto das pedidas, e não exatamente iguais, que é o que uma amostra é.

```python
arrivals = rng.poisson(lam=4, size=10_000)
arrivals[:10], arrivals.mean().round(3)
```

```
(array([2, 2, 3, 4, 5, 1, 1, 5, 5, 3]), np.float64(3.944))
```

**Poisson**, contagens de eventos num intervalo fixo quando acontecem de forma independente a uma
taxa constante: `lam` é a contagem média. Viagens por hora numa estação, ligações por minuto num
atendimento. Todo valor é inteiro, nunca negativo.

```python
gaps = rng.exponential(scale=15, size=10_000)
gaps.mean().round(2), (gaps > 45).mean().round(3)
```

```
(np.float64(14.85), np.float64(0.047))
```

**Exponencial**, o tempo de espera entre eventos de Poisson: `scale` é a espera média. Quase
sempre curta, de vez em quando longa. A fração de esperas acima de três vezes a média sai perto de
5%, uma propriedade deste formato e uma coisa útil de saber sobre filas.

```python
plans = rng.choice(["annual", "day"], size=10_000, p=[0.7, 0.3])
(plans == "day").mean()
```

```
np.float64(0.2908)
```

**Escolha com probabilidades**, para categorias: cada sorteio é um dos itens, com as probabilidades
em `p`, que têm de somar 1.

## Vendo o formato

Um número-resumo não distingue um sino de uma cauda torta. Um histograma distingue, e o
`np.histogram` conta quantos valores caem em cada faixa sem desenhar nada:

```python
counts, edges = np.histogram(gaps, bins=[0, 15, 30, 45, 60, 1000])
counts
```

```
array([6387, 2291,  854,  277,  191])
```

Mais da metade das esperas abaixo da média de 15, e uma cauda longa depois. A aula 18 desenha
histogramas; as contagens são as mesmas de qualquer jeito.
