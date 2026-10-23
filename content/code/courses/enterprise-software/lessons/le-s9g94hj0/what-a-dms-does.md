---
title: What a DMS does that a shared folder cannot
version: 1
---

The common picture of document management is a shared drive with sensible folder names. **A folder
stores files; a document management system controls them**, and the difference shows on the day
somebody has to prove which version was in force. At Serra Alta that day comes several times a
year, when an FSSC 22000 auditor or a federal inspector stops at a procedure on the factory floor
and asks to see that it is the approved one.

## The folder, and what goes wrong in it

The cheese plant at Alagoa came with Queijaria Mantiqueira in 2021, and its quality documents still
live on the plant's file server, one folder per process. In the brining room hangs a printed
procedure whose file is called `POP-salmoura_v3_FINAL_revisado.docx` (POP is the Portuguese for a
standard operating procedure, *procedimento operacional padrão*). The folder holds four files with
names like it. Nobody can say which one was approved, by whom or when, because the folder records
none of that. It knows a name, the date of the last change and who may open the folder.

Every failure of the folder comes from that poverty. Two people open the same file, both edit, and
whoever saves last wins without either of them knowing. "Final" becomes "final2". The copy printed
in 2023 stays on the wall after the procedure changes. A search for *salmoura* finds file names and
not the sentence inside them. Permissions follow the folder, so either everybody in Quality can edit
every procedure or somebody invents a folder for each exception.

## What a DMS adds

A DMS (document management system) keeps the file and, beside it, an object that describes it.
**Everything a DMS adds lives in that object, not in the file**, which is why copying the file out
of the system loses all of it.

| capability | what it means | what the folder does instead |
|---|---|---|
| check-out and check-in | one person holds the document for editing; others read the last version and cannot overwrite it | the last save wins |
| versions | every check-in makes a new version, and the old ones stay, numbered | files renamed `v3_FINAL` |
| one approved version | a label or a state marks the version in force | a person remembers |
| metadata | typed attributes: plant, process, document type, owner, next review date | the folder path, which holds one classification |
| renditions | a PDF made from the Word original, which is what people read and print | somebody exports a PDF by hand, and forgets next time |
| full-text search | the words inside, combined with the attributes | file names |
| access per document | who may read, edit, approve or delete this one document | permissions on the folder |
| workflow | the document is routed to reviewers and an approver, with deadlines | an e-mail with an attachment |
| audit trail | every read, change, approval and deletion, with who and when | the date of the last change |

Two rows deserve a second look. **Metadata is what lets one document belong to several things at
once.** The pasteurisation procedure for line 2 at Juiz de Fora is about a plant, a production line,
a process step, a product family and a regulation. A folder path can hold one of those; attributes
hold all five, so a search on any of them finds the document. And **the audit trail is the
capability an auditor actually tests**, because "who approved this, and when" is a question about
the past that the file cannot answer about itself.

## A version number carries a meaning

Most systems number versions in two parts. Documentum lets each check-in choose a minor increment (1.0 to 1.1) or a major one (1.0 to 2.0). Quality teams add a convention on top
of that: minor versions are working drafts, major versions are the ones that were released. The number then tells
a reader the state. Somebody who sees 1.2 knows they are looking at a draft of what will become 2.0,
and that 1.0 is still the one the line works to.

A number cannot say whether a version is the latest. For that the system keeps a separate marker:
Documentum calls these markers version labels and keeps one called `CURRENT` on the latest version,
while other products use a flag or a state. **The latest version and the approved version are two
different things**, and the gap between them is the point. While 1.2 is being reviewed, the line
runs on 1.0.

## The life of one procedure

