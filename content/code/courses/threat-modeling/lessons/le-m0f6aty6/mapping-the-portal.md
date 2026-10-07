---
title: Mapping the portal
version: 1
---

The map does not need a new drawing. Every entry and exit point is a flow in `model.py` that
crosses the edge of what Vereda runs, which is the cloud and the private network inside it.
`surface.py` reads the JSON pytm writes and lists them:

```schooling-example
{"language": "python", "file": "surface.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"The attack surface of a pytm model: every flow that enters or leaves what Vereda runs.\"\"\"\nimport json\nimport sys\n\nOURS = {\"Vereda cloud\", \"Private network\"}\n", "note": "What Vereda runs is two boundaries: the cloud and the private network inside it. Everything else is outside."}, {"code": "model = json.load(open(sys.argv[1]))\nwhere = {e[\"name\"]: e[\"inBoundary\"] for e in model[\"elements\"]}\ninside = lambda name: where[name] in OURS\n", "note": "Each element's boundary, from pytm's JSON, and a test for whether a name is on Vereda's side."}, {"code": "entries = [f for f in model[\"flows\"] if not inside(f[\"source\"]) and inside(f[\"sink\"])]\nexits = [f for f in model[\"flows\"] if inside(f[\"source\"]) and not inside(f[\"sink\"])]\n", "note": "An entry point arrives from outside to inside; an exit point leaves from inside to outside. A flow inside, like the worker reading the database, is neither."}, {"code": "for title, flows in ((\"entry points\", entries), (\"exit points\", exits)):\n    print(f\"{len(flows)} {title}\")\n    for f in flows:\n        print(f\"  {f['name']:26} {f['source']} -> {f['sink']}\")", "note": "Print each list with its count, the flow's name and its two ends."}]}
```

```
(.venv) ana@vm:~/tm/portal-model$ python3 model.py --json model.json
(.venv) ana@vm:~/tm/portal-model$ python3 surface.py model.json
4 entry points
  Sign in and book           Patient -> Portal
  Upload exam PDF            Patient -> Portal
  Payment webhook            Payment gateway -> Portal
  Manage the agenda          Clinic staff -> Staff console
3 exit points
  Pages and booking status   Portal -> Patient
  Charge for a session       Portal -> Payment gateway
  Send reminder              Reminder worker -> SMS provider
```

Four ways in and three ways out, and every one of them is a flow already in the figure of lesson 2.
For comparison with what comes next, pytm's count on this model:

```
(.venv) ana@vm:~/tm/portal-model$ python3 findings.py model.json | grep findings
196 findings on 17 elements
```

### The door the drawing left out

Lesson 2 drew the staff console behind the clinic network, as designed, and noted that it answers
from the internet. Lesson 3 wrote that as T12. The map is the place to stop describing the
intention and **draw the system as it is**: one more actor, anybody on the internet, and one more
flow, to the console's sign-in page. In `model.py` that is six lines:

```
--- a/model.py
+++ b/model.py
@@ -26,6 +26,9 @@
 payments = ExternalEntity("Payment gateway")
 payments.inBoundary = vendors
 payments.protocol = "HTTPS"
+anyone = Actor("Anyone on the internet")
+anyone.inBoundary = internet
+anyone.protocol = "HTTPS"
 
 # Processes: code Vereda runs.
 portal = Server("Portal")
@@ -67,5 +70,8 @@
 Dataflow(worker, db, "Read tomorrow's bookings")
 Dataflow(worker, sms, "Send reminder")
 
+# Drawn in lesson 6: the console answers from the internet, not only the clinics.
+Dataflow(anyone, console, "Staff sign-in page")
+
 if __name__ == "__main__":
     tm.process()
```

And the map, run again:

