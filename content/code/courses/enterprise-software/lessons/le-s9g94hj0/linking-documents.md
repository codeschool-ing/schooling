---
title: Linking a document to the thing it is about
version: 1
---

A document on its own answers no business question. **A certificate of analysis matters because it
belongs to a batch, and a supplier certificate because it belongs to a supplier**, so almost every
useful search in a DMS starts from something the ERP knows. How the two are tied together is an
architectural decision, and the commonest answers are the ones that break.

## The question that tests the link

On a Tuesday in October 2026 the quality team of a supermarket chain opens a case in Service Cloud:
they want the certificate of analysis of batch L2610-0457, whole UHT milk made at Juiz de Fora. The
customer service agent works in Salesforce, the certificate is in Documentum, and the batch is in
SAP. Today the agent e-mails the plant's lab, and the lab finds the PDF by searching Documentum for
the batch number in the file name. That takes about a day, and twice in 2025 the lab sent the
certificate of the wrong batch.

Any way of linking documents can be judged by that case. Does it find the document from the batch,
does it find the right version, and will it still work in five years, after the file server, the
DMS and the ERP have each been replaced?

## Three ways to break a link

**By file path.** Until 2019, Serra Alta's batch records in SAP carried the path of the certificate
PDF in a free-text field: `\\jf-fs02\qualidade\certificados\2018\...`. When that file server was
replaced in 2019, every one of those paths pointed at nothing, and nothing reported a failure. A
path is a string, and SAP had no idea it meant anything. **A path is the address of a copy, and
copies move.**

**By file name.** Names are chosen by people, and people repeat them. Until 2022 the labs at Juiz de
Fora and Lavras both named certificates by a sequence number, so a file called `CA-0457.pdf` existed
in both plants. A name is also edited when somebody corrects a typo, and the link goes with the old
spelling.

**By title or by position.** "The third attachment of the batch" or "the document titled Certificate
of analysis L2610-0457" detaches the day somebody adds an attachment or retitles the document. Words
and places in a list are both things people change, which is why neither can hold a link.

## Link by a stable id

Every object in a DMS has an id that the system assigns and never reuses. In Documentum it is the
`r_object_id`, sixteen hexadecimal characters; in CMIS it is the property `cmis:objectId`. **A link
is a pair of ids: the business object's key on one side and the document's id on the other.** Neither
id describes anything, which is exactly why both survive a renamed file, a moved folder and a new
server.

There is a subtlety that matters more than it looks. A document with versions has two ids worth
storing, and they answer different questions:

| the id of | it names | store it when the link is to |
|---|---|---|
| one version | that exact version, for ever | evidence: the certificate sent to a customer, the procedure version in force when a batch was made |
| the version series | the document as a whole, whichever version is in force | an instruction: "work to the pasteurisation procedure" |

In CMIS these are `cmis:objectId` and `cmis:versionSeriesId`. In Documentum every version has its
own `r_object_id`, and all the versions of one document share an `i_chronicle_id`. A work order that
links to POP-JF-PAS-004 by its series opens version 2.0 the day 2.0 takes effect. A batch record that
links to the exact version line 2 worked to in March 2026 keeps opening 1.0 after 2.0 is approved,
and that is right: **evidence points at what was true then, an instruction at what is true now.**

## Which side holds the link

Either system can hold the pair, and both patterns are in use.

**The ERP holds the document's id.** SAP's own interface for this, ArchiveLink, keeps a link table
that maps a business object, by its type and key, to a document in an external content repository,
so the batch screen in SAP can list the batch's documents. The cost is that every document has to be
registered in SAP, and the DMS on its own cannot say which batch a document belongs to.

