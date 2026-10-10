---
title: Lendo o erro
version: 1
---

**O erro de broadcasting nomeia os dois formatos, e os formatos são todo o diagnóstico.** É o erro
que você mais vai encontrar no NumPy e o mais fácil de corrigir, depois que você o lê como a regra
falhando e não como algo misterioso.

Subtraia de cada semana a média dela, do jeito natural, sem `keepdims`:

```python
weekly_flat = weeks.mean(axis=1)
weeks - weekly_flat
```

```
ValueError: operands could not be broadcast together with shapes (52,7) (52,) 
```

Alinhe os formatos pela direita, como a regra manda: `(52, 7)` contra `(52,)`. O par mais à
direita é `7` e `52`: nem iguais nem 1. **O NumPy não tenta o outro alinhamento.** Ele nunca
adivinha que você quis o 52 com o 52; ele só alinha pela direita, e é por isso que a mesma subtração
funciona com `(52, 1)`.

O espaço depois de `(52,)` na mensagem é do NumPy, aliás, não um erro de digitação deste curso.

## Três perguntas que resolvem

Todo erro de broadcasting se responde com estas, nesta ordem:

1. **Quais são os dois formatos?** A mensagem diz. Se não disser, pergunte o `.shape` de cada array.
2. **Qual eixo deveria casar?** Aqui, as 52 semanas.
3. **Esse eixo está à direita nos dois?** Aqui, não: é o eixo da esquerda de `weeks` e o único eixo
   de `weekly_flat`. Dê a `weekly_flat` um eixo de comprimento 1 à direita, e o 52 vai para a
   esquerda, onde deve estar. A próxima seção mostra como.

O mesmo erro aparece no pandas, da aula 9 em diante, sempre que uma conta desce para o NumPy, e as
mesmas três perguntas o respondem lá.

Um erro parecido, que não é de broadcasting, é a diferença de formato num produto de matrizes:

```python
weeks @ by_position[:5]
```

```
ValueError: matmul: Input operand 1 has a mismatch in its core dimension 0, with gufunc signature (n?,k),(k,m?)->(n?,m?) (size 5 is different from 7)
```

`@` é a multiplicação de matrizes, que exige que os comprimentos internos combinem, `7` e `5` aqui.
Operadores elemento a elemento fazem broadcasting; `@` faz álgebra linear. A mensagem diz
`matmul` para que você saiba distinguir os dois.
