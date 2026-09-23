---
title: `timeit` para a expressão, `cProfile` para o programa
version: 2
---

```sh
python -m timeit -s "data = list(range(100_000))" "99_999 in data"
```

```sh
500 loops, best of 5: 866 usec per loop
```

`-s` é a preparação, rodada uma vez e não cronometrada. A instrução é rodada muitas vezes e a
**melhor** rodada é relatada, porque as rodadas lentas são outros processos e não o seu código.

```python
import timeit
timeit.timeit("99_999 in data", "data = list(range(100_000))", number=1000)
```

A mesma coisa de dentro de um programa, devolvendo o total em segundos para `number` rodadas.

## Para o que o `timeit` não serve

Uma função que toca a rede, o disco ou um banco. A variação engole a medição, e rodá-la mil vezes
é falta de educação com o que estiver do outro lado. O `timeit` é para uma expressão pequena e
pura que você pode repetir.

## `cProfile`, para um programa

```sh
python -m cProfile -s tottime report.py
```

```sh
   ncalls  tottime  percall  cumtime  percall filename:lineno(function)
    17145   13.879    0.001   13.879    0.001 report.py:15(find_customer)
    20000    0.490    0.000    0.490    0.000 report.py:12(allowed)
        1    0.054    0.054   14.423   14.423 report.py:31(<listcomp>)
```

- **`tottime`** — tempo naquela função, **sem** contar o que ela chamou. É esta a coluna pela qual
  ordenar quando se procura a coisa lenta.
- **`cumtime`** — tempo naquela função e em tudo o que ela chamou. Ordenar por esta põe o `main`
  no topo, o que é verdade e é inútil.
- **`ncalls`** — quantas vezes. Uma função barata chamada dois milhões de vezes é um achado de
  verdade.

## O profile é por função, e isso é um limite

```sh
        1   18.307   18.307   18.317   18.317 report.py:12(report)
```

O primeiro profile daquele programa disse `report`, que é a coisa toda. **Um profiler não enxerga
dentro de uma função**, então uma função de duzentas linhas não conta nada que você já não
soubesse.

O conserto é dividi-la — três funções em vez de uma — e rodar de novo, que é o que transformou a
linha acima na tabela acima dela. O `line_profiler` é uma ferramenta de terceiros que relata por
linha, e dividir a função em geral é melhor de qualquer jeito.

## O custo de instrumentar

A rodada com profile acima levou 18 segundos onde a rodada limpa levou 9. O `cProfile` instrumenta
cada chamada, então **tempos absolutos sob ele estão errados** e uma função que faz muitas
chamadas pequenas parece pior do que é. Leia o profile pela forma, e cronometre o conserto sem
ele.

## A única regra

```sh
first fix, the obvious one:   9.0s → 8.4s     7%
second fix, the profiled one: 8.4s → 0.0166s  544×
```

**Faça o profile antes de mudar qualquer coisa.** Na demonstração, a mudança que parecia mais
errada valeu sete por cento, e a que o profiler nomeou valeu quinhentas vezes.
