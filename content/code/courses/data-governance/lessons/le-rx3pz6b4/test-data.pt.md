---
title: Dado de teste que não pode ser ninguém
version: 1
---

A aula 5 montou uma cópia mascarada para desenvolvedores e disse que, para a maior parte do trabalho,
dado gerado é melhor que qualquer cópia. O dado da própria Ipê é gerado — pelo `generate.py` da aula 1, com
sementes fixas — e foi construído para **não poder ser real**, uma propriedade que vale conferir em vez
de confiar.

O CPF é o caso mais claro. Um CPF tem onze dígitos, e os dois últimos são dígitos verificadores
calculados a partir dos nove primeiros. Um número cujos verificadores estão certos *pode* ser de
alguém; um cujos verificadores estão errados não é de ninguém. O gerador acerta o primeiro
verificador e erra o segundo de propósito. Os CPFs em claro saíram do banco na aula 5, então a
verificação lê o arquivo de onde o laboratório os carregou:

```python
"""How many CPFs in the file pass their own check digits."""
import csv, sys

def digit_ok(cpf, n):
    """Is the n-th digit (9 or 10, from zero) the check digit it should be?"""
    d = [int(c) for c in cpf if c.isdigit()]
    s = sum(v * w for v, w in zip(d[:n], range(n + 1, 1, -1)))
    return (s * 10 % 11) % 10 == d[n]

rows = list(csv.DictReader(open(sys.argv[1])))
first = sum(digit_ok(r["cpf"], 9) for r in rows)
both = sum(digit_ok(r["cpf"], 9) and digit_ok(r["cpf"], 10) for r in rows)
print(len(rows), "CPFs:", first, "pass the first check digit,", both, "pass both")
```

```
ana@lab:~/gov$ python3 cpf_check.py /var/lib/ipe-data/customers.csv
6012 CPFs: 6012 pass the first check digit, 0 pass both
```

Os 6.012 passam no primeiro verificador — o validador funciona — e **nenhum passa nos dois.** Nenhum
cliente deste curso tem um CPF que possa ser de uma pessoa real.

O resto do gerador segue a mesma regra, e o cabeçalho dele diz isso:

- todo e-mail fica em `example.com`, `example.net` ou `example.org`, domínios reservados para
  documentação, então nenhuma mensagem mandada por um teste alcança alguém;
- nenhum número de telefone é gerado, porque o Brasil não reserva faixa de números para ficção;
- os nomes são um prenome e dois sobrenomes tirados de listas de nomes comuns, e a combinação é
  acaso;
- números de cartão nunca são gerados — os pagamentos levam um token e quatro dígitos, como a aula 5
  descreveu.

## Por que isso importa além do laboratório

Dado de teste escapa. Vai para capturas de tela, demonstrações, relatos de bug, material de
treinamento e, de vez em quando, para uma campanha de e-mail apontada para o banco errado. **Dado
gerado que não pode ser real torna inofensivo cada um desses acidentes**, coisa que uma cópia
mascarada da produção nunca garante por inteiro. É também o único tipo de dado que uma empresa pode
pôr num repositório público — o deste curso inclusive — sem pensar duas vezes.
