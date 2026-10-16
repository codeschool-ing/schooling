---
title: A scoring matrix, and what it does not decide
version: 1
---

**A weighted decision matrix turns a choice into arithmetic, and the arithmetic is the least
important part of it.** The method is short. List the options. List the criteria. Score each option
on each criterion. Give each criterion a weight for how much it matters, multiply, add up. The
highest total wins, and the trap is believing that last sentence.

Roda Livre has a real choice to make. Marta's van report needs tables somewhere they can be queried,
and the team has narrowed it to three: a **PostgreSQL server the team runs** itself, a **managed
warehouse** from a cloud provider, or **Parquet files in object storage** with a query engine reading
them. Davi scores them on five criteria taken from the previous section. Save this as `matrix.py`:

```schooling-example
{"language": "python", "file": "choose/matrix.py", "parts": [
{"code": "# choose/matrix.py\nCRITERIA = [\"known\", \"bill\", \"upkeep\", \"growth\", \"exit\"]\n\nSCORES = {                    # 1 is poor and 5 is good, in Davi's judgement\n    \"PostgreSQL we run\":  [5, 4, 2, 2, 5],\n    \"managed warehouse\":  [3, 2, 5, 5, 2],\n    \"Parquet in storage\": [2, 5, 3, 4, 4],\n}\n", "note": "Five criteria: how well the team knows it, how small the bill is, how few hours it takes to keep running, how much room it has to grow, and how easy it is to leave. A 5 is always the good end, so a cheap option scores high on `bill`."},
{"code": "\nWEIGHTS = {\n    \"a team of two\":    [3, 2, 3, 1, 1],\n    \"a year of growth\": [1, 1, 2, 4, 2],\n}\n", "note": "Two sets of weights, each adding up to ten, for two views of the year ahead. The first says the team's hours matter most; the second says room to grow does."},
{"code": "\nfor label, weights in WEIGHTS.items():\n    print(f\"weighted for {label}:\", dict(zip(CRITERIA, weights)))\n    totals = {\n        option: sum(w * s for w, s in zip(weights, scores))\n        for option, scores in SCORES.items()\n    }\n    for option, total in sorted(totals.items(), key=lambda kv: -kv[1]):\n        print(f\"  {option:20}{total:3}\")\n", "note": "For each set of weights, every score is multiplied by its criterion's weight and the products are added. The options are printed highest first."}
]}
```

Run it:

```
ana@lab:~/roda/choose$ python matrix.py
weighted for a team of two: {'known': 3, 'bill': 2, 'upkeep': 3, 'growth': 1, 'exit': 1}
  PostgreSQL we run    36
  managed warehouse    35
  Parquet in storage   33
weighted for a year of growth: {'known': 1, 'bill': 1, 'upkeep': 2, 'growth': 4, 'exit': 2}
  managed warehouse    39
  Parquet in storage   37
  PostgreSQL we run    31
```

## The weights choose the winner

With the weights for a team of two, the server the team runs wins by one point, 36 to 35. With the
weights for a year of growth, the same scores put the managed warehouse first with 39, and the
server last with 31. **Nothing about the options changed between the two runs. Only the priorities
did.**

And one point is less than the uncertainty in any single score. Davi gave the managed warehouse a 3
for how well the team knows it. Caio, who used one at his last job, would say 4. Change that one
cell with `sed`, as lesson 1 did, and run the first ranking again:

```
ana@lab:~/roda/choose$ sed "s/\[3, 2, 5, 5, 2\]/[4, 2, 5, 5, 2]/" matrix.py > nudged.py
ana@lab:~/roda/choose$ python nudged.py | head -4
weighted for a team of two: {'known': 3, 'bill': 2, 'upkeep': 3, 'growth': 1, 'exit': 1}
  managed warehouse    38
  PostgreSQL we run    36
  Parquet in storage   33
```

The managed warehouse now wins with 38. One judgement, moved by one, on one criterion, reversed the
result.

## So what is it for?

Not for producing the answer. A matrix is useful for three other things, and all three are about
people.

- **It shows where people disagree.** Davi and Caio do not disagree about the warehouse; they
  disagree about whether the next year is about the team's hours or about growth. That is a question
  for Marta, and the matrix is what made it visible.
- **It forces every criterion to be written down.** A criterion nobody wrote down still decides the
  outcome, through whoever argues loudest.
- **It records the reasoning.** In a year somebody will ask why the team chose what it chose. A
  matrix with its weights answers that better than anybody's memory.

Two habits spoil it. **Scoring after deciding**: somebody who already prefers an option adjusts the
numbers until it wins, and the matrix launders a preference into a calculation. And **counting one
thing twice**: "bill" and "upkeep" are both cost, and a matrix with five cost criteria and one for
everything else has decided before anybody scored. When the totals are as close as 36 and 35, the
honest output is "these two are equivalent on our criteria", and the choice goes to something the
matrix does not hold, such as which mistake is easier to undo.
