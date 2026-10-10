---
title: Centralizando e escalando todas as colunas de uma vez
version: 1
---

**O uso mais comum do broadcasting em dados é pôr colunas em pé de igualdade**: subtrair a média de
cada coluna, dividir pela dispersão de cada coluna. É uma linha, e a regra é o motivo de ser uma
linha.

As duas colunas do tempo estão em escalas diferentes: chuva de 0 a 45,9 milímetros, temperatura a
poucos graus de 30. Pegue os dias com leitura de chuva, para que todo valor seja conhecido:

```python
known = weather[~np.isnan(weather[:, 0])]
known.shape, known.mean(axis=0).round(2), known.std(axis=0).round(2)
```

```
((359, 2), array([ 4.77, 29.93]), array([8.09, 1.03]))
```

`~` troca `True` por `False` e vice-versa, então a máscara fica com as linhas cuja chuva não é
`nan`; a aula 7 explica máscaras direito. As médias e os desvios-padrão saem com formato `(2,)`, um
por coluna, que se alinha pela direita com a tabela `(359, 2)`. Então:

```python
z = (known - known.mean(axis=0)) / known.std(axis=0)
z.shape, z.mean(axis=0).round(6), z.std(axis=0).round(6)
```

```
((359, 2), array([0., 0.]), array([1., 1.]))
```

Toda coluna agora tem média 0 e desvio-padrão 1: um **z-score**, quantos desvios-padrão um valor está
da média da coluna. O dia mais chuvoso e o dia mais quente agora se comparam numa escala só:

```python
z[:, 0].max().round(2), z[:, 1].max().round(2)
```

```
(np.float64(5.08), np.float64(2.21))
```

O dia mais chuvoso fica muito mais longe na chuva do que o dia mais quente fica na temperatura, o
que é uma afirmação sobre o tempo do Recife que os números brutos, em milímetros e graus, não
conseguiam fazer. O curso `machine-learning` escala colunas assim antes da maioria dos modelos, com
uma biblioteca que faz a mesma aritmética.

## Escalando linhas

Para escalar cada **linha** pelos próprios números, as estatísticas têm de manter o eixo, como nas
duas últimas seções. A fração do calor de cada semana que cabe a cada dia, sobre o total da semana:

```python
share = weeks / weeks.sum(axis=1, keepdims=True)
share.shape, share.sum(axis=1)[:3]
```

```
((52, 7), array([1., 1., 1.]))
```

Cada linha soma 1. Sem `keepdims`, o `(52,)` teria encontrado o `(52, 7)` pela direita, e o erro
de duas seções atrás teria sido o resultado.
