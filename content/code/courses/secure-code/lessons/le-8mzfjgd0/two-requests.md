---
title: The same request, twice
version: 1
---

An **insecure direct object reference**, IDOR for short, is the simplest access-control flaw to
describe. A request names a record by its identifier, `/exams/2`, and the server fetches that
record and returns it, having checked that *somebody* is signed in but not that the record is
**theirs**. Lesson 12 called this the question roles cannot answer: *to this?*

It needs no skill to find, which is what makes it common. The identifier is in the address bar, and
it is usually a number that counts up.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l13-two\" aria-label=\"An insecure direct object reference drawn as two requests from lucia's browser, both carrying her valid session cookie. The first asks for GET /exams/1, her own knee MRI, and the server answers 200 with it. The second differs by one character, GET /exams/2, which is marta's lumbar spine X-ray, and the flawed server answers 200 with marta's exam, because it checked only that somebody was signed in. After the fix, the second request is answered 404, the same answer as for an exam that does not exist.\"><defs><marker id=\"l13-two-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l13-two-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l13-two-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"120\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">lucia's browser, signed in</text><text x=\"600\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">the portal</text><rect x=\"520\" y=\"36\" width=\"160\" height=\"170\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><rect x=\"20\" y=\"44\" width=\"200\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"120.0\" y=\"63.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">GET /exams/1</text><text x=\"120.0\" y=\"76.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Cookie: lucia's session</text><path d=\"M220 62 L520 62\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-two-ah-paper-dim)\"></path><path d=\"M520 84 L220 84\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-two-ah-phosphor)\"></path><text x=\"370\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">200: Knee MRI (lucia's)</text><rect x=\"20\" y=\"130\" width=\"200\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"120.0\" y=\"149.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">GET /exams/2</text><text x=\"120.0\" y=\"162.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Cookie: lucia's session</text><path d=\"M220 148 L520 148\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-two-ah-paper-dim)\"></path><path d=\"M520 170 L220 170\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-two-ah-amber)\"></path><text x=\"370\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">200: Lumbar spine X-ray (marta's)</text><text x=\"120\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">one character apart</text><text x=\"370\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--phosphor)\">after the fix: 404, as for an exam that does not exist</text></svg>", "caption": "Both requests are lucia's and both are valid. Only the server can tell that the second asks for somebody else's record."}
```

The two requests differ in **one character**. Both carry lucia's valid session cookie. The first asks
for her own knee scan and gets it. The second asks for exam 2, which is marta's, and on a portal with
the flaw it gets that too: the server read the number, found a row, and sent it. Nothing in the
request was forged. **The session proves who lucia is; it says nothing about what she may see.** On a
physiotherapy portal what she sees is somebody else's health data, and under the LGPD that is a
reportable incident.

### Why it keeps happening

The wrong idea is that **an identifier is a secret**, or at least obscure: patients only see their own
exam links, so they only ever ask for their own exams. Every part of that is about the screen. The
server receives requests, not screens, and lesson 12 already showed what a hidden link is worth.

Two habits of ordinary code produce it:

- **Fetching by id alone.** `SELECT … WHERE id = ?` is the first query anybody writes for a detail
  page, and it is correct for the data and wrong for the access. Ownership has to be part of the
  query, or checked against its result, every single time.
- **Taking the owner from the request.** `?patient=marta` in a list, a `patient_id` field in a JSON
  body, an account number in a form. If the server uses it to decide whose data to read, the client
  has chosen whose data it reads.

### The rule

**Every request for a record is answered for the signed-in person's records only, and the owner
comes from the session, never from the request.** A record that exists but is not theirs gets the
same answer as a record that does not exist.

The rest of the lesson is that rule as a test that asks every patient for every exam, a query that
cannot return the wrong row, and the reason the answer is `404` rather than `403`.
