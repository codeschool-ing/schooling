---
title: Testes instáveis no pipeline
version: 2
---

A aula 3 seção 09 definiu um teste instável: um que passa e falha sem mudança nenhuma entre uma vez e
outra. Num pipeline, a instabilidade deixa de ser incômodo de uma pessoa; vira uma execução vermelha
no pull request de outra, e um hábito da equipe de apertar "rodar de novo" até ficar verde.

A falha em UTC da seção 06 **não** era instável. Falhou toda vez em toda célula UTC e passou toda vez
em toda célula de São Paulo. É uma falha determinística que depende do ambiente, e a matriz foi o que
a deixou visível. Distinguir as duas é o primeiro passo diante de qualquer teste vermelho.

## Um teste instável, medido

Este teste, escrito para a seção, confere as zonas de dois CEPs transformando um set numa lista.
Apague-o quando a seção terminar. Salve como `tests/test_zones_seen.py`:

```python
from shipquote.quote import zone_of


def test_the_zones_of_two_ceps():
    seen = {zone_of(cep) for cep in ["01310-100", "20040-002"]}
    assert list(seen) == ["SP", "SE"]
```

Rodado dez vezes seguidas, no mesmo código e na mesma máquina:

```
ana@laptop:~/shipquote$ for i in 1 2 3 4 5 6 7 8 9 10; do python -m pytest -q tests/test_zones_seen.py | tail -1; done | sed "s/ in .*//" | sort | uniq -c
      4 1 failed
      6 1 passed
ana@laptop:~/shipquote$ for i in 1 2 3 4 5 6 7 8 9 10; do PYTHONHASHSEED=0 python -m pytest -q tests/test_zones_seen.py | tail -1; done | sed "s/ in .*//" | sort | uniq -c
     10 1 passed
```

**Cinco aprovações, cinco falhas.** O Python torna aleatório o hash de strings em cada processo novo,
como defesa contra um tipo de ataque de negação de serviço, então a ordem em que um set entrega
`"SP"` e `"SE"` muda de uma execução para outra. Definir `PYTHONHASHSEED=0` fixa a semente do hash, e
o segundo laço passou dez vezes em dez.

**Fixar a semente é a correção errada.** Faz o teste passar congelando um acaso; o teste continuaria
afirmando algo que o código nunca prometeu. A correção certa é comparar o que importa, o próprio set
ou `sorted(seen)`, para o teste passar seja qual for a ordem.

## O que uma equipe faz com a instabilidade

1. **Medir antes de acreditar.** Rode o teste suspeito muitas vezes num laço, como acima; um teste que
   falha uma vez em cinquenta continua instável.
2. **Achar a origem.** Tempo, acaso e ordem, da aula 3, cobrem a maioria dos casos; estado
   compartilhado entre testes e chamadas reais de rede cobrem a maior parte do resto.
3. **Pôr em quarentena enquanto corrige, à vista.** Algumas equipes mudam um teste instável para um
   job separado, que não bloqueia, com um responsável e um prazo. Isso mantém a execução principal
   confiável sem fingir que o teste está bem.

O que uma equipe não deve fazer é configurar o pipeline para **repetir automaticamente os testes que
falham** e chamar a segunda tentativa de aprovação. Isso transforma todo teste instável num verde,
inclusive o teste que estava certo, e ensina todo mundo que vermelho quer dizer "tente de novo".
