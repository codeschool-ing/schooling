---
title: One task, one context
version: 2
---

The listings feature above answers questions about listings, so its prompt has to contain listings.
The support assistant answers questions about Marginalia's policies, and its prompt has no reason to
contain them. It is still a common design to give one assistant everything it might need, "related
listings" alongside the policies, in case a customer asks about both:

```schooling-example
{
  "language": "python",
  "file": "mixed.py",
  "parts": [
    {
      "code": "import sys\n\nfrom answer import ask, sources_for\nfrom listings import LISTINGS, as_sources\n\nquestion = sys.argv[1]\npolicies = sources_for(question)\nprint(\"policies only:          \", ask(question, policies))\nprint(\"policies and listings:  \", ask(question, policies + as_sources(LISTINGS)))",
      "note": "The same question answered twice: from the policies the search found, and from those policies with the six listings added to the same prompt."
    }
  ]
}
```

```
ana@vm:~/rag$ python mixed.py "How many days do I have to return a printed book?"
policies only:           According to [1], you have 30 days from delivery to return a printed book. This is the most recent and updated policy, as stated in the source date (2026-02-02).
policies and listings:   According to [1], you have 30 days from delivery to return a printed book in the condition you received it.
```

**Thirty days, cited, both times.** The model ignored the seller's sentence, and the reply is right.
The design is still wrong. A question about the returns policy, from a customer who never looked at a
listing, was answered from a context that held a seller's instruction, and whether the reply was right
depended on the model choosing to ignore it, on this model, this time.

Isolation is the rule that follows: **one task, one context, and untrusted text only in the contexts
whose task needs it.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Two separate pipelines. Support questions are answered from Marginalia&#x27;s own policies by lesson 7&#x27;s pipeline, with a cited reply. Listing comparisons are answered from text written by sellers, by a call with no tools and no memory, and the reply is shown only if every sentence is grounded in a listing, or a safe message otherwise. A dashed line between the two says no text crosses it.\"><defs><marker id=\"rg-8ce9ae\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 5 L0 10 z\" fill=\"var(--wire)\"></path></marker></defs><text x=\"10\" y=\"26\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">support questions</text><rect x=\"10\" y=\"40\" width=\"150\" height=\"56\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"85.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">the question</text><text x=\"85.0\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">from the customer</text><rect x=\"190\" y=\"40\" width=\"150\" height=\"56\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"265.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">policies</text><text x=\"265.0\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Marginalia's own</text><rect x=\"370\" y=\"40\" width=\"150\" height=\"56\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"445.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">answer</text><text x=\"445.0\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">lesson 7's pipeline</text><rect x=\"550\" y=\"40\" width=\"150\" height=\"56\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"625.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">reply</text><text x=\"625.0\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">cited</text><path d=\"M160 68.0 L188 68.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rg-8ce9ae)\"></path><path d=\"M340 68.0 L368 68.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rg-8ce9ae)\"></path><path d=\"M520 68.0 L548 68.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rg-8ce9ae)\"></path><text x=\"10\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">comparing listings</text><rect x=\"10\" y=\"150\" width=\"150\" height=\"56\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"85.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">the question</text><text x=\"85.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">from the customer</text><rect x=\"190\" y=\"150\" width=\"150\" height=\"56\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"265.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">listings</text><text x=\"265.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">written by sellers</text><rect x=\"370\" y=\"150\" width=\"150\" height=\"56\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"445.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">answer</text><text x=\"445.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">no tools, no memory</text><rect x=\"550\" y=\"150\" width=\"150\" height=\"56\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"625.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">check</text><text x=\"625.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">grounded, or a safe message</text><path d=\"M160 178.0 L188 178.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rg-8ce9ae)\"></path><path d=\"M340 178.0 L368 178.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rg-8ce9ae)\"></path><path d=\"M520 178.0 L548 178.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rg-8ce9ae)\"></path><path d=\"M20 120 L700 120\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"700\" y=\"132\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">no text crosses this line</text></svg>", "caption": "Two tasks, two contexts. The listings never enter the support assistant's prompt, and the call that reads them can do nothing but write a reply that is checked before anyone sees it."}
```

- The support assistant reads Marginalia's own documents, filtered by lesson 14's permissions. No
  seller text, no web page, no other customer's words.
- The listings feature reads listings, and nothing else: no account data, no memory of the customer, no
  tools. Whatever an injection makes it say is checked against the listings before it is shown.
- When one task needs the other's result, it receives the **checked output**, not the raw text: a
  listing id and a condition from a fixed list, never the description.

The same reasoning separates tasks within one conversation. A request to summarise an uploaded file
runs in its own call, and what comes back into the chat is the summary, labelled as a summary of an
upload, not the file.
