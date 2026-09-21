---
title: O número diz o que rodou, não o que foi conferido
version: 1
---

```sh
pytest --cov=app --cov-report=term-missing
```

```text
Name              Stmts   Miss  Cover   Missing
-----------------------------------------------
app/__init__.py       0      0   100%
app/rates.py          6      2    67%   4-5
-----------------------------------------------
TOTAL                 6      2    67%
```

**`Missing` é a coluna útil.** A porcentagem é manchete; as linhas 4 e 5 são um lugar onde olhar.
Aqui elas são o corpo de `fetch`, que um `monkeypatch` substituiu — então o número está dizendo a
verdade e a verdade é que nada exercitou a função de verdade.

## Cem por cento, com um defeito

```python
def tax(valor, taxa):
    return valor * taxa * 2        # dobrado

def test_total_roda():
    resultado = total([(2, 10.0)], 0.1)
    assert resultado is not None
```

```text
app/invoice.py        7      0   100%
1 passed
```

Toda linha rodou. Nada sobre a resposta foi afirmado. **A cobertura mede execução e não tem como
enxergar uma asserção**, então ela não consegue distinguir uma linha provada de uma linha que
apenas aconteceu — e isto não é hipótese, é o módulo em que a demonstração acha um imposto
dobrado.

## Para o que ela serve

A outra direção. Uma linha em 0% é uma linha que teste nenhum jamais rodou, e essa lista é
confiável, específica e vale ler. A cobertura é uma **achadora de lacunas**, não uma medida de
qualidade — e a lacuna que ela acha em geral é um caminho de erro que alguém escreveu e nunca
exercitou.

## Cobertura de ramos

```sh
pytest --cov=app --cov-branch --cov-report=term-missing
```

```text
Name              Stmts   Miss Branch BrPart  Cover   Missing
-------------------------------------------------------------
app/guard.py          4      1      2      1    67%   4
```

Sem o `--cov-branch`, um `if` cujo corpo sempre rodou conta como coberto mesmo que o outro caminho
por ele nunca tenha rodado. Com ele, um ramo tomado pela metade é relatado como `BrPart`. Fica
mais perto da pergunta que você queria fazer.

## A meta na CI

```toml
[tool.coverage.report]
fail_under = 80
```

Um piso que impede o número de cair é defensável. Uma meta que alguém precisa alcançar é onde
testes passam a ser escritos para tocar linhas em vez de conferir comportamento, e
`assert resultado is not None` é o que isso produz.

**Cobertura não é meta.** Escreva o teste que teria pegado a falha que você acabou de achar, e o
do modo de falhar que você consegue nomear.
