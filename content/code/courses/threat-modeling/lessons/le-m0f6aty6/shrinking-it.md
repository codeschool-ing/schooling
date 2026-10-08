---
title: Shrinking it
version: 1
---

There are only three ways to make an attack surface smaller, and they are worth trying in order,
because each is cheaper and more reliable than the one after it.

| | what it means | at the portal |
|---|---|---|
| **remove** | the entry point stops existing | does the profile page need a free-text "notes to reception" field that staff never read? |
| **restrict** | fewer people can reach it, or only with a credential | the console only on the clinic network; the webhook only with the gateway's signature |
| **reduce what it reaches** | it still exists, and can do less | the worker with an account that reads bookings and nothing else |

**Removing** is the strongest: a field that does not exist cannot be abused, and needs no test,
no patch and no review. It is also the one teams forget to consider, because a feature has an owner
and its absence does not.

**Restricting** changes who is on the far side of the boundary. The console on the clinic network
means a stranger has to be inside a clinic, or inside its network, before the sign-in page even
answers. The webhook with a verified signature means only the holder of the gateway's key can
send it.

**Reducing what it reaches** is what is left when an entry point has to stay open. The patient
sign-in form has to answer anyone, by definition. What it can do afterwards can still be made
smaller: a patient session that cannot reach another patient's exam (T07) is a smaller surface
behind the same door.

### Measuring the change

Counting entry points is the first measure, and it barely moves. What moves is **the number of
entries a stranger can use without a credential**:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l06-shrinking\" aria-label=\"Entry points by who can use them without a credential, in three states. As drawn in lesson 2: four entry points, two open to anyone, the sign-in form and the webhook, and two that need a credential. As it is, with the console answering the internet: five, three open to anyone. After two changes, the webhook signature and the console on the clinic network only: four, one open to anyone, the patient sign-in form.\"><text x=\"200.0\" y=\"46.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">as drawn in lesson 2</text><rect x=\"212.0\" y=\"30.0\" width=\"110.0\" height=\"32.0\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"322.0\" y=\"30.0\" width=\"110.0\" height=\"32.0\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><path d=\"M267.0 30.0 L267.0 62.0\" stroke=\"var(--ink)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M322.0 30.0 L322.0 62.0\" stroke=\"var(--ink)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M377.0 30.0 L377.0 62.0\" stroke=\"var(--ink)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"442.0\" y=\"46.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">4 entries, 2 open to anyone</text><text x=\"200.0\" y=\"102.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">as it is</text><rect x=\"212.0\" y=\"86.0\" width=\"165.0\" height=\"32.0\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"377.0\" y=\"86.0\" width=\"110.0\" height=\"32.0\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><path d=\"M267.0 86.0 L267.0 118.0\" stroke=\"var(--ink)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M322.0 86.0 L322.0 118.0\" stroke=\"var(--ink)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M377.0 86.0 L377.0 118.0\" stroke=\"var(--ink)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M432.0 86.0 L432.0 118.0\" stroke=\"var(--ink)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"497.0\" y=\"102.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">5 entries, 3 open to anyone</text><text x=\"200.0\" y=\"158.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">after two changes</text><rect x=\"212.0\" y=\"142.0\" width=\"55.0\" height=\"32.0\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"267.0\" y=\"142.0\" width=\"165.0\" height=\"32.0\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><path d=\"M267.0 142.0 L267.0 174.0\" stroke=\"var(--ink)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M322.0 142.0 L322.0 174.0\" stroke=\"var(--ink)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M377.0 142.0 L377.0 174.0\" stroke=\"var(--ink)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"442.0\" y=\"158.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">4 entries, 1 open to anyone</text><rect x=\"212.0\" y=\"214.0\" width=\"14.0\" height=\"10.0\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"232.0\" y=\"219.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">anyone can send it</text><rect x=\"420.0\" y=\"214.0\" width=\"14.0\" height=\"10.0\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"440.0\" y=\"219.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">needs a credential</text></svg>", "caption": "Counting entry points is a start. Counting the ones a stranger can use is the number that moves when the surface really shrinks."}
```

As drawn in lesson 2, the portal looked as though it had two open doors: the sign-in form and the
webhook. Drawn as it is, it has three. After two changes, the webhook signature and the console
on the clinic network, it has one, and that one cannot be closed because patients need it. The
total went from five to four; the open doors went from three to one. That second number is the one
to report.

### What it does to the threat list

Restricting the console closes T12 as written: the sign-in page no longer answers the internet. It
does not close T03, the phished receptionist, which now needs the attacker on a clinic network
too; that makes T03 less likely, and the risk lessons will put a number on how much less. The
signature check closes T01. And neither change removes a line from `threats.csv`. A threat that has
been dealt with stays on the list with its decision next to it, which is lesson 12's subject: a
model that deletes mitigated threats forgets why the mitigation is there.
