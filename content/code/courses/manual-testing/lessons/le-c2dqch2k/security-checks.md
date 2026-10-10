---
title: Security, from the defender's side
version: 1
---

Security testing has a reputation as breaking in: clever tricks, special tools, a hooded figure.
Some of it is that, done by specialists, under contract, with written permission. **Most of what a
manual tester contributes is noticing**: the page that says more than it should, the rule that is
weaker than it looks, the address that should start with `https` and does not. Each is something a
defender wants to hear about before anybody else finds it, and none of it needs an attack.

One rule comes first, and it is not a formality. **Test only systems you have been given permission
to test, and only in the ways agreed.** Testing somebody else's system without permission can be a crime in
many countries, Brazil included, whatever the intention. Everything in this section happens on your own
copy of boxoffice.

## The error page that says too much

Lesson 4 found that a tickets field that is not a number answers with an error page instead of a
sentence. That broke R7, a functional requirement. Seen with a defender's eyes it is also a
security finding, and a different report:

```
ana@laptop:~$ curl -s -d 'email=member@example.org&show=S2&quantity=two' http://127.0.0.1:8000/book
<pre>Traceback (most recent call last):
  File &quot;/home/ana/boxoffice/boxoffice.py&quot;, line 230, in answer
    status, body = route(fields) if route else page(&quot;Not found&quot;, &quot;&quot;, 404)
                   ~~~~~^^^^^^^^
  File &quot;/home/ana/boxoffice/boxoffice.py&quot;, line 172, in book
    quantity = int(f.get(&quot;quantity&quot;, &quot;&quot;))
ValueError: invalid literal for int() with base 10: &#x27;two&#x27;
</pre>
```

In a browser the same request shows the traceback as text on a white page. Read it the way a
stranger would. It gives the **full path of the program** on the server, `/home/ana/boxoffice/`,
and with it, very likely, the name of the account it runs under. It names the language, quotes **lines of the source
code** with their line numbers, and shows how the quantity is read and which function reads it.
None of that is a password, and all of it is free knowledge for somebody planning something worse:
it saves them the guessing. The status code confirms the program failed rather than refused:

```
ana@laptop:~$ curl -s -o /dev/null -w '%{http_code}\n' -d 'email=member@example.org&show=S2&quantity=two' http://127.0.0.1:8000/book
500
```

**What should happen instead** is a page that says something went wrong, in plain words, while the
details go to a log only the team can read. As a defect, this is one report about R7 (lesson 4's)
and one about information disclosure (this one), because they will be fixed and checked by
different people, with different urgency.

The response headers leak a smaller detail on every page:

```
ana@laptop:~$ curl -s -o /dev/null -D - http://127.0.0.1:8000/
HTTP/1.0 200 OK
Server: BaseHTTP/0.6 Python/3.13.16
Date: Sat, 10 Oct 2026 07:20:02 GMT
Content-Type: text/html; charset=utf-8
Content-Length: 931

```

The `Server` line names the exact Python version. Minor, and worth a line in a report: many teams
remove or blur that header in production for the same reason as the traceback.

## The things a tester looks for

These need no tool beyond a browser and curl, and they cover a good share of what a security
specialist would raise first.

**Error pages.** Wrong input, a missing page, an order number that does not exist: every one should
answer with a sentence, never with internals. Asked for an order that does not exist, boxoffice
answers the way it should:

```
ana@laptop:~$ curl -s 'http://127.0.0.1:8000/order?id=9999' | grep msg
<p class="msg">There is no such order.</p>
```

**HTTPS.** Every page of a real site should load over `https`, with the padlock in the address bar,
and typing the `http` address should redirect to it. A form that sends a password over plain `http`
sends it readable by anybody on the same network. boxoffice runs on `http://127.0.0.1`, which is
fine for a program that never leaves your laptop; in the theatre's production environment, plain
`http` on the sign-up page would be a defect of the highest severity. This one cannot be tested in
the lab, so it goes into the plan as something to check in production.

**Password rules.** R2 asks for 8 to 64 characters and nothing else, so the weakest password in the
world is accepted:

```
ana@laptop:~$ curl -s -d 'name=Caio&email=caio@example.org&password=12345678' http://127.0.0.1:8000/signup | grep msg
<p class="msg">Account created. We sent a link to caio@example.org.</p>
ana@laptop:~$ curl -s http://127.0.0.1:8000/outbox | grep -c 12345678
0
```

That is not a defect: the application does what R2 says. It is a **question for the client**, the
validation question of lesson 6. Current guidance, such as NIST's on digital identity, prefers
length and a check against lists of passwords already known to have leaked over rules about
symbols. The second command above is a check worth keeping: the outbox holds the confirmation
e-mail for Caio and the password appears nowhere in it, so `grep -c` counts 0 lines. A password
sent back by e-mail would be a defect.

**What a message gives away.** Try to sign up with an address that already has an account:

```
ana@laptop:~$ curl -s -d 'name=Somebody&email=member@example.org&password=long-enough' http://127.0.0.1:8000/signup | grep msg
<p class="msg">There is already an account with that e-mail.</p><form method="post" action="/signup">
```

The sentence is helpful, and it also tells anybody who asks whether a given address is a customer
of the theatre. For a theatre that may be acceptable; for a clinic or a dating site it would not be.
It is a trade-off for the client to decide, and the tester's part is to put it in front of them
with the exact message, the way lesson 12 put the student discount in front of the manager.

## Where this goes next

Security testers work from shared lists of what goes wrong most often. The best known is the
**OWASP Top 10**, maintained by the OWASP Foundation, and information leaking
through error messages is part of it. Scanners and intercepting proxies exist for the work beyond
this section, and they are used with permission, by people trained to use them.
`security-fundamentals` and `non-functional-testing` are the two courses in this track that teach
them. For a manual tester the habit is enough: **read every unexpected page as a stranger would,
and ask what it tells them**.
