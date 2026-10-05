---
title: The matrix, with one column empty
version: 1
---

Everything in this lesson goes into one table. Rows are candidates, columns are criteria, and the
thresholds come first because they remove rows before anything is ranked.

| candidate | structured output | window ≥ 32k | terms read | drafting, cached | first token p95 | sorting accuracy |
|---|---|---|---|---|---|---|
| claude-haiku-4-5 | yes | 200,000 | yes | $18.72 | to measure | lesson 5 |
| claude-sonnet-5-5 | yes | 1,000,000 | yes | $37.44 | to measure | lesson 5 |
| gemini/gemini-3.5-flash-lite | yes | 1,048,576 | yes | $8.02 | to measure | lesson 5 |
| gpt-5.4-mini | yes | 272,000 | yes | $15.84 | to measure | lesson 5 |
| mistral/mistral-small-latest | yes | 262,144 | yes | $2.45 | to measure | lesson 5 |
| deepseek/deepseek-v3.2 | **not recorded** | 163,840 | yes | $2.84 | to measure | lesson 5 |

The structured-output and window columns come from the sheet, the costs from section 05, and
"terms read" is ana's own note from lesson 2. **The last two columns are empty on purpose.**

## Reading it per task

The matrix answers differently for each of ana's tasks, because each task has its own thresholds:

- **Extraction** needs structured output. DeepSeek V3.2 leaves the list for this task until she
  checks the provider's own documentation; a sheet's silence is a question, not a no. Everybody
  else stays.
- **Sorting** needs neither long context nor structured output, and nobody is waiting. Every row
  stays, and the cheapest model that clears the accuracy floor wins.
- **Drafting** has a person waiting, so the latency ceiling from section 06 applies, and it is the
  task where the quality column is most likely to separate the cheap rows from the dear ones.

## The step that turns this into a decision

The six rows span a factor of about fifteen in cost, from $2.45 to $37.44, and all of them are cheap
in absolute terms for a shop this size. **The decision is going to be made by the empty column.** A
model that sorts 39 cases in 40 for $8 a month beats one that sorts 34 for $2, and the opposite may
hold for drafting.

Lesson 5 fills the column. In this course's lab the candidates are played by the stand-in's three
models, one for each kind of row: `standin-large` for the expensive tier, `standin-small` for the
cheap tier, `standin-local` for an open model ana would run herself. **Their answers were written by
the course**, so the scores they get are the course's too. What carries over to real candidates is
the harness, the scoring and the reading of the results, which are the parts that are hard to get
right.
