---
title: Running smoke, by hand and as a loop
version: 1
---

The list in section 03 of this lesson can be run in two ways, and both are worth knowing. **By
hand, in the browser, it takes a couple of minutes. As a short shell loop, it takes one command**
and prints one line per check, which can be pasted into a message as it is.

## By hand

With boxoffice freshly started, in the browser:

1. open `http://127.0.0.1:8000/health`: the page shows one line, `ok boxoffice` and the version;
2. open `http://127.0.0.1:8000`: the Shows table lists The Seagull, Hamlet and The Little Prince;
3. click Sign up: the form appears, with its Create account button;
4. go back, click Book on the Hamlet row, type `member@example.org`, type 2 in the tickets field and
   press Book: the next page says Order 1001 reserved;
5. click Outbox at the foot of the page: the page opens, with the heading Outbox.

Each step has one thing to look for, decided in advance, and a step either shows it or does not.
That is what makes it a check rather than a look around.

## As a loop

The same five checks fit in a few lines of shell. Each line under `CHECKS` is one check, with four
fields separated by `|`: its name; the form to send, empty when the check only opens a page; the
path; and a pattern the answer has to contain. The loop sends each request with curl, looks for the
pattern with grep, and prints `pass` or `FAIL`. At the end it says how many failed, and it finishes
with a failing exit status if any did, so that another program can tell the result without reading
the lines.

Save it as `smoke.sh` in your `boxoffice` directory, next to `boxoffice.py`:

```sh
# smoke.sh: five checks that say whether a build of boxoffice is worth testing.
# Run it with:  sh smoke.sh      while boxoffice is running.
URL=http://127.0.0.1:8000
failed=0
while IFS='|' read -r name form path expect; do
  if curl -s ${form:+-d "$form"} "$URL$path" | grep -q "$expect"; then
    echo "pass  $name"
  else
    echo "FAIL  $name"
    failed=$((failed + 1))
  fi
done <<'CHECKS'
the server answers||/health|^ok boxoffice
the home page lists three shows||/|The Seagull.*Hamlet.*The Little Prince
the sign-up page loads||/signup|Create account
one booking goes through|email=member@example.org&show=S2&quantity=2|/book|Order [0-9]* reserved
the outbox opens||/outbox|<h1>Outbox</h1>
CHECKS
echo "$failed of 5 checks failed"
[ "$failed" -eq 0 ]
```

Two details are easy to miss. `${form:+-d "$form"}` adds curl's `-d` and the form only
when the field is not empty, which is how one loop sends both a plain request and a booking. And the
pattern for the home page, `The Seagull.*Hamlet.*The Little Prince`, asks for all three titles in
that order on one line, which they are, because boxoffice writes the whole table on one line.

Restart boxoffice if you have just done the steps by hand, so that it starts from nothing, and run
the script from the second terminal. Adding `; echo $?` prints the exit status after it:

```
ana@laptop:~/boxoffice$ sh smoke.sh; echo $?
pass  the server answers
pass  the home page lists three shows
pass  the sign-up page loads
pass  one booking goes through
pass  the outbox opens
0 of 5 checks failed
0
```

Five passes and a status of 0: this build is worth testing. The script needs a Unix shell, so on
Windows it runs in WSL or in the Git Bash that comes with Git for Windows; elsewhere the five steps
by hand do the same job. The Windows paths were not run for this course.

## What smoke leaves behind

A smoke check that does something real changes the application. The booking check reserved two
seats for Hamlet, and the home page says so:

```
ana@laptop:~/boxoffice$ curl -s http://127.0.0.1:8000/ | grep -o 'Hamlet</td><td>[^<]*</td><td>[^<]*</td><td>[0-9]*'
Hamlet</td><td>2026-10-17 20:00</td><td>R$ 80,00</td><td>78
```

Hamlet has 78 seats left instead of 80, and the next order will be 1002, not 1001. Cases that count
seats or quote order numbers would now expect the wrong thing. **So after a smoke run, restart
boxoffice before the real testing starts**, which for this application is the whole of a reset. A
product that cannot be reset this easily needs smoke data of its own, set apart from the data the
cases use, and lesson 20 is about keeping test data under control.

## Keeping it small

A loop this easy to extend invites extending it. Every check added is a second it takes and one
more thing that can fail for a reason that is not the build. A smoke list that grows into
thirty checks of discounts and refunds has become a regression suite that runs first, which is
lesson 10's subject. The test for a new line is the one from section 03: does the build stop being
worth testing if this fails?
