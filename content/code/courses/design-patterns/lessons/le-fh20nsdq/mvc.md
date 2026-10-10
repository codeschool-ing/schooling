---
title: "MVC: the view watches the model"
version: 1
---

**Model-view-controller divides a program with a screen into the rules, the drawing and the input,
and its defining move is that the view watches the model.** Trygve Reenskaug described it at Xerox
PARC in 1979, for Smalltalk, and the Smalltalk-80 class library shipped it. When the model changes,
it announces the change; every view that subscribed redraws itself. The controller never tells a
view to redraw. A common belief is that the controller fetches data and passes it to the view.
That is the web version, which is the next section, and it lost the observer on the way.

## The model

The model is the rules of the last section, taken out of the loop and given names. It is the one
file every program in this lesson imports.

```schooling-example
{"language": "python", "file": "desk_model.py", "parts": [
 {"code": "# desk_model.py\nfrom dataclasses import dataclass\nfrom datetime import date, timedelta\n\nDAILY_FINE = 50  # cents\n\n\n@dataclass\nclass Loan:\n    code: str\n    member: str\n    due: date", "note": "The loan from lesson 1, cut down to what the desk needs: which item, who has it, when it is due. Fines are still whole cents."},
 {"code": "\n\nclass Desk:\n    def __init__(self, codes: list[str], limit: int = 5):\n        self.on_shelf = list(codes)\n        self.loans: dict[str, Loan] = {}\n        self.limit = limit\n        self._watchers = []", "note": "The desk holds the shelf and the loans. `limit` defaults to the library's five; the programs in this lesson pass two to keep their transcripts short."},
 {"code": "\n    def subscribe(self, watcher) -> None:\n        self._watchers.append(watcher)\n\n    def _changed(self) -> None:\n        for watcher in self._watchers:\n            watcher()", "note": "Anybody may ask to be told when the desk changes. The desk keeps a list of functions and calls each one; it does not know or care what they do. This is the observer of lesson 6."},
 {"code": "\n    def held_by(self, member: str) -> int:\n        return sum(1 for loan in self.loans.values() if loan.member == member)", "note": "A question the rules need and a screen may want too. It is a method of the model so that nobody else has to count loans their own way."},
 {"code": "\n    def lend(self, code: str, member: str, on: date) -> Loan:\n        if code not in self.on_shelf:\n            raise ValueError(f\"{code} is not on the shelf\")\n        if self.held_by(member) >= self.limit:\n            raise ValueError(f\"{member} already has {self.limit} loans\")\n        self.on_shelf.remove(code)\n        loan = self.loans[code] = Loan(code, member, on + timedelta(days=14))\n        self._changed()\n        return loan", "note": "Both rules of lending, and the change itself. A refusal is an exception with a sentence, never a `print`: the model cannot know whether its words will end up on a terminal, a web page or nowhere."},
 {"code": "\n    def give_back(self, code: str, on: date) -> int:\n        if code not in self.loans:\n            raise ValueError(f\"{code} is not out on loan\")\n        loan = self.loans.pop(code)\n        self.on_shelf.append(code)\n        self._changed()\n        return max((on - loan.due).days, 0) * DAILY_FINE", "note": "Returning computes the fine and hands it back as a number. What a fine looks like on a screen is somebody else's decision."}
]}
```

Read it for what is absent. **There is no `print`, no `input` and no `sys.stdin` anywhere in the
model**, and the refusals are exceptions carrying a sentence. Those two facts are what let one model
serve a terminal, a web page and a test with no change at all, which the rest of the lesson does.

## The view and the controller

