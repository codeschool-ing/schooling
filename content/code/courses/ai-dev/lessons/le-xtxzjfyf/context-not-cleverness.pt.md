---
title: A evidência vence a descrição
version: 2
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
testes dela e as convenções. O `--write` guarda o primeiro bloco de código da resposta, o diff, em
`comma.diff`:

```
ana@dev:~/shop$ python scratch/assist.py ask "$(cat prompts/comma.md) Traceback from running it: $(cat error.txt)" --open shop/money.py tests/test_money.py CONVENTIONS.md --write comma.diff > /dev/null
context sent (596 of 3000 tokens):
    137  shop/money.py
     85  tests/test_money.py
    374  CONVENTIONS.md
---
ana@dev:~/shop$ cat comma.diff
--- /dev/null
+++ shop/money.py
@@ -8,6 +8,7 @@
 def parse_price(text: str) -> int:
     units, _, cents = text.strip().partition(".")
     # Introduce a comma as a decimal separator
     if ',' in text:
         cents = text.replace(',', '.').strip()
     cents = (cents + "00")[:2]
     return int(units) * 100 + int(cents)
```

**Agora a resposta é sobre a coisa certa.** Ela trata a vírgula como separador decimal, só mexe no
`parse_price` e fica nos inteiros: nenhum `float` em lugar nenhum, o que o pedido de uma linha não
pediu e este pediu. Com o erro e as regras no contexto sobra muito menos para adivinhar, e os palpites
que restam são sobre o código diante do modelo, e não sobre um código que ele imagina.

Ainda não é uma boa resposta. As unidades continuam sendo separadas num ponto, então `12,90` chega
inteiro ao `int()`, exatamente como no traceback; e as linhas novas põem o preço inteiro em `cents`,
unidades incluídas, e ficam com os dois primeiros caracteres. E não é um diff que algo consiga
aplicar: diz que o arquivo é novo (`--- /dev/null`), e o cabeçalho promete seis linhas do arquivo
antigo onde o corpo cita sete. Se uma resposta está certa é uma pergunta para um programa tanto
quanto para uma pessoa, e a aula 5 seção 05, a faz.

## O que conta como evidência

- **A mensagem de erro e o traceback, sem edição.** Inclusive as partes que parecem irrelevantes: o
  caminho do arquivo diz que cópia do código rodou.
- **O comando que o produziu**, para a entrada ser exata.
- **Versões**, quando o problema pode ser uma: a versão da biblioteca no `pip list`, a do Python. A
  "API que existia" da aula 1 seção 11 se resolve com esta linha.
- **O que você já tentou**, para a resposta não sugerir isso.

E uma coisa a tirar antes: **segredos**. Um traceback pode levar uma string de conexão, uma linha de
log pode levar um token. A aula 3 seção 03 vale para o que você cola tanto quanto para o que um
editor manda.
