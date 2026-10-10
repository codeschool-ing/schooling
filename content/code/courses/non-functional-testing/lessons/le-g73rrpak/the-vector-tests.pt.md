---
title: Os testes dos vetores
version: 1
---

Cada teste manual desta aula já tem um teste automatizado no `test_account.py` da aula 16: a aspa, a
marca, o formulário sem token, o arquivo que não é imagem. **O que um segundo olhar acrescenta são os
casos que o primeiro teste não alcançou**, um para cada vetor, e eles vão num arquivo próprio ao lado
dos outros. Crie-o com `nano test_vectors.py` em `~/boxoffice`:

```python
# boxoffice/test_vectors.py
# The four vectors of lesson 20, one more test each. Run: python3 -m unittest -v test_vectors
import json, re, unittest
from test_account import PNG, book, call, customer, setUpModule, tearDownModule

class Vectors(unittest.TestCase):
    def test_a_quote_in_a_booking_is_kept_as_text(self):
        _, ana = customer()
        booking = book(ana, holder="Ana O'Brien")
        status, body, _ = call("GET", f"/bookings/{booking}", token=ana)
        self.assertEqual(status, 200)
        self.assertEqual(json.loads(body)["holder"], "Ana O'Brien",
                         "the quote did not come back as the text that was sent")

    def test_the_search_term_is_escaped_inside_its_attribute(self):
        _, ana = customer()
        status, body, _ = call("GET", "/account?q=nft%22probe", cookie=ana)
        self.assertEqual(status, 200)
        self.assertIn('value="nft&quot;probe"', body,
                      "a double quote in the search ended the attribute it was written into")

    def test_one_customers_form_token_does_not_work_for_another(self):
        _, ana = customer()
        _, bia = customer()
        book(ana)                          # so that ana's page carries a form
        booking = book(bia)
        page = call("GET", "/account", cookie=ana)[1]
        ana_csrf = re.search(r'name="csrf" value="([^"]+)"', page)
        form = {"booking": booking, "csrf": ana_csrf.group(1)}
        self.assertEqual(call("POST", "/account/cancel", cookie=bia, form=form)[0], 403,
                         "a form token issued to one session was accepted from another")
        self.assertEqual(call("GET", f"/bookings/{booking}", token=bia)[0], 200)

    def test_an_upload_is_never_served_back(self):
        _, ana = customer()
        self.assertEqual(call("POST", "/avatar", PNG, token=ana)[0], 201)
        for path in ("/uploads/", "/data/uploads/", "/avatar"):
            self.assertIn(call("GET", path, token=ana)[0], (404, 405),
                          f"GET {path} answered as if it served stored files")
```

Os quatro testes, um para cada seção desta aula:

- **a aspa sobrevive à ida e volta** como texto, que é o lado da escrita da conferência de injeção;
- **a aspa dupla é codificada dentro do atributo**, o contexto que a marca sozinha não alcança;
- **o token de formulário de uma sessão é recusado com o cookie de outra**, então o token está preso
  à sessão e não apenas presente;
- **nada serve os uploads de volta**, nos caminhos que uma rota descuidada usaria. O `405` é aceito ao
  lado do `404` porque `/avatar` existe para `POST` e pode recusar outros métodos.

```
ana@nft:~/boxoffice$ python3 -m unittest -v test_vectors
test_a_quote_in_a_booking_is_kept_as_text (test_vectors.Vectors.test_a_quote_in_a_booking_is_kept_as_text) ... ok
test_an_upload_is_never_served_back (test_vectors.Vectors.test_an_upload_is_never_served_back) ... ok
test_one_customers_form_token_does_not_work_for_another (test_vectors.Vectors.test_one_customers_form_token_does_not_work_for_another) ... ok
test_the_search_term_is_escaped_inside_its_attribute (test_vectors.Vectors.test_the_search_term_is_escaped_inside_its_attribute) ... ok

----------------------------------------------------------------------
Ran 4 tests in 1.087s

OK
```

E com o arquivo da aula 16, doze testes juntos:

```
ana@nft:~/boxoffice$ python3 -m unittest test_account test_vectors
............
----------------------------------------------------------------------
Ran 12 tests in 2.281s

OK
```

## Tirando a conferência do CSRF

O mesmo movimento das aulas 16 e 17, na linha que termina em `# CSRF check`:

```
ana@nft:~/boxoffice$ mkdir -p ~/unguarded && cp test_account.py test_vectors.py ~/unguarded/
ana@nft:~/boxoffice$ sed '/# CSRF check$/s/^ */&# /' account.py > ~/unguarded/account.py
ana@nft:~/boxoffice$ cd ~/unguarded
ana@nft:~/unguarded$ python3 -m unittest test_account test_vectors
.F........F.
======================================================================
FAIL: test_a_form_without_its_token_is_refused (test_account.Defences.test_a_form_without_its_token_is_refused)
----------------------------------------------------------------------
Traceback (most recent call last):
  File "/home/ana/unguarded/test_account.py", line 93, in test_a_form_without_its_token_is_refused
    self.assertEqual(status, 403, "a form with no CSRF token cancelled a booking")
AssertionError: 303 != 403 : a form with no CSRF token cancelled a booking

======================================================================
FAIL: test_one_customers_form_token_does_not_work_for_another (test_vectors.Vectors.test_one_customers_form_token_does_not_work_for_another)
----------------------------------------------------------------------
Traceback (most recent call last):
  File "/home/ana/unguarded/test_vectors.py", line 30, in test_one_customers_form_token_does_not_work_for_another
    self.assertEqual(call("POST", "/account/cancel", cookie=bia, form=form)[0], 403,
AssertionError: 303 != 403 : a form token issued to one session was accepted from another

----------------------------------------------------------------------
Ran 12 tests in 2.330s

FAILED (failures=2)
ana@nft:~/unguarded$ cd ~/boxoffice
ana@nft:~/boxoffice$ rm -r ~/unguarded
```

**Dois testes reprovam, e os dois são sobre formulários**: o formulário sem token da aula 16, e o
token da sessão errada desta aula. Os outros dez passam, entre eles o formulário que leva o próprio
token. Duas falhas para uma linha não é defeito da suíte; a linha guarda dois casos, e cada caso tem
um teste que diz, na sua própria frase, qual deles sumiu.
