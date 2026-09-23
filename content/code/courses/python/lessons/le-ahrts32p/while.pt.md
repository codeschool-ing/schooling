---
title: A condição tem de mudar
version: 2
---

```python
attempts = 0
while attempts < 3:
    if try_once():
        break
    attempts += 1
```

O `while` repete enquanto a condição valer. **Algo dentro do laço tem de mudá-la**, ou ele nunca
para — e é esse o risco inteiro deste construto comparado ao `for`.

## Quando usar

`for` quando você sabe o que está iterando. `while` quando não sabe:

- ler até um sentinela ou até o fim de um fluxo
- repetir até dar certo ou até acabarem as tentativas
- um laço de jogo, rodando até alguém sair

Se der para expressar como `for … in`, faça. `while` sobre um índice é o `for` com a segurança
removida.

## `while True` com um `break`

```python
while True:
    line = input("> ")
    if line == "quit":
        break
    handle(line)
```

Isto é Python idiomático e não um cheiro ruim, e muitas vezes é mais claro do que duplicar a leitura
antes do laço e no fim dele. A regra é que o `break` precisa ser **visível**: um só, perto do topo, e
não enterrado três níveis para dentro.

## O infinito

```python
i = 0
while i < 10:
    print(i)          # i never changes
```

Sem erro, sem mensagem, e o programa nunca termina. `Ctrl-C` para. Depois procure a linha que deveria
ter movido a condição — ela está faltando, ou está dentro de um `if` que não rodou.

## `else`, de novo

`while … else` roda quando a condição ficou falsa sem um `break`, exatamente como a versão do `for`.
Mesma utilidade, mesma tendência a ser lido errado.

## O padrão a evitar

```python
i = 0
while i < len(items):
    print(items[i])
    i += 1
```

Três linhas de contabilidade e duas chances de errar, para algo que `for item in items` diz numa. Se
você encontrar isto em código que está lendo, é quase sempre tradução de uma linguagem sem `for … in`.