```
(.venv) ana@vm:~/tm/portal-model$ git diff --stat
 model.py | 6 ++++++
 1 file changed, 6 insertions(+)
(.venv) ana@vm:~/tm/portal-model$ python3 model.py --json model.json
(.venv) ana@vm:~/tm/portal-model$ python3 surface.py model.json
5 entry points
  Sign in and book           Patient -> Portal
  Upload exam PDF            Patient -> Portal
  Payment webhook            Payment gateway -> Portal
  Manage the agenda          Clinic staff -> Staff console
  Staff sign-in page         Anyone on the internet -> Staff console
3 exit points
  Pages and booking status   Portal -> Patient
  Charge for a session       Portal -> Payment gateway
  Send reminder              Reminder worker -> SMS provider
```

**Five entry points.** The new one is the only entry point into the staff side of Vereda that
anybody, anywhere, can reach without being on a clinic's network. pytm's count went up by five,
the generic findings every new flow gets:

```
(.venv) ana@vm:~/tm/portal-model$ python3 findings.py model.json | grep findings
201 findings on 18 elements
```

The change is committed like any other, so the history shows when the model started telling the
truth about the console:

```
(.venv) ana@vm:~/tm/portal-model$ git commit -qam 'Draw the console as it is: reachable from the internet'
(.venv) ana@vm:~/tm/portal-model$ git log --oneline -3
23e3e45 Draw the console as it is: reachable from the internet
088ee69 List the entry and exit points
f602de2 Model one goal as an attack tree
```

### The map as a list to keep

Five entries and three exits fit in a table, and the table is the document to keep beside the model:

| entry point | who can reach it without a credential | what it changes |
|---|---|---|
| sign in and book | anyone (the sign-in form) | the patient's bookings |
| upload exam PDF | nobody: patients only | the patient's exams, and the storage |
| payment webhook | anyone who knows the address | whether a booking is paid |
| manage the agenda | nobody: staff only | every patient's record |
| staff sign-in page | anyone | nothing by itself; it guards every patient's record |

Three rows say "anyone", and two of those guard money or every record. Those are where the next
section starts.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" data-fig=\"l06-reach-change\" aria-label=\"The portal’s five entry points placed by who can reach them without a credential, across, and by what they change, up. The payment webhook: anyone who knows the address, and it changes whether a booking is paid. Sign in and book: anyone, and it changes the patient’s bookings. The staff sign-in page: anyone, and it changes nothing by itself but guards every patient’s record. Upload exam PDF: patients only, the patient’s exams. Manage the agenda: staff only, every patient’s record.\"><defs><marker id=\"l06-reach-change-tm-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M120.0 240.0 L700.0 240.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l06-reach-change-tm-ah-paper-dim)\"></path><path d=\"M120.0 240.0 L120.0 20.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l06-reach-change-tm-ah-paper-dim)\"></path><text x=\"210.0\" y=\"258.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">anyone</text><text x=\"420.0\" y=\"258.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">patients</text><text x=\"620.0\" y=\"258.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">staff</text><text x=\"112.0\" y=\"200.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">own data</text><text x=\"112.0\" y=\"130.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">money</text><text x=\"112.0\" y=\"60.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">everyone’s data</text><circle cx=\"210.0\" cy=\"130.0\" r=\"7\" fill=\"var(--amber)\"></circle><text x=\"222.0\" y=\"118.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">payment webhook</text><circle cx=\"210.0\" cy=\"200.0\" r=\"7\" fill=\"var(--paper-dim)\"></circle><text x=\"222.0\" y=\"188.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">sign in and book</text><circle cx=\"210.0\" cy=\"60.0\" r=\"7\" fill=\"var(--amber)\"></circle><text x=\"222.0\" y=\"48.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">staff sign-in page (guards it)</text><circle cx=\"420.0\" cy=\"200.0\" r=\"7\" fill=\"var(--paper-dim)\"></circle><text x=\"432.0\" y=\"188.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">upload exam PDF</text><circle cx=\"620.0\" cy=\"60.0\" r=\"7\" fill=\"var(--paper-dim)\"></circle><text x=\"632.0\" y=\"48.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">manage the agenda</text><text x=\"410.0\" y=\"275.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">top left is where to look first</text></svg>", "caption": "Two questions rank the entries better than their number: who reaches it with nothing, and what they can change."}
```
