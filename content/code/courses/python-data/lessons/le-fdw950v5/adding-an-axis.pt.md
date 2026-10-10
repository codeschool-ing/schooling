---
title: Acrescentando um eixo onde a regra precisa
version: 1
---

**Um eixo de comprimento 1 não custa nada e muda tudo no broadcasting de um array.** Há três jeitos
de acrescentar um, e todos produzem o mesmo `(52, 1)` a partir do mesmo `(52,)`:

```python
weekly_flat.shape, weekly_flat[:, np.newaxis].shape, weekly_flat[:, None].shape, weekly_flat.reshape(-1, 1).shape
```

```
((52,), (52, 1), (52, 1), (52, 1))
```

`np.newaxis` é um apelido de `None`, e dentro de colchetes quer dizer "ponha aqui um eixo novo de
comprimento 1". `[:, np.newaxis]` mantém todos os elementos no primeiro eixo e acrescenta um
segundo; `[np.newaxis, :]` o acrescentaria à esquerda, dando `(1, 52)`. `reshape(-1, 1)` diz o
mesmo em termos do formato final. Os três são views: nenhum número é copiado.

Com o eixo no lugar, a subtração da seção anterior funciona:

```python
deviation = weeks - weekly_flat[:, np.newaxis]
deviation.shape, deviation[0].round(2)
```

```
((52, 7), array([-0.47, -0.37,  0.33,  0.83,  0.43, -0.87,  0.13]))
```

Cada linha agora guarda quanto cada dia se afastou da média da própria semana, e cada linha soma
aproximadamente zero, o que é uma conferência rápida de que a coisa certa foi subtraída da coisa
certa:

```python
np.abs(deviation.sum(axis=1)).max() < 1e-9
```

```
np.True_
```

## O hábito que evita isso

**Quando você reduz algo que vai subtrair de volta, mantenha a dimensão.** `keepdims=True` na
redução produz o `(52, 1)` direto, e diz no código por que o formato é o que é. Acrescentar o eixo
depois funciona; é o passo que as pessoas esquecem.

| você tem | quer que case com | escreva |
|---|---|---|
| um valor por linha, `(n,)` | cada linha de uma tabela `(n, m)` | `x[:, np.newaxis]`, ou reduza com `keepdims=True` |
| um valor por coluna, `(m,)` | cada coluna de uma tabela `(n, m)` | `x` como está: já se alinha pela direita |
| uma coluna, `(n, 1)` | uma linha, `(m,)`, para ter todos os pares | `x - y`, de propósito: "Todos os pares, de propósito", adiante |
