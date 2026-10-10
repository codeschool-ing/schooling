---
title: Input that is not a number
version: 1
---

**The quantity field is drawn as a box, and a box accepts anything you type.** It has a
placeholder saying *Tickets (1 to 6)*, and nothing in the browser stops somebody typing `two`,
`2.5`, a space, or nothing at all and pressing **Book**. Section 04 of this lesson partitioned the
whole numbers. This section takes the fourth partition, **input that is not a whole number**, and
R7 says what should happen to all of it: "Wrong input is answered with a sentence saying what is
wrong, never with an error page."

It is the partition testers forget most, for a reason that sounds respectable: the field is for
numbers, so the cases are numbers. The customer, though, has a keyboard, and a phone that suggests
words while they type. Every value in this partition is something a real person can send, and the
requirement already says how boxoffice must answer.

## One representative: a word

The partition holds words, decimals, empty input, and symbols, and one representative stands for
it. Here it is `two`, which is what a person types when they read *Tickets* and not the numbers
after it. In the browser, book Hamlet as the member with `two` in the quantity field. From the
terminal, the transcript adds the status code after the page, which curl's `-w` prints:

```
ana@laptop:~/boxoffice$ curl -s -w '\n%{http_code}\n' -d 'email=member@example.org&show=S2&quantity=two' http://127.0.0.1:8000/book
<pre>Traceback (most recent call last):
  File &quot;/home/ana/boxoffice/boxoffice.py&quot;, line 237, in answer
    status, body = route(fields) if route else page(&quot;Not found&quot;, &quot;&quot;, 404)
                   ~~~~~^^^^^^^^
  File &quot;/home/ana/boxoffice/boxoffice.py&quot;, line 179, in book
    quantity = int(f.get(&quot;quantity&quot;, &quot;&quot;))
ValueError: invalid literal for int() with base 10: &#x27;two&#x27;
</pre>
500
```

**That is the second defect of the lesson.** In the browser it is a page with no heading and no
links, holding a block of monospaced text that starts with *Traceback (most recent call last)*.
The status at the end of the transcript is `500`, the code HTTP uses for "the server failed",
which is a different statement from the refusals in section 04: those came back as an ordinary page
with a sentence on it.

Read it as a customer would and it breaks R7 twice. It is an error page, which R7 rules out by
name. And it is not a sentence saying what is wrong: nothing on it tells the customer that the
quantity has to be written as digits. Read it as a tester and it says more than that. It names a
file on the server, `/home/ana/boxoffice/boxoffice.py`, the line numbers inside it, and the line of
code that failed. A page that hands any visitor a description of the program's insides is a
concern for security as well as for the customer, and lesson 14 comes back to it from the
defender's side.

The quotes in the transcript read `&quot;` because the page escapes them for HTML, and the browser
shows them as ordinary quotation marks.

## Is it one defect or three?

If the partition is right, every value in it fails the same way, and that is worth one check
before writing anything down, because it changes what the result says. Empty input and a decimal
are both in the partition; `-1` is a whole number, and belongs to the "0 or fewer" partition of
section 04 instead:

```
ana@laptop:~/boxoffice$ curl -s -o /dev/null -w '%{http_code}\n' -d 'email=member@example.org&show=S2&quantity=' http://127.0.0.1:8000/book
500
ana@laptop:~/boxoffice$ curl -s -o /dev/null -w '%{http_code}\n' -d 'email=member@example.org&show=S2&quantity=2.5' http://127.0.0.1:8000/book
500
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S2&quantity=-1' http://127.0.0.1:8000/book | grep msg
<p class="msg">You can book 1 to 6 tickets.</p><form method="post" action="/book">
```

Empty and `2.5` answer 500 like `two`, and `-1` gets the sentence. The partitions predicted exactly
this split, and that makes the result one defect, stated as a partition: **any quantity that is not
a whole number answers 500 and a traceback.** Three reports, one per value, would describe one
fault three times and leave a developer to discover that they are the same.

## One invalid value per case

A case that tests an invalid partition carries one invalid value, and everything else in it valid.
It is tempting to save cases by putting two wrong things into one request, and the transcript below
shows what that costs. This is the same `two`, sent with an e-mail address no account has:

```
ana@laptop:~/boxoffice$ curl -s -d 'email=nobody@example.org&show=S2&quantity=two' http://127.0.0.1:8000/book | grep msg
<p class="msg">Sign up before you book.</p><form method="post" action="/book">
```

The answer is a polite sentence about signing up, and the traceback never happens. **boxoffice
stops at the first thing it finds wrong**, and it checks the account before it reads the quantity,
so the second invalid value is never looked at. A tester running this combined case would have
recorded a pass for a field that fails. This effect is called **masking**: one invalid input hides
another. Which of the two a program checks first is a fact about its code, and a black-box tester
does not get to rely on it.

So the rule from section 02 of this lesson has a reason now. Valid partitions can share a case,
because a valid value lets the program carry on to the next field. An invalid one may stop it, and
whatever comes after goes untested.

## What the two techniques found

This lesson sent 19 requests to boxoffice, each chosen rather than guessed, and found two defects
in R4. Six tickets is refused because a boundary is off by one; a quantity that is not a number
brings down the request with a traceback. Neither was visible to a tester typing sensible numbers
into a number field. Lesson 5 moves from single fields to rules where several conditions decide one
result together, and to an order whose behaviour depends on what has happened to it before.
