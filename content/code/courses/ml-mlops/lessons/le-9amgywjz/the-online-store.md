---
title: The online store, and values too old to serve
version: 1
---

The online store answers one question, **what does this member look like now?**, and it is built
from the offline store rather than computed separately, so that the two can never disagree about
what a feature means. Each member gets their latest row. The decision is what to do when a member's
latest row is old.

```
ana@dev:~/ml$ python featurestore.py online
online store: 3372 members as of 2026-02-28; 466 left out as too old to serve
ana@dev:~/ml$ python featurestore.py get 2
{'member_id': 2, 'as_of': '2026-02-28', 'channel': 'store', 'age_band': '25-34', 'home_shop': 'Savassi', 'tenure_days': 468.0, 'recency_days': 3.0, 'visits_180d': 4, 'spend_180d': 30940, 'basket_avg': 7735.0, 'online_share': 0.25, 'shops_180d': 2}
ana@dev:~/ml$ python featurestore.py get 8
None
```

The offline store knows 3,838 members, everybody who was active on any Sunday since June. **466 of
them have no row from the last seven days**: they stopped being active, and their newest values are
weeks or months old. Served, those would describe a member who no longer exists, as if they had
visited yesterday. So `online` leaves them out, and asking for one, as the last command does for
member 8, returns `None`.

The 3,372 kept are tonight's 3,355 and **17 members whose newest row is last Sunday's**: active on 22
February, no longer active by 28 February, and still inside the seven days. They are served with a
six-day-old row. That is the time to live doing what it says, and it is a choice: a shorter one
would drop them and a longer one would keep more of the 466.

**What a service does with `None` is the platform's decision, made in advance.** Refuse to score,
score with defaults, or fall back to a rule: each is defensible, and each must be written down,
because the alternative is a service that crashes on the first member the store has forgotten.
Lesson 8's service has to choose.
