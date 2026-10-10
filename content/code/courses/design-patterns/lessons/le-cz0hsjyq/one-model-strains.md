---
title: One model, pulled two ways
version: 1
---

**A single model serving both the rules and the screens ends up shaped badly for each.** The rules
want a small structure holding exactly what they check: who holds which copy, who is waiting. The
screens want answers already joined and counted: a title with its author and the number of copies
on the shelf. Put both in one class and every new screen adds a query that walks structures built
for the rules, and every new rule has to pick its way round fields that are only there for display.

The wrong idea to drop first is that this strain is about performance and only matters at scale.
The cost shows up in the design first, at three titles, and the speed problem arrives later.

Make `~/patterns/cqrs` and work there for the whole lesson:

```sh
mkdir -p ~/patterns/cqrs
cd ~/patterns/cqrs
```

## A library with copies and a queue

Lesson 7's desk lent items by code. A real library holds several copies of a title, and a member
can reserve a title that is out, which puts them in a queue for the next copy that comes back. Here
is all of that in one class, the way it usually starts:

```schooling-example
{"language": "python", "file": "strained.py", "parts": [
 {"code": "# strained.py\nfrom datetime import date, timedelta\n\n\nclass Library:\n    LIMIT = 5\n\n    def __init__(self):\n        self.titles = {}       # title_id -> (title, author)\n        self.copies = {}       # copy_id -> title_id\n        self.holder = {}       # copy_id -> (member, due)\n        self.waiting = {}      # title_id -> [member, ...]", "note": "One class for the whole library. A title has many copies, a copy is either on the shelf or held by a member until a due date, and a title can have a queue of members waiting for it."},
 {"code": "\n    # ---- commands: they change the library and enforce the rules\n    def lend(self, copy_id: str, member: str, on: date) -> None:\n        title_id = self.copies[copy_id]\n        queue = self.waiting.get(title_id, [])\n        if copy_id in self.holder:\n            raise ValueError(f\"{copy_id} is already out\")\n        if queue and queue[0] != member:\n            raise ValueError(f\"reserved for {queue[0]}\")\n        if sum(1 for m, _ in self.holder.values() if m == member) >= self.LIMIT:\n            raise ValueError(f\"{member} is at the limit\")\n        if queue:\n            queue.pop(0)\n        self.holder[copy_id] = (member, on + timedelta(days=14))\n\n    def give_back(self, copy_id: str) -> None:\n        del self.holder[copy_id]\n\n    def reserve(self, title_id: str, member: str) -> None:\n        self.waiting.setdefault(title_id, []).append(member)", "note": "The three commands, with the rules from lesson 7 plus one: a reserved title goes to the first member in its queue. Each method needs `holder` and `waiting`, and none of them reads a title's name or its author."},
 {"code": "\n    # ---- queries: added one screen at a time\n    def availability(self) -> list[str]:\n        rows, visited = [], 0\n        for title_id, (title, author) in sorted(self.titles.items()):\n            on_shelf = 0\n            for copy_id, of_title in self.copies.items():\n                visited += 1\n                if of_title == title_id and copy_id not in self.holder:\n                    on_shelf += 1\n            queue = len(self.waiting.get(title_id, []))\n            rows.append(f\"{title:<20} {author:<20} on shelf {on_shelf}  waiting {queue}\")\n        rows.append(f\"(visited {visited} copy records for {len(self.titles)} titles)\")\n        return rows", "note": "The screen the desk looks at most. For every title it walks every copy, counting the ones that are on the shelf, and it counts how many records it visited so that the cost is on the screen too."},
 {"code": "\n    def loans_of(self, member: str) -> list[str]:\n        return [f\"{self.titles[self.copies[c]][0]}, due {due}\"\n                for c, (m, due) in sorted(self.holder.items()) if m == member]", "note": "A second screen, a member's loans with titles and due dates. It joins three dictionaries to build one line."},
 {"code": "\n\nif __name__ == \"__main__\":\n    lib = Library()\n    lib.titles = {\"T1\": (\"Dom Casmurro\", \"Machado de Assis\"),\n                  \"T2\": (\"Vidas Secas\", \"Graciliano Ramos\"),\n                  \"T3\": (\"A Hora da Estrela\", \"Clarice Lispector\")}\n    lib.copies = {\"C1\": \"T1\", \"C2\": \"T1\", \"C3\": \"T2\", \"C4\": \"T3\"}\n    lib.lend(\"C1\", \"bia\", date(2026, 3, 2))\n    lib.lend(\"C3\", \"caio\", date(2026, 3, 2))\n    lib.reserve(\"T2\", \"bia\")\n    for row in lib.availability():\n        print(row)\n    print(lib.loans_of(\"bia\"))", "note": "Two loans and a reservation, then both screens."}
]}
```

```
ana@laptop:~/patterns/cqrs$ python3 strained.py
Dom Casmurro         Machado de Assis     on shelf 1  waiting 0
Vidas Secas          Graciliano Ramos     on shelf 0  waiting 1
A Hora da Estrela    Clarice Lispector    on shelf 1  waiting 0
(visited 12 copy records for 3 titles)
['Dom Casmurro, due 2026-03-16']
```

The screen is right: one *Dom Casmurro* is on the shelf, the only *Vidas Secas* is out with Caio and
Bia is waiting for it. And to say so, the class visited twelve copy records for three titles.

## Where the strain shows

**The two halves of the class read different data.** `lend`, `give_back` and `reserve` read
`copies`, `holder` and `waiting`. They never touch `titles`, the names and authors. The queries
read everything, and do most of their work joining. Two sets of methods share a class because they
share a subject, not because they share a need.

**Every query pays for a structure built for writing.** `holder` is keyed by copy because that is
what a loan changes. The availability screen wants a count per title, so it walks every copy for
every title: 3 titles times 4 copies is the 12 the program printed. A branch library with 2,000
titles and 5,000 copies would visit ten million records to draw one page. An index would help, and
it would be an index added to the rules' structure for the screen's sake.

**Every new screen widens the model.** The desk asks for "copies due back this week"; the class
gains a method that sorts `holder` by date. The website asks for "most borrowed this year"; the
class gains a counter that `lend` must now update, and the rule method starts carrying a field no
rule reads. Each addition is small. After a year, the class that guards the loan limit is mostly
code for screens, and a change to one of them needs a reader to check that no rule moved.

In a database the same strain appears as one normalised schema serving both: writes want narrow
tables and few indexes so that each change touches little, and screens want wide rows and many
indexes so that each page reads little. One schema is a compromise between them, and it is tuned
for whichever side complained last.

## Two jobs, two models

The rest of the lesson pulls the class apart along the line already visible in it, the comment
that says `# ---- queries`. That line has a name and a history. The next section starts with the
rule behind it, at the scale of one method, and the section after takes it up to the scale of
whole models, where it is called CQRS.
