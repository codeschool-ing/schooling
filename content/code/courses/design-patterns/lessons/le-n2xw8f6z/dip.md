---
title: "Dependency inversion: details depend on policy"
version: 1
---

**The dependency inversion principle says that the code holding a program's rules should not depend
on the code that talks to the outside world; both should depend on an abstraction, and the
abstraction belongs to the rules.** In Martin's words, high-level modules should not depend on
low-level modules, and abstractions should not depend on details. The *inversion* is of the arrow
in the source code: it ends up pointing from the detail towards the policy.

Two misreadings are common. The first is that the principle is the same thing as dependency
injection, passing an object in instead of building it. Injection is a technique, and lesson 5 is
about it; you can inject a concrete mail class and invert nothing. The second is that adding an
interface is enough. An interface that lives beside the mail code and mirrors its methods still
leaves the rules depending on the mail package. **What decides it is who owns the abstraction, and
which way the `import` lines point.**

## Policy and detail

In the library, the *policy* is the rule about overdue loans: fourteen days, 50 cents a day, a
notice to anybody late. The *details* are how the notice travels: an e-mail server, an SMS gateway,
a printer at the desk. The policy is what the library is; the details change whenever a supplier or
a contract does.

Written the obvious way, the policy calls the detail:

```python
from smtp_mailer import SmtpMailer      # the rules import the mail code


class OverdueNotices:
    def __init__(self):
        self.mailer = SmtpMailer("smtp.example.org")

    def send(self, loans, today):
        ...
        self.mailer.send_mail(address, subject, body)
```

The arrow runs from the rules to the mail code. To run the rules you need the mail code; to test
them you need a mail server or a mocking library that pretends to be one; to move from e-mail to SMS
you open the rules and edit them. The most important code in the program depends on the code most
likely to change.

## Turning the arrow round

Inversion moves one declaration. The rules say what they need, in their own words and in their own
module: something that can notify a member. The mail code, wherever it lives, provides it.

| | before | after |
|---|---|---|
| who declares what is needed | nobody: the rules use whatever the mail class offers | the rules, as a `Notifier` protocol in their own module |
| which module imports which | the rules import the mail code | the mail code imports the rules' protocol, or imports nothing and fits its shape |
| to test the rules | a mail server, or a mock of one | any object with a `notify` method |
| to switch to SMS | edit the rules | write an SMS class and change the wiring |

The words matter. The protocol is called `Notifier` and its method `notify(member, text)`, because
that is what the rules want to do. It is not called `Mailer` with `send_mail(address, subject,
body)`, which is what one detail happens to offer. An abstraction named after the detail is the
detail with an `I` in front of it, and switching to SMS would still mean changing it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l04-inversion\" aria-label=\"Two diagrams of the fine notices. On the left, before: OverdueNotices imports SmtpMailer, so the arrow runs down from the rules to the mail code, and the policy depends on the detail. On the right, after: the module notices.py holds both OverdueNotices and the Notifier protocol it uses, drawn with a diamond. Below it, in adapters.py, EmailNotifier and SmsNotifier each point up to Notifier with a hollow arrowhead. The arrows now run from the details up to the policy.\"><defs><marker id=\"l04-inversion-dp-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><text x=\"175.0\" y=\"18.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">before: the rules import the detail</text><rect x=\"90.0\" y=\"60.0\" width=\"170.0\" height=\"45.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"175.0\" y=\"71.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">OverdueNotices</text><path d=\"M90.0 82.5 L260.0 82.5\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"98.0\" y=\"93.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">send()</text><rect x=\"90.0\" y=\"200.0\" width=\"170.0\" height=\"45.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"175.0\" y=\"211.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">SmtpMailer</text><path d=\"M90.0 222.5 L260.0 222.5\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"98.0\" y=\"233.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">send_mail()</text><path d=\"M175.0 105.0 L175.0 196.0\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#l04-inversion-dp-ah-amber)\"></path><text x=\"185.0\" y=\"150.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">import</text><text x=\"175.0\" y=\"275.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">the policy depends on the detail</text><path d=\"M355.0 20.0 L355.0 290.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"540.0\" y=\"18.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">after: the detail imports the rules' port</text><rect x=\"380.0\" y=\"36.0\" width=\"320.0\" height=\"116.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"390.0\" y=\"50.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">notices.py</text><rect x=\"392.0\" y=\"70.0\" width=\"140.0\" height=\"45.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"462.0\" y=\"81.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">OverdueNotices</text><path d=\"M392.0 92.5 L532.0 92.5\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"400.0\" y=\"103.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">send()</text><rect x=\"560.0\" y=\"62.0\" width=\"130.0\" height=\"59.5\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"625.0\" y=\"73.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">«protocol»</text><text x=\"625.0\" y=\"87.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Notifier</text><path d=\"M560.0 99.0 L690.0 99.0\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"568.0\" y=\"110.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">notify()</text><path d=\"M532.0 92.0 L560.0 92.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M532.0 92.0 L541.0 97.5 L550.0 92.0 L541.0 86.5 Z\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"var(--paper-dim)\"></path><path d=\"M380.0 196.0 L700.0 196.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"390.0\" y=\"210.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">adapters.py</text><rect x=\"392.0\" y=\"226.0\" width=\"140.0\" height=\"22.5\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"462.0\" y=\"237.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">EmailNotifier</text><rect x=\"560.0\" y=\"226.0\" width=\"130.0\" height=\"22.5\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"625.0\" y=\"237.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">SmsNotifier</text><path d=\"M462.0 226.0 L462.0 176.0 L625.0 176.0 L625.0 121.5\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M625.0 121.5 L632.0 133.5 L618.0 133.5 Z\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"var(--panel)\"></path><path d=\"M625.0 226.0 L625.0 121.5\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M625.0 121.5 L632.0 133.5 L618.0 133.5 Z\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"var(--panel)\"></path><text x=\"540.0\" y=\"288.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">the detail depends on the policy</text></svg>", "caption": "The same rules before and after inversion. The protocol moved into the rules' module, and the import arrows turned round."}
```

## Why the rules deserve to be the stable end

Code depended on by many is expensive to change, and code that depends on nothing is cheap to test.
The principle arranges a program so that the code with those two properties is the code that should
have them: the rules, which change only when the library changes its mind. Mail servers, gateways,
databases and frameworks are replaced every few years. The next section builds the inverted version
and shows the `import` lines that prove the direction.
