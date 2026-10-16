---
title: Views e cópias, e a mudança que aparece em outro lugar
version: 1
---

**Uma fatia de um array não é um array novo de números; é uma descrição nova do mesmo bloco.** O
NumPy chama isso de **view**. Mudar uma view muda o original, e isso é ou a coisa mais eficiente da
biblioteca ou um defeito que aparece três células depois, dependendo de você saber ou não.

A coluna de chuva da primeira seção é ela mesma uma view, de `weather`:

```python
rain = weather[:, 0]
np.shares_memory(rain, weather), rain.base is weather
```
```
(True, True)
```

`np.shares_memory` responde se dois arrays usam algum dos mesmos bytes, e o `base` de uma view é o
array dono deles. Agora pegue a primeira semana, e corrija o que parece um erro do sensor nela:

```python
week = rain[:7]
week[0] = 0.0
week, rain[0], weather[0]
```
```
(array([ 0. ,  6.8,  7.9, 15.7,  0. ,  0. ,  1.3]),
 np.float64(0.0),
 array([ 0. , 29.9]))
```

A mudança feita por `week` está em `rain` e em `weather`, porque os três descrevem os mesmos oito
bytes. Aqui o valor já era `0.0`, então nada foi estragado; com qualquer outro valor, os dados do
ano agora seriam outros e nenhuma célula mostraria a mudança. **Fatiar nunca copia.** Quando você
quer um array independente, diga:

```python
week = rain[:7].copy()
week[1] = 99.0
rain[1], np.shares_memory(week, rain)
```
```
(np.float64(6.8), False)
```

## Quais operações dão uma view

| dá uma view | dá uma cópia |
|---|---|
| uma fatia, `a[2:5]`, `a[:, 0]`, `a[::2]` | uma máscara, `a[a > 10]` (aula 7) |
| `reshape` de um array contíguo, `.T` | uma lista de posições, `a[[0, 3, 5]]` (aula 7) |
| `ravel` quando a ordem deixa | aritmética, `a + 1`, `a * 2` |
| `a.view(…)` | `.copy()`, `astype`, `flatten` |

Uma regra que cobre quase tudo: **uma operação que se faz mudando a descrição dá uma view; uma que
precisa escolher ou calcular valores dá uma cópia.** Quando importa, não raciocine: pergunte ao
`np.shares_memory`.

O pandas fica por cima do NumPy, e a mesma pergunta, se uma seleção é o dado ou uma cópia dele, é o
assunto da aula 11. O pandas 3 a respondeu de um jeito diferente do NumPy, de propósito, e aquela
aula diz como.
