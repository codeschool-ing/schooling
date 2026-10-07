---
title: What the assistant sees
version: 1
---

An assistant in the editor looks as though it reads your project. **It reads what the editor sends
it**, and the editor decides that in the moment before each request. It sends some of the file you
are in, some of the other files that look related, and the project's instruction file if there is
one, all cut down to fit a budget. Lesson 1 section 10 said the model knows only what is in the request;
this section is about who fills the request in, and how.

Real assistants do not publish their exact rules, and they change them often. So the lab has one
small enough to read, `assist`, written for the course. It follows the same three steps the
real ones describe in their documentation, against labllm, and unlike them it prints what it sent.
**Its replies come from `scripted-1`, so every suggestion in this lesson was written by the
course**, and the ones that are wrong are wrong on purpose.

## A completion request

ana has started a method in `shop/cart.py`: the signature and the docstring that says what it is
for. The cursor is on the empty line after the docstring:

```
ana@dev:~/shop$ sed -n 28,34p shop/cart.py
    def remove(self, sku: str, quantity: int = 1) -> None:
        """Take `quantity` units of `sku` out of the cart.

        A line that reaches zero is removed. Removing more than the cart
        holds, or a sku it does not hold, raises ValueError.
        """

```

She asks for a completion with two other files open in the editor, the way they would be in her
tabs:

```
ana@dev:~/shop$ assist complete shop/cart.py:34 --open shop/coupons.py tests/test_cart.py
context sent (602 of 3000 tokens):
    335  shop/cart.py (cursor at line 34)
     91  shop/coupons.py
    176  tests/test_cart.py
---
        for line in self.lines:
            if line.sku == sku:
                line.quantity -= quantity
                return
        raise ValueError(f"{sku} is not in the cart")

```

The lines above `---` are what `assist` reports about its own request: **602 tokens of context out
of a budget of 3,000**, made of the file she is in and the two open tabs. Below `---` is the
suggestion, which the next sections judge.

## What was in the request

labllm keeps every request it receives, so the request can be read back exactly as the model would
have read it:

```
ana@dev:~/shop$ python lab/sent.py
system: You complete code. The text <CURSOR> marks the cursor. Reply with only the lines to insert there, nothing else.
### shop/cart.py (cursor at line 34)
from dataclasses import dataclass, field
(...)
        holds, or a sku it does not hold, raises ValueError.
        """

<CURSOR>
    def subtotal(self) -> int:
        return sum(line.unit_price * line.quantity for line in self.lines)
(...)
### shop/cart.py (cursor at line 34)
### shop/coupons.py
### tests/test_cart.py
```

Three things to notice, because every completion tool has a version of each:

- **The cursor is a marker in the text.** The file goes in whole, with `<CURSOR>` where ana is
  typing, so the model sees both what comes before the cursor and what comes after it. Filling a
  gap between a known start and a known end is called **fill-in-the-middle**, and it is why a
  completion can close a block correctly: the code below the cursor is in the prompt too.
- **The other files are chosen by the tool, not by you.** Here they are whatever ana had open.
  Real assistants also use recently edited files and files that share names with the one you are
  in, and some search the repository. A file nobody chose can be in the request.
- **A budget decides what is dropped.** 3,000 tokens here. A large file, or many open tabs, means
  something is left out, and the model will not tell you what it did not see.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Where a completion request comes from. The editor holds the file with the cursor, the open tabs and the instruction file. assist leaves out files on the exclusion list and files holding something shaped like a secret, fits the rest into a budget of 3,000 tokens, and sends the result to the model.\"><defs><marker id=\"cx-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"100\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">in the editor</text><rect x=\"20\" y=\"40\" width=\"160\" height=\"38\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"100.0\" y=\"59.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">instruction file</text><rect x=\"20\" y=\"92\" width=\"160\" height=\"38\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"100.0\" y=\"111.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the file, with &lt;CURSOR&gt;</text><rect x=\"20\" y=\"144\" width=\"160\" height=\"38\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"100.0\" y=\"163.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">open tabs</text><text x=\"360\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the assistant&#x27;s rules</text><rect x=\"270\" y=\"40\" width=\"180\" height=\"38\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"59.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">exclusion list</text><rect x=\"270\" y=\"92\" width=\"180\" height=\"38\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"111.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">secret check</text><rect x=\"270\" y=\"144\" width=\"180\" height=\"38\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"163.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">budget: 3,000 tokens</text><path d=\"M182 59 L266 59\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cx-ah)\"></path><path d=\"M182 111 L266 111\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cx-ah)\"></path><path d=\"M182 163 L266 163\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cx-ah)\"></path><text x=\"610\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the request</text><rect x=\"520\" y=\"40\" width=\"180\" height=\"142\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"610.0\" y=\"111.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">what the model sees</text><path d=\"M452 59 L516 59\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cx-ah)\"></path><path d=\"M452 111 L516 111\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cx-ah)\"></path><path d=\"M452 163 L516 163\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cx-ah)\"></path><path d=\"M360 196 L360 222\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cx-ah)\"></path><text x=\"360\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">left out: nothing tells you</text></svg>", "caption": "The model sees the request, and the request is what the tool assembled. Every completion tool has some version of these three rules."}
```

**The working conclusion is the same as lesson 1's, applied to the editor:** when a suggestion
ignores a convention or calls a function that does not exist, the first question is whether the
file that defines it was in the context. Opening it in a tab, or naming it in a chat question, is
often the whole fix.
