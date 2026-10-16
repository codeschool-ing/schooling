---
title: "MVVM: the screen binds itself"
version: 1
---

**Model-view-viewmodel gives the screen a model of its own, the view-model, made of properties the
view binds to, so that nobody writes code to update the screen.** When a property changes, every
widget bound to it changes with it. The view-model holds the screen's state and logic, whether the
Lend button is enabled and what the status line says, and it holds no reference to the view. John
Gossman described it in 2005 for Microsoft's WPF, whose markup language made binding a one-line
declaration, and it has since become the native shape of Android's `ViewModel`, Vue, Angular and
Knockout.

The belief to drop is that a view-model is a presenter with a different name. A presenter **tells**
the view what to show, method by method. A view-model only **exposes** state, and the bindings
carry it to the screen. The view-model cannot tell a view anything, because it does not know one
exists.

```schooling-example
{"language": "python", "file": "mvvm.py", "parts": [
 {"code": "# mvvm.py\nfrom datetime import date\nfrom desk_model import Desk"},
 {"code": "\n\nclass Observable:\n    def __init__(self, value):\n        self._value = value\n        self._subscribers = []\n\n    def get(self):\n        return self._value\n\n    def set(self, value) -> None:\n        if value != self._value:\n            self._value = value\n            for fn in self._subscribers:\n                fn(value)\n\n    def subscribe(self, fn) -> None:\n        self._subscribers.append(fn)\n        fn(self._value)", "note": "The whole binding machinery, in under twenty lines. An observable holds one value and a list of subscribers, calls each when the value changes, and calls a new subscriber at once so it starts in step. Setting the same value again notifies nobody."},
 {"code": "\n\nclass LendViewModel:\n    def __init__(self, desk: Desk, today: date):\n        self.desk, self.today = desk, today\n        self.code = Observable(\"\")\n        self.member = Observable(\"\")\n        self.can_lend = Observable(False)\n        self.status = Observable(\"\")", "note": "The view-model is the screen's state, made of observables: what is typed in the two boxes, whether lending is possible, and the status line. It holds the model and never the view."},
 {"code": "        self.code.subscribe(lambda _: self._recompute())\n        self.member.subscribe(lambda _: self._recompute())\n        desk.subscribe(self._recompute)", "note": "Whenever either box changes, or the desk changes, the view-model works out its state again. These three lines are the only wiring it does itself."},
 {"code": "\n    def _recompute(self) -> None:\n        code, member = self.code.get(), self.member.get()\n        if not code or not member:\n            self.can_lend.set(False)\n            self.status.set(\"type a code and a member\")\n        elif code not in self.desk.on_shelf:\n            self.can_lend.set(False)\n            self.status.set(f\"{code} is out\")\n        elif self.desk.held_by(member) >= self.desk.limit:\n            self.can_lend.set(False)\n            self.status.set(f\"{member} is at the limit\")\n        else:\n            self.can_lend.set(True)\n            self.status.set(f\"ready to lend {code} to {member}\")", "note": "The screen logic, in one place: every reason the Lend button might be greyed out, each with the sentence the status line should show. It reads the model's rules through `on_shelf`, `held_by` and `limit`, and keeps none of its own."},
 {"code": "\n    def lend(self) -> None:\n        if self.can_lend.get():\n            self.desk.lend(self.code.get(), self.member.get(), self.today)", "note": "A command. The view calls it when the button is pressed; the view-model checks its own state and calls the model."},
 {"code": "\n\nclass TextBox:\n    def __init__(self, name: str):\n        self.name, self.text, self.on_edit = name, \"\", None\n\n    def type(self, text: str) -> None:\n        print(f\"(types {text!r} into {self.name})\")\n        self.text = text\n        if self.on_edit:\n            self.on_edit(text)\n\n\nclass Button:\n    def __init__(self, label: str):\n        self.label, self.enabled = label, False\n\n    def set_enabled(self, enabled: bool) -> None:\n        self.enabled = enabled\n        print(f\"  [{self.label}] {'enabled' if enabled else 'greyed out'}\")\n\n\nclass Label:\n    def set_text(self, text: str) -> None:\n        print(f\"  status: {text}\")", "note": "Three stand-ins for widgets, each printing what a real one would draw. None of them has heard of the desk or of the view-model."},
 {"code": "\n\ndef bind_text(box: TextBox, prop: Observable) -> None:\n    box.on_edit = prop.set", "note": "A binding: when the box is edited, the property is set. Real frameworks write this in markup instead of code."},
 {"code": "\n\nif __name__ == \"__main__\":\n    desk = Desk([\"B1\", \"B2\", \"B3\"], limit=2)\n    vm = LendViewModel(desk, date(2026, 3, 2))\n    code_box, member_box = TextBox(\"code\"), TextBox(\"member\")\n    button, label = Button(\"Lend\"), Label()\n    bind_text(code_box, vm.code)\n    bind_text(member_box, vm.member)\n    vm.can_lend.subscribe(button.set_enabled)\n    vm.status.subscribe(label.set_text)\n\n    code_box.type(\"B1\")\n    member_box.type(\"bia\")\n    print(\"(clicks Lend)\")\n    vm.lend()\n    code_box.type(\"B2\")\n    print(\"(clicks Lend)\")\n    vm.lend()\n    code_box.type(\"B3\")", "note": "The composition: four bindings, then a person typing and clicking. The button is never told to grey itself out by anybody's `if`; its `enabled` follows `can_lend`."}
]}
```

