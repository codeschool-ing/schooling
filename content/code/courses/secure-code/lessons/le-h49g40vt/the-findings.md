---
title: What one reviewer found
version: 1
---

Here is the same diff, marked the way a reviewer working through the five questions marks it.
Six findings, and each one has a lesson of this course behind it:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l18-marked\" aria-label=\"The diff of the messages branch, reduced to the six lines that matter, each with a numbered marker. Marker 1, the new route that reads a message by its number: nothing checks whose message it is. Marker 2, the message built from every form field: the sender can choose whose name it carries. Marker 3, the template that adds the safe filter: escaping is switched off for patients' text. Marker 4, the secret key written as a string in the code. Marker 5, the Flask pin loosened to a range. Marker 6, a new feature with no new test.\"><rect x=\"20\" y=\"14\" width=\"420\" height=\"276\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"36\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">+@app.get(\"/messages/&lt;int:number&gt;\")</text><rect x=\"456\" y=\"26\" width=\"28\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"470.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">1</text><text x=\"496\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">nothing checks whose message</text><text x=\"36\" y=\"84\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">+    message = dict(request.form)</text><rect x=\"456\" y=\"70\" width=\"28\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"470.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">2</text><text x=\"496\" y=\"84\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the sender chooses the name</text><text x=\"36\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">+ … m.text|replace('\\n', '&lt;br&gt;')|safe …</text><rect x=\"456\" y=\"114\" width=\"28\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"470.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">3</text><text x=\"496\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">escaping switched off</text><text x=\"36\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">+app.secret_key = \"vereda-dev\"</text><rect x=\"456\" y=\"158\" width=\"28\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"470.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">4</text><text x=\"496\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a secret in the repository</text><text x=\"36\" y=\"216\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">+flask&gt;=3.0</text><rect x=\"456\" y=\"202\" width=\"28\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"470.0\" y=\"216.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">5</text><text x=\"496\" y=\"216\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the pin became a range</text><text x=\"36\" y=\"260\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">(nothing changed in any test)</text><rect x=\"456\" y=\"246\" width=\"28\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"470.0\" y=\"260.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">6</text><text x=\"496\" y=\"260\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">no test came with it</text></svg>", "caption": "The same diff, as a reviewer marks it. Every marker is a question, and each one has a lesson behind it."}
```

### 1 · Any patient reads any message

`read_message` calls `patient()`, which refuses somebody who is not signed in, and then returns
`MESSAGES[number]` whatever patient it belongs to. Messages are numbered 1, 2, 3, so every message
in the portal is one guess away from every signed-in patient. This is lesson 1's flaw again, in a
new route, and it is first in the list because it exposes other people's data. The fix is the
same: a message that is not the caller's is answered like one that does not exist.

### 2 · The sender chooses whose message it is

`dict(request.form)` stores every field that arrived, and
`message.get("patient", patient())` uses a `patient` field from the form when there is one. A
request can therefore file a message under another patient's name, and the clinic would answer
the wrong person. Lesson 3 called this mass assignment. The fix is to build the record from the
known fields only, with `patient` taken from the session and never from the request.

### 3 · Escaping switched off for patients' text

To keep line breaks, the template replaces `\n` with `<br>` and marks the result `safe`. That
switches off, for text a patient typed, the escaping lesson 4 relied on. The line breaks are a
real need with a safe answer: keep the text escaped and let CSS show the line breaks, with
`white-space: pre-line` on the paragraph. No HTML needs to be trusted for a newline.

### 4 · A secret in the repository

`app.secret_key = "vereda-dev"` replaces a random key with a fixed one written in the code. Flask
signs the session cookie with that key, so anybody who has read the repository can produce a
session cookie the server accepts as genuine. The description calls it a simplification. Lesson 16
says where a key belongs instead.

### 5 · The pin became a range

`flask>=3.0` installs whatever Flask is newest on the day of each deployment. Lesson 17 explained
why an application pins; nothing in the change needed the range.

### 6 · No test came with it

The change adds two routes and touches the template, and no test changed. Every finding above is
the kind of thing a single test would have pinned down: *a patient cannot read message 2*,
*the sender in the form is ignored*, *a message's text is escaped*. A review comment that asks for
the test is often worth more than one that describes the fix, because the test stays after the
reviewer has gone.

### What the reviewer did not mark

`max(MESSAGES) + 1` can give two messages the same number if two arrive at once, and a missing
message number raises an error that becomes a 500. Both are real and both are worth a comment.
Neither exposes anybody's data, so they go below the six, marked as not blocking.
