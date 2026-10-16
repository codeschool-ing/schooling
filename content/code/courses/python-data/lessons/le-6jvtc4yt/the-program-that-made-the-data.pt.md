---
title: O programa que criou os dados, finalmente lido
version: 1
---

**A aula 1 pediu que você rodasse o `make_data.py` e confiasse nele. A metade aleatória dele já pode
ser lida.** O programa inteiro depende de uma linha, `rng = np.random.default_rng(2025)`, e de
sortear tudo desse único gerador numa ordem fixa. É por isso que os seus três arquivos são, byte a
byte, os do curso.

Eis os sorteios que ele faz, na ordem em que os faz, cada um com a distribuição escolhida e o porquê:

| linha no `make_data.py` | distribuição | o que modela |
|---|---|---|
| `rng.integers(10, 21, size=20)` | inteiros uniformes | docas por estação, de 10 a 20 |
| `rng.gamma(1.2, 9, 365)` | gama | a altura da chuva num dia chuvoso: nunca negativa, quase sempre pequena, às vezes grande |
| `rng.random(365) < …` | uniforme, comparada | se um dia é chuvoso: 70% nos meses de chuva, 30% nos outros |
| `rng.normal(0, 0.8, 365)` | normal | o desvio do dia em relação à temperatura da estação |
| `rng.choice(365, size=6, replace=False)` | amostra | os seis dias cuja leitura de chuva se perdeu |
| `rng.poisson(…)` | Poisson | viagens por dia, perto de 110 em dias úteis e 70 nos fins de semana, menos com chuva forte |
| `rng.choice(24, n, p=…)` | escolha com probabilidades | a hora em que uma viagem começa, com picos de deslocamento nos dias úteis |
| `rng.dirichlet(np.full(20, 2.0))` | Dirichlet | quão popular é cada estação: vinte frações que somam 1 |
| `rng.lognormal(2.6, 0.5, n)` | log-normal | a duração da viagem em minutos: a maioria por volta de um quarto de hora, uma cauda longa |
| `rng.random(n) < 0.004` | uniforme, comparada | as bicicletas que nunca voltam |

Duas coisas nessa lista importam mais que as distribuições.

**A ordem faz parte da semente.** Troque duas dessas linhas e todo número depois da troca muda,
porque cada sorteio começa onde o anterior parou. O programa é reproduzível como um todo, não linha
a linha.

**Tudo é sorteado em arrays, não em laços.** `rng.poisson(…)` devolve 365 dias de contagens numa
chamada, e `rng.choice(24, n, p=…)` devolve uma hora para cada uma das 33.337 viagens. Um laço que
sorteasse uma viagem por vez daria o mesmo tipo de dado e outros números, e levaria muito mais
tempo.

Dá para conferir o programa contra os seus arquivos diretamente. O gerador, recomeçado da mesma
semente e com o mesmo primeiro sorteio, dá as docas do `stations.csv`:

```python
np.random.default_rng(2025).integers(10, 21, size=20)[:5]
```

```
array([14, 20, 20, 14, 20])
```

```python
np.genfromtxt("stations.csv", delimiter=",", skip_header=1, usecols=2)[:5]
```

```
array([14., 20., 20., 14., 20.])
```
