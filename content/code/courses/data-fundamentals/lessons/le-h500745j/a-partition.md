---
title: A partition on your own machine
version: 1
---

**The quickest way to believe CAP is to cut a link yourself and watch both answers happen.** The
program in this section keeps three copies of one number, cuts one copy off from the other two,
and sends it the same two requests twice: once behaving as a system that chose consistency, once as
one that chose availability.

Everything runs in the lab lesson 1 built. This lesson works in its own directory:

```sh
mkdir -p ~/roda/cap && cd ~/roda/cap
```

## Three copies and a cut

The network here is a dictionary. Nothing is sent anywhere; a node "reaches" another when both
are on the same side. That is enough to show the choice, because the choice does not depend on how
a message travels, only on whether it arrives. Save it in `~/roda/cap` as `replicas.py`:

```schooling-example
{"language": "python", "file": "cap/replicas.py", "parts": [{"code": "# cap/replicas.py\nimport sys\n\nMODE = sys.argv[1]  # \"cp\" or \"ap\"\nNODES = [\"n1\", \"n2\", \"n3\"]\nbikes = {n: 6 for n in NODES}  # bicycles docked at ST02, one copy per node\nside = {\"n1\": \"A\", \"n2\": \"A\", \"n3\": \"A\"}  # one side: nothing is cut\n", "note": "Three copies of one number: the bicycles docked at ST02, Rua XV. `side` says which side of a cut each node is on, and while all three say `A`, every node reaches every other. `MODE` comes from the command line, so one program shows both behaviours."}, {"code": "\n\ndef reach(node):\n    return [n for n in NODES if side[n] == side[node]]\n\n\ndef majority(node):\n    return len(reach(node)) > len(NODES) // 2\n", "note": "`reach` is the list of nodes a node can still talk to, itself included. `majority` asks whether that list is more than half of the three: two of three is, one of three is not."}, {"code": "\n\ndef write(node, value):\n    if MODE == \"cp\" and not majority(node):\n        return f\"{node} write {value}: refused, sees {len(reach(node))} of 3\"\n    for n in reach(node):\n        bikes[n] = value\n    return f\"{node} write {value}: ok on {' '.join(reach(node))}\"\n", "note": "A write in `cp` mode needs a majority or it is refused. Otherwise it is copied to every node in reach, and only those, because nothing crosses the cut. In `ap` mode the check is skipped."}, {"code": "\n\ndef read(node):\n    if MODE == \"cp\" and not majority(node):\n        return f\"{node} read: refused, sees {len(reach(node))} of 3\"\n    return f\"{node} read: {bikes[node]}\"\n", "note": "A read refuses on the same condition, because a node cut off from the majority cannot know whether its copy is still the latest. In `ap` mode it returns whatever this node holds."}, {"code": "\n\nprint(MODE, \"before the cut:\", bikes)\nside[\"n3\"] = \"B\"  # the link between n3 and the others is cut\nprint(write(\"n1\", 5))  # a bicycle is taken, seen by n1\nprint(write(\"n3\", 7))  # a bicycle is returned, seen by n3\nprint(read(\"n2\"))\nprint(read(\"n3\"))\nprint(MODE, \"after the cut:\", bikes)\n", "note": "The story: the link to `n3` is cut, a bicycle is taken at a node on the larger side, and one is returned at the node on its own. After both, ST02 really holds 6 again."}]}
```

