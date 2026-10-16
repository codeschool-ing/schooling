---
title: "Duplicação: um conhecimento, um lugar"
version: 1
---

**Código duplicado é perigoso por causa da mudança que atualiza uma cópia e não a outra**, não por
ocupar espaço. `report` formata dinheiro duas vezes, uma para cada linha e uma para o total, com a
mesma expressão: `str(f // 100) + "," + str(f % 100).zfill(2)`. No dia em que a biblioteca decidir
imprimir `R$ 1.150,00` com separador de milhar, alguém vai corrigir a linha que reclamaram e deixar
a outra imprimindo do jeito antigo.

A cura é o movimento da seção anterior aplicado às cópias: extraia a expressão para uma função,
depois troque cada cópia por uma chamada. Com o arquivo aberto, o `50` solto ganha um nome também,
já que é um fato sobre a biblioteca que quem lê não deveria ter de adivinhar:

```schooling-example
{"language": "python", "file": "report.py", "parts": [
 {"code": "# report.py\nfrom datetime import date, timedelta\n\nLOANS = [\n    (\"Bia Souza\", \"+55 11 5550-0142\", \"bia@example.org\", \"Dom Casmurro\", \"book\", date(2026, 3, 2), date(2026, 3, 20)),\n    (\"Caio Lima\", \"+55 11 5550-0177\", \"caio@example.org\", \"Central do Brasil\", \"film\", date(2026, 3, 9), None),\n    (\"Bia Souza\", \"+55 11 5550-0142\", \"bia@example.org\", \"Iracema\", \"book\", date(2026, 3, 10), date(2026, 3, 21)),\n    (\"Duda Alves\", \"+55 11 5550-0193\", \"duda@example.org\", \"Cidade de Deus\", \"film\", date(2026, 3, 1), date(2026, 3, 12)),\n]\nDAILY_FINE = 50  # cents", "note": "A multa por dia, nomeada uma vez. O comentário dá a unidade, que a próxima seção transforma num tipo."},
 {"code": "\n\ndef due_date(kind, lent_on):\n    if kind == \"book\":\n        return lent_on + timedelta(days=14)\n    elif kind == \"film\":\n        return lent_on + timedelta(days=7)\n    return lent_on\n\n\ndef label(kind):\n    if kind == \"book\":\n        return \"book\"\n    elif kind == \"film\":\n        return \"film (DVD)\"\n    return \"item\"\n\n\ndef days_late(row, today):\n    end = row[6] or today\n    return (end - due_date(row[4], row[5])).days", "note": "Sem mudança desde a seção anterior."},
 {"code": "\n\ndef money(cents):\n    return f\"R$ {cents // 100},{cents % 100:02d}\"", "note": "O único lugar que sabe como a biblioteca escreve um valor. `:02d` completa os centavos com dois dígitos, que era o que `zfill(2)` fazia."},
 {"code": "\n\ndef report(loans, today):\n    out = []\n    total = 0\n    for l in loans:\n        d = days_late(l, today)\n        if d > 0:\n            f = d * DAILY_FINE\n            total = total + f\n            out.append(f\"{l[0]} <{l[2]}>: {label(l[4])} '{l[3]}', {d} days late, {money(f)}\")\n    out.append(f\"total: {money(total)}\")\n    return \"\\n\".join(out)", "note": "As duas cópias agora chamam `money`. A concatenação virou uma f-string, um movimento pequeno à parte feito enquanto a linha estava sendo mexida de qualquer jeito, com uma execução de testes depois."},
 {"code": "\n\nif __name__ == \"__main__\":\n    print(report(LOANS, date(2026, 3, 31)))"}
]}
```

## A rede se paga

Suponha que, ao escrever `money`, você tivesse esquecido o preenchimento com zeros, o que é fácil ao
converter `zfill` numa f-string:

```python
    return f"R$ {cents // 100},{cents % 100}"
```

