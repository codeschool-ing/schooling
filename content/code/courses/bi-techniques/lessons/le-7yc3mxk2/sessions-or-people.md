---
title: Sessions or people
version: 1
---

The funnel of the last section counted **sessions**. People come back: they look at the menu on
Sunday, return on Monday and order. Counted by session, that is one failure and one success; counted
by person, it is one success.

```schooling-example
{"language": "python", "file": "people.py", "parts": [{"code": "import pandas as pd\n\nsessions = pd.read_csv(\"sessions.csv\")\nbest = sessions.groupby(\"visitor\")[\"step\"].max()", "note": "For each visitor, the furthest step reached in any of their sessions."}, {"code": "print(f\"{len(sessions):,} sessions from {len(best):,} visitors, \"\n      f\"{len(sessions) / len(best):.2f} sessions each\")\nprint(f\"sessions that paid: {(sessions['step'] == 5).mean():.1%}\")\nprint(f\"visitors who paid in any session: {(best == 5).mean():.1%}\")", "note": "The same month counted two ways."}], "output": "55,800 sessions from 26,471 visitors, 2.11 sessions each\nsessions that paid: 14.4%\nvisitors who paid in any session: 27.0%"}
```

**14.4 per cent of sessions paid, and 27.0 per cent of visitors paid in at least one session.** Both
are correct, and they describe different things. A session funnel says how well each visit converts,
which is the right lens for a page or a form: the mobile checkout fails per visit. A person funnel
says how many people the site eventually turns into customers, which is the right lens for marketing
and for the business: some of the sessions that "failed" belonged to people who ordered the next day.

Three rules keep the two apart.

- **Say which one a funnel counts**, in its title. "Conversion 14 per cent" and "conversion 27 per
  cent" from the same month are both true.
- **A person funnel needs a window**: paid within the same session, within seven days, within the
  month. The longer the window, the higher the rate, and the later the number is final, which is
  lesson 12's censoring in another form.
- **A person is only as good as the identifier**, as lesson 9 found for experiments: a visitor on a
  phone and a laptop is two people to the cookie, and a person funnel built on cookies undercounts
  people who switch devices before paying, exactly the ones a broken mobile checkout produces.
