---
title: A first look, and the defect that was in the sentence
version: 1
---

**The fastest way to see the difference between preventing a defect and detecting one is to watch one
defect go through both.** Here is the first thing Lia was given at Cine Aurora: the price rule of the
online ticket shop, as Joana, the product owner, wrote it for the developers.

> **Ticket prices.** A ticket costs R$ 36,00 for a session that starts at 17:00 or later, and R$ 28,00
> for one that starts earlier. Students, over-60s and children under 12 pay half. On Wednesdays every
> ticket is half price. An order holds between one and six tickets.

And here is what Rafael, one of the two developers, built from it. Save it in `~/aurora` as
`tickets.py`. You are not expected to be able to write it; read the notes, and the code beside each
one, until you can say in your own words what each part decides.

```schooling-example
{"language": "python", "file": "tickets.py", "parts": [{"code": "# tickets.py\nimport sys\n\nEVENING = 3600\nMATINEE = 2800\n", "note": "The two full prices, in centavos: R$ 36,00 for an evening session and R$ 28,00 for a matinée. Money is kept as a whole number of centavos, because a fraction of a real cannot be paid."}, {"code": "\n\ndef price(age, student, day, time):\n    if time < \"17:00\":\n        full = MATINEE\n    else:\n        full = EVENING\n", "note": "`price` takes four facts about one ticket and answers what it costs. First the session: one starting before 17:00 is a matinée."}, {"code": "    half = False\n    if student:\n        half = True\n    if age > 60:\n        half = True\n    if age < 12:\n        half = True\n", "note": "Then who is buying. Three kinds of customer pay half: a student, an older person, a child. Each `if` is one line of the requirement turned into code."}, {"code": "    if day == \"wed\":\n        full = full // 2\n    if half:\n        return full // 2\n    return full\n", "note": "Wednesday is half price for everybody. `//` divides and drops what is left over, which on these prices is nothing."}, {"code": "\n\ndef brl(cents):\n    return f\"R$ {cents // 100},{cents % 100:02d}\"\n", "note": "Turns 1800 centavos into the text `R$ 18,00`, the way a Brazilian receipt writes it."}, {"code": "\n\nif __name__ == \"__main__\":\n    age, student, day, time = sys.argv[1:]\n    print(brl(price(int(age), student == \"yes\", day, time)))\n", "note": "What runs when you type the command. The four words after `python tickets.py` are the age, `yes` or `no` for a student, the day as three letters and the session time."}]}
```

Run it for four customers: an adult at an evening session on a Thursday, a student at the same
session, an eight-year-old at a Saturday matinée, and an adult on a Wednesday evening.

```
lia@lab:~/aurora$ python tickets.py 35 no thu 20:00
R$ 36,00
lia@lab:~/aurora$ python tickets.py 20 yes thu 20:00
R$ 18,00
lia@lab:~/aurora$ python tickets.py 8 no sat 14:00
R$ 14,00
lia@lab:~/aurora$ python tickets.py 35 no wed 20:00
R$ 18,00
```

Each answer can be checked against the rule above without reading a line of the program. R$ 36,00
for the adult, half of that for the student, half of R$ 28,00 for the child, and half price on the
Wednesday. Four for four.

## Detecting it

Lia did not stop at four, because four answers that agree with the rule say nothing about the inputs
nobody tried. The rule names three ages; she tried the edges of one of them.

```
lia@lab:~/aurora$ python tickets.py 61 no thu 20:00
R$ 18,00
lia@lab:~/aurora$ python tickets.py 60 no thu 20:00
R$ 36,00
```

**A sixty-year-old pays full price.** Sixty-one pays half, so the program does give the reduction; it
gives it from one year too late. Brazilian law, the statute that protects older people, grants the
half-price ticket from sixty, and the box office has always sold it that way.

That is **detection**: the defect existed, a check was run, and the check exposed it. The check was
cheap, two commands, and it was cheap because the program was small, nobody had sold a ticket with it
yet and Lia knew where to look. Each of those three is an advantage that disappears later, which is
lesson 3's subject.

## Preventing it

Now read the sentence again. *Over-60s.* Does somebody who is exactly sixty count as over sixty?
Rafael read it the way a programmer reads `over`, and wrote `age > 60`. Joana meant what the box office
does. Both readings are reasonable, and the sentence allows both.

The defect was **in the requirement before it was in the code**, and one question would have stopped
it there: *"over 60, or 60 and over?"*, asked on the day the rule was written, by anybody who reads a
sentence looking for the two ways it can be taken. That is **prevention**. It costs one reply in a
conversation, nothing has to be fixed, and no customer is ever charged the wrong price.

**Quality assurance is both of these, and this course is about knowing which one a moment calls for.**
Detection needs something to exist and costs more the later it runs; prevention needs somebody to
doubt a plan and costs almost nothing, but it cannot catch what nobody thought to ask.

`tickets.py` has at least two more defects in its forty lines, and none of them shows up in the four
answers above. Lessons 4 and 6 find them. Keep the file: from here on it is the system under test.
