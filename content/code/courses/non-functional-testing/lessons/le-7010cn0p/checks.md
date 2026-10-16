---
title: The rows a test can hold
version: 1
---

Some rows of the plan are checked by looking, once, by hand, and the rest by a test that keeps
looking. **Look first, by hand, at your own service on `127.0.0.1`**, because that is where a
finding is understood; then write the test that holds it. Start `account.py` in its terminal if it
is not running, and in the second terminal make an account and ask for its page with only the
headers printed:

```
ana@nft:~/boxoffice$ curl -s -X POST localhost:8001/register -d '{"name": "ana", "password": "correct horse battery"}'
{"ok": true}
ana@nft:~/boxoffice$ curl -s -X POST localhost:8001/login -d '{"name": "ana", "password": "correct horse battery"}' | jq -r .token > ~/ana.token
ana@nft:~/boxoffice$ curl -s -o /dev/null -D - localhost:8001/account --cookie "session=$(cat ~/ana.token)"
HTTP/1.1 200 OK
Server: account
Date: Fri, 16 Oct 2026 00:39:57 GMT
Content-Type: text/html; charset=utf-8
Content-Length: 273
X-Content-Type-Options: nosniff
Content-Security-Policy: default-src 'none'; form-action 'self'; frame-ancestors 'none'
```

Read the headers the way the A02 rows ask. **What is there**: `Server: account`, which names no
software and no version; `X-Content-Type-Options: nosniff`, which stops a browser guessing that a
file is something other than its declared type; and a Content-Security-Policy whose
`frame-ancestors 'none'` keeps the page out of other sites' frames. **What is not there** matters as
much. No `Cache-Control`, on a page that lists somebody's bookings, so a shared computer's browser
or a proxy may keep a copy: that is finding F19-1. And no `Strict-Transport-Security`, which is
right here, because the header only means something over HTTPS, and is a row for the deployment's
review.

Now the A10 probe: a request whose `Content-Length` is a word rather than a number. It is a broken
request, of the kind a buggy client or a careless proxy sends, and it is harmless:

```
ana@nft:~/boxoffice$ curl -s -w ' %{http_code}\n' -X POST localhost:8001/avatar -H "Authorization: Bearer $(cat ~/ana.token)" -H 'Content-Length: many'
{"error": "something went wrong"}
 500
```

**The answer gives nothing away**: one sentence and no trace of the code. That is the defence lesson
16's `guarded` was written for, and it holds. The status is the finding: `500` says the server
failed, when it was the request that was wrong, and a `400` is the answer the client needs. The
server's own terminal shows why, and that it kept the whole story for whoever runs it:

```
ana@nft:~/boxoffice$ python3 account.py
account on http://127.0.0.1:8001
2026-10-15 21:39:57,100 ERROR unhandled error on POST /avatar
Traceback (most recent call last):
  File "/home/ana/boxoffice/account.py", line 78, in guarded
    route(urlparse(self.path))
  File "/home/ana/boxoffice/account.py", line 163, in post
    return self.upload(me)
           ^^^^^^^^^^^^^^^
  File "/home/ana/boxoffice/account.py", line 217, in upload
    size = int(self.headers.get("Content-Length", 0))
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
ValueError: invalid literal for int() with base 10: 'many'
```

The traceback names the line, 217, where `int()` met the word `many`. It is logged in full on the
server and never sent, which is the right split; the fix is to read the length where it can be
refused with a `400`. Until somebody makes that fix, it is finding F19-2.

## The findings, written down

A finding is written so that somebody who was not there can act on it:

| | F19-1 | F19-2 | F19-3 |
|---|---|---|---|
| category | A02 | A10 | A09 |
| what | the bookings page sends no `Cache-Control: no-store` | a non-numeric `Content-Length` on `/avatar` is answered `500` | a successful sign-in writes no log line |
| evidence | the headers above | the probe and the traceback above | the log in "What a log line carries" |
| severity | low: personal data in a browser cache | low: fails safe, wrong status | medium: a stolen password leaves no trace |
| fix | send the header on every page with personal data | parse the header where it can answer `400` | log the success, with the account |

## The file