```schooling-example
{"language": "python", "file": "mvc.py", "parts": [
 {"code": "# mvc.py\nimport sys\nfrom datetime import date\nfrom desk_model import Desk", "note": "The model is imported, not copied. Nothing in `desk_model.py` will change for the rest of the lesson."},
 {"code": "\n\nclass ShelfView:\n    def __init__(self, desk: Desk):\n        self.desk = desk\n        desk.subscribe(self.render)\n\n    def render(self) -> None:\n        shelf = \", \".join(sorted(self.desk.on_shelf)) or \"empty\"\n        print(f\"  [shelf: {shelf} | out: {len(self.desk.loans)}]\")", "note": "The view holds a reference to the model and subscribes to it. From then on the desk calls `render` after every change, and nobody else has to remember to."},
 {"code": "\n    def say(self, text: str) -> None:\n        print(f\"  {text}\")", "note": "The view also prints the controller's short messages, so that every line on the screen goes through one class."},
 {"code": "\n\nclass DeskController:\n    def __init__(self, desk: Desk, view: ShelfView, today: date):\n        self.desk, self.view, self.today = desk, view, today", "note": "The controller knows the model and the view. It owns the one piece of state that is about the session rather than the library: what day the desk thinks it is."},
 {"code": "\n    def handle(self, line: str) -> None:\n        cmd, *args = line.split()\n        try:\n            if cmd == \"lend\":\n                loan = self.desk.lend(args[0], args[1], self.today)\n                self.view.say(f\"{loan.code} due back {loan.due}\")\n            elif cmd == \"return\":\n                fine = self.desk.give_back(args[0], self.today)\n                self.view.say(f\"fine: {fine} cents\")\n            elif cmd == \"day\":\n                self.today = date.fromisoformat(args[0])\n            else:\n                self.view.say(f\"unknown command {cmd!r}\")\n        except ValueError as err:\n            self.view.say(f\"refused: {err}\")", "note": "Input in, model call out. The controller parses the command, calls the model, and turns a refusal into a message. It never draws the shelf: it does not have to, because the view is already watching."},
 {"code": "\n\nif __name__ == \"__main__\":\n    desk = Desk([\"B1\", \"B2\", \"B3\"], limit=2)\n    view = ShelfView(desk)\n    controller = DeskController(desk, view, date(2026, 3, 2))\n    for line in sys.stdin:\n        print(\">\", line.strip())\n        controller.handle(line)", "note": "The wiring: build the model, hand it to the view, hand both to the controller, then feed the controller one line at a time. Each command is echoed after `>` so that the transcript reads like a conversation."}
]}
```

Save `desk_model.py` and `mvc.py` side by side and send the desk six commands, the last two after
moving the clock to 20 March:

```
ana@laptop:~/patterns/presentation$ printf 'lend B1 bia\nlend B2 bia\nlend B3 bia\nday 2026-03-20\nreturn B1\nreturn B1\n' | python3 mvc.py
> lend B1 bia
  [shelf: B2, B3 | out: 1]
  B1 due back 2026-03-16
> lend B2 bia
  [shelf: B3 | out: 2]
  B2 due back 2026-03-16
> lend B3 bia
  refused: bia already has 2 loans
> day 2026-03-20
> return B1
  [shelf: B1, B3 | out: 1]
  fine: 200 cents
> return B1
  refused: B1 is not out on loan
```

Look at the order of the two lines under each loan. The shelf comes **before** the controller's
message. The controller called `desk.lend`; inside that call, the desk ran `_changed`, which ran
the view's `render`; only after `lend` returned did the controller get to say when B1 is due. That
order is the observer at work, and it is the mark of the original MVC.

The refusals show the other half. `lend B3 bia` changed nothing, so the model announced nothing and
no shelf line was drawn; the controller turned the exception into `refused: …`. The fine of 200
cents is four days at 50, from a due date of 16 March, and the model computed it without knowing it
would be printed.

## Who knows whom

The arrows matter more than the names, so here they are for `mvc.py`:

| class | holds a reference to | is called by |
|---|---|---|
| `Desk` (model) | a list of functions, and nothing else | the controller, to change it; the view, to read it |
| `ShelfView` | the model | the model, through `subscribe`; the controller, through `say` |
| `DeskController` | the model and the view | the main loop, with each line of input |

**The model points at nobody.** It holds callables, which could belong to a terminal view, a log
file or a test; `desk_model.py` imports nothing of the program around it. The view reads the model
directly, which is convenient and is also MVC's weak point. Whatever logic decides how the shelf
looks, here the sorting and the word `empty`, lives inside the view, and the view is the hardest
class to test because its output is a screen. MVP, two sections on, exists to fix exactly that.

In the original Smalltalk each widget on the screen had its own view and controller pair, and a
window was a tree of them. Most desktop toolkits since have merged the two into one widget object
that both draws and handles its own clicks, which is why "MVC" in a desktop framework often means
"a model and some widgets". The part that survived everywhere is the model announcing its changes.
