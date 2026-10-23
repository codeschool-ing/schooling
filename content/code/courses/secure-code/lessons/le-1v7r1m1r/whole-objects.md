---
title: When the outside sends a whole object
version: 1
---

Most of this course has been about values: a surname, a term, a note. This lesson is about two
features that accept something larger from outside the portal: **a serialised object**, and **a
file**. Each one is a bigger version of the same question, *what does the code do with what it
received?*, and each has a habit that answers it badly.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" data-fig=\"l14-two\" aria-label=\"Two features that accept a whole object from outside the portal. Above, a preferences cookie: read with pickle, the bytes decide which objects are rebuilt and which functions run; read as JSON and validated, the bytes can only become strings, numbers, lists and dictionaries, and only the allowed values pass. Below, an exam upload: the sender chooses the name, the declared type and the size; the portal instead chooses the name, reads the type from the first bytes, limits the size, stores outside the served folder and hands the file back as a download.\"><defs><marker id=\"l14-two-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"370\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">before</text><text x=\"600\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">after</text><rect x=\"20\" y=\"34\" width=\"180\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"110.0\" y=\"69.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a cookie from the browser</text><rect x=\"240\" y=\"34\" width=\"250\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"365.0\" y=\"62.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">pickle.loads</text><text x=\"365.0\" y=\"75.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">the bytes decide what is built</text><rect x=\"510\" y=\"34\" width=\"190\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"605.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">json.loads + allowlist</text><text x=\"605.0\" y=\"75.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">only data, only allowed values</text><path d=\"M200 69 L240 69\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-two-ah-paper-dim)\"></path><rect x=\"20\" y=\"140\" width=\"180\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"110.0\" y=\"175.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">an uploaded file</text><rect x=\"240\" y=\"140\" width=\"250\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"365.0\" y=\"168.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">the sender's name, type, size</text><text x=\"365.0\" y=\"181.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">trusted as given</text><rect x=\"510\" y=\"140\" width=\"190\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"605.0\" y=\"169.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">the portal's name, the bytes' type,</text><text x=\"605.0\" y=\"181.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">a limit, stored outside static/</text><path d=\"M200 175 L240 175\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-two-ah-paper-dim)\"></path></svg>", "caption": "In both features the fix is the same move: the portal decides what the outside is allowed to make it build."}
```

### Deserialisation

To keep a value between requests, a program **serialises** it into bytes and later **deserialises**
the bytes back into a value. Formats differ in what the bytes are allowed to describe:

- **Data formats**, JSON among them, describe data: strings, numbers, lists, objects with keys.
  Reading them builds those and nothing else.
- **Object formats**, Python's `pickle`, Java's native serialisation, PHP's `unserialize`, describe
  **how to rebuild an object**, including which class to create and which functions to call while
  creating it. Reading them runs whatever the bytes describe.

Python's documentation puts the consequence at the top of the `pickle` page: the module is not
secure, and data should be unpickled only if you trust where it came from, because a pickle can be
built to run code while it is loaded. **A cookie comes from the browser, and anything that comes from
the browser can be edited**, so a portal that unpickles a cookie runs bytes chosen by whoever sends
it. The rule is simple and has no exceptions worth making: **never deserialise an object format from
outside the program's own trust boundary; use a data format, and validate what it contains.**

### Upload

A file upload hands the server a name, a declared type and some bytes, and all three are chosen by the
sender. The habits that go wrong are each a value trusted too far:

- **The name** used as a path, so a name containing `../` writes somewhere else.
- **The declared type or the extension** taken as the truth, so a text file called `scan.pdf` is
  stored, and later served, as a PDF.
- **No limit on size**, so one request fills the disk.
- **Storage in a folder the web server serves**, under the original name, so the uploaded file comes
  back with whatever type a browser decides to read it as.

The witnesses this lesson uses are ordinary: a name with `../` at the front, as a broken client
might send, a file of plain text with the wrong extension, and a file that is simply too big.
