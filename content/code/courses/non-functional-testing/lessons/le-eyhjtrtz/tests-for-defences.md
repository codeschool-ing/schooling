---
title: Tests that hold a defence
version: 1
---

A functional test asks whether the system does what it should for somebody who wants it to work. A
security test asks the opposite question of the same code: **does it refuse what it should
refuse**, to somebody asking for something they may not have? The test looks the same, a request
and an assertion about the answer. What changes is who sends the request, and which answer counts
as a pass.

That makes most of a tester's security work ordinary regression testing. A defence is a few lines
of code, and a few lines of code disappear: in a refactor, in a merge that took the wrong side, in
a change by somebody who did not know why the line was there. **A test that fails the day the
defence goes is the cheapest security control there is**, because it costs nothing on every day
the defence is still in place.

## The suite

Each test below is a probe a tester would try by hand, written down so that it runs on every
change. None of them attacks anything: a second customer asking for the first one's booking, a
single quote in a search box, a harmless marker string where a name should be, a form posted
without the token the page gave it, a text file sent as a picture. Create it with
`nano test_account.py`.

```schooling-example
{"language": "python", "file": "boxoffice/test_account.py", "parts": [{"code": "# boxoffice/test_account.py\n# One test for each defence in account.py. Run: python3 -m unittest -v test_account\nimport http.client, json, logging, os, re, tempfile, threading, unittest\nfrom http.server import ThreadingHTTPServer\nfrom urllib.parse import quote, urlencode\n\nHOME = tempfile.mkdtemp()                 # a database of its own, thrown away\nos.environ.update(ACCOUNT_DB=f\"{HOME}/account.db\", ACCOUNT_UPLOADS=f\"{HOME}/uploads\")\nimport account\nlogging.getLogger(\"account\").addHandler(logging.NullHandler())\nPASSWORD = \"correct horse battery\"\nPNG = b\"\\x89PNG\\r\\n\\x1a\\n\" + bytes(64)\n", "note": "The suite never touches `data/account.db`. It makes a temporary directory, points the two environment variables at it and only then imports `account`, which reads them when it loads. `PASSWORD` belongs to accounts that exist only inside this run, and `PNG` is eight bytes of PNG signature followed by zeros."}, {"code": "def setUpModule():\n    global server\n    account.init()\n    server = ThreadingHTTPServer((\"127.0.0.1\", 0), account.Account)\n    threading.Thread(target=server.serve_forever, daemon=True).start()\n\ndef tearDownModule():\n    server.shutdown(); server.server_close()\n", "note": "Before the first test, the server starts in a thread of the test process, on port 0, which tells the system to pick any free port. Nothing else has to be running, and the suite cannot collide with a server you left open on 8001."}, {"code": "def call(method, path, body=None, token=None, cookie=None, form=None, headers=None):\n    \"\"\"One request to the server under test: (status, body, headers).\"\"\"\n    headers = dict(headers or {})\n    if token:\n        headers[\"Authorization\"] = f\"Bearer {token}\"\n    if cookie:\n        headers[\"Cookie\"] = f\"session={cookie}\"\n    if form is not None:\n        body, headers[\"Content-Type\"] = urlencode(form), \"application/x-www-form-urlencoded\"\n    elif isinstance(body, dict):\n        body = json.dumps(body)\n    conn = http.client.HTTPConnection(\"127.0.0.1\", server.server_address[1], timeout=10)\n    conn.request(method, path, body, headers)\n    answer = conn.getresponse()\n    result = answer.status, answer.read().decode(errors=\"replace\"), answer.headers\n    conn.close()\n    return result\n", "note": "`call` sends one request and hands back the status, the body and the headers. It never raises on a 403 or a 404, because for these tests a refusal is the expected answer, not an error."}, {"code": "made = 0\ndef customer():\n    \"\"\"A new account, signed in. Its token is also its session cookie.\"\"\"\n    global made\n    made += 1\n    name = f\"customer{made}\"\n    call(\"POST\", \"/register\", {\"name\": name, \"password\": PASSWORD})\n    status, body, _ = call(\"POST\", \"/login\", {\"name\": name, \"password\": PASSWORD})\n    assert status == 200, body\n    return name, json.loads(body)[\"token\"]\n\ndef book(token, holder=\"Ana Lima\"):\n    status, body, _ = call(\"POST\", \"/bookings\", {\"show_id\": 990, \"seat\": 12, \"holder\": holder},\n                           token=token)\n    assert status == 201, body\n    return json.loads(body)[\"id\"]\n", "note": "`customer` registers a new account with a name no other test uses and signs it in. Every test makes its own people, so no test depends on what another left behind. `book` makes a booking and returns its id."}, {"code": "class Defences(unittest.TestCase):\n    def test_a_customer_cannot_read_another_customers_booking(self):\n        _, ana = customer()\n        _, bia = customer()\n        booking = book(ana)\n        self.assertEqual(call(\"GET\", f\"/bookings/{booking}\", token=ana)[0], 200)\n        self.assertEqual(call(\"GET\", f\"/bookings/{booking}\", token=bia)[0], 404,\n                         \"a second customer's token read the first customer's booking\")\n\n    def test_logout_ends_the_session(self):\n        _, ana = customer()\n        booking = book(ana)\n        self.assertEqual(call(\"POST\", \"/logout\", token=ana)[0], 200)\n        self.assertEqual(call(\"GET\", f\"/bookings/{booking}\", token=ana)[0], 401,\n                         \"the token still worked after logout\")\n", "note": "The first test is the promise of lesson 1, in code: two customers, a booking of the first, and the second customer's token asking for it. The `200` before the `404` is the control, proving the booking exists and the route works, so that the `404` means refused and not broken."}, {"code": "    def test_a_quote_in_the_search_is_only_text(self):\n        _, ana = customer()\n        book(ana)\n        status, body, _ = call(\"GET\", \"/account?q=\" + quote(\"'\"), cookie=ana)\n        self.assertEqual(status, 200, \"a single quote in the search broke the query\")\n        self.assertNotIn(\"<li>\", body)\n\n    def test_markup_in_a_booking_comes_back_escaped(self):\n        _, ana = customer()\n        book(ana, holder=\"<em>nft-probe</em>\")\n        status, body, headers = call(\"GET\", \"/account\", cookie=ana)\n        self.assertIn(\"&lt;em&gt;nft-probe&lt;/em&gt;\", body)\n        self.assertNotIn(\"<em>nft-probe</em>\", body, \"the page sent the markup as markup\")\n        self.assertIn(\"default-src 'none'\", headers[\"Content-Security-Policy\"])\n", "note": "The two text probes. A single quote in the search must be an ordinary search with no results. A harmless marker as the name on a ticket must come back as `&lt;em&gt;`, the text of a tag rather than a tag, on a page carrying a Content-Security-Policy."}, {"code": "    def test_a_form_without_its_token_is_refused(self):\n        _, ana = customer()\n        booking = book(ana)\n        status, _, _ = call(\"POST\", \"/account/cancel\", cookie=ana, form={\"booking\": booking})\n        self.assertEqual(status, 403, \"a form with no CSRF token cancelled a booking\")\n        self.assertEqual(call(\"GET\", f\"/bookings/{booking}\", token=ana)[0], 200)\n\n    def test_the_same_form_with_its_token_works(self):\n        _, ana = customer()\n        booking = book(ana)\n        csrf = re.search(r'name=\"csrf\" value=\"([^\"]+)\"', call(\"GET\", \"/account\", cookie=ana)[1])\n        form = {\"booking\": booking, \"csrf\": csrf.group(1)}\n        self.assertEqual(call(\"POST\", \"/account/cancel\", cookie=ana, form=form)[0], 303)\n        self.assertEqual(call(\"GET\", f\"/bookings/{booking}\", token=ana)[0], 404)\n", "note": "The form probe and its control. Without its CSRF token the cancellation is refused and the booking is still there; with the token taken from the page, the same form works."}, {"code": "    def test_an_upload_that_is_not_an_image_is_refused(self):\n        _, ana = customer()\n        self.assertEqual(call(\"POST\", \"/avatar\", b\"name,seat\\nana,12\\n\", token=ana)[0], 415)\n        self.assertEqual(call(\"POST\", \"/avatar\", bytes(300_000), token=ana)[0], 413)\n        self.assertEqual(call(\"POST\", \"/avatar\", PNG, token=ana)[0], 201)\n        for name in os.listdir(f\"{HOME}/uploads\"):\n            self.assertRegex(name, r\"^[0-9a-f]{32}\\.png$\")\n\n    def test_an_error_says_nothing_about_the_software(self):\n        status, body, headers = call(\"POST\", \"/register\", \"{not json\")\n        self.assertEqual(status, 400)\n        self.assertNotIn(\"Traceback\", body)\n        self.assertEqual(headers[\"Server\"], \"account\")\n\nif __name__ == \"__main__\":\n    unittest.main()", "note": "Text pretending to be a picture is refused with 415, a body over the limit with 413, and a real PNG signature is accepted and stored under 32 random hex characters. The last test sends a broken body and checks the answer is a plain 400 from a server that does not say what it runs."}]}
```

