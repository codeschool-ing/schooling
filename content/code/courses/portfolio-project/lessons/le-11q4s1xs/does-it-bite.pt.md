---
title: Um teste que não falha não prova nada
version: 1
---

O teste da regra única foi escrito depois da regra, então nunca teve o seu momento vermelho. Isso deixa uma
pergunta que vale fazer a todo teste importante: **ele perceberia se a regra sumisse?** O jeito de descobrir
é tirar a regra e rodar.

A regra do loanbook é o índice único parcial. Apague-o e rode a suíte:

```
ana@laptop:~/loanbook$ sed -i '/CREATE UNIQUE INDEX/,/WHERE returned_on IS NULL;/d' app.py
ana@laptop:~/loanbook$ git diff --stat
 app.py | 2 --
 1 file changed, 2 deletions(-)
ana@laptop:~/loanbook$ python3 -m unittest
....F..
======================================================================
FAIL: test_an_item_cannot_be_lent_twice (test_app.LoanRules.test_an_item_cannot_be_lent_twice)
----------------------------------------------------------------------
Traceback (most recent call last):
  File "/home/ana/loanbook/test_app.py", line 22, in test_an_item_cannot_be_lent_twice
    with self.assertRaises(app.Refused) as refused:
AssertionError: Refused not raised

----------------------------------------------------------------------
Ran 7 tests in 0.003s

FAILED (failures=1)
ana@laptop:~/loanbook$ git restore app.py
```

O `sed` apagou as duas linhas do índice, o stat confirma que nada mais mudou, e exatamente um teste falhou:
`test_an_item_cannot_be_lent_twice`, com `Refused not raised`. O teste morde. Depois o `git restore` põe o
índice de volta, e nada da experiência fica.

Esta é uma versão pequena e manual do que se chama *teste de mutação*: mudar o código de propósito e
conferir que algum teste reclama. Existem ferramentas que fazem isso automaticamente, no código inteiro, e
elas são lentas. Para um projeto de portfólio, fazer à mão com **a regra única** leva um minuto e responde à
única pergunta que importa: a garantia que está no README está de fato protegida.

Também é uma boa coisa para dizer numa entrevista. *Como você sabe que os seus testes funcionam?* tem uma
resposta fraca, *eles passam*, e uma forte: *tirei o índice e vi o teste certo falhar.*
