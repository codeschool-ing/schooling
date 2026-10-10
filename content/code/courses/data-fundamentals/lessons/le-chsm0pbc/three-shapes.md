---
title: Three shapes, and the question that sorts them
version: 1
---

**Structured, semi-structured and unstructured are not three kinds of file. They are three answers
to one question: where does the schema live?** A schema is the description of the data: what the
fields are called, what type each one holds, which ones must be there. Somebody always has to know
it. The three shapes differ in who knows it, and when.

The common picture sorts by extension instead: a `.csv` or a database is structured, a `.json` is
semi-structured, a `.jpg` or a `.txt` is unstructured. It works often enough to survive, and it
breaks on the first case that matters. A CSV file has column names in its first line and no types
anywhere, so `12` and `12 min` sit in the same column without complaint. A JSON file checked
against a strict description at the door behaves like a table. The extension tells you how the
bytes are laid out. It does not tell you whether anybody checked them.

## One ride, written down three times

Here is the same ride at Roda Livre, as three systems record it.

**In the app's database**, it is a row in a table whose columns were declared before the first ride
was ever stored:

| ride_id | start_station | started_at | minutes |
|---|---|---|---|
| R000001 | ST02 | 2025-09-14 07:52 | 12 |

The names and the types live in the table. A row cannot arrive without them, and a value of the
wrong type is refused when it is written.

**In the event the app sends** when the ride ends, it is a JSON document:

```json
{"ride_id": "R000001", "bike": {"id": "B017", "battery": 82},
 "start": {"station": "ST02", "at": "2025-09-14T07:52:00-03:00"}, "minutes": 12}
```

The names travel with every record, beside their values. Nothing declared them in advance, so the
next event may carry a field this one does not, or the same field with a different type. Whoever
reads the events decides what to expect.

**In the email the customer wrote** afterwards, it is a sentence: *"Rode from Rua XV this morning,
twelve minutes, and the dock would not let go of the bike."* There are no names at all. The station,
the duration and the complaint are in the words, and getting them out means reading the words.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"Three panels. Structured: a table whose header declares ride_id, station and minutes with their types, and one row under it. Semi-structured: a JSON event in which the names sit beside the values and bike is nested. Unstructured: an email whose body is a sentence, with structured metadata above it: customer, time and one attachment.\" data-fig=\"three-shapes\"><defs><marker id=\"three-shapes-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"14\" y=\"14\" width=\"222\" height=\"262\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"125\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\" font-weight=\"600\">structured</text><rect x=\"249\" y=\"14\" width=\"222\" height=\"262\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\" font-weight=\"600\">semi-structured</text><rect x=\"484\" y=\"14\" width=\"222\" height=\"262\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"595\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\" font-weight=\"600\">unstructured</text><rect x=\"26\" y=\"56\" width=\"198\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"59\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\" font-weight=\"600\">ride_id</text><text x=\"59\" y=\"85\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">string</text><text x=\"59\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">R000001</text><text x=\"125\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\" font-weight=\"600\">station</text><text x=\"125\" y=\"85\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">string</text><text x=\"125\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ST02</text><text x=\"191\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\" font-weight=\"600\">minutes</text><text x=\"191\" y=\"85\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">int32</text><text x=\"191\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">12</text><line x1=\"26\" y1=\"94\" x2=\"224\" y2=\"94\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><text x=\"125\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">names and types:</text><text x=\"125\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">in the table, declared</text><text x=\"125\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">before any row</text><text x=\"125\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a wrong value is</text><text x=\"125\" y=\"248\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">refused on write</text><rect x=\"261\" y=\"56\" width=\"198\" height=\"92\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"273.0\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">{\"ride_id\": \"R000001\",</text><text x=\"279.0\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">\"bike\": {</text><text x=\"291.0\" y=\"102\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">\"id\": \"B017\",</text><text x=\"291.0\" y=\"118\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">\"battery\": 82},</text><text x=\"279.0\" y=\"134\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">\"minutes\": 12}</text><text x=\"360\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">names: in every record,</text><text x=\"360\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">beside the values</text><text x=\"360\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">each reader decides</text><text x=\"360\" y=\"248\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">what to expect</text><rect x=\"496\" y=\"56\" width=\"198\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"595\" y=\"69\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">C0042 · 08:12 · 1 photo</text><rect x=\"496\" y=\"88\" width=\"198\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"595\" y=\"99\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">“Rode from Rua XV this</text><text x=\"595\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">morning, twelve minutes,</text><text x=\"595\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">and the dock would not</text><text x=\"595\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">let go of the bike.”</text><text x=\"595\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">names: none; the meaning</text><text x=\"595\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">is in the words</text><text x=\"595\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">somebody has to</text><text x=\"595\" y=\"248\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">interpret the body</text></svg>", "caption": "The same ride three times. What changes is where the names and types are kept: in the table, in every record, or nowhere."}
```

## What changes with the shape

| shape | where the schema lives | when a wrong value is caught | at Roda Livre |
|---|---|---|---|
| **structured** | in the table, declared once, before the data | when it is written | rides, payments, the station list |
| **semi-structured** | in each record, as the names beside the values | when somebody reads it, if they check | app events, API responses, sensor messages |
| **unstructured** | nowhere; the meaning is in the content | when a person or a program interprets it | support emails, photos of damaged bicycles, call recordings |

The rest of this lesson takes the three in turn and does something to each on your machine: a table
that refuses a bad value, nested events turned into rows, a batch whose shape changed overnight, and a
pattern that pulls station names out of emails. **The question to carry through all of it is the one
in the second column**, because it decides who pays for a mistake, and how late.
