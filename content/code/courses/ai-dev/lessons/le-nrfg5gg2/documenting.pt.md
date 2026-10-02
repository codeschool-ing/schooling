---
title: Documentação que roda
version: 1
---

Escrever docstrings é a tarefa que as pessoas entregam mais contentes a um assistente: é chata, o
assistente é fluente, e ninguém lê documentação com atenção suficiente para discutir com ela. Essa
última parte é o risco. **Uma docstring faz afirmações sobre o código, e uma afirmação errada e
fluente é acreditada** pela próxima pessoa, que não tem motivo para conferir.

O Python tem um jeito de tornar algumas dessas afirmações conferíveis. Um exemplo de docstring
escrito como uma sessão interativa (`>>>` e a saída esperada) é um **doctest**, e o pytest
consegue rodá-lo.

## Pedindo uma docstring

A ana pede uma docstring com exemplos para o `format_price`. A resposta foi escrita pelo curso:

```
ana@dev:~/shop$ assist ask "Write a docstring with examples for format_price." --open shop/money.py
context sent (137 of 3000 tokens):
    137  shop/money.py
---
    """Turn cents into a price as people read it.

    >>> format_price(1290)
    '12.90'
    >>> format_price(5)
    '0.05'
    >>> format_price(-5)
    '-0.05'
    """

```

Três exemplos, e parecem os óbvios. A ana põe a docstring no `shop/money.py` e, antes do commit,
roda:

```
ana@dev:~/shop$ python -m pytest -q --doctest-modules shop/money.py
F                                                                        [100%]
=================================== FAILURES ===================================
______________________ [doctest] shop.money.format_price _______________________
012 Turn cents into a price as people read it.
013 
014     >>> format_price(1290)
015     '12.90'
016     >>> format_price(5)
017     '0.05'
018     >>> format_price(-5)
Expected:
    '-0.05'
Got:
    '-1.95'

/home/ana/shop/shop/money.py:18: DocTestFailure
=========================== short test summary info ============================
FAILED shop/money.py::shop.money.format_price
1 failed in 0.55s
```

**O terceiro exemplo está errado, e o código também.** A docstring diz que `-5` centavos deve ser
lido como `'-0.05'`, que é o que qualquer pessoa esperaria. A função devolve `'-1.95'`, porque o
`//` do Python arredonda para menos infinito: `-5 // 100` é `-1` e `-5 % 100` é `95`. O exemplo foi
escrito a partir do que a função deve fazer, o código faz outra coisa, e ninguém nunca tinha
perguntado a ele sobre um valor negativo.

Então a docstring do assistente achou um bug de verdade, por acaso, e só porque foi rodada. Se a
ana tivesse lido os três exemplos e feito commit, a documentação agora afirmaria algo falso sobre o
código, no único lugar onde as pessoas olham para saber o que ele faz. A aula 4 volta a esta função
e acha a classe inteira de entradas que ela erra.

## Regras para documentação gerada

- **Rode todo exemplo.** Um doctest, um trecho do README que um teste executa, um exemplo de API
  que a CI chama. Documentação que é executada não se afasta do código sem falhar.
- **Confira contra o código toda afirmação que não for exemplo**: as exceções que levanta, as
  unidades dos argumentos, o que faz com uma lista vazia. São exatamente os detalhes que um
  escritor fluente preenche por plausibilidade.
- **Prefira o motivo à paráfrase.** `"""Return the total."""` em cima de `def total()` não diz nada
  que o nome não dissesse. O que um leitor precisa de uma docstring é o que o código não consegue
  dizer: a unidade, a regra de arredondamento, por que o limite vem depois do desconto. Isso é
  conhecimento sobre o projeto, e o assistente só o tem se você o puser no contexto.
