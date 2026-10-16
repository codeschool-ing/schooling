---
title: The session tests
version: 1
---

Every probe in this lesson so far was typed once, by hand, and read by a person. That is how a
tester finds out what the answers are; it is not how a defence stays defended. **Each probe becomes
a test that runs on every change**, beside the eight of lesson 16, in a second file that uses the
same helpers. Create it with `nano test_sessions.py`, in `~/boxoffice` next to `test_account.py`.

```schooling-example
{"language": "python", "file": "boxoffice/test_sessions.py", "parts": [{"code": "# boxoffice/test_sessions.py\n# Who may do what, for how long. Run: python3 -m unittest -v test_sessions\nimport sqlite3, time, unittest\nfrom test_account import HOME, PASSWORD, book, call, customer, setUpModule, tearDownModule\nimport account                  # after test_account, which points it at a database of its own\n\ndef database():\n    return sqlite3.connect(f\"{HOME}/account.db\")\n", "note": "It borrows the server, `call`, `customer` and `book` from `test_account.py`, so it needs that file beside it. The order of the imports matters: `test_account` sets the two environment variables, and `account` reads them when it is first imported, so importing `account` first would point the suite at the real `data/account.db`. `database` opens the suite's own copy, for the tests that look at what was stored."}, {"code": "class Privilege(unittest.TestCase):\n    def test_a_customer_cannot_open_the_staff_list(self):\n        _, ana = customer()\n        self.assertEqual(call(\"GET\", \"/staff/bookings\", token=ana)[0], 403,\n                         \"a customer's token opened a staff-only route\")\n\n    def test_a_member_of_staff_can(self):\n        sam, token = customer()\n        with database() as db:\n            db.execute(\"UPDATE accounts SET role = 'staff' WHERE name = ?\", (sam,))\n        self.assertEqual(call(\"GET\", \"/staff/bookings\", token=token)[0], 200)\n\n    def test_a_token_in_the_address_is_not_accepted(self):\n        _, ana = customer()\n        booking = book(ana)\n        self.assertEqual(call(\"GET\", f\"/bookings/{booking}?token={ana}\")[0], 401)\n", "note": "Vertical escalation and its control: a customer's token is refused the staff list, and the same request from an account made staff at the database succeeds. There is no route that makes somebody staff, so the test does it the way an operator would. The third test puts a valid token in the address, where the service never looks."}, {"code": "class Sessions(unittest.TestCase):\n    def test_a_session_ends_when_it_expires(self):\n        self.addCleanup(setattr, account, \"SESSION_SECONDS\", account.SESSION_SECONDS)\n        account.SESSION_SECONDS = 1\n        _, ana = customer()\n        booking = book(ana)\n        time.sleep(1.5)\n        self.assertEqual(call(\"GET\", f\"/bookings/{booking}\", token=ana)[0], 401,\n                         \"the token still worked after its session expired\")\n\n    def test_the_cookie_is_out_of_reach_of_scripts_and_other_sites(self):\n        name, _ = customer()\n        _, _, headers = call(\"POST\", \"/login\", {\"name\": name, \"password\": PASSWORD})\n        cookie = headers[\"Set-Cookie\"]\n        self.assertIn(\"HttpOnly\", cookie)\n        self.assertIn(\"SameSite=Lax\", cookie)\n\n    def test_the_database_holds_no_live_token(self):\n        _, ana = customer()\n        with database() as db:\n            stored = [row[0] for row in db.execute(\"SELECT token FROM sessions\")]\n        self.assertNotIn(ana, stored)\n", "note": "The session tests. `addCleanup` puts `SESSION_SECONDS` back when the test ends, pass or fail, so a one-second session cannot leak into the next test. The cookie test reads the `Set-Cookie` header; the last one checks that what the database stores is not the token the customer holds."}, {"code": "class Passwords(unittest.TestCase):\n    def test_the_same_password_is_stored_two_different_ways(self):\n        ana, _ = customer()\n        bia, _ = customer()\n        with database() as db:\n            hashes = [db.execute(\"SELECT hash FROM accounts WHERE name = ?\", (n,)).fetchone()[0]\n                      for n in (ana, bia)]\n        self.assertNotIn(PASSWORD, hashes)\n        self.assertNotEqual(hashes[0], hashes[1], \"two accounts share a hash: no salt\")\n\n    def test_sign_in_stops_after_five_failures(self):\n        ana, _ = customer()\n        wrong = {\"name\": ana, \"password\": \"not the password\"}\n        for attempt in range(5):\n            self.assertEqual(call(\"POST\", \"/login\", wrong)[0], 401)\n        right = {\"name\": ana, \"password\": PASSWORD}\n        self.assertEqual(call(\"POST\", \"/login\", right)[0], 429,\n                         \"a sixth attempt was let through after five failures\")\n\n    def test_an_unknown_name_is_answered_like_a_wrong_password(self):\n        ana, _ = customer()\n        wrong = call(\"POST\", \"/login\", {\"name\": ana, \"password\": \"not the password\"})\n        nobody = call(\"POST\", \"/login\", {\"name\": \"nobody\", \"password\": \"not the password\"})\n        self.assertEqual(wrong[:2], nobody[:2])\n\nif __name__ == \"__main__\":\n    unittest.main()", "note": "The password tests: the same password, two accounts, two different hashes, neither of them the password. Five wrong passwords, then the right one, must be refused with 429. And an unknown name must get exactly the status and the body a wrong password gets."}]}
```

