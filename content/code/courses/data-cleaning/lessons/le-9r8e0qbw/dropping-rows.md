---
title: Dropping rows, and who leaves with them
version: 1
---

**Dropping every row with a blank is the default in more tools than it should be**, and it is the
right choice in exactly one situation: the blanks are MCAR and the rows that remain are enough.
Anywhere else, dropping changes not only how many rows there are but **who** they are.

Ana wants the average age of Quitanda Verde's customers. Dropping the customers without a usable
birth year looks harmless:

```
ana@lab:~/clean$ python -c "from customers import customers as c; print(len(c)); print((c['signup_channel'].value_counts(normalize=True) * 100).round(1).to_string()); kept = c.dropna(subset=['birth_year']); print(len(kept)); print((kept['signup_channel'].value_counts(normalize=True) * 100).round(1).to_string())"
2376
signup_channel
site           42.2
app            30.4
store          25.5
import-2023     1.9
1601
signup_channel
site           51.0
app            38.8
store           8.4
import-2023     1.8
```

2,376 customers become 1,601, and the mix changes completely. **The shops' customers were a
quarter of the base and are 8.4% of what is left.** Lesson 3 found why: the shops' form produced
the placeholders, so the blanks are concentrated there. Any statement about "our customers" made
from the remaining rows is now mostly a statement about website and app customers.

Whether that matters depends on the question again. If the shops' customers are the same age as
everybody else, the average survives; if they are older, it is wrong in a direction nobody
announced. **Dropping turns a question about missing values into a question about the people who
remain**, and the profile of who remains is the check to run every time.

Three things make dropping more defensible:

- **dropping per question, not per file.** `dropna(subset=["birth_year"])` drops for the age
  question and nothing else. Dropping every row with any blank anywhere would remove most of the
  shops' customers from questions that never needed a birth year;
- **reporting how many rows the answer rests on**, beside the answer: "average age of the 1,601
  customers with a known year";
- **checking the mix before and after**, as above. A shift like 25.5% to 8.4% is the signal to stop
  and look for another strategy.

What dropping never does is invent anything. That is its whole appeal, and it is real: a smaller
honest sample can be better than a larger one filled with guesses. The rest of this lesson is the
guesses, and what they cost.
