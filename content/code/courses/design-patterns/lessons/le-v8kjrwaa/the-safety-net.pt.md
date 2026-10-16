---
title: "A rede de segurança: testes de caracterização"
version: 1
---

**Refatorar exige testes, e o código que mais precisa de refatoração é o que não tem nenhum.** A
saída desse círculo é um tipo diferente de teste. Um teste de caracterização, nome que Michael
Feathers deu em *Working Effectively with Legacy Code* (2004), não diz o que o código deveria
fazer. Ele registra o que o código *faz* hoje, certo ou errado, para que qualquer mudança nisso
apareça como falha.

Crie `~/patterns/refactoring` e trabalhe lá:

```sh
mkdir -p ~/patterns/refactoring
cd ~/patterns/refactoring
```

## O arquivo que todo mundo evita

A biblioteca imprime um relatório mensal de empréstimos atrasados. Ele foi escrito às pressas anos
atrás, funciona, e é o tipo de arquivo que as pessoas editam acrescentando mais um `elif`. Salve
como `report.py`:

```python
# report.py
from datetime import date, timedelta

LOANS = [
    ("Bia Souza", "+55 11 5550-0142", "bia@example.org", "Dom Casmurro", "book", date(2026, 3, 2), date(2026, 3, 20)),
    ("Caio Lima", "+55 11 5550-0177", "caio@example.org", "Central do Brasil", "film", date(2026, 3, 9), None),
    ("Bia Souza", "+55 11 5550-0142", "bia@example.org", "Iracema", "book", date(2026, 3, 10), date(2026, 3, 21)),
    ("Duda Alves", "+55 11 5550-0193", "duda@example.org", "Cidade de Deus", "film", date(2026, 3, 1), date(2026, 3, 12)),
]


def report(loans, today):
    out = []
    total = 0
    for l in loans:
        if l[4] == "book":
            due = l[5] + timedelta(days=14)
        elif l[4] == "film":
            due = l[5] + timedelta(days=7)
        else:
            due = l[5]
        if l[6]:
            end = l[6]
        else:
            end = today
        d = (end - due).days
        if d > 0:
            f = d * 50
            total = total + f
            if l[4] == "book":
                what = "book"
            elif l[4] == "film":
                what = "film (DVD)"
            else:
                what = "item"
            out.append(l[0] + " <" + l[2] + ">: " + what + " '" + l[3] + "', " + str(d) + " days late, R$ "
                       + str(f // 100) + "," + str(f % 100).zfill(2))
    out.append("total: R$ " + str(total // 100) + "," + str(total % 100).zfill(2))
    return "\n".join(out)


if __name__ == "__main__":
    print(report(LOANS, date(2026, 3, 31)))
```

```
ana@laptop:~/patterns/refactoring$ python3 report.py
Bia Souza <bia@example.org>: book 'Dom Casmurro', 4 days late, R$ 2,00
Caio Lima <caio@example.org>: film (DVD) 'Central do Brasil', 15 days late, R$ 7,50
Duda Alves <duda@example.org>: film (DVD) 'Cidade de Deus', 4 days late, R$ 2,00
total: R$ 11,50
```

A saída está correta. O *Dom Casmurro* da Bia venceu em 16 de março e voltou no dia 20: quatro dias,
200 centavos. O filme do Caio ainda está fora, quinze dias além do empréstimo de 7 dias em 31 de
março. *Iracema* voltou antes do prazo e não aparece. Todo cheiro da tabela da seção anterior está
nesta única função, e o resto da lição os tira um de cada vez.

## Fixe a saída

A rede mais barata para uma função que produz texto é o próprio texto. Guarde o que ela imprime hoje
como a saída aprovada; daqui em diante, o teste é ela continuar imprimindo exatamente isso. A
técnica tem vários nomes: golden master, snapshot, teste de aprovação.

```
ana@laptop:~/patterns/refactoring$ python3 report.py > approved.txt
```

O relatório de março cobre o caminho principal, mas não todos os desvios. Um mês em que ninguém
atrasou passa por outro caminho da função, e talvez você não saiba o que ele imprime. **O truque de
Feathers é perguntar ao código**: escreva a asserção com uma resposta que você sabe que está errada,
e deixe a falha dizer a verdadeira.

