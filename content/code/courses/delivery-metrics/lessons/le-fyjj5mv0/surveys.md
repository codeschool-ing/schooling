---
title: Asking the team, and reading what it says
version: 1
---

A survey is the cheapest way to measure the dimensions no system records. It is also easy to do badly, and a bad survey is worse than none, because people stop answering honestly the moment they suspect it is being used against them.

## Five rules

- **Few questions, the same every time.** Five statements a quarter, unchanged, beat thirty that change. The value is in the trend, and a trend needs the same question.
- **Anonymous, really.** No names, no team breakdowns small enough to identify somebody, no free text that can be recognised by its style if the team is small. If people cannot trust that, the answers are fiction.
- **Statements about experience, not about colleagues.** "Reviews of my work arrive quickly" measures the system; "my colleagues review promptly" invites blame.
- **Show everything, as distributions.** Every answer to every statement, as counts. No averages on small groups.
- **Say what you will do with it, and then do it.** A survey followed by nothing teaches people not to answer the next one.

## The Billing team's survey

Here is a survey the Billing team might have run at the end of each quarter, written for the course like the rest of its history. **Save the program below as `survey.py`.** It needs no other file.

```schooling-example
{
  "language": "python",
  "file": "survey.py",
  "parts": [
    {
      "code": "\"\"\"survey.py: a team's quarterly survey, read as distributions rather than averages.\"\"\"\nimport statistics\n\n# Five statements, each answered from 1 (strongly disagree) to 5 (strongly agree).\n# One string per quarter, one digit per person, in no particular order: anonymous.\nSURVEY = {\n    \"I can work on one thing without interruption most days\": {\"Q2\": \"221321\", \"Q3\": \"434434\"},\n    \"When I ask for a review, it arrives quickly\": {\"Q2\": \"112212\", \"Q3\": \"454445\"},\n    \"I know what the team is trying to finish this month\": {\"Q2\": \"332423\", \"Q3\": \"444534\"},\n    \"I finished most weeks with energy left\": {\"Q2\": \"333234\", \"Q3\": \"454414\"},\n    \"I would recommend this team to a friend\": {\"Q2\": \"434344\", \"Q3\": \"454544\"},\n}\n",
      "note": "**The survey is the data.** Five statements, the same five every quarter, and six answers to each: Bia and the five developers. The answers are written for the course, like the rest of the Billing team's history. The order of the digits carries no meaning, so no answer can be traced to a person by its position."
    },
    {
      "code": "\nfor statement, quarters in SURVEY.items():\n    print(statement)\n    for quarter, answers in quarters.items():\n        scores = [int(a) for a in answers]\n        bars = \"  \".join(f\"{n}:{'#' * scores.count(n):<6}\" for n in range(1, 6))\n        print(f\"  {quarter}  {bars} median {statistics.median(scores)}\")\n",
      "note": "**Every answer is shown, as a count per score**, with the median beside it. No mean: with six people, one answer moves a mean a long way and a count shows exactly which way."
    }
  ]
}
```

```
ana@laptop:~/delivery$ python3 survey.py
I can work on one thing without interruption most days
  Q2  1:##      2:###     3:#       4:        5:       median 2.0
  Q3  1:        2:        3:##      4:####    5:       median 4.0
When I ask for a review, it arrives quickly
  Q2  1:###     2:###     3:        4:        5:       median 1.5
  Q3  1:        2:        3:        4:####    5:##     median 4.0
I know what the team is trying to finish this month
  Q2  1:        2:##      3:###     4:#       5:       median 3.0
  Q3  1:        2:        3:#       4:####    5:#      median 4.0
I finished most weeks with energy left
  Q2  1:        2:#       3:####    4:#       5:       median 3.0
  Q3  1:#       2:        3:        4:####    5:#      median 4.0
I would recommend this team to a friend
  Q2  1:        2:        3:##      4:####    5:       median 4.0
  Q3  1:        2:        3:        4:####    5:##     median 4.0
```

## Reading it

**The first two statements moved most, and they agree with the files.** Focus went from a median of 2 to 4, and reviews arriving quickly from 1.5 to 4. Lessons 2 to 4 measured the same change from the board: one item each, and reviews done first. When the survey and the system data say the same thing, each makes the other more credible.

**The fourth statement is the one to look at twice.** Its median rose from 3 to 4, which a summary would report as good news. But one person answered **1**: they finished most weeks with no energy left, in a quarter when the others felt better than before. In a team of six, a single answer at the bottom is not a statistic; it is a person, and an average would have hidden them entirely, since the six answers average 3.7. Nothing in the survey says who it is, and nothing should. What it says is that the tech lead has a conversation to make possible, without asking who: lesson 17 looks at one of the commonest reasons, the on-call rota.

## Small teams and anonymity

A team of six is close to the limit at which a survey can stay anonymous. If one person always answers the same way and everybody knows who it is, the distribution gives them away. Common practice in larger organisations is to show results only when at least five people answered, and never to break a small team down further. For a team the size of Billing, it is worth saying out loud, every time, what the results will and will not be used for, and lesson 20 makes that a written agreement.