Run it on its own:

```
ana@nft:~/boxoffice$ python3 -m unittest -v test_sessions
test_an_unknown_name_is_answered_like_a_wrong_password (test_sessions.Passwords.test_an_unknown_name_is_answered_like_a_wrong_password) ... ok
test_sign_in_stops_after_five_failures (test_sessions.Passwords.test_sign_in_stops_after_five_failures) ... ok
test_the_same_password_is_stored_two_different_ways (test_sessions.Passwords.test_the_same_password_is_stored_two_different_ways) ... ok
test_a_customer_cannot_open_the_staff_list (test_sessions.Privilege.test_a_customer_cannot_open_the_staff_list) ... ok
test_a_member_of_staff_can (test_sessions.Privilege.test_a_member_of_staff_can) ... ok
test_a_token_in_the_address_is_not_accepted (test_sessions.Privilege.test_a_token_in_the_address_is_not_accepted) ... ok
test_a_session_ends_when_it_expires (test_sessions.Sessions.test_a_session_ends_when_it_expires) ... ok
test_the_cookie_is_out_of_reach_of_scripts_and_other_sites (test_sessions.Sessions.test_the_cookie_is_out_of_reach_of_scripts_and_other_sites) ... ok
test_the_database_holds_no_live_token (test_sessions.Sessions.test_the_database_holds_no_live_token) ... ok

----------------------------------------------------------------------
Ran 9 tests in 3.246s

OK
```

Nine tests, green, in 3.246 seconds, of which one and a half are the expiry test sleeping while a
one-second session runs out. A test that waits is slow, and **this one waits on purpose rather than
reaching into the database to backdate a row**: it checks the expiry the way a customer meets it,
by the clock. With both files in place, `python3 -m unittest` with no name runs the two of them
together, the seventeen tests that are now the security half of the suite.

## Taking the role check away

The same move as lesson 16, on the other kind of escalation: a copy of the service with the line
ending `# role check` commented out, and the session tests run against it.

```
ana@nft:~/boxoffice$ mkdir -p ~/unguarded && cp test_account.py test_sessions.py ~/unguarded/
ana@nft:~/boxoffice$ sed '/# role check$/s/^ */&# /' account.py > ~/unguarded/account.py
ana@nft:~/boxoffice$ cd ~/unguarded
ana@nft:~/unguarded$ python3 -m unittest test_sessions
...F.....
======================================================================
FAIL: test_a_customer_cannot_open_the_staff_list (test_sessions.Privilege.test_a_customer_cannot_open_the_staff_list)
----------------------------------------------------------------------
Traceback (most recent call last):
  File "/home/ana/unguarded/test_sessions.py", line 13, in test_a_customer_cannot_open_the_staff_list
    self.assertEqual(call("GET", "/staff/bookings", token=ana)[0], 403,
AssertionError: 200 != 403 : a customer's token opened a staff-only route

----------------------------------------------------------------------
Ran 9 tests in 3.385s

FAILED (failures=1)
ana@nft:~/unguarded$ cd ~/boxoffice
ana@nft:~/boxoffice$ rm -r ~/unguarded
```

One failure, the vertical test, with its sentence: a customer's token opened a staff-only route.
The other eight pass, the staff control among them, because a member of staff is still allowed in;
what went is the refusal of everybody else. **The two kinds of escalation have one test each, and
each test answers only for its own line**: lesson 16's copy without the owner check failed only the
two-customer test, and this one fails only the staff test. A suite built like that tells whoever
breaks it which defence they broke, in the first line of the failure.