Two habits in it are worth copying into any security suite you write. **Every refusal has a
control beside it**: the owner's own request for the booking succeeds, the form with its token
works, a real PNG is accepted. A test that only checks for a `403` passes just as happily when the
route is broken for everybody, and a broken route is not a defence. And **every assertion that
guards a defence carries a message** saying, in a sentence, what went wrong, because that sentence
is what a developer reads when it fails.

Run it:

```
ana@nft:~/boxoffice$ python3 -m unittest -v test_account
test_a_customer_cannot_read_another_customers_booking (test_account.Defences.test_a_customer_cannot_read_another_customers_booking) ... ok
test_a_form_without_its_token_is_refused (test_account.Defences.test_a_form_without_its_token_is_refused) ... ok
test_a_quote_in_the_search_is_only_text (test_account.Defences.test_a_quote_in_the_search_is_only_text) ... ok
test_an_error_says_nothing_about_the_software (test_account.Defences.test_an_error_says_nothing_about_the_software) ... ok
test_an_upload_that_is_not_an_image_is_refused (test_account.Defences.test_an_upload_that_is_not_an_image_is_refused) ... ok
test_logout_ends_the_session (test_account.Defences.test_logout_ends_the_session) ... ok
test_markup_in_a_booking_comes_back_escaped (test_account.Defences.test_markup_in_a_booking_comes_back_escaped) ... ok
test_the_same_form_with_its_token_works (test_account.Defences.test_the_same_form_with_its_token_works) ... ok

----------------------------------------------------------------------
Ran 8 tests in 1.532s

OK
```

