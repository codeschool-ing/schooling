---
title: Escreva o teste antes da correção
version: 1
---

O teste dos espaços foi escrito por causa de um bug: um nome digitado como três espaços era aceito, e a lista
mostrava um item emprestado a ninguém. A ordem em que ele foi escrito importa, então aqui está de novo.

**Primeiro o teste, sozinho**, com o código ainda como estava:

```
ana@laptop:~/loanbook$ git diff --stat
 test_app.py | 5 +++++
 1 file changed, 5 insertions(+)
ana@laptop:~/loanbook$ python3 -m unittest
F......
======================================================================
FAIL: test_a_borrower_made_of_spaces_is_refused (test_app.LoanRules.test_a_borrower_made_of_spaces_is_refused)
----------------------------------------------------------------------
Traceback (most recent call last):
  File "/home/ana/loanbook/test_app.py", line 39, in test_a_borrower_made_of_spaces_is_refused
    with self.assertRaises(app.Refused) as refused:
AssertionError: Refused not raised

----------------------------------------------------------------------
Ran 7 tests in 0.003s

FAILED (failures=1)
```

`F......` quer dizer uma falha e seis sucessos, e o relatório diz qual teste e por quê: `Refused not
raised`, porque `"   "` não é vazio e então `if not borrower` deixou passar. Este é o momento mais útil que
um teste tem. **Ele prova que o teste enxerga o bug.** Um teste escrito depois da correção passa desde a
primeira execução, e não há como saber se passa porque o código está certo ou porque o teste não verifica
nada.

**Depois a correção**, uma linha, e o mesmo comando:

```
ana@laptop:~/loanbook$ git diff app.py
diff --git a/app.py b/app.py
index e6039b6..e48521f 100644
--- a/app.py
+++ b/app.py
@@ -71,6 +71,7 @@ def item_named(db, item_id):
 
 
 def lend(db, item_id, borrower, today):
+    borrower = (borrower or "").strip()
     if not borrower:
         raise Refused(HTTPStatus.BAD_REQUEST, "Say who is borrowing it.")
     item = item_named(db, item_id)
ana@laptop:~/loanbook$ python3 -m unittest
.......
----------------------------------------------------------------------
Ran 7 tests in 0.004s

OK
```

Sete pontos. O commit que leva os dois, o *Refuse a borrower made of spaces* da aula 9, diz no corpo que o
teste veio primeiro e falhou. Quem avalia e lê isso sabe como você trabalha.

Esse hábito tem nome, *desenvolvimento guiado por testes*, e um método inteiro construído em volta. Para um
projeto de portfólio você não precisa do método. Precisa da regra única: **para um bug, o teste vem
primeiro, e você o vê falhar.**
