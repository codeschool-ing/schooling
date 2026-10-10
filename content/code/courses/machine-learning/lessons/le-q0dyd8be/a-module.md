---
title: One file every lesson imports
version: 1
---

From here on, nearly every program needs the same four things: the data loaded the same way, the
same list of columns a model may read, the same split into months to learn from and months to test
on, and lesson 1's arithmetic of credits. Writing them into every program would be twenty-one
chances to write one of them differently, and a difference there changes a score without anybody
noticing why.

So they go in one file, `feira.py`, in `~/ml`, and every program from this lesson on starts with
`from feira import …`. **This is the whole file.** Save it once; no later lesson changes it.

```schooling-example
{
  "language": "python",
  "file": "feira.py",
  "parts": [
    {
      "code": "# feira.py\n\"\"\"What every program in this course needs to know about Feira em Casa.\"\"\"\nimport pandas as pd\n",
      "note": "The file names itself on its first line, like every program in this course."
    },
    {
      "code": "CREDIT = 40          # reais, paid for every credit sent\nKEPT = 480           # reais, what a subscriber who stays is worth\nSAVED = 0.30         # the share of leavers a credit keeps\n",
      "note": "**The business's three numbers**, from lesson 1. They live here and nowhere else, so changing the price of the credit changes every lesson's arithmetic at once."
    },
    {
      "code": "NUMERIC = [\"age\", \"app_user\", \"tenure_months\", \"price_month\", \"orders_90d\", \"skips_90d\",\n           \"late_90d\", \"complaints_90d\", \"support_calls_90d\", \"rating_90d\", \"days_since_login\"]\nCATEGORICAL = [\"city\", \"payment\", \"plan\", \"box\", \"channel\"]\n",
      "note": "The columns a model may read. Two columns of `churn.csv` are missing from both lists on purpose, and so are the id and the date; lesson 4 says why each one."
    },
    {
      "code": "\ndef load_churn(path=\"data/churn.csv\"):\n    churn = pd.read_csv(path, parse_dates=[\"snapshot\"])\n    for col in CATEGORICAL:\n        churn[col] = churn[col].astype(\"category\")\n    return churn\n",
      "note": "Reads the file with the dates as dates and the text columns as pandas categories, which some models in this course can use without any further work."
    },
    {
      "code": "\ndef by_time(churn, first_test=\"2025-07-01\"):\n    \"\"\"The months before first_test to learn from, and the months from it on to test.\"\"\"\n    test = churn[\"snapshot\"] >= first_test\n    return churn[~test], churn[test]\n",
      "note": "**The split.** Everything before July 2025 to learn from, July to December to test on. Lesson 3 is the argument for cutting by date rather than at random; until then, take it as given."
    },
    {
      "code": "\ndef net_value(churned, send):\n    \"\"\"Reais gained by sending the credit where send is true, against sending nobody.\"\"\"\n    churned = pd.Series(churned).to_numpy() == 1\n    send = pd.Series(send).to_numpy().astype(bool)\n    return SAVED * KEPT * (churned & send).sum() - CREDIT * send.sum()",
      "note": "**The score that matters**: lesson 1's table as a function. A true positive earns 0.3 × 480, every credit costs 40, and sending nobody is zero."
    }
  ]
}
```

Two things in it deserve a second look now, and each gets a lesson of its own later.

**`by_time` tests on the last six months.** The 18 months of snapshots are cut on 1 July 2025: the
twelve before it are what any method in this course may learn from, and the six after it are what
it is judged on. A model, a rule and a constant all get the same cut, which is what makes their
scores comparable. Lesson 3 is about why the cut is a date.

**`net_value` is the score.** Accuracy, precision and the rest arrive in lesson 10, and they are
useful for understanding a model. But the question Feira em Casa asked is in reais, and this is the
function that answers it. Every comparison in this lesson is made with it.