The tests in this file hold the rows that no earlier file holds, and they hold the two findings
that a test can see. Create it in `~/boxoffice` with `nano test_owasp.py`:

```schooling-example
{"language": "python", "file": "boxoffice/test_owasp.py", "parts": [{"code": "# boxoffice/test_owasp.py\n# The rows of lesson 19's test plan that no earlier file holds. Run: python3 -m unittest -v test_owasp\nimport json, unittest\nfrom test_account import call, customer, setUpModule, tearDownModule\n", "note": "It takes the server and the helpers from lesson 16's file, as `test_sessions.py` and `test_vectors.py` do, so it starts its own copy of `account.py` on a free port, with a database of its own. The comment at the end of each `class` line names the category of the Top 10 its tests hold."}, {"code": "class Misconfiguration(unittest.TestCase):                                    # A02\n    def test_every_answer_forbids_guessing_its_type(self):\n        for path in (\"/health\", \"/nowhere\", \"/bookings/1\"):\n            _, _, headers = call(\"GET\", path)\n            self.assertEqual(headers[\"X-Content-Type-Options\"], \"nosniff\", path)\n            self.assertEqual(headers[\"Server\"], \"account\", path)\n", "note": "A02, misconfiguration, seen from outside: every answer, a 404 and a refusal included, carries `nosniff`, and its `Server` header names no software and no version. Three paths, because a header added on one route and forgotten on another is the usual way this breaks."}, {"code": "    def test_the_page_cannot_be_framed_by_another_site(self):\n        _, ana = customer()\n        _, _, headers = call(\"GET\", \"/account\", cookie=ana)\n        self.assertIn(\"frame-ancestors 'none'\", headers[\"Content-Security-Policy\"])\n\n    @unittest.expectedFailure                     # open finding F19-1, see the test plan\n    def test_a_page_of_personal_data_is_kept_out_of_caches(self):\n        _, ana = customer()\n        _, _, headers = call(\"GET\", \"/account\", cookie=ana)\n        self.assertEqual(headers[\"Cache-Control\"], \"no-store\")\n", "note": "The page cannot be put inside another site's frame, which is what `frame-ancestors 'none'` in its Content-Security-Policy says. The third test is the first open finding: the page that lists somebody's bookings does not tell caches to keep no copy. `expectedFailure` marks it as known, so the run stays green, reports the failure as expected, and goes red the day somebody fixes the page without updating the test."}, {"code": "class Logging(unittest.TestCase):                                             # A09\n    def test_a_failed_sign_in_is_logged_without_the_password(self):\n        name, _ = customer()\n        with self.assertLogs(\"account\", \"WARNING\") as seen:\n            call(\"POST\", \"/login\", {\"name\": name, \"password\": \"not the password\"})\n        self.assertEqual(seen.output, [f\"WARNING:account:failed sign-in for '{name}'\"])\n", "note": "A09: a failed sign-in writes exactly one line, and the line holds the name and not the password. `assertLogs` collects what the `account` logger wrote during the block, so the test reads the log the way an operator would."}, {"code": "    def test_a_refusal_names_the_account_and_what_it_asked_for(self):\n        _, ana = customer()\n        with self.assertLogs(\"account\", \"WARNING\") as seen:\n            call(\"GET\", \"/staff/bookings\", token=ana)\n        self.assertRegex(seen.output[0], r\"refused GET /staff/bookings to account \\d+: staff only\")\n\n    def test_a_name_cannot_start_a_log_line_of_its_own(self):\n        with self.assertLogs(\"account\", \"WARNING\") as seen:\n            call(\"POST\", \"/login\", {\"name\": \"nft\\nWARNING nft-probe\", \"password\": \"x\"})\n        self.assertEqual(len(seen.records), 1)\n        self.assertNotIn(\"\\n\", seen.records[0].getMessage())\n", "note": "A refusal names who asked and for what. The last test sends a name with a line break and a marker in it, the log's version of the single quote. The service logs names with `%r`, so the break is written as the two characters `\\n` and cannot start a line that looks like one of the service's own."}, {"code": "class ExceptionalConditions(unittest.TestCase):                               # A10\n    def test_a_malformed_body_is_a_400(self):\n        for body in (\"\", \"{\", \"[1, 2]\", json.dumps({\"name\": \"ana\"})):\n            self.assertEqual(call(\"POST\", \"/login\", body)[0], 400, body)\n\n    def test_an_unexpected_error_says_nothing_about_the_code(self):\n        _, ana = customer()\n        _, body, _ = call(\"POST\", \"/avatar\", token=ana, headers={\"Content-Length\": \"many\"})\n        self.assertEqual(json.loads(body), {\"error\": \"something went wrong\"})\n", "note": "A10: four broken bodies (empty, cut short, the wrong shape, a field missing) are each a `400`. Then a request whose `Content-Length` is a word: the code reading it raises an error nobody planned for, and the test holds that the answer is still the one plain sentence of `guarded`, with no trace of the code in it."}, {"code": "    @unittest.expectedFailure                     # open finding F19-2, see the test plan\n    def test_a_length_that_is_not_a_number_is_the_clients_mistake(self):\n        _, ana = customer()\n        status, _, _ = call(\"POST\", \"/avatar\", token=ana, headers={\"Content-Length\": \"many\"})\n        self.assertEqual(status, 400)\n\nif __name__ == \"__main__\":\n    unittest.main()", "note": "The second open finding. That request is the client's mistake and should be a `400`; `account.py` answers it with a `500`, because the error is caught by the catch-all rather than where the length is read. It fails safe, it is still wrong, and the test says so on every run until it is fixed."}]}
```

