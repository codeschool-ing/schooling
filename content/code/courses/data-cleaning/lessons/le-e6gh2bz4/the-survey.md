---
title: The survey, and the customers who did not answer
version: 1
---

**A survey is the purest case of missing data there is: most people do not answer, and nobody
chooses at random whether to.** The day after every delivered online order, Quitanda Verde sends a
one-question survey — how likely are you to recommend us, from 0 to 10 — and reports the Net
Promoter Score: the share of 9s and 10s, the promoters, minus the share of 0s to 6s, the
detractors.

The response rate first, and then whether it depends on how the delivery went:

```schooling-example
{
  "language": "python",
  "file": "survey.py",
  "parts": [
    {
      "code": "import pandas as pd\n\n"
    },
    {
      "code": "survey = pd.read_csv(\"raw/survey.csv\", dtype=str, keep_default_na=False, na_values=[\"\"])\norders = pd.read_csv(\"raw/orders.csv\", dtype=str, keep_default_na=False,\n                     na_values=[\"\"]).drop_duplicates()\n",
      "note": "The survey and the orders, both as text, the orders without their repeats."
    },
    {
      "code": "both = survey.merge(orders[[\"order_id\", \"courier\", \"delivery_minutes\"]], on=\"order_id\")\nboth[\"answered\"] = both[\"nps\"].notna()\n",
      "note": "Each invitation joined to its order, so it carries the courier and the delivery time. An answer is a score that is not blank."
    },
    {
      "code": "print(f\"invitations: {len(both)}, answered: {both['answered'].sum()} \"\n      f\"({both['answered'].mean() * 100:.1f}%)\")\n",
      "note": "The overall response rate."
    },
    {
      "code": "own = both[both[\"courier\"] == \"propria\"].copy()\nown[\"band\"] = pd.cut(pd.to_numeric(own[\"delivery_minutes\"]), [0, 40, 60, 80, 120],\n                     right=False)\nprint((own.groupby(\"band\", observed=True)[\"answered\"].mean() * 100).round(1).to_string())\n",
      "note": "For the own fleet, the response rate by band of delivery time. `right=False` makes each band include its lower edge: 40 belongs to `[40, 60)`."
    }
  ]
}
```

```
ana@lab:~/clean$ python survey.py
invitations: 26494, answered: 9656 (36.4%)
band
[0, 40)      37.2
[40, 60)     38.2
[60, 80)     34.7
[80, 120)    32.4
```

About one invitation in three is answered. **And past 40 minutes, the rate falls as the delivery
gets slower**: 38.2% for deliveries of 40 to 60 minutes, 34.7% from 60 to 80, and 32.4% for those
of 80 minutes or more. Customers whose
delivery went badly are less likely to answer.

That is a visible column predicting the blanks again, which makes the survey look MAR on delivery
time. Part of it is. But think about what drives the decision to answer: not the minutes
themselves, but **how the customer felt** — the very score that is missing. A customer annoyed by a
fast delivery that arrived with bruised mangoes skips the survey too, and no column records the
mangoes. Satisfaction drives both the score and the decision to give it. That is MNAR, with a
visible shadow.

## What it does to the number

Again the lab has what work never does: `truth/nps.csv` holds the score every invited customer
would have given, answered or not.

```python
import pandas as pd


def nps(scores):
    return round(((scores >= 9).mean() - (scores <= 6).mean()) * 100, 1)


survey = pd.read_csv("raw/survey.csv")
truth = pd.read_csv("/var/lib/clean-data/truth/nps.csv")
print("NPS from the answers:      ", nps(survey["nps"].dropna()))
print("NPS of everybody invited:  ", nps(truth["nps"]))
```

```
ana@lab:~/clean$ python nps_truth.py
NPS from the answers:       40.6
NPS of everybody invited:   31.3
```

**The NPS from the answers is 40.6. The NPS of everybody invited is 31.3.** Nine points, from a
response rate and a selection nobody can see in the file. And the bias runs in the flattering
direction, which is the usual one: the people least happy with a service are also the least
inclined to spend a minute telling it so.

## What can be done with only the real data

No technique recovers the missing scores; they were never given. What a careful report does:

- **reports the response rate beside the score**, every time, so a reader can weigh it;
- **compares respondents and non-respondents on what is known about both** — delivery time, channel,
  how often they buy — and says where they differ, as the table above does for delivery time;
- **watches the trend rather than the level**: if the selection stays similar from month to month,
  a falling score still means something, even when the level is flattered;
- and, when the number matters enough, **asks a small random sample of non-respondents directly**,
  by phone, which is the only way to measure the people the survey cannot see.

Lesson 4 comes back to this with the options for the delivery times, where the source did have
the answer and simply threw it away.
