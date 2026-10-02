---
title: A evidência vence a descrição
version: 1
---

As pessoas descrevem um bug com as próprias palavras: "o parse_price quebra com vírgulas". O modelo
então tem de adivinhar que linha, que entrada, que erro. **Cole a evidência em vez disso**: o
comando exato, a entrada exata e o traceback exato. É mais curto copiar do que descrever, e traz
detalhes que você não teria pensado em mencionar.

## O traceback, como o programa o escreveu

```
ana@dev:~/shop$ python -c 'from shop.money import parse_price; print(parse_price("12,90"))'
Traceback (most recent call last):
  File "<string>", line 1, in <module>
  File "/home/ana/shop/shop/money.py", line 8, in parse_price
    return int(units) * 100 + int(cents)
           ^^^^^^^^^^
ValueError: invalid literal for int() with base 10: '12,90'
```

Quatro linhas de fatos úteis: o arquivo, a linha, a expressão `int(units) * 100`, e o valor que
falhou, `'12,90'`. Essa última parte diz que a string inteira chegou ao `int()` como as unidades,
então a função nunca a dividiu, porque divide no ponto. Uma descrição teria dito "quebra"; o
traceback diz por quê.

A ana o salva num arquivo, para ele entrar na requisição byte a byte:

```
ana@dev:~/shop$ python -c 'from shop.money import parse_price; print(parse_price("12,90"))' 2> error.txt; cat error.txt
Traceback (most recent call last):
  File "<string>", line 1, in <module>
  File "/home/ana/shop/shop/money.py", line 8, in parse_price
    return int(units) * 100 + int(cents)
           ^^^^^^^^^^
ValueError: invalid literal for int() with base 10: '12,90'
```

## O pedido com a evidência

O prompt estruturado da aula 5 seção 02, o traceback, e três arquivos de contexto: a função, os
testes dela e as convenções:

```
ana@dev:~/shop$ assist ask "$(cat prompts/comma.md) Traceback from running it: $(cat error.txt)" --open shop/money.py tests/test_money.py CONVENTIONS.md > comma.diff
context sent (596 of 3000 tokens):
    137  shop/money.py
     85  tests/test_money.py
    374  CONVENTIONS.md
---
ana@dev:~/shop$ cat comma.diff
diff --git a/shop/money.py b/shop/money.py
index 9af0e26..3eb6322 100644
--- a/shop/money.py
+++ b/shop/money.py
@@ -3,7 +3,7 @@
 
 def parse_price(text: str) -> int:
     """Turn a price as people write it into cents: '12.90' -> 1290."""
-    units, _, cents = text.strip().partition(".")
+    units, _, cents = text.strip().replace(",", ".").partition(".")
     cents = (cents + "00")[:2]
     return int(units) * 100 + int(cents)
 
```

**Um diff de uma linha**, em inteiros, mexendo só no `parse_price`. A resposta foi escrita pelo
curso, mas a forma da melhora é a geral. Com o erro e as regras no contexto sobra muito menos para
adivinhar, e os chutes que restam são sobre o código que está na frente do modelo e não sobre um
código que ele imagina.

## O que conta como evidência

- **A mensagem de erro e o traceback, sem edição.** Inclusive as partes que parecem irrelevantes: o
  caminho do arquivo diz que cópia do código rodou.
- **O comando que o produziu**, para a entrada ser exata.
- **Versões**, quando o problema pode ser uma: a versão da biblioteca no `pip list`, a do Python. A
  "API que existia" da aula 1 seção 07 se resolve com esta linha.
- **O que você já tentou**, para a resposta não sugerir isso.

E uma coisa a tirar antes: **segredos**. Um traceback pode levar uma string de conexão, uma linha de
log pode levar um token. A aula 3 seção 03 vale para o que você cola tanto quanto para o que um
editor manda.
