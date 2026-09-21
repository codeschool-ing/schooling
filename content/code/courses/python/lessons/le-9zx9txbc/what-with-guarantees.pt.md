---
title: `try`/`finally`, com um nome
version: 1
---

```python
with open(caminho, encoding="utf-8") as f:
    processar(f)
```

Três coisas acontecem, em ordem: a PREPARAÇÃO (o arquivo é aberto), o CORPO, e o DESFAZER (o
arquivo é fechado). A terceira acontece termine a segunda como terminar.

## A mesma coisa, escrita por extenso

```python
f = open(caminho, encoding="utf-8")
try:
    processar(f)
finally:
    f.close()
```

É isso que o `with` faz, e a aula 8 escreveu. O que o `with` acrescenta é que o desfazer mora ao
lado da preparação, dentro da coisa que está sendo usada, em vez de no fim de quem lembrou.

## "Termine o corpo como terminar"

- ele chega ao fim
- ele dá `return`
- ele dá `break` ou `continue` num laço
- ele levanta erro

**Nos cinco o desfazer roda.** A exceção então segue para cima, sem mudança — o gerenciador
arrumou e não interferiu.

## O que isso compra, numa frase

Quem USA não consegue esquecer. Um `open` sem `with` é um `close` que alguém precisa lembrar em
todo caminho de saída de toda função, para sempre; o `with` é uma linha e o problema não existe.

## Onde você já viu isso

```python
with open(caminho) as f: ...         # aula 9
with trava: ...                      # uma trava de thread
with conn: ...                       # uma transação de banco
with tempfile.TemporaryDirectory() as d: ...
```

Cada um é a mesma forma com um desfazer diferente: fechar, soltar, confirmar ou desfazer, apagar.

## E a frase a levar

**Se alguma coisa precisa ser desfeita, o desfazer pertence à coisa que fez** — e não a um
comentário, nem a quem chama, nem a um `finally` que alguém vai esquecer.
