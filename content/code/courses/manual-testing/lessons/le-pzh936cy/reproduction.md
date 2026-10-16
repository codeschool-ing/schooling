---
title: A reproduction a stranger can replay
version: 1
---

The steps of a report are usually written from memory, in the order things happened. They carry
everything that happened: the page you opened first, the show you looked at and changed your
mind about, the account you signed in with because it was the one in your browser. **A
reproduction is the shortest path from a known state to the failure**, with nothing on it the
failure does not need. Every extra step is one more place for the reader to do something slightly
different and see something else.

Getting there takes three moves: pin down the state you start from, cut the steps to the ones that
matter, and try a few neighbours to learn the defect's shape. The defect from section 02 of this
lesson is a good one to practise on, because it is deterministic and has a simple trigger.

## Start from a state somebody else can reach

The reader cannot reach *"my laptop after an hour of testing"*. They can reach *"boxoffice 1.1,
freshly started"*, because lesson 1 says what a fresh start contains: three shows with every seat
free, no orders, and one account. So the first line of every reproduction names the version, and
the cheapest way to prove it is to ask the application:

```
ana@laptop:~/boxoffice$ curl http://127.0.0.1:8000/health
ok boxoffice 1.1
```

**A report against the wrong version wastes the reader's first hour.** If 1.2 has fixed it and
you are still running 1.1, the developer tries it, sees nothing wrong, and the report comes back
marked *cannot reproduce*, with the defect still in your copy and gone from theirs.

## Cut it to one request

In the browser the steps are five: open the booking page, type an e-mail, leave the show, type a
quantity, press Book. They belong in the report, because a reader who wants to see the page should
be able to. But the browser hides the part that matters, the request itself, and **curl writes the
whole request on one line**, so a reader can paste it and get exactly what you got:

```
ana@laptop:~/boxoffice$ curl -s -o /dev/null -w '%{http_code}\n' -d 'email=member@example.org&show=S2&quantity=two' http://127.0.0.1:8000/book
500
```

`-d` sends the three fields as the form would. `-o /dev/null` throws the page away and
`-w '%{http_code}\n'` prints only the status, so the whole result is one number a reader can
compare with theirs. Without those two options, curl prints the page itself:

```
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S2&quantity=two' http://127.0.0.1:8000/book
<pre>Traceback (most recent call last):
  File &quot;/home/ana/boxoffice/boxoffice.py&quot;, line 230, in answer
    status, body = route(fields) if route else page(&quot;Not found&quot;, &quot;&quot;, 404)
                   ~~~~~^^^^^^^^
  File &quot;/home/ana/boxoffice/boxoffice.py&quot;, line 172, in book
    quantity = int(f.get(&quot;quantity&quot;, &quot;&quot;))
ValueError: invalid literal for int() with base 10: &#x27;two&#x27;
</pre>
```

The `&quot;` marks are how HTML writes a quotation mark; in a browser the same page reads with
ordinary quotes. Its last line names the failure and the value that caused it, `'two'`, which is
the line a report quotes.

**Then check that every field is earning its place.** Take one away and send it again. Without
the e-mail, and without the show:

```
ana@laptop:~/boxoffice$ curl -s -d 'show=S2&quantity=two' http://127.0.0.1:8000/book | grep msg
<p class="msg">Sign up before you book.</p><form method="post" action="/book">
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&quantity=two' http://127.0.0.1:8000/book | grep msg
<p class="msg">There is no such show.</p><form method="post" action="/book">
```

Both answer with a proper sentence, so the program checks the account and the show before it
reads the quantity, and both fields belong in the reproduction. The student box was never needed,
and neither was the browser.

## Try the neighbours

One failing value is a fact. Three values tell you its shape, and the shape is what the developer
needs to fix the whole defect instead of the one word you happened to type:

```
ana@laptop:~/boxoffice$ curl -s -o /dev/null -w '%{http_code}\n' -d 'email=member@example.org&show=S2&quantity=' http://127.0.0.1:8000/book
500
ana@laptop:~/boxoffice$ curl -s -o /dev/null -w '%{http_code}\n' -d 'email=member@example.org&show=S2&quantity=2.5' http://127.0.0.1:8000/book
500
ana@laptop:~/boxoffice$ curl -s -o /dev/null -w '%{http_code}\n' -d 'email=member@example.org&show=S2&quantity=7' http://127.0.0.1:8000/book
200
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S2&quantity=7' http://127.0.0.1:8000/book | grep msg
<p class="msg">You can book 1 to 6 tickets.</p><form method="post" action="/book">
```

An empty box and a decimal fail the same way; a whole number out of range gets the sentence R7
asks for. So the report's title says *a quantity that is not a whole number*, not *the word two*,
and a developer who fixes only the word would be caught by the next tester to leave the box empty.
These are the partitions of lesson 4, used here to describe a failure instead of to design a case.

## When it does not happen every time

This defect fails on every try, which makes it easy. Some do not: a failure that depends on timing,
on two people booking the last seat at once, or on something the reporter has not noticed. **Then
the report says how often**, as a count: *"3 of 10 attempts, same steps, same build"*. "Sometimes"
tells the reader nothing about whether their one clean try means the defect is gone. A count also
tells the reader how many tries to make before they believe their result.

## For Windows

The commands above were run in a Unix shell. In PowerShell, type `curl.exe` rather than `curl`,
because older PowerShell versions answer `curl` with a command of their own; the single quotes work
as written. This was not run for this course. In the browser, the same five steps give the same
traceback as the page's only content, with no title, links or footer.