Eight tests, green, in 1.532 seconds. Most of that went on scrypt, which is slow on purpose and
hashed the password of every account the tests made, twice: once to register it, once to sign in.

## Proving the test is worth having

A green run says the defences hold today. It does not say the tests would notice if one stopped
holding, and a security test that cannot fail is worse than none, because it is believed. So check
it the way you would check any regression test: **take the defence away and watch the test go
red.**

Make a copy of the service in another directory with one line commented out, the one that ends in
`# owner check`. You can do it in `nano`, by putting `# ` in front of that line; `sed` does the
same in one command, and `diff` shows that nothing else changed:

```
ana@nft:~/boxoffice$ mkdir -p ~/unguarded && cp test_account.py ~/unguarded/
ana@nft:~/boxoffice$ sed '/# owner check$/s/^ */&# /' account.py > ~/unguarded/account.py
ana@nft:~/boxoffice$ diff account.py ~/unguarded/account.py
121c121
<             if row[0] != me[0]: return self.refuse(404, "no such booking", me)  # owner check
---
>             # if row[0] != me[0]: return self.refuse(404, "no such booking", me)  # owner check
ana@nft:~/boxoffice$ cd ~/unguarded
ana@nft:~/unguarded$ python3 -m unittest test_account
F.......
======================================================================
FAIL: test_a_customer_cannot_read_another_customers_booking (test_account.Defences.test_a_customer_cannot_read_another_customers_booking)
----------------------------------------------------------------------
Traceback (most recent call last):
  File "/home/ana/unguarded/test_account.py", line 64, in test_a_customer_cannot_read_another_customers_booking
    self.assertEqual(call("GET", f"/bookings/{booking}", token=bia)[0], 404,
AssertionError: 200 != 404 : a second customer's token read the first customer's booking

----------------------------------------------------------------------
Ran 8 tests in 1.508s

FAILED (failures=1)
ana@nft:~/unguarded$ cd ~/boxoffice
ana@nft:~/boxoffice$ rm -r ~/unguarded
```

One test failed, the one written for that line, with the sentence it was given: a second
customer's token read the first customer's booking. The other seven still pass, because the other
defences are still there. **That is the property to look for: one defence removed, one test red.**
A defence whose removal turns nothing red has no test, whatever the suite's name says. Running the
whole suite against deliberately altered copies like this one, automatically and for every line,
is called mutation testing, and tools exist that do it; one hand-made copy per defence is enough to
trust a suite this size.

The copy is gone again with the last command. **Never leave a weakened copy where a server could
start it**: this one lived in its own directory, was run only by the tests, and was deleted.