**The DMS holds the ERP's key as metadata.** The certificate carries typed properties, batch,
material and plant, filled in when it is filed, and a search by batch works in the DMS without asking
SAP. The cost is that the key has to be right when the document is filed and stay right: a batch
corrected in SAP after filing leaves a certificate that nobody finds.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 340\" role=\"img\" data-fig=\"l05-links\" aria-label=\"On the left, the batch in SAP: material 100231, batch L2610-0457, plant JF, and the id of its certificate document. On the right, the certificate in the DMS: its object id and the properties batch, material and plant. An arrow from the DMS to SAP is the document id written back to the batch; an arrow from SAP to the DMS is the batch key stored as properties, which is the source of truth. Below the DMS, a Service Cloud case asks for the certificate by batch and gets a link. Below SAP, in amber, the links that break: a file path on a file server, and a file name that two plants use.\"><defs><marker id=\"l05-links-es-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l05-links-es-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"30.0\" y=\"40.0\" width=\"230.0\" height=\"128.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"145.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">SAP: the batch</text><text x=\"44.0\" y=\"84.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">material  100231</text><text x=\"44.0\" y=\"104.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">batch     L2610-0457</text><text x=\"44.0\" y=\"124.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">plant     JF</text><text x=\"44.0\" y=\"144.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">doc id    0901e24080003a7f</text><rect x=\"460.0\" y=\"40.0\" width=\"230.0\" height=\"128.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"575.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">DMS: the certificate</text><text x=\"474.0\" y=\"84.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">object id 0901e24080003a7f</text><text x=\"474.0\" y=\"104.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">batch     L2610-0457</text><text x=\"474.0\" y=\"124.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">material  100231</text><text x=\"474.0\" y=\"144.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">plant     JF</text><path d=\"M270.0 88.0 L450.0 88.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#l05-links-es-ah-phosphor)\"></path><text x=\"360.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">key stored as properties</text><text x=\"360.0\" y=\"102.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">(source of truth)</text><path d=\"M450.0 144.0 L270.0 144.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"5 3\" marker-end=\"url(#l05-links-es-ah-paper-dim)\"></path><text x=\"360.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">document id written back</text><rect x=\"460.0\" y=\"243.0\" width=\"230.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"575.0\" y=\"261.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Service Cloud case</text><text x=\"575.0\" y=\"274.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">asks by batch, gets a link</text><path d=\"M560.0 242.0 L560.0 172.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l05-links-es-ah-phosphor)\"></path><path d=\"M590.0 172.0 L590.0 242.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"5 3\" marker-end=\"url(#l05-links-es-ah-paper-dim)\"></path><text x=\"552.0\" y=\"207.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">query</text><text x=\"598.0\" y=\"207.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">link</text><rect x=\"30.0\" y=\"214.0\" width=\"280.0\" height=\"110.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"170.0\" y=\"232.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">links that break</text><text x=\"44.0\" y=\"256.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">\\\\jf-fs02\\qualidade\\...</text><text x=\"44.0\" y=\"272.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the server is replaced</text><text x=\"44.0\" y=\"294.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">CA-0457.pdf</text><text x=\"44.0\" y=\"310.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">two plants, one name</text></svg>", "caption": "A link is a pair of ids. The certificate carries the batch key it was filed under, SAP keeps the document id, and nothing depends on where the file sits or what it is called."}
```

Serra Alta today does half of the second pattern: the batch number is typed into the file name.
Joana's design does both patterns, and makes one of them the source of truth for the link. The job
that produces the certificate from SAP QM's results files it with batch, material and plant as typed
properties, then writes the new document's id back to the batch in SAP. The DMS answers "which
certificates belong to this batch?" and SAP shows the certificate on the batch screen. **If the two
ever disagree, the properties in the DMS win**, because they were set from the source at the moment
of filing and the id in SAP was copied from them.

With that in place, the supermarket's case is a query on batch L2610-0457 for the approved
certificate, and Service Cloud shows the agent a link that opens it. A link, not a copy: the DMS
checks the agent's access when the link is followed, and there is still only one certificate.

## Use the whole key, and the business key

Which key goes into the DMS? SAP identifies a batch by the material and the batch number together,
and the same batch number can exist for two materials. **Use all of the key the ERP uses**, or a
search by batch number alone will one day return two certificates and somebody will send the wrong
one.

And prefer business keys, the material code, the batch number, the vendor number, to an internal
technical number of the ERP. Serra Alta's SAP will be replaced in the next few years, as lesson 2
explains, and the next system will carry the batch numbers printed on the cartons but not the
internal row ids of the old one. The farms are the same case, since each one is a vendor record in
SAP. A supplier certificate or an onboarding file filed under the vendor number survives the ERP
that issued it, provided the migration in lesson 14 keeps the numbers.

## When the document goes

The section on retention left a question open: what happens to a link when its document is disposed
of? If the batch record in SAP holds the id of a certificate destroyed in January 2034, the batch
screen shows a link to nothing. So the disposal run reports the ids it destroyed, and the systems
holding links mark them as disposed, keeping the date and the rule. **A link to a destroyed record
should say it was destroyed**, not fail silently, for the same reason the record of the disposal is
kept.

## Send the id, not the document

The same idea applies when documents travel between systems. Today the ESB flow that sends order
confirmations to two of the supermarket chains attaches the certificate PDF to each message, about
300 KB a time. The queues carry megabytes of copies, and every copy is a record nobody manages. The
alternative is to send the document's id, or a link that resolves it, and let the receiver fetch the
document from the DMS when it needs it. The message stays small, access is checked when the document
is fetched, and there is one copy. Lesson 11 gives this pattern its name, the claim check, and puts it
among the other message patterns.

The rule that covers the whole section is one this course keeps coming back to: **join by a stable
id, never by a name, a path or a position.** A document system that does everything the three
sections before this one describe, and is linked to the ERP by file name, still loses the
certificate.