Run it:

```
ana@nft:~/boxoffice$ python3 -m unittest -v test_owasp
test_a_length_that_is_not_a_number_is_the_clients_mistake (test_owasp.ExceptionalConditions.test_a_length_that_is_not_a_number_is_the_clients_mistake) ... expected failure
test_a_malformed_body_is_a_400 (test_owasp.ExceptionalConditions.test_a_malformed_body_is_a_400) ... ok
test_an_unexpected_error_says_nothing_about_the_code (test_owasp.ExceptionalConditions.test_an_unexpected_error_says_nothing_about_the_code) ... ok
test_a_failed_sign_in_is_logged_without_the_password (test_owasp.Logging.test_a_failed_sign_in_is_logged_without_the_password) ... ok
test_a_name_cannot_start_a_log_line_of_its_own (test_owasp.Logging.test_a_name_cannot_start_a_log_line_of_its_own) ... ok
test_a_refusal_names_the_account_and_what_it_asked_for (test_owasp.Logging.test_a_refusal_names_the_account_and_what_it_asked_for) ... ok
test_a_page_of_personal_data_is_kept_out_of_caches (test_owasp.Misconfiguration.test_a_page_of_personal_data_is_kept_out_of_caches) ... expected failure
test_every_answer_forbids_guessing_its_type (test_owasp.Misconfiguration.test_every_answer_forbids_guessing_its_type) ... ok
test_the_page_cannot_be_framed_by_another_site (test_owasp.Misconfiguration.test_the_page_cannot_be_framed_by_another_site) ... ok

----------------------------------------------------------------------
Ran 9 tests in 1.152s

OK (expected failures=2)
```

Nine tests, seven `ok` and two **`expected failure`**: the findings, failing exactly as the plan
says they do, while the run as a whole is `OK`. That is what `@unittest.expectedFailure` buys. An
open finding stays visible in every run without turning the build red for a defect everybody
already knows about. **The day somebody fixes it, the test reports an unexpected success and
the run fails**, which is the reminder to remove the marker so the test holds the fix from then on.
Use it only for a finding with a number, written down; an expected failure nobody can explain is a
test that was switched off.

F19-3 has no test, because a successful sign-in writes no line for a test to read. Its test belongs
with its fix.

With this file the security half of the suite is four files, and running `unittest` with no name
runs them all:

```
ana@nft:~/boxoffice$ python3 -m unittest
........x.....x...............
----------------------------------------------------------------------
Ran 30 tests in 6.656s

OK (expected failures=2)
```

Thirty tests, each `x` an open finding, in 6.656 seconds. Every row of the plan marked *a test* is
one of those dots.
