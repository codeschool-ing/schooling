---
title: Quatro lugares, numa ordem fixa
version: 1
---

Um nome é resolvido olhando em quatro lugares, sempre nesta ordem:

**L**ocal → **E**nvolvente → **G**lobal → em**B**utido.

```python
total = 0                 # global (nível do módulo)

def externa():
    conta = 1             # envolvente, do ponto de vista da interna
    def interna():
        n = 2             # local
        print(n, conta, total, len)     # um de cada
    interna()
```

O primeiro lugar que tem o nome vence, e o Python nunca pergunta qual deles você queria.

## Atribuir é o que torna um nome local

```python
total = 0

def somar():
    total = total + 1     # UnboundLocalError
```

O erro acontece na leitura, e a leitura parece correta. **O Python decide que `total` é local
varrendo o corpo da função atrás de uma atribuição — antes de rodar uma linha dele.** Existe uma,
então `total` é local em todo o corpo, inclusive à direita da linha que o atribui. O `total` do
módulo não é consultado.

Ler uma global sem atribuir a ela funciona bem, e é isso que confunde: a função estava correta até
uma linha ser acrescentada lá embaixo.

## Sombrear um embutido

```python
list = [1, 2, 3]      # agora `list(...)` está quebrado neste escopo
```

Sem erro, e nada avisa. `list`, `dict`, `id`, `type`, `sum`, `input` e `str` são os que as pessoas
tomam por acidente. Acrescente um sublinhado — `list_` — ou escolha um nome melhor, que costuma ser
o que a colisão estava dizendo.

## A variável do laço não é um escopo

```python
for linha in linhas:
    ...
print(linha)        # ainda aqui
```

O último engano da aula 4, visto daqui: um `for`, um `if` e um `while` não fazem escopo em Python.
Só uma função faz — e um módulo, e uma classe.