```python
# test_report.py
import unittest
from datetime import date
from pathlib import Path

from report import LOANS, report

ON_TIME = [("Eva Rocha", "+55 11 5550-0105", "eva@example.org", "Vidas Secas", "book", date(2026, 3, 2), date(2026, 3, 16))]


class ReportCharacterisation(unittest.TestCase):
    def test_the_march_report(self):
        approved = Path("approved.txt").read_text()
        self.assertEqual(report(LOANS, date(2026, 3, 31)) + "\n", approved)

    def test_a_month_with_nobody_late(self):
        self.assertEqual(report(ON_TIME, date(2026, 3, 31)), "")


if __name__ == "__main__":
    unittest.main()
```

O `+ "\n"` está ali porque o `print` acrescentou uma quebra de linha quando o arquivo aprovado foi
gravado, e `report` devolve o texto sem ela.

```
ana@laptop:~/patterns/refactoring$ python3 -m unittest -v test_report.py
test_a_month_with_nobody_late (test_report.ReportCharacterisation.test_a_month_with_nobody_late) ... FAIL
test_the_march_report (test_report.ReportCharacterisation.test_the_march_report) ... ok

======================================================================
FAIL: test_a_month_with_nobody_late (test_report.ReportCharacterisation.test_a_month_with_nobody_late)
----------------------------------------------------------------------
Traceback (most recent call last):
  File "/home/ana/patterns/refactoring/test_report.py", line 17, in test_a_month_with_nobody_late
    self.assertEqual(report(ON_TIME, date(2026, 3, 31)), "")
AssertionError: 'total: R$ 0,00' != ''
- total: R$ 0,00


----------------------------------------------------------------------
Ran 2 tests in 0.001s

FAILED (failures=1)
```

A string vazia era um palpite, e a falha o corrige: um mês sem ninguém atrasado ainda imprime um
total de `R$ 0,00`. Copie o que o código disse para o teste:

```python
# test_report.py
import unittest
from datetime import date
from pathlib import Path

from report import LOANS, report

ON_TIME = [("Eva Rocha", "+55 11 5550-0105", "eva@example.org", "Vidas Secas", "book", date(2026, 3, 2), date(2026, 3, 16))]


class ReportCharacterisation(unittest.TestCase):
    def test_the_march_report(self):
        approved = Path("approved.txt").read_text()
        self.assertEqual(report(LOANS, date(2026, 3, 31)) + "\n", approved)

    def test_a_month_with_nobody_late(self):
        self.assertEqual(report(ON_TIME, date(2026, 3, 31)), "total: R$ 0,00")


if __name__ == "__main__":
    unittest.main()
```

```
ana@laptop:~/patterns/refactoring$ python3 -m unittest -v test_report.py
test_a_month_with_nobody_late (test_report.ReportCharacterisation.test_a_month_with_nobody_late) ... ok
test_the_march_report (test_report.ReportCharacterisation.test_the_march_report) ... ok

----------------------------------------------------------------------
Ran 2 tests in 0.000s

OK
```

## O que um teste de caracterização promete, e o que não promete

Ele promete que o comportamento que você registrou não mudou. **Ele não promete que o comportamento
está certo.** Se um mês sem atrasos deveria imprimir um total zero é pergunta para as
bibliotecárias. Se a resposta for não, isso é mudança de comportamento: ganha teste próprio, commit
próprio e revisão própria, e nunca vai de carona dentro de uma refatoração.

A rede também só é tão larga quanto os casos que ela guarda. Os dois testes aqui cobrem o caminho do
atraso, o da devolução antecipada e o do mês vazio. Eles não cobrem um tipo de item que não seja
nem livro nem filme, então uma refatoração que quebrasse os ramos `else` passaria. Antes de mexer em
código que nenhum teste alcança, acrescente um caso que o alcance, ou aceite o risco sabendo dele.

Repare também no que os testes chamam: `report(rows, today)` com tuplas simples, do jeito que o
resto do código da biblioteca chama. Essa é a interface que as refatorações precisam manter, aconteça
o que acontecer dentro do arquivo.
