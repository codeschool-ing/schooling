---
title: O silencioso, (n,) contra (n, 1)
version: 1
---

**O broadcasting perigoso é o que funciona.** Um erro para você; um broadcasting que você não quis
dá um array do formato errado e deixa você seguir. O caso clássico é uma coluna e uma linha do mesmo
comprimento, `(n, 1)` e `(n,)`: a regra estica as duas, e em vez de `n` resultados você recebe
`n × n`.

Ana tem uma previsão para a primeira semana de janeiro, um valor por dia, guardada como coluna
porque foi assim que um modelo a entregou:

```python
forecast = np.array([30.1, 30.0, 30.5, 31.0, 30.8, 30.2, 30.6]).reshape(-1, 1)
actual = temp[:7]
forecast.shape, actual.shape
```

```
((7, 1), (7,))
```

O erro da previsão de cada dia é uma subtração, e aqui está:

```python
error = forecast - actual
error.shape
```

```
(7, 7)
```

**Sete por sete.** Toda previsão menos todo real: a previsão do dia 1 contra a temperatura do dia 4,
e outros 42 pares que não querem dizer nada. Nenhum erro, nenhum aviso. A linha seguinte é onde o
estrago acontece, porque um resumo de um array de formato errado é um número como qualquer outro:

```python
np.abs(error).mean().round(3), np.abs(forecast.ravel() - actual).mean().round(3)
```

```
(np.float64(0.539), np.float64(0.2))
```

O primeiro número é o erro absoluto médio de 49 comparações, 42 delas sem sentido; o segundo é o de
verdade, dos sete dias comparados consigo mesmos. Eles diferem, e nada no primeiro faria você
desconfiar se não tivesse visto o segundo.

## Como ficar fora disso

- **Confira o formato de um resultado que você esperava ter um formato conhecido.** Uma linha,
  `error.shape`, teria mostrado `(7, 7)` em vez de `(7,)`. Um `assert error.shape == actual.shape`
  num notebook não custa nada e transforma o silêncio num erro.
- **Achate colunas que na verdade são listas.** Uma previsão de sete dias é um dado unidimensional,
  e `ravel()` ou `reshape(-1)` o deixa assim antes de encontrar qualquer outra coisa.
- **Prefira o pandas para dados com rótulos.** A partir da aula 9, duas Series se alinham pelo índice,
  não pelo formato, e este erro específico vira outro, "o índice que ninguém lê" da aula 9.
