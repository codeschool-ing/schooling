---
title: Um primeiro teste, passando e falhando
version: 1
---

Um teste no pytest é uma função cujo nome começa com `test_`, num arquivo cujo nome começa com
`test_`. Dentro dela você chama seu código e afirma o que precisa ser verdade com um `assert`
simples. O pytest acha as funções, roda cada uma e informa quais afirmações se sustentaram.

Este é o `tests/test_money.py` inteiro, o primeiro arquivo de testes que o `shipquote` teve. Ele
verifica `brl`, que formata centavos como preço brasileiro, e `split`, que divide um total em
parcelas.

```python
from shipquote.money import brl, split


def test_brl_uses_a_dot_for_thousands_and_a_comma_for_cents():
    assert brl(123456) == "R$ 1.234,56"


def test_brl_keeps_two_digits_of_cents():
    assert brl(1205) == "R$ 12,05"


def test_split_hands_the_odd_cents_to_the_first_instalments():
    assert split(10000, 3) == [3334, 3333, 3333]


def test_split_adds_back_up_to_the_total():
    assert sum(split(19990, 7)) == 19990
```

Cada teste faz os mesmos três movimentos, muitas vezes chamados de **preparar, agir, verificar**
(*arrange, act, assert*): montar as entradas, chamar o código, conferir o resultado. Aqui a
preparação são só os argumentos literais, então cada teste tem uma linha. Repare que **todo valor é
um número inteiro de centavos**: 123456 é R$ 1.234,56. A próxima seção mostra por que um float
faria esses testes mentirem.

## Rodando

`python -m pytest` roda os testes com o interpretador do ambiente virtual ativo, que é o que tem o
pytest instalado. `-v` lista cada teste pelo nome:

```
ana@laptop:~/shipquote$ python -m pytest tests/test_money.py -v
============================= test session starts ==============================
platform linux -- Python 3.13.16, pytest-9.1.1, pluggy-1.6.0 -- /home/ana/shipquote/.venv/bin/python
cachedir: .pytest_cache
hypothesis profile 'default'
rootdir: /home/ana/shipquote
configfile: pyproject.toml
plugins: hypothesis-6.168.5
collecting ... collected 4 items

tests/test_money.py::test_brl_uses_a_dot_for_thousands_and_a_comma_for_cents PASSED [ 25%]
tests/test_money.py::test_brl_keeps_two_digits_of_cents PASSED           [ 50%]
tests/test_money.py::test_split_hands_the_odd_cents_to_the_first_instalments PASSED [ 75%]
tests/test_money.py::test_split_adds_back_up_to_the_total PASSED         [100%]

============================== 4 passed in 0.62s ===============================
```

O cabeçalho diz qual Python e qual pytest rodaram, onde fica a raiz do projeto e qual arquivo de
configuração foi lido (`pyproject.toml`). As quatro linhas são as quatro funções, e a última é o
veredito: **4 passed in 0.62s**.

## Vendo falhar

Um teste que você nunca viu falhar é um teste em que não dá para confiar: pode nem estar rodando,
ou pode afirmar algo que é sempre verdade. Então quebre o código de propósito. Aqui a `brl` perde o
`:02d` que completa os centavos com dois dígitos, e a suíte roda de novo sem `-v`:

```
ana@laptop:~/shipquote$ python -m pytest tests/test_money.py
============================= test session starts ==============================
platform linux -- Python 3.13.16, pytest-9.1.1, pluggy-1.6.0
rootdir: /home/ana/shipquote
configfile: pyproject.toml
plugins: hypothesis-6.168.5
collected 4 items

tests/test_money.py .F..                                                 [100%]

=================================== FAILURES ===================================
______________________ test_brl_keeps_two_digits_of_cents ______________________

    def test_brl_keeps_two_digits_of_cents():
>       assert brl(1205) == "R$ 12,05"
E       AssertionError: assert 'R$ 12,5' == 'R$ 12,05'
E         
E         - R$ 12,05
E         ?       -
E         + R$ 12,5

tests/test_money.py:9: AssertionError
=========================== short test summary info ============================
FAILED tests/test_money.py::test_brl_keeps_two_digits_of_cents - AssertionErr...
========================= 1 failed, 3 passed in 0.14s ==========================
```

Leia uma falha de baixo para cima. O resumo dá o nome do teste. Acima dele, o pytest mostra a
linha que falhou, marcada com `>`, e os dois valores que comparou: `brl(1205)` devolveu `'R$ 12,5'`
onde o teste esperava `'R$ 12,05'`. As linhas `- / ? / +` são uma diferença entre as duas strings,
e o `-` embaixo da linha esperada aponta o caractere que falta. O local, `tests/test_money.py:9`, é
onde olhar primeiro.

**O teste não achou o defeito por ser esperto.** Achou porque alguém escreveu que 1205 centavos são
`R$ 12,05`. Quase todo o valor de um teste está em escolher uma entrada onde um erro plausível
aparece: 1205 tem centavos de um dígito, e 123456 não tem. Só com o primeiro teste, esse defeito
teria passado.

## O hábito do vermelho e verde

Duas execuções valem virar hábito:

- escreva o teste, rode e **veja falhar** pelo motivo que você espera;
- depois faça passar, e rode a suíte inteira, não só o teste novo.

A primeira prova que o teste é capaz de falhar. A segunda prova que a mudança não quebrou um
vizinho. Equipes que escrevem o teste antes do código chamam esse ritmo de *red, green, refactor*,
e na trilha `qa` a aula 15 de `qa-fundamentals` trata dele como método. Aqui é só o jeito de
conferir que um teste confere alguma coisa.
