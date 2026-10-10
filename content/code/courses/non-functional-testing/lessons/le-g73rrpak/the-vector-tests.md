---
title: The vector tests
version: 1
---

Each probe of this lesson already has a test in lesson 16's `test_account.py`: the quote, the
marker, the form without its token, the file that is not an image. **What a second look adds are the
cases the first probe did not reach**, one for each vector, and they go in a file of their own beside
the others. Create it with `nano test_vectors.py` in `~/boxoffice`:

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

The four tests, one for each section of this lesson:

- **the quote survives the round trip** as text, which is the write side of the injection check;
- **the double quote is encoded inside the attribute**, the context the marker on its own does not
  reach;
- **one session's form token is refused with another session's cookie**, so the token is tied to
  the session and not merely present;
- **nothing serves the uploads back**, at the paths a careless route would have used. `405` is
  accepted beside `404` because `/avatar` exists for `POST` and may refuse other methods.

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

And with lesson 16's file, twelve tests together:

```
ana@nft:~/boxoffice$ python3 -m unittest test_account test_vectors
............
----------------------------------------------------------------------
Ran 12 tests in 2.281s

OK
```

## Taking the CSRF check away

The same move as lessons 16 and 17, on the line ending `# CSRF check`:

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

**Two tests fail, and both are about forms**: lesson 16's form without a token, and this lesson's
token from the wrong session. The other ten pass, the form that carries its own token among them.
Two failures for one line is not a fault in the suite; the line guards two cases, and each case has a
test that says, in its own sentence, which one went.
