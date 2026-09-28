---
title: Sete testes
version: 1
---

Aqui estão eles, rodando com o `unittest` do próprio Python, que não precisa de nada instalado:

```
ana@laptop:~/loanbook$ python3 -m unittest -v
test_a_borrower_made_of_spaces_is_refused (test_app.LoanRules.test_a_borrower_made_of_spaces_is_refused) ... ok
test_a_lent_item_shows_who_has_it (test_app.LoanRules.test_a_lent_item_shows_who_has_it) ... ok
test_a_loan_is_overdue_the_day_after_it_is_due (test_app.LoanRules.test_a_loan_is_overdue_the_day_after_it_is_due) ... ok
test_a_returned_item_can_be_lent_again (test_app.LoanRules.test_a_returned_item_can_be_lent_again) ... ok
test_an_item_cannot_be_lent_twice (test_app.LoanRules.test_an_item_cannot_be_lent_twice) ... ok
test_an_item_that_is_in_cannot_come_back (test_app.LoanRules.test_an_item_that_is_in_cannot_come_back) ... ok
test_an_unknown_item_is_not_found (test_app.LoanRules.test_an_unknown_item_is_not_found) ... ok

----------------------------------------------------------------------
Ran 7 tests in 0.003s

OK
```

Sete testes em três milésimos de segundo. Essa velocidade não é acaso: os testes chamam `lend`,
`give_back` e `items` diretamente, contra um banco na memória, e nunca sobem um servidor. A aula 11
manteve o HTTP fora dessas funções, e foi isso que ela comprou. Uma suíte que roda em milissegundos é
rodada depois de cada mudança; uma que leva um minuto é rodada antes de um push, se você lembrar.

Os nomes são a outra coisa a notar. **O nome de cada teste é a regra que ele verifica, escrita como
frase**, então a saída acima se lê como uma lista do que o loanbook garante. Quando um falha, o relatório
diz qual regra quebrou.

Aqui está o mais importante, com a preparação que todos os testes compartilham:

```schooling-example
{"language": "python", "file": "test_app.py", "parts": [{"code": "class LoanRules(unittest.TestCase):\n    def setUp(self):\n        self.db = app.connect(\":memory:\")\n        self.db.execute(\"INSERT INTO items (id, name) VALUES (1, 'Projector 1')\")", "note": "Todo teste começa de um banco novo que vive na memória, com um item. Nada que um teste faça vaza para o próximo, e nenhum arquivo fica para trás."}, {"code": "    def test_an_item_cannot_be_lent_twice(self):\n        app.lend(self.db, 1, \"Bruno\", TODAY)", "note": "O nome é a regra, em forma de frase. Quando falha, o relatório diz qual regra quebrou sem ninguém abrir o arquivo."}, {"code": "        with self.assertRaises(app.Refused) as refused:\n            app.lend(self.db, 1, \"Carla\", TODAY)", "note": "O segundo empréstimo precisa levantar `Refused`. Se ele passar, `assertRaises` faz o teste falhar."}, {"code": "        self.assertEqual(refused.exception.status, 409)\n        self.assertIn(\"already lent to Bruno\", refused.exception.message)", "note": "Também confere o que a recusa diz: o status, e que a frase cita quem está com o item. Essa frase é o que a Marta lê."}]}
```

Repare nas duas últimas linhas. O teste não para em *um segundo empréstimo é recusado*; confere o status e
que a frase cita quem está com o item. Essa frase é tudo o que a Marta vê quando a regra dispara, e uma
mudança que mantivesse a recusa e perdesse o nome passaria num teste mais fraco.
