---
title: What a conflict is, and why nothing crashes
version: 1
---

**A conflict is two writes to the same record, each made without seeing the other.** The word
suggests an error, a red banner, a sync that stops. Nothing of the kind happens. Both writes are
valid, both reach the server, and the server, which sees them one after the other, has to decide
what the record says now. Whatever rule it uses, it makes that decision quietly.

Here is the case this lesson follows. On Wednesday 21 October, Ana has a guitar session in the
planner, `s3`: 20 minutes, not done. At 10:05, on the train with no signal, she opens the planner
on her phone and changes it to 30 minutes. At 10:20, at home, where the Wi-Fi has been down since
the morning, she ticks the same session done on her tablet. The tablet reconnects at 10:40 and
sends its copy. The phone gets a signal at 11:00 and sends its own.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"l13-timeline\" aria-label=\"A timeline of one Wednesday morning in three lanes: phone, server, tablet. At 10:05 the phone, offline on a train, changes session s3 to 30 minutes. At 10:20 the tablet, offline at home, ticks s3 done. At 10:40 the tablet reconnects and sends its copy to the server. At 11:00 the phone reconnects and sends its copy. Neither device saw the other's edit before sending its own.\"><defs><marker id=\"l13-timeline-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"20\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">phone</text><text x=\"20\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">server</text><text x=\"20\" y=\"250\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">tablet</text><path d=\"M110 160 L700 160\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M110 70 L600.0 70\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\"></path><path d=\"M600.0 70 L700 70\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M110 250 L450.0 250\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\"></path><path d=\"M450.0 250 L700 250\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"120\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">offline: on the train</text><text x=\"120\" y=\"268\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">offline: Wi-Fi down</text><text x=\"187.5\" y=\"286\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10:05</text><text x=\"300.0\" y=\"286\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10:20</text><text x=\"450.0\" y=\"286\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10:40</text><text x=\"600.0\" y=\"286\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">11:00</text><rect x=\"147.5\" y=\"82\" width=\"80\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"187.5\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">minutes</text><text x=\"187.5\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">20 → 30</text><path d=\"M187.5 70 L187.5 82\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"252.0\" y=\"206\" width=\"96\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"300.0\" y=\"216.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">done</text><text x=\"300.0\" y=\"228.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">false → true</text><path d=\"M300.0 238 L300.0 250\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M450.0 250 L450.0 164\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-timeline-ah-phosphor)\"></path><text x=\"458.0\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">sends its copy</text><path d=\"M600.0 70 L600.0 156\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-timeline-ah-phosphor)\"></path><text x=\"608.0\" y=\"115\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">sends its copy</text></svg>", "caption": "Two edits fifteen minutes apart, and still concurrent: neither device had seen the other's change when it made its own."}
```

Each device did exactly what lesson 7 asks of an offline-first app: it wrote locally and told Ana
the change was saved. The outbox of lesson 8 delivered each write once, the idempotency key of
lesson 10 made sure a retry did not deliver it twice, and the delta sync of lesson 11 will bring
each device the other's row afterwards. **None of that machinery notices that the two writes
disagree.** It moves operations; it does not compare them.

## Concurrent, not simultaneous

The two edits were fifteen minutes apart, and they still conflict. What makes them concurrent is
not the clock but what each device knew: the phone changed the minutes without having seen the
tick, and the tablet ticked without having seen the minutes. **Two writes conflict when neither
was made by somebody who had seen the other.** A write made on the tablet after it had pulled the
phone's change is not a conflict at all, even if it lands a second later; it is an ordinary edit
of the newest version.

That definition is the whole difficulty. A server that receives a row cannot tell, from the row
alone, whether its sender had seen the last write or not. Lesson 14 gives it the information to
tell, with a version number and then a vector clock. This lesson looks at the rule most apps start
with, because it needs none: keep the last write and throw the other away.