Desta vez o arquivo roda os próprios testes pelo `unittest.main()`:

```
ana@laptop:~/patterns/refactoring$ python3 test_report.py
FF
======================================================================
FAIL: test_a_month_with_nobody_late (__main__.ReportCharacterisation.test_a_month_with_nobody_late)
----------------------------------------------------------------------
Traceback (most recent call last):
  File "/home/ana/patterns/refactoring/test_report.py", line 17, in test_a_month_with_nobody_late
    self.assertEqual(report(ON_TIME, date(2026, 3, 31)), "total: R$ 0,00")
AssertionError: 'total: R$ 0,0' != 'total: R$ 0,00'
- total: R$ 0,0
+ total: R$ 0,00
?              +


======================================================================
FAIL: test_the_march_report (__main__.ReportCharacterisation.test_the_march_report)
----------------------------------------------------------------------
Traceback (most recent call last):
  File "/home/ana/patterns/refactoring/test_report.py", line 14, in test_the_march_report
    self.assertEqual(report(LOANS, date(2026, 3, 31)) + "\n", approved)
AssertionError: "Bia [60 chars]$ 2,0\nCaio Lima <caio@example.org>: film (DVD[140 chars]50\n" != "Bia [60 chars]$ 2,00\nCaio Lima <caio@example.org>: film (DV[142 chars]50\n"
- Bia Souza <bia@example.org>: book 'Dom Casmurro', 4 days late, R$ 2,0
+ Bia Souza <bia@example.org>: book 'Dom Casmurro', 4 days late, R$ 2,00
?                                                                      +
  Caio Lima <caio@example.org>: film (DVD) 'Central do Brasil', 15 days late, R$ 7,50
- Duda Alves <duda@example.org>: film (DVD) 'Cidade de Deus', 4 days late, R$ 2,0
+ Duda Alves <duda@example.org>: film (DVD) 'Cidade de Deus', 4 days late, R$ 2,00
?                                                                                +
  total: R$ 11,50


----------------------------------------------------------------------
Ran 2 tests in 0.001s

FAILED (failures=2)
```

**A saída aprovada pegou um zero faltando que nenhum leitor teria visto na revisão.** `R$ 2,0`
parece um jeito plausível de escrever dois reais até você pôr ao lado de `R$ 2,00`. Os dois testes
falham, porque cada relatório tem um valor cujos centavos são zero. Desfaça, escreva o `:02d`, rode
de novo:

```
ana@laptop:~/patterns/refactoring$ python3 test_report.py
..
----------------------------------------------------------------------
Ran 2 tests in 0.000s

OK
```

## Conhecimento duplicado, não texto duplicado

Andy Hunt e Dave Thomas formularam o princípio como *don't repeat yourself* em *The Pragmatic
Programmer* (1999), e foram precisos: cada pedaço de **conhecimento** deve ter uma representação
oficial única. Texto parecido nem sempre é o mesmo conhecimento.

As duas cadeias de `if` deste arquivo testam `kind == "book"` e `kind == "film"`. São duplicação?
Elas codificam um fato, *quais tipos de item existem*, e acrescentar um tipo exige editar as duas,
então sim, e a seção sobre switches a tira. Compare o 14 e o 7: parecem o mesmo tipo de número, mas
codificam duas políticas separadas que mudam por motivos separados. Juntá-las numa tabela seria
ótimo; derivar uma da outra seria um erro.

Duas regras práticas impedem a extração de ir longe demais:

- **A regra de três**, que Fowler atribui a Don Roberts: na primeira vez, só escreva; na segunda,
  note a cópia e faça uma careta; na terceira, extraia. Duas cópias às vezes são coincidência, e
  uma abstração feita a partir de dois exemplos muitas vezes adivinha a forma errada.
- Extraia o que muda junto. Se duas cópias teriam de mudar por motivos diferentes, elas são dois
  conhecimentos que só se parecem, e juntá-las acopla coisas que eram independentes.
