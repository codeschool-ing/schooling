---
title: A week that looks real
version: 1
---

loanbook's seed script is twenty-four lines:

```schooling-example
{"language": "python", "file": "seed.py", "parts": [{"code": "\"\"\"Fill an empty loanbook with a week that looks like a real one.\"\"\"\nfrom contextlib import closing\nfrom datetime import date, timedelta\n\nimport app", "note": "It uses the application's own functions, not raw SQL, so the seeded loans go through the same rules as a teacher's: a seeded loan could not be lent twice either."}, {"code": "ITEMS = [\"Projector 1\", \"Projector 2\", \"Laptop 03\", \"Laptop 07\", \"HDMI adapter A\",\n         \"Document camera\", \"Tripod\", \"Conference speaker\"]", "note": "Names the IT room would actually use, with the numbering a real inventory has."}, {"code": "LOANS = [  # item, borrower, how many days ago it went out\n    (\"Projector 2\", \"Beatriz Nunes\", 2),\n    (\"Laptop 03\", \"Carlos Mendes\", 9),\n    (\"Document camera\", \"Dora Okafor\", 1),\n    (\"Tripod\", \"Eduardo Lins\", 4),\n]", "note": "Invented people, with names of the kind a school's staff list has. Dates are relative to today, so the data never goes stale; nine days ago is past the seven-day loan, so one loan is always overdue, and the screenshot always shows that state."}, {"code": "with closing(app.connect()) as db:\n    if db.execute(\"SELECT count(*) FROM items\").fetchone()[0]:\n        raise SystemExit(\"loanbook already has items; seed only an empty one\")", "note": "It refuses to touch a database that already has items. A seed script that runs on a real database by mistake is how demo data ends up mixed with somebody's real loans."}, {"code": "    with db:\n        db.executemany(\"INSERT INTO items (name) VALUES (?)\", [(n,) for n in ITEMS])\n    ids = {r[\"name\"]: r[\"id\"] for r in db.execute(\"SELECT id, name FROM items\")}\n    for name, borrower, ago in LOANS:\n        app.lend(db, ids[name], borrower, date.today() - timedelta(days=ago))\n    print(f\"seeded {len(ITEMS)} items, {len(LOANS)} of them out\")", "note": "The items go in one transaction; the loans go through `lend`. It ends by saying what it did, in one line."}]}
```

Run on an empty database, it produces a week any IT room would recognise:

```
ana@laptop:~/loanbook$ python3 seed.py
seeded 8 items, 4 of them out
ana@laptop:~/loanbook$ sqlite3 -header -column loanbook.db "SELECT i.name, l.borrower, l.lent_on, l.due_on FROM items i LEFT JOIN loans l ON l.item_id = i.id AND l.returned_on IS NULL ORDER BY i.name"
name                borrower       lent_on     due_on    
------------------  -------------  ----------  ----------
Conference speaker                                       
Document camera     Dora Okafor    2026-09-26  2026-10-03
HDMI adapter A                                           
Laptop 03           Carlos Mendes  2026-09-18  2026-09-25
Laptop 07                                                
Projector 1                                              
Projector 2         Beatriz Nunes  2026-09-25  2026-10-02
Tripod              Eduardo Lins   2026-09-23  2026-09-30
```

Eight items, four out, and **each loan chosen to show something**: Laptop 03 went out nine days ago, so it
is overdue; the other three are due on different days, so the list is not uniform; four items are
available, so the *Lend* form appears too. Every state the page has is on screen at once. Run it a second
time and it refuses, as its fourth part says it should:

```
ana@laptop:~/loanbook$ python3 seed.py
loanbook already has items; seed only an empty one
```

Three properties are worth copying into any seed script. **Relative dates**: a seed with `2026-06-24`
written in it is overdue by months a year later, and the demo changes meaning on its own. **Through the
application, not around it**: calling `lend` means the seed cannot create a state the rules forbid.
**Refusing to run twice**: the one mistake a seed script must never make is mixing invented loans into
real ones.
