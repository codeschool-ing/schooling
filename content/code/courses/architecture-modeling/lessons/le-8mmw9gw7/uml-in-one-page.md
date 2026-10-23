---
title: UML on one page
version: 1
---

**UML, the Unified Modeling Language, is a standard set of diagram types for describing software,
with a precise meaning for every shape and arrowhead.** It is maintained by the Object Management
Group (OMG); the current version, 2.5.1, was published in 2017, and an earlier version is also an
ISO standard. It defines fourteen kinds of diagram. You need five of them for this lesson, and two
more for lesson 4.

UML came out of the 1990s, when three popular object-oriented notations, those of Grady Booch,
James Rumbaugh and Ivar Jacobson, were merged into one. That history explains its size: it was
built to describe everything an object-oriented design might contain, and most teams use a small
part of it.

## Structure and behaviour

The fourteen types fall into two families. **Structure diagrams** show what exists and how it is
related, regardless of time. **Behaviour diagrams** show what happens: who does what, in what order,
and how something changes state.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l02-family\" aria-label=\"The fourteen UML diagram types in two families. Structure diagrams: class, component, deployment, object, package, composite structure and profile. Behaviour diagrams: use case, activity, state machine, and four interaction diagrams: sequence, communication, interaction overview and timing. Highlighted are the five this lesson draws, class, component, deployment, use case and sequence, and the two lesson 4 draws, activity and state machine.\"><text x=\"360.0\" y=\"18.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">UML 2.5.1: fourteen diagram types</text><rect x=\"20.0\" y=\"34.0\" width=\"300.0\" height=\"230.0\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"340.0\" y=\"34.0\" width=\"360.0\" height=\"230.0\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"170.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Structure</text><text x=\"520.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Behaviour</text><rect x=\"27.0\" y=\"68.0\" width=\"136.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"95.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Class</text><rect x=\"177.0\" y=\"68.0\" width=\"136.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"245.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Component</text><rect x=\"27.0\" y=\"112.0\" width=\"136.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"95.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Deployment</text><rect x=\"177.0\" y=\"112.0\" width=\"136.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"245.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Object</text><rect x=\"27.0\" y=\"156.0\" width=\"136.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"95.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Package</text><rect x=\"177.0\" y=\"156.0\" width=\"136.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"245.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Composite structure</text><rect x=\"27.0\" y=\"200.0\" width=\"136.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"95.0\" y=\"216.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Profile</text><rect x=\"352.0\" y=\"68.0\" width=\"156.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"430.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Use case</text><rect x=\"352.0\" y=\"112.0\" width=\"156.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"430.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Activity</text><rect x=\"352.0\" y=\"156.0\" width=\"156.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"430.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">State machine</text><rect x=\"518.0\" y=\"66.0\" width=\"172.0\" height=\"186.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"604.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">Interaction</text><rect x=\"526.0\" y=\"92.0\" width=\"156.0\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"604.0\" y=\"106.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">Sequence</text><rect x=\"526.0\" y=\"130.0\" width=\"156.0\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"604.0\" y=\"144.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Communication</text><rect x=\"526.0\" y=\"168.0\" width=\"156.0\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"604.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Interaction overview</text><rect x=\"526.0\" y=\"206.0\" width=\"156.0\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"604.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Timing</text><rect x=\"120.0\" y=\"278.0\" width=\"22.0\" height=\"12.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"150.0\" y=\"284.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">drawn in this lesson</text><rect x=\"380.0\" y=\"278.0\" width=\"22.0\" height=\"12.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"410.0\" y=\"284.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">drawn in lesson 4</text></svg>", "caption": "Seven of the fourteen do most of the work in architecture documents. The other seven are worth recognising and rarely worth drawing."}
```

The five drawn in this lesson are the five that turn up again and again in architecture documents.
Two more, the activity diagram and the state machine diagram, are lesson 4's subject. The rest exist
for good reasons and are rarer: an object diagram shows one moment's instances, a timing diagram
shows signals against a clock, and a profile extends UML itself.

## Three ways to use it

Martin Fowler, in *UML Distilled*, separated three ways people use UML, and most arguments about
whether UML is worth learning are people talking about different ones:

| | what it is | who does it |
| --- | --- | --- |
| **UML as sketch** | partial diagrams that communicate one idea; correct where it matters, loose elsewhere | most architects, most of the time |
| **UML as blueprint** | complete diagrams detailed enough that a programmer could build from them | teams in regulated or contract-heavy settings |
| **UML as programming language** | models detailed enough to generate the program | a few specialist tools and domains |

**This course uses UML as sketch.** That does not mean careless: a sketch still uses the notation
correctly, because a diamond on the wrong end of a line says the opposite of what was meant, and a
reader who knows UML will read what you drew rather than what you intended. It means you draw only
what the question needs, and you leave out everything else.

## Strict in small places

UML is forgiving about layout and very strict about a few marks. Four of them change meaning
entirely and are worth learning before anything else:

- **arrowheads**: a filled triangle, an open one and a hollow triangle are three different things
  in UML, as the sequence and class diagrams in this lesson show;
- **line style**: solid and dashed lines are different relationships;
- **the end a symbol sits on**: a diamond or a triangle says which side is the whole, or which side
  is the parent;
- **guillemets**: words in `«angle quotes»`, called stereotypes or keywords, change what a shape
  means, as `«include»` and `«device»` will.

The rest of this lesson takes the five diagrams one at a time, each with Carcará's ticket sale as
the example, and shows each one drawn right and then drawn wrong.
