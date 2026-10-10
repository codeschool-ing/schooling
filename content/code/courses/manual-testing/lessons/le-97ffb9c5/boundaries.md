---
title: Boundary values
version: 1
---

**Defects gather at the edges of partitions, not in their middles.** A requirement says "1 to
40"; somebody turns that into code, and has to decide, character by character, whether 40 is in or
out. Writing "less than" where "less than or equal" was meant moves the edge by one, and every
value in the middle of the partition still behaves. A representative of 20 characters passes on
both versions of the code. Only a value on the edge can tell them apart.

**Boundary value analysis** is the technique that goes there. It takes the partitions from section
02 of this lesson and, instead of one value from the middle of each, tests the values on either
side of every line between them. It does not replace partitioning; it is drawn on top of it, and
without the partitions there are no lines to go to.

## Which values sit on a boundary

A **boundary value** is the smallest or the largest value of a partition. The name partitions of
R2 meet at two lines, one between 0 and 1 character and one between 40 and 41, so the boundary
values are 0, 1, 40 and 41. Two conventions say how many of them to test around each line:

- **two-value** boundary analysis tests the value on the boundary and its nearest neighbour across
  the line: for the name, 0 and 1, and 40 and 41. Four cases;
- **three-value** analysis adds the nearest neighbour on the inside as well: 2 and 39. Six cases.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 660 250\" role=\"img\" data-fig=\"l04-boundary\" aria-label=\"A number line of name lengths: 0, 1 and 2, a break, then 39, 40 and 41. Shaded behind it, the partitions empty, 1 to 40 characters, and 41 or more. Dashed lines mark the two boundaries, between 0 and 1 and between 40 and 41. The values 0, 1, 40 and 41 are filled circles, the two-value boundary values; 2 and 39 are hollow circles, the values three-value analysis adds.\"><rect x=\"112.0\" y=\"52.0\" width=\"66.0\" height=\"110.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"145.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">empty</text><rect x=\"182.0\" y=\"52.0\" width=\"296.0\" height=\"110.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"330.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">1 to 40 characters</text><rect x=\"482.0\" y=\"52.0\" width=\"76.0\" height=\"110.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"520.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">41 or more</text><path d=\"M118.0 130.0 L172.0 130.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M188.0 130.0 L320.0 130.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M340.0 130.0 L472.0 130.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M488.0 130.0 L552.0 130.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"330.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">…</text><path d=\"M180.0 34.0 L180.0 176.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"180.0\" y=\"26.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">boundary</text><path d=\"M480.0 34.0 L480.0 176.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"480.0\" y=\"26.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">boundary</text><circle cx=\"150.0\" cy=\"130.0\" r=\"7\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"150.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">0</text><circle cx=\"210.0\" cy=\"130.0\" r=\"7\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"210.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1</text><circle cx=\"270.0\" cy=\"130.0\" r=\"7\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"270.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">2</text><circle cx=\"390.0\" cy=\"130.0\" r=\"7\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"390.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">39</text><circle cx=\"450.0\" cy=\"130.0\" r=\"7\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"450.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">40</text><circle cx=\"510.0\" cy=\"130.0\" r=\"7\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"510.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">41</text><text x=\"330.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">characters in the name</text><circle cx=\"130.0\" cy=\"222.0\" r=\"6\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"144.0\" y=\"222.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">two-value: 0, 1, 40 and 41</text><circle cx=\"390.0\" cy=\"222.0\" r=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"404.0\" y=\"222.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">three-value adds 2 and 39</text></svg>", "caption": "The boundaries of R2's name length. Two-value analysis tests the four filled values, one on each side of each line; three-value analysis adds the hollow ones, the next value inside."}
```

Two values are enough for most fields, and they are what this course uses. The third value earns
its cost when the line is drawn by an expression rather than a plain comparison, such as a limit
computed from something else, where a mistake can move the edge by more than one. On a fixed limit
like 40 it rarely finds what the first two missed.

"Nearest neighbour" depends on what the field holds. For a count of characters or tickets it is one
more or one less. For money it is one cent: a voucher valid "up to R$ 100,00" has its line between
R$ 100,00 and R$ 100,01. For a time it is the smallest step the system keeps, a minute or a second.
The line in R4's "booking closes one hour before it starts" falls at 19:00 for a show at 20:00, and
its cases sit a minute either side of it. That one needs the clock moved to test, and lesson 13
shows how a fake clock does it.

## Running R2's boundaries

R2 has two length rules, so two-value analysis gives eight values: 0, 1, 40 and 41 characters for
the name, and 7, 8, 64 and 65 for the password. Each runs as a sign-up with everything else valid,
so the one thing that can go wrong is the value under test, and each needs an e-mail address of its
own, because an address that worked once is taken the second time.

In the browser, open **Sign up**, type the values into the three fields and press **Create
account**: the sentence at the top of the page that comes back is the result. Strings of 40 or 65
characters are easiest to get right by not inventing them: the transcripts use digits,
`1234567890` repeated, so the length can be counted in tens. From the terminal, with a freshly
started boxoffice:

```
ana@laptop:~/boxoffice$ curl -s -d 'name=&email=n0@example.org&password=12345678' http://127.0.0.1:8000/signup | grep msg
<p class="msg">Name must be 1 to 40 characters.</p><form method="post" action="/signup">
ana@laptop:~/boxoffice$ curl -s -d 'name=A&email=n1@example.org&password=12345678' http://127.0.0.1:8000/signup | grep msg
<p class="msg">Account created. We sent a link to n1@example.org.</p>
ana@laptop:~/boxoffice$ curl -s -d 'name=1234567890123456789012345678901234567890&email=n40@example.org&password=12345678' http://127.0.0.1:8000/signup | grep msg
<p class="msg">Account created. We sent a link to n40@example.org.</p>
ana@laptop:~/boxoffice$ curl -s -d 'name=12345678901234567890123456789012345678901&email=n41@example.org&password=12345678' http://127.0.0.1:8000/signup | grep msg
<p class="msg">Name must be 1 to 40 characters.</p><form method="post" action="/signup">
```

```
ana@laptop:~/boxoffice$ curl -s -d 'name=Ana&email=p7@example.org&password=1234567' http://127.0.0.1:8000/signup | grep msg
<p class="msg">Password must be 8 to 64 characters.</p><form method="post" action="/signup">
ana@laptop:~/boxoffice$ curl -s -d 'name=Ana&email=p8@example.org&password=12345678' http://127.0.0.1:8000/signup | grep msg
<p class="msg">Account created. We sent a link to p8@example.org.</p>
ana@laptop:~/boxoffice$ curl -s -d 'name=Ana&email=p64@example.org&password=1234567890123456789012345678901234567890123456789012345678901234' http://127.0.0.1:8000/signup | grep msg
<p class="msg">Account created. We sent a link to p64@example.org.</p>
ana@laptop:~/boxoffice$ curl -s -d 'name=Ana&email=p65@example.org&password=12345678901234567890123456789012345678901234567890123456789012345' http://127.0.0.1:8000/signup | grep msg
<p class="msg">Password must be 8 to 64 characters.</p><form method="post" action="/signup">
```

All eight behave. The empty name and the 41-character one get the sentence R2 and R7 ask for; one
and 40 characters create an account; the password is refused at 7 and 65 and accepted at 8 and 64.
**A boundary test that passes is a result, not a waste.** Before these eight ran, nobody knew where
boxoffice drew those four lines; now there is evidence that it draws them where R2 does. That is
worth recording in exactly the same way as a failure, with the values used and what came back.

## Boundaries the requirement does not write down

Some lines are not in the requirement's numbers. R4's "while seats last" is a boundary that moves:
it sits between the seats left and one more than that, and it is somewhere else after every
booking. A theatre with 200 seats for The Little Prince does not need 200 bookings to reach it,
only a moment when few are left. Other lines come from the platform rather than the rule: a field
that is stored in a column of 255 characters has a boundary at 255 whatever the requirement says.
**Asking a developer "is there any limit here I cannot see?" is part of the technique**, and the
answer often adds a line to the drawing.

Section 04 of this lesson takes both techniques to R4's quantity field, where one of the four
boundary values does not behave.
