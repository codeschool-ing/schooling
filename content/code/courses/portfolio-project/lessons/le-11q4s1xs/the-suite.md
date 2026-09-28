---
title: Seven tests
version: 1
---

Here they are, run with Python's own `unittest`, which needs nothing installed:

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

Seven tests in three thousandths of a second. That speed is not an accident: the tests call `lend`,
`give_back` and `items` directly, against a database in memory, and never start a server. Lesson 11
kept HTTP out of those functions, and this is what it bought. A suite that runs in milliseconds gets
run after every change; one that takes a minute gets run before a push, if you remember.

The names are the other thing to notice. **Each test's name is the rule it checks, written as a
sentence**, so the output above reads as a list of what loanbook guarantees. When one fails, the report
says which rule broke.

Here is the most important one, with the setup every test shares:

```schooling-example
{"language": "python", "file": "test_app.py", "parts": [{"code": "class LoanRules(unittest.TestCase):\n    def setUp(self):\n        self.db = app.connect(\":memory:\")\n        self.db.execute(\"INSERT INTO items (id, name) VALUES (1, 'Projector 1')\")", "note": "Every test starts from a fresh database that lives in memory, with one item in it. Nothing one test does can leak into the next, and no file is left behind."}, {"code": "    def test_an_item_cannot_be_lent_twice(self):\n        app.lend(self.db, 1, \"Bruno\", TODAY)", "note": "The name is the rule, as a sentence. When it fails, the report says which rule broke without anybody opening the file."}, {"code": "        with self.assertRaises(app.Refused) as refused:\n            app.lend(self.db, 1, \"Carla\", TODAY)", "note": "The second loan must raise `Refused`. If it goes through, `assertRaises` fails the test."}, {"code": "        self.assertEqual(refused.exception.status, 409)\n        self.assertIn(\"already lent to Bruno\", refused.exception.message)", "note": "It also checks what the refusal says: the status, and that the sentence names who has the item. That sentence is what Marta reads."}]}
```

Notice the last two lines. The test does not stop at *a second loan is refused*; it checks the status
and that the sentence names who has the item. That sentence is the whole of what Marta sees when the
rule fires, and a change that kept the refusal and lost the name would pass a weaker test.