```
ana@laptop:~/patterns/presentation$ python3 mvvm.py
  [Lend] greyed out
  status: type a code and a member
(types 'B1' into code)
(types 'bia' into member)
  [Lend] enabled
  status: ready to lend B1 to bia
(clicks Lend)
  [Lend] greyed out
  status: B1 is out
(types 'B2' into code)
  [Lend] enabled
  status: ready to lend B2 to bia
(clicks Lend)
  [Lend] greyed out
  status: B2 is out
(types 'B3' into code)
  status: bia is at the limit
```

Read the first two lines before anybody types anything: the button starts greyed out and the
status line asks for a code and a member, because `subscribe` calls each new subscriber with the
current value. Typing `B1` printed nothing, since the status was still "type a code and a member" and
an unchanged value notifies nobody. Typing `bia` made both changes at once. After the click the desk
changed, the desk told the view-model, and the button greyed itself out because B1 was no longer
on the shelf. The last line is the limit: Bia holds two loans, the button was already grey and
stayed that way, so only the status moved.

## What the bindings bought

**There is no line anywhere that says `button.set_enabled(False)` after a loan.** In `mvp.py` the
presenter had to remember to call `_refresh` after every change, and a presenter that forgot would
leave a stale screen. Here the button follows `can_lend` whatever changed it: typing, clicking, or
the desk changing because of something on another screen entirely.

**The view-model is tested like any object.** Set `vm.code` and `vm.member`, read `vm.can_lend`:

```python
vm = LendViewModel(Desk(["B1"], limit=1), date(2026, 3, 2))
vm.code.set("B1"); vm.member.set("bia")
assert vm.can_lend.get() is True
```

No fake view is needed, because there is no view interface to fake. That is the boilerplate of the
last section, gone.

## What it costs

**The flow becomes invisible.** In MVP, "why did the button grey out?" is answered by reading the
presenter top to bottom. Here it is answered by tracing subscriptions: the desk notified the
view-model, which recomputed, which set `can_lend`, which ran the button's subscriber. With a few
dozen properties feeding each other, a change in one place can set off updates nobody expected, and
the debugger shows a stack of callbacks rather than a line of logic.

Subscriptions also have a lifetime. `Observable` above keeps every subscriber forever; a screen that
is closed but still subscribed keeps receiving updates, and keeps its memory alive. Real binding
frameworks unsubscribe when a view goes away, and that bookkeeping is part of their size.
Lesson 16 builds observables properly, with unsubscribing and operators; this section needed only
enough to show a binding.

## In your language

| language | where binding comes from | what the view-model is |
|---|---|---|
| TypeScript / JavaScript | Vue's reactivity, Angular's templates, Knockout's `observable` | a component's state object, or a class of signals |
| Java | JavaFX `Property` objects; Android Data Binding or Compose | Android's `ViewModel` with `LiveData` or `StateFlow` |
| Go | rarely needed: Go seldom draws screens | a struct with channels, when it does |
| Python | the `Observable` class above; GUI toolkits offer variables such as Tkinter's `StringVar` | an ordinary class |

React is worth a sentence, because it is the framework people ask about. It renders the screen as a
function of state and re-runs that function when state changes, so the direction of flow is the
same as MVVM's: state in, screen out, no code that updates a widget. What it lacks is the two-way
binding, since an input box reports changes by calling a handler you wrote.
