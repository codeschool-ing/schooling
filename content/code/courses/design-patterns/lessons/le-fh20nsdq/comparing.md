---
title: The four side by side
version: 1
---

**The three patterns agree on the model and disagree about the view, and the quickest way to tell
them apart is to ask who holds a reference to whom.** Names are unreliable, as Django's "views"
showed in the section on the server; arrows are not. This section puts the four programs of the lesson next to
each other and reads them that way.

Start with what did not change. Every program imported the same model, and the model never
printed a thing:

```
ana@laptop:~/patterns/presentation$ grep -n "^from desk_model" *.py
mvc.py:4:from desk_model import Desk
mvp.py:4:from desk_model import Desk
mvvm.py:3:from desk_model import Desk
test_presenter.py:4:from desk_model import Desk
web.py:5:from desk_model import Desk
ana@laptop:~/patterns/presentation$ grep -c "print" desk_model.py
0
```

Four presentations and one test, on one model, which `grep -c` confirms contains no `print` at
all. **That is the separation the whole lesson is about, and it is the part worth keeping even when
you use none of the patterns by name.** The tangled loop of the first section could not have been
shared by a terminal, a web page, a test and a set of widgets; `desk_model.py` was.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l07-triads\" aria-label=\"Three panels, one per pattern, each showing which part holds a reference to which. MVC: the controller calls the model, the model notifies the view, and the view reads the model; the model points at nobody. MVP: the view forwards events to the presenter, the presenter calls the model and tells the view what to show; the view never sees the model. MVVM: the view binds to the view-model, the view-model calls the model and is notified by it; the view-model never sees the view.\"><defs><marker id=\"l07-triads-dp-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"115.0\" y=\"20.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">MVC</text><rect x=\"63.0\" y=\"55.0\" width=\"104.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"115.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Model</text><rect x=\"6.0\" y=\"185.0\" width=\"104.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"58.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">View</text><rect x=\"120.0\" y=\"185.0\" width=\"104.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"172.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Controller</text><path d=\"M172.0 185.0 L140.0 89.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l07-triads-dp-ah-paper-dim)\"></path><text x=\"160.0\" y=\"132.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">calls</text><path d=\"M88.0 89.0 L40.0 185.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"5 3\" marker-end=\"url(#l07-triads-dp-ah-paper-dim)\"></path><text x=\"8.0\" y=\"128.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">notifies</text><path d=\"M80.0 185.0 L112.0 89.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l07-triads-dp-ah-paper-dim)\"></path><text x=\"102.0\" y=\"152.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">reads</text><text x=\"115.0\" y=\"268.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--amber)\">the model points at nobody</text><path d=\"M240.0 30.0 L240.0 285.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"360.0\" y=\"20.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">MVP</text><rect x=\"308.0\" y=\"45.0\" width=\"104.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Model</text><rect x=\"308.0\" y=\"115.0\" width=\"104.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Presenter</text><rect x=\"308.0\" y=\"185.0\" width=\"104.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">View</text><path d=\"M360.0 115.0 L360.0 77.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l07-triads-dp-ah-paper-dim)\"></path><text x=\"367.0\" y=\"96.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">calls</text><path d=\"M345.0 185.0 L345.0 147.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l07-triads-dp-ah-paper-dim)\"></path><text x=\"285.0\" y=\"166.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">events</text><path d=\"M375.0 147.0 L375.0 185.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l07-triads-dp-ah-paper-dim)\"></path><text x=\"383.0\" y=\"166.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">show_…</text><text x=\"360.0\" y=\"268.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--amber)\">the view never sees the model</text><path d=\"M485.0 30.0 L485.0 285.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"605.0\" y=\"20.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">MVVM</text><rect x=\"553.0\" y=\"45.0\" width=\"104.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"605.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Model</text><rect x=\"553.0\" y=\"115.0\" width=\"104.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"605.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">ViewModel</text><rect x=\"553.0\" y=\"185.0\" width=\"104.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"605.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">View</text><path d=\"M590.0 115.0 L590.0 77.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l07-triads-dp-ah-paper-dim)\"></path><text x=\"536.0\" y=\"96.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">calls</text><path d=\"M620.0 77.0 L620.0 115.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"5 3\" marker-end=\"url(#l07-triads-dp-ah-paper-dim)\"></path><text x=\"628.0\" y=\"96.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">notifies</text><path d=\"M605.0 185.0 L605.0 147.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"5 3\" marker-end=\"url(#l07-triads-dp-ah-paper-dim)\"></path><text x=\"612.0\" y=\"166.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">binds</text><text x=\"605.0\" y=\"268.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--amber)\">the view-model never sees the view</text></svg>", "caption": "Who holds a reference to whom. In all three the model points at nobody; what moves is the line between the view and the rest."}
```

## The table

| | MVC (desktop) | MVC (web) | MVP | MVVM |
|---|---|---|---|---|
| input arrives at | the controller | the controller, through a route | the view, which forwards it to the presenter | the view, through bindings and commands |
| does the view see the model? | yes, it reads it | no, it receives values | no | no, it sees the view-model |
| who updates the screen | the view, when the model notifies it | the controller, by rendering a view per request | the presenter, by calling the view | the bindings, when a property changes |
| screen logic lives in | the view | the controller and the template | the presenter | the view-model |
| what a test can reach without a screen | the model | the controller and the template, as functions | the presenter, through a fake view | the view-model, directly |
| in `~/patterns/presentation` | `mvc.py` | `web.py` | `mvp.py` | `mvvm.py` |

The row that decides most choices is the fourth. **Screen logic is whatever decides what the
person sees without being a rule of the library**: that `B1` is greyed out, that 150 cents reads
`R$ 1,50`, that a refusal is an alarm. It exists in every program with a screen. The patterns
differ in where they put it, and the place they put it is exactly what a test can and cannot reach.

## What each one costs, measured

The four presentation files are not the same size, and the differences are honest:

```
ana@laptop:~/patterns/presentation$ wc -l mvc.py web.py mvp.py mvvm.py
  47 mvc.py
  67 web.py
  65 mvp.py
 102 mvvm.py
 281 total
```

`mvvm.py` is the longest because it carries its own binding machinery, `Observable` and three
stand-in widgets; in WPF, Vue or Android those come with the framework and the view-model alone is
about the size of the presenter. `mvp.py` pays for its view interface, two methods here and many more
on a real form. `web.py` spends its extra lines on HTTP: decoding the form and choosing a status.
None of this is the model's cost, which was paid once.

## The two questions that tell them apart

When you meet an unfamiliar codebase, two questions place it faster than the folder names do.

**Does the view hold a reference to the model?** If it does, and redraws when the model announces
a change, you are looking at the original MVC. If it receives values and renders them once, it is
the web's MVC.

**If not, does something call the view, or does the view subscribe?** A class that calls
`view.show_…` is a presenter. A class that exposes properties and has never heard of the view is a
view-model.

Lesson 19 comes back to recognising patterns by their shape in code you did not write; this is one
of the cases where the shape is easy to see once you know which arrow to look for.
