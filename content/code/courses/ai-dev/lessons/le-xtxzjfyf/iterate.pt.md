---
title: Devolvendo a evidência
version: 2
---

A primeira resposta raramente é a última, e a pergunta útil é o que mandar de volta. "Está errado,
tente de novo" não dá nada de novo ao modelo; ele vai produzir uma variação do mesmo palpite. **Mande
a evidência de que estava errado**: o teste que falha, o erro, a saída, exatamente como as
ferramentas imprimiram. É a mesma regra da aula 5 seção 03, aplicada à segunda rodada.

## A falha, literal

O `--tb=line` faz o pytest imprimir cada falha numa linha, o que é curto o bastante para mandar:

```
ana@dev:~/shop$ python -m pytest -q --tb=line tests/test_comma.py > failure.txt; cat failure.txt
.F...                                                                    [100%]
=================================== FAILURES ===================================
E   ValueError: invalid literal for int() with base 10: '12.90'
/home/ana/shop/shop/money.py:8: ValueError: invalid literal for int() with base 10: '12.90'
=========================== short test summary info ============================
FAILED tests/test_comma.py::test_a_comma_or_a_dot_is_the_decimal_separator[12.90]
1 failed, 4 passed in 0.72s
```

## Três rodadas

Cada rodada manda o prompt, a falha e o código atual, troca a resposta no lugar e roda a suíte
inteira, gravando as falhas novas em `failure.txt` para a rodada seguinte. A ana dá três rodadas e
para na primeira que passar:

```
ana@dev:~/shop$ python scratch/assist.py ask "$(cat prompts/comma.md) The parse_price in shop/money.py below fails these tests, which must pass: $(cat failure.txt)" --open shop/money.py tests/test_comma.py CONVENTIONS.md --write scratch/parse_price.py > /dev/null
context sent (608 of 3000 tokens):
    137  shop/money.py
     97  tests/test_comma.py
    374  CONVENTIONS.md
---
ana@dev:~/shop$ cat scratch/parse_price.py
def parse_price(text: str) -> int:
    """Turn a price as people write it into cents: '12,90' -> 1290."""
    if ',' in text and '.' in text:
        raise ValueError("Invalid decimal separator")
    units, _, cents = text.strip().partition(",")
    cents = (cents + "00")[:2]
    return int(units) * 100 + int(cents)
ana@dev:~/shop$ python scratch/swap.py shop/money.py scratch/parse_price.py && python -m pytest -q --tb=line > failure.txt; tail -n 3 failure.txt
swap: parse_price replaced in shop/money.py
FAILED tests/test_comma.py::test_a_comma_or_a_dot_is_the_decimal_separator[12.90]
FAILED tests/test_money.py::test_parse_price - ValueError: invalid literal fo...
2 failed, 11 passed in 0.70s
```

A primeira rodada acrescentou algo de verdade: um preço com vírgula e ponto agora levanta `ValueError`
de propósito, que era o que o teste do `1.234,56` queria dizer. Ela ainda divide na vírgula, então o
`12.90` falha como antes, no teste novo e no antigo. Rodadas dois e três:

```
ana@dev:~/shop$ python scratch/assist.py ask "$(cat prompts/comma.md) The parse_price in shop/money.py below fails these tests, which must pass: $(cat failure.txt)" --open shop/money.py tests/test_comma.py CONVENTIONS.md --write scratch/parse_price.py > /dev/null
context sent (627 of 3000 tokens):
    156  shop/money.py
     97  tests/test_comma.py
    374  CONVENTIONS.md
---
ana@dev:~/shop$ cat scratch/parse_price.py
def parse_price(text: str) -> int:
    """Turn a price as people write it into cents: '12,90' -> 1290."""
    if ',' in text and '.' in text:
        raise ValueError("Invalid decimal separator")
    units, _, cents = text.strip().partition(",")
    cents = (cents + "00")[:2]
    return int(units) * 100 + int(cents)
ana@dev:~/shop$ python scratch/swap.py shop/money.py scratch/parse_price.py && python -m pytest -q --tb=line > failure.txt; tail -n 3 failure.txt
swap: parse_price replaced in shop/money.py
FAILED tests/test_comma.py::test_a_comma_or_a_dot_is_the_decimal_separator[12.90]
FAILED tests/test_money.py::test_parse_price - ValueError: invalid literal fo...
2 failed, 11 passed in 0.73s
ana@dev:~/shop$ python scratch/assist.py ask "$(cat prompts/comma.md) The parse_price in shop/money.py below fails these tests, which must pass: $(cat failure.txt)" --open shop/money.py tests/test_comma.py CONVENTIONS.md --write scratch/parse_price.py > /dev/null
context sent (627 of 3000 tokens):
    156  shop/money.py
     97  tests/test_comma.py
    374  CONVENTIONS.md
---
ana@dev:~/shop$ cat scratch/parse_price.py
def parse_price(text: str) -> int:
    """Turn a price as people write it into cents: '12,90' -> 1290."""
    if ',' in text and '.' in text:
        raise ValueError("Invalid decimal separator")
    units, _, cents = text.strip().partition(",")
    cents = (cents + "00")[:2]
    return int(units) * 100 + int(cents)
ana@dev:~/shop$ python scratch/swap.py shop/money.py scratch/parse_price.py && python -m pytest -q --tb=line > failure.txt; tail -n 3 failure.txt
swap: parse_price replaced in shop/money.py
FAILED tests/test_comma.py::test_a_comma_or_a_dot_is_the_decimal_separator[12.90]
FAILED tests/test_money.py::test_parse_price - ValueError: invalid literal fo...
2 failed, 11 passed in 0.71s
```

**A mesma função, caractere por caractere, três vezes.** Com o código que ele mesmo tinha escrito e
os dois testes que ele quebrava, o modelo devolveu o próprio código sem mudança. Mais rodadas não
teriam ajudado. A evidência estava toda na requisição, e o modelo não agiu sobre ela. Um modelo de
três bilhões de parâmetros desiste nesse tipo de passo antes de um grande, e quando isso acontece o
próximo movimento é seu, e não mais uma rodada.

## À mão

A ana para, como diz a primeira regra abaixo, e escreve a função ela mesma. São oito linhas, e a
ideia da primeira rodada, de recusar um preço com os dois separadores, vale a pena manter:

```python
def parse_price(text: str) -> int:
    """Turn a price as people write it into cents: '12.90' or '12,90' -> 1290."""
    text = text.strip()
    if "." in text and "," in text:
        raise ValueError(f"a dot and a comma in one price: {text!r}")
    units, _, cents = text.replace(",", ".").partition(".")
    cents = (cents + "00")[:2]
    return int(units) * 100 + int(cents)
```

```
ana@dev:~/shop$ git checkout -q shop/money.py && python scratch/swap.py shop/money.py scratch/parse_price.py && python -m pytest -q
swap: parse_price replaced in shop/money.py
.............                                                            [100%]
13 passed in 0.69s
```

Treze testes: os oito que o projeto tinha e os cinco novos. Os testes que ela escreveu na aula 5,
seção 06, julgaram o código dela do mesmo jeito que julgaram o do modelo, e é isso que faz valer a
pena escrevê-los primeiro: eles não se importam com quem escreveu a mudança.

## Quando parar de iterar

- **Quando os testes passam**, e é por isso que foram escritos primeiro. Sem eles, "pronto" é uma
  sensação.
- **Quando a mesma falha volta duas vezes.** Um modelo que não corrige algo na segunda tentativa,
  com a evidência na mão, raramente corrige na quinta; acima, ele nem mudou a resposta. O problema
  costuma ser contexto que falta (um arquivo que ele não viu) ou um requisito que contradiz outro.
  Leia o código você mesmo, ou mude o que manda.
- **Quando as mudanças crescem.** Uma correção que mexe em mais coisas a cada rodada está se
  afastando do problema. Volte ao último estado bom e faça uma pergunta mais estreita.

Cada rodada é uma requisição, e a aula 2 seção 06 vale: uma conversa que leva todas as tentativas
anteriores fica mais cara a cada turno. Começar uma requisição nova com o código atual e a falha
atual muitas vezes é ao mesmo tempo mais barato e melhor.
