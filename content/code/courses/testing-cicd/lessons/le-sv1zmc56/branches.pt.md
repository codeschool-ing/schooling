---
title: Linhas e ramos
version: 1
---

A cobertura de linhas pergunta se cada linha rodou. A **cobertura de ramos** pergunta, em cada
decisão, se cada saída foi tomada. A diferença aparece num `if` sem `else`, e a regra de despacho do
`shipquote` tem um:

```python
def dispatch_date(ordered_at: float) -> date:
    """The day an order placed at this Unix time leaves the warehouse."""
    local = datetime.fromtimestamp(ordered_at, WAREHOUSE)
    day = local.date()
    if local.time() >= CUTOFF:
        day += timedelta(days=1)
    while day.weekday() >= 5:     # Saturday and Sunday
        day += timedelta(days=1)
    return day
```

A linha 13 decide se o pedido é depois do corte. Se for, a linha 14 soma um dia. Se não for, a
execução vai direto da linha 13 para a 15. Aqui dois dos três testes de despacho rodam sozinhos: o
pedido de segunda depois das duas e o de sexta à tarde. **Os dois são depois das 14:00**, então o
caminho "antes do corte" nunca é tomado.

Primeiro só com cobertura de linhas, mandando o `coverage` ignorar a configuração do projeto:

```
ana@laptop:~/shipquote$ coverage run --rcfile=/dev/null --source=shipquote -m pytest -q tests/test_dispatch.py -k "after_two or friday"
..                                                                       [100%]
2 passed, 1 deselected in 0.19s
ana@laptop:~/shipquote$ coverage report --rcfile=/dev/null -m --include=shipquote/dispatch.py
Name                    Stmts   Miss  Cover   Missing
-----------------------------------------------------
shipquote/dispatch.py      12      0   100%
-----------------------------------------------------
TOTAL                      12      0   100%
```

**100%.** Toda linha rodou: a 14 rodou para os dois pedidos, e o laço do fim de semana, nas linhas
15 e 16, rodou para o de sexta. Nada neste relatório diz que o caso mais comum de todos, um pedido
antes das duas, nunca foi tentado.

Depois com a configuração do projeto, que liga os ramos:

```
ana@laptop:~/shipquote$ coverage run -m pytest -q tests/test_dispatch.py -k "after_two or friday"
..                                                                       [100%]
2 passed, 1 deselected in 0.19s
ana@laptop:~/shipquote$ coverage report -m --include=shipquote/dispatch.py
Name                    Stmts   Miss Branch BrPart  Cover   Missing
-------------------------------------------------------------------
shipquote/dispatch.py      12      0      4      1    94%   13->15
-------------------------------------------------------------------
TOTAL                      12      0      4      1    94%
```

**94%**, e o que falta não é uma linha, é um arco: `13->15`, o salto da decisão direto para o laço,
que só acontece quando o pedido é antes do corte. Um defeito nesse caminho, um pedido às 13:30
mandado para o dia seguinte, passaria por estes dois testes e pelo relatório de linhas.

## Por que a cobertura de ramos é o padrão a querer

A cobertura de linhas é o número que a maioria das ferramentas mostra primeiro, e ela exagera o que
foi testado de forma sistemática: todo `if` sem `else` é um lugar onde só um dos dois resultados
precisa acontecer para a linha contar. A cobertura de ramos fecha essa lacuna quase sem custo, e é
por isso que o `shipquote` a liga no `pyproject.toml` e o relatório da equipe mostra as colunas
`Branch` e `BrPart`.

## O que nenhuma das duas vê

As duas medem saltos **entre linhas**. Uma decisão que mora dentro de uma linha é invisível para
ambas:

```python
    sign = "-" if cents < 0 else ""
```

Essa linha de `brl` é coberta por todo teste que formata um preço, e nenhum teste do `shipquote`
formata um negativo. Cobertura de linhas e de ramos a mostram como totalmente coberta. Expressões de
curto-circuito como `a or b` se escondem do mesmo jeito. Cobertura é um piso: diz que algo nunca
rodou, e pode ser enganada a dizer que algo rodou.