Two lines decide everything. `majority` is how a system that chose consistency knows it is on the
side allowed to speak: a node that reaches two of three can be sure no other group of nodes is
accepting writes at the same moment, because there is no second group of two. And the `MODE`
check is the only difference between the two behaviours. The rest of the program is the same.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Two panels, each with nodes n1 and n2 on one side of a cut link and n3 alone on the other. Consistency chosen: n1 and n2 hold 5, n3 still holds 6 and refuses reads and writes. Availability chosen: n1 and n2 hold 5, n3 accepted a return and holds 7. The true count is 6.\" data-fig=\"partition\"><defs><marker id=\"partition-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"180\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\" font-weight=\"600\">consistency chosen (cp)</text><rect x=\"16\" y=\"36\" width=\"214\" height=\"116\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"26\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">side A</text><rect x=\"30\" y=\"62\" width=\"82\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"71.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">n1</text><text x=\"71.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">5</text><rect x=\"134\" y=\"62\" width=\"82\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"175.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">n2</text><text x=\"175.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">5</text><line x1=\"112\" y1=\"92\" x2=\"134\" y2=\"92\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></line><rect x=\"258\" y=\"36\" width=\"86\" height=\"116\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"268\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">side B</text><rect x=\"262\" y=\"62\" width=\"78\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"301.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">n3</text><text x=\"301.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">6</text><line x1=\"216\" y1=\"92\" x2=\"232\" y2=\"92\" stroke=\"var(--amber)\" stroke-width=\"2\"></line><line x1=\"246\" y1=\"92\" x2=\"262\" y2=\"92\" stroke=\"var(--amber)\" stroke-width=\"2\"></line><text x=\"239\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\" font-weight=\"600\">cut</text><text x=\"123\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">keeps working</text><text x=\"301\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">refuses writes</text><text x=\"301\" y=\"183\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">and reads</text><text x=\"180\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">every answer is true;</text><text x=\"180\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">n3 answers with errors</text><text x=\"540\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\" font-weight=\"600\">availability chosen (ap)</text><rect x=\"376\" y=\"36\" width=\"214\" height=\"116\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"386\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">side A</text><rect x=\"390\" y=\"62\" width=\"82\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"431.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">n1</text><text x=\"431.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">5</text><rect x=\"494\" y=\"62\" width=\"82\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"535.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">n2</text><text x=\"535.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">5</text><line x1=\"472\" y1=\"92\" x2=\"494\" y2=\"92\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></line><rect x=\"618\" y=\"36\" width=\"86\" height=\"116\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"628\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">side B</text><rect x=\"622\" y=\"62\" width=\"78\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"661.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">n3</text><text x=\"661.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">7</text><line x1=\"576\" y1=\"92\" x2=\"592\" y2=\"92\" stroke=\"var(--amber)\" stroke-width=\"2\"></line><line x1=\"606\" y1=\"92\" x2=\"622\" y2=\"92\" stroke=\"var(--amber)\" stroke-width=\"2\"></line><text x=\"599\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\" font-weight=\"600\">cut</text><text x=\"483\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">keeps working</text><text x=\"661\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">accepts the</text><text x=\"661\" y=\"183\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">returned bicycle</text><text x=\"540\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">n2 says 5, n3 says 7;</text><text x=\"540\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Rua XV really holds 6</text></svg>", "caption": "The same cut, two choices. On the left the lone node refuses and every answer stays true; on the right it accepts, and two copies disagree until the link heals."}
```

## Consistency chosen

```
ana@lab:~/roda/cap$ python replicas.py cp
cp before the cut: {'n1': 6, 'n2': 6, 'n3': 6}
n1 write 5: ok on n1 n2
n3 write 7: refused, sees 1 of 3
n2 read: 5
n3 read: refused, sees 1 of 3
cp after the cut: {'n1': 5, 'n2': 5, 'n3': 6}
```

`n1` reached two of the three nodes, a majority, so the bicycle taken at Rua XV was recorded on
`n1` and `n2`. `n3` saw one of three and refused both the returned bicycle and the read. The
customer at `n3` got an error.

Look at what is still true. **Nothing anybody read was wrong.** `n2` answered 5, which was the
latest accepted write. `n3`'s copy still says 6, but nobody was allowed to read it while it might
be stale. And the system did not go down: the two nodes on the larger side kept working, which is
what most of its users saw.

## Availability chosen

```
ana@lab:~/roda/cap$ python replicas.py ap
ap before the cut: {'n1': 6, 'n2': 6, 'n3': 6}
n1 write 5: ok on n1 n2
n3 write 7: ok on n3
n2 read: 5
n3 read: 7
ap after the cut: {'n1': 5, 'n2': 5, 'n3': 7}
```

Now every request got an answer. The return at `n3` was accepted, so the customer is happy, and
anyone reading from `n3` sees 7. At the same moment, anyone reading from `n2` sees 5.

**Two readers asked the same question at the same instant and got two different answers**, and
the true count is neither: one bicycle left and one came back, so Rua XV holds 6. That is what
giving up linearisability looks like. No node lied — each reported what it had seen — and the
disagreement lasts until the link heals and somebody decides how 5 and 7 become one number.
Section 05 makes that decision three ways.

## What the simulation leaves out

Two things, and both make the real case harder rather than easier.

- **A real node does not know it is partitioned.** Here `side` says so. On a network, `n3` only
  sees that its messages go unanswered, and lesson 9 showed that a timeout cannot tell a cut link
  from a slow peer or a dead one. A real system picks a timeout and treats silence as a cut, and it
  is sometimes wrong.
- **The number of nodes matters.** With two nodes instead of three, a cut leaves each side seeing
  one of two, and one is not more than half. A system that chose consistency would then refuse on
  **both** sides. That is why such systems run an odd number of nodes, three or five: a fourth
  node adds a machine without letting the system lose one more.
