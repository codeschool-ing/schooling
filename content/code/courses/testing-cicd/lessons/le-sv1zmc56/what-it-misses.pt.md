---
title: Coberto não é conferido
version: 2
---

Uma linha conta como coberta quando **rodou**. Nada na medição pergunta se um teste olhou o que ela
fez. Essa lacuna é fácil de dizer e fácil de esquecer, então aqui ela fica concreta.

Este arquivo de teste foi escrito para esta seção, e você o apaga no fim dela. Chama todas as
funções de `money.py` e não verifica nada. Salve como `tests/test_money_runs.py`:

```python
from shipquote.money import brl, split


def test_brl_runs():
    brl(123456)
    brl(1205)


def test_split_runs():
    split(10000, 3)
    try:
        split(10000, 0)
    except ValueError:
        pass
```

Medido sozinho:

```
ana@laptop:~/shipquote$ coverage run -m pytest -q tests/test_money_runs.py
..                                                                       [100%]
2 passed in 0.18s
ana@laptop:~/shipquote$ coverage report -m --include=shipquote/money.py
Name                 Stmts   Miss Branch BrPart  Cover   Missing
----------------------------------------------------------------
shipquote/money.py       9      0      2      0   100%
----------------------------------------------------------------
TOTAL                    9      0      2      0   100%
ana@laptop:~/shipquote$ python -m pytest -q tests/test_money_runs.py
..                                                                       [100%]
2 passed in 0.13s
```

**100% de `money.py`, ramos incluídos**, mais do que a suíte real alcançou na seção 02, onde a linha
14 faltava. Depois a `brl` é quebrada do mesmo jeito que a aula 1 a quebrou, perdendo o zero que
completa os centavos, e os mesmos dois testes rodam de novo: continuam verdes. Um arquivo pode estar
totalmente coberto por testes que não perceberiam que ele devolve bobagem. Ponha o `brl` de volta
com `git checkout shipquote/money.py` e apague `tests/test_money_runs.py`.

Ninguém escreve um arquivo de teste assim de propósito, mas toda suíte tem pedaços de um: um teste
que confere o código de status e não o corpo, um teste cuja verificação é `is not None`, uma chamada
feita na preparação e nunca conferida. **A cobertura conta todos eles igual a um teste cuidadoso.**

## Então para que serve a cobertura?

Para a metade da pergunta que ela responde com exatidão. **Uma linha que nunca rodou é uma linha que
nenhum teste pode ter conferido.** O relatório da seção 02 apontou cinco lugares assim no
`shipquote`, entre eles uma classe inteira cujos únicos testes foram pulados. Essa lista vale ser
lida depois de cada mudança, e é a parte do relatório que não tem como mentir.

A outra metade, *os testes conferiram o que o código coberto fez?*, precisa de outra ferramenta. A
próxima seção usa a mais direta: quebrar o código de propósito e ver se algum teste percebe.