Cláudia Mendes's team owns about 2,300 controlled documents in Documentum: procedures, work
instructions, forms and specifications. The repository also holds the certificates that the next
sections are about. Follow one procedure through its life: POP-JF-PAS-004, pasteurisation on line 2
at Juiz de Fora, approved as 1.0 in 2019.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l05-lifecycle\" aria-label=\"Two parts. Above, the states of a controlled document: draft, in review, approved and superseded, in a row, with withdrawn below approved. Draft goes to review when it is sent; review goes back to draft when it is returned, or on to approved; approved becomes superseded when a new version takes effect, or withdrawn when there is no successor. Below, the history of procedure POP-JF-PAS-004 on two time lines. The latest version moves through 1.0, 1.1, 1.2 and 2.0. The version in force on line 2 stays 1.0 through both drafts and the approval, and changes to 2.0 only on the effective date, a week after approval.\"><defs><marker id=\"l05-lifecycle-es-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l05-lifecycle-es-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"30.0\" y=\"32.0\" width=\"120.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"90.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">draft</text><rect x=\"210.0\" y=\"32.0\" width=\"120.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"270.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">in review</text><rect x=\"390.0\" y=\"32.0\" width=\"120.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"450.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">approved</text><rect x=\"570.0\" y=\"32.0\" width=\"120.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"630.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">superseded</text><rect x=\"390.0\" y=\"112.0\" width=\"120.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"450.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">withdrawn</text><path d=\"M152.0 44.0 L208.0 44.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l05-lifecycle-es-ah-phosphor)\"></path><text x=\"180.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">send</text><path d=\"M208 62 C190 82 170 82 152 62\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"5 3\" marker-end=\"url(#l05-lifecycle-es-ah-paper-dim)\"></path><text x=\"180.0\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">returned</text><path d=\"M332.0 50.0 L388.0 50.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l05-lifecycle-es-ah-phosphor)\"></path><text x=\"360.0\" y=\"36.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">approve</text><path d=\"M512.0 50.0 L568.0 50.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l05-lifecycle-es-ah-phosphor)\"></path><text x=\"540.0\" y=\"77.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">successor</text><text x=\"540.0\" y=\"90.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">takes effect</text><path d=\"M450.0 70.0 L450.0 110.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l05-lifecycle-es-ah-paper-dim)\"></path><text x=\"442.0\" y=\"92.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">no successor</text><path d=\"M20.0 168.0 L700.0 168.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><text x=\"20.0\" y=\"186.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">POP-JF-PAS-004</text><text x=\"150.0\" y=\"214.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">latest version</text><text x=\"150.0\" y=\"262.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">in force on line 2</text><path d=\"M160.0 214.0 L700.0 214.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><circle cx=\"290.0\" cy=\"214.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"290.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1.1</text><circle cx=\"400.0\" cy=\"214.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"400.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1.2</text><circle cx=\"500.0\" cy=\"214.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"500.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">2.0</text><circle cx=\"170.0\" cy=\"214.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"170.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1.0</text><rect x=\"160.0\" y=\"252.0\" width=\"430.0\" height=\"20.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"375.0\" y=\"262.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">1.0 in force</text><rect x=\"590.0\" y=\"252.0\" width=\"110.0\" height=\"20.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"645.0\" y=\"262.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">2.0 in force</text><path d=\"M500.0 220.0 L500.0 249.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 3\"></path><path d=\"M500.0 275.0 L500.0 296.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 3\"></path><text x=\"500.0\" y=\"306.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">approved</text><path d=\"M590.0 220.0 L590.0 296.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><text x=\"596.0\" y=\"306.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">effective date</text><text x=\"345.0\" y=\"236.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">drafts under review: the line still works to 1.0</text></svg>", "caption": "Draft, review, approval, and then superseded or withdrawn. The latest version is not the one in force: 2.0 exists for a week before the line works to it."}
```

In 2026 the lab finds that the thermometer on the holding tube drifts between checks, so the
procedure has to say the check is daily rather than weekly. A quality analyst checks out version 1.0,
edits the Word file and checks it in as 1.1, a **draft**. Nothing on the floor changes.

She sends it for **review**. The line supervisor and the plant's quality coordinator each get a task
with a deadline. The supervisor objects that a daily check needs a form to record it on, so the
document goes back to draft, gains a reference to the new form and comes back as 1.2. This loop, to
review and back, is the commonest path in any document workflow, and the system keeps every lap of
it.

Cláudia **approves** 1.2. The system makes it 2.0, generates the PDF rendition, records her
electronic signature and the date, and sets an effective date a week later, so that the operators
can be trained on the change before it applies. On that date 2.0 becomes the version the line works
to, and 1.0 becomes **superseded**: still in the repository, read-only, findable, and marked as no
longer in force.

**Superseded is not deleted.** An inspector who asks in 2027 what the procedure said on the day a
batch was made in March 2026 is asking about 1.0, and the answer has to be the exact text rather
than somebody's memory of it. That is the bridge to the next section: once it is superseded, a
procedure stops being an instruction and becomes evidence.

A procedure can also be **withdrawn** with no successor, when the process it describes stops
existing. The Alagoa plant closed one of its maturing rooms in 2024, and the room's three procedures
went that way. Withdrawn or superseded, a document leaves the list of what is in force and stays in
the repository.

## Printed copies

A food plant reads its procedures on paper, on a wall, with wet hands. The DMS cannot reach that
copy, so quality practice adds a rule. The rendition carries a footer such as "uncontrolled when
printed: check the version in the system", and the copies that do hang on walls are numbered, issued
by the quality team and collected when a new version takes effect. **A document management system
controls the copies it knows about**, and part of the work of putting one in is making the other
copies known.

## What it is not

Three neighbours share vocabulary with a DMS and do other jobs. A wiki or a SharePoint site is good for pages people write together, and lighter on approval and
records control unless somebody configures it for them. Microsoft 365, which Serra Alta has, does
carry retention features, and lesson 3 describes the company's Microsoft estate. A BPM suite routes work in general,
of which a document approval is one kind, and lesson 6 is about those. And an ERP stores
transactions, not documents, though it has to point at them, which is the last section of this
lesson.

Nobody can download Documentum to try it, so if you want to see these ideas working, an open-source
system is the way. Alfresco Community Edition is free and has check-out, versions, metadata, rules
and simple workflows. Installing it is optional, and nothing in this course depends on it.
