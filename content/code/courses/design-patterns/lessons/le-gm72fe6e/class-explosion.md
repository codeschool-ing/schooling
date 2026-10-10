---
title: The class explosion
version: 1
---

**When more than one thing varies, inheritance needs a class for every combination, and
combinations multiply.** Lesson 1 showed it with two axes and six classes. This section counts what
happens as a design keeps growing, because the growth is the argument: nobody designs a hierarchy of
thirty-six classes, they arrive at one an axis at a time.

The common belief is that a class explosion is what bad designers produce, and that a careful one
avoids it by choosing the hierarchy well. The trouble is that a hierarchy can only be chosen along
**one** axis. Whatever varies second has to be pushed down into every branch of the first, and
whatever varies third into every branch of that.

## Counting it

The library's loans differ by the item (a book or a film), the member (an adult or a student), the
reminder channel (e-mail, SMS or a printed slip) and the fine rule (per day, per day after some
grace days, or an amnesty). Here is the arithmetic, done by the machine so that nobody has to trust
it:

```schooling-example
{"language": "python", "file": "explosion.py", "parts": [
 {"code": "# explosion.py\nfrom itertools import product\n\naxes = [\n    (\"item\", [\"Book\", \"Film\"]),\n    (\"member\", [\"Adult\", \"Student\"]),\n    (\"channel\", [\"Email\", \"Sms\", \"Slip\"]),\n    (\"fine\", [\"PerDay\", \"Grace\", \"Amnesty\"]),\n]", "note": "Four things that vary, each with its options. These are the axes the next sections keep coming back to."},
 {"code": "\nprint(f\"{'what varies':<32}{'subclasses':>10}{'parts':>7}\")\nfor n in range(1, len(axes) + 1):\n    used = axes[:n]\n    names = [\"\".join(combo) for combo in product(*(options for _, options in used))]\n    parts = sum(len(options) for _, options in used)", "note": "Add the axes one at a time, as a codebase does. `product` gives one class name per combination; the composed design needs one small class per option, so its count is a sum."},
 {"code": "    label = \" x \".join(axis for axis, _ in used)\n    print(f\"{label:<32}{len(names):>10}{parts:>7}\")", "note": "One line per stage of growth."},
 {"code": "\nsms = [name for name in names if \"Sms\" in name]\nprint(len(sms), \"classes contain Sms, from\", sms[0], \"to\", sms[-1])", "note": "And one question a maintainer asks: if the SMS gateway changes, how many classes are involved?"}
]}
```

```
ana@laptop:~/patterns/composition$ python3 explosion.py
what varies                     subclasses  parts
item                                     2      2
item x member                            4      4
item x member x channel                 12      7
item x member x channel x fine          36     10
12 classes contain Sms, from BookAdultSmsPerDay to FilmStudentSmsAmnesty
```

With two axes of two options the two designs cost the same, which is why the explosion is invisible
early on. The third axis is where they part: twelve classes against seven parts. At the fourth,
**thirty-six classes against ten parts**, and a change to how SMS works touches twelve classes on
the left and one on the right.

## The cost is not only the count

A class per combination is also code per combination. `BookStudentSmsGrace` and
`FilmStudentSmsGrace` both need the grace-days rule. Either it is copied into each, or it lives in
a shared parent, and then the hierarchy has a second parent per class and the tree has become a
lattice. Python allows that, and the section on mixins shows what it costs; Java and Go do not allow
it at all.

Adding an option is uneven too. A fourth channel, a WhatsApp message say, costs twelve new classes
in the inheritance design, one for every pairing of 2 items, 2 kinds of member and 3 fine rules. In
the composed design it costs one class that knows how to send the message.

## Which axis gets to be the tree

There is a quieter cost. A hierarchy says one axis is what the object *is*, and everything else is
detail. `Book` and `Film` at the top makes sense for a catalogue. The fines office would put the
fine rule at the top; the notifications team would put the channel there. Each team is right about
its own work, and the class tree can only agree with one of them.

**Composition does not have to choose.** A loan *has* an item, *has* a fine rule, and its member
*has* a channel. Each axis is a field holding an object, and each can be replaced without asking the
others. That is what the next two sections build: first delegation, the mechanism, then swapping a
behaviour while the program runs, which no class tree can do.

None of this says inheritance is never right. A single axis that never grows, where the children
really are kinds of the parent, is a tree and should be drawn as one. Exception classes are the
standard example, and the section on when inheritance fits starts there.
