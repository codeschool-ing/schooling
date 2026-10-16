---
title: Amostras, embaralhamentos e um bootstrap
version: 1
---

**A operação aleatória mais comum em análise não é sortear números de um formato; é escolher algumas
das linhas que você já tem.** Uma amostra para olhar, um embaralhamento para dividir dados, uma
reamostragem para perguntar quanto uma estatística se mexeria se os dados tivessem saído um pouco
diferentes.

A chuva, com os seis dias sem leitura postos de lado, como a aula 7 fez:

```python
weather = np.genfromtxt("weather.csv", delimiter=",", skip_header=1, usecols=(1, 2))
rain = weather[:, 0]
known = rain[~np.isnan(rain)]
rng = np.random.default_rng(7)
```

## Uma amostra

```python
days = rng.choice(len(known), size=5, replace=False)
days, known[days]
```

```
(array([222, 244, 335, 207, 321]), array([21. ,  0. ,  0. ,  0. ,  0.4]))
```

`replace=False` quer dizer que nenhuma posição é escolhida duas vezes, que é o que "uma amostra de
cinco dias" quer dizer. Escolha posições em vez de valores, como a aula 5 ordenou posições: as
mesmas posições então pegam as datas, as temperaturas ou qualquer outra coisa em passo.

## Um embaralhamento

```python
order = rng.permutation(10)
order
```

```
array([3, 2, 6, 8, 1, 5, 0, 7, 4, 9])
```

`permutation(n)` são os números de 0 a n − 1 numa ordem aleatória, num array novo. Indexar com ele
embaralha qualquer array desse comprimento sem tocar no original; `rng.shuffle(a)` faz o mesmo **no
lugar**, mudando o próprio `a`. O primeiro é o padrão mais seguro, pelos motivos da aula 4.

## Um bootstrap

Quão certa é a chuva média diária, 4,77 mm? Os dados são um ano; outro ano teria dado outra média. O
**bootstrap** imita "outro ano" sorteando 359 dias **com** reposição dos 359 que temos, muitas vezes,
e olhando quanto a média se mexe:

```python
means = np.array([rng.choice(known, size=len(known), replace=True).mean() for _ in range(2000)])
known.mean().round(3), np.percentile(means, [2.5, 97.5]).round(2)
```

```
(np.float64(4.771), array([3.9 , 5.63]))
```

Dois mil anos reamostrados, e os 95% do meio das médias deles. O intervalo diz que, pela evidência
deste ano, o dia médio de chuva poderia estar em qualquer lugar dessa faixa. É um laço, e tudo bem:
duas mil iterações de uma média vetorizada.

O intervalo é um resultado aleatório, e uma semente o torna reproduzível. **Troque a semente e as
pontas se mexem na segunda casa decimal**:

```python
for seed in (1, 2, 3):
    r = np.random.default_rng(seed)
    m = np.array([r.choice(known, size=len(known)).mean() for _ in range(2000)])
    print(seed, np.percentile(m, [2.5, 97.5]).round(2))
```

```
1 [3.92 5.61]
2 [3.98 5.63]
3 [3.99 5.62]
```

Essa dispersão é o tamanho honesto do ruído da própria simulação. O curso `statistics` é onde o
bootstrap é discutido direito; aqui o ponto é a semente.
