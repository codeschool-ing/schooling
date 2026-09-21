---
title: Classes, e as duas que você não deve capturar
version: 1
---

Toda exceção é uma classe, e elas formam uma árvore:

```
BaseException
 ├── SystemExit           ← sys.exit()
 ├── KeyboardInterrupt    ← Ctrl-C
 └── Exception
      ├── ValueError
      ├── TypeError
      ├── LookupError
      │    ├── KeyError
      │    └── IndexError
      ├── OSError
      │    └── FileNotFoundError
      └── ...
```

`except LookupError` captura um `KeyError` e um `IndexError`, porque capturar uma classe captura
tudo abaixo dela. Essa é a única regra que você precisa tirar do desenho.

## `except Exception`, e nunca um `except` pelado

```python
try:
    ...
except:              # NÃO
except Exception:    # a rede larga, quando você quer uma
```

`SystemExit` e `KeyboardInterrupt` ficam FORA de `Exception` de propósito: eles não são erros do
programa, são alguém pedindo que o programa pare. Um `except` pelado os captura, e aí o `Ctrl-C`
não funciona.

**`except Exception` pertence ao topo de um programa**, uma vez, onde o trabalho é registrar o que
aconteceu e sair com status diferente de zero. Em todo outro lugar ele é uma rede lançada sobre
código que você não leu.

## Capturar uma classe captura os filhos dela

```python
except OSError:          # inclui FileNotFoundError e PermissionError
except (ValueError, TypeError):    # duas sem relação, numa tupla
```

A forma de tupla é para classes sem relação. A forma da classe base diz algo sobre o que você se
dispõe a tratar, então ela envelhece melhor conforme o código abaixo dela cresce.

## O que uma exceção carrega

```python
except ValueError as e:
    print(e)             # a mensagem
    print(type(e))       # a classe
```

O objeto tem a mensagem, a classe e o traceback. Num log, imprima os três — a classe sozinha diz
`ValueError` e a mensagem sozinha diz `invalid literal for int()`, e nenhuma das duas diz em que
linha.
