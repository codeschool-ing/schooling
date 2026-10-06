---
title: Counting what survived
version: 1
---

A summary cannot be checked by reading it, because what is missing is invisible. It can be checked
against a list of what must be there. For Beatriz's conversation, the list is six facts, written by
someone who read the conversation and knows what an agent would need:

```schooling-example
{
  "language": "python",
  "file": "essentials.py",
  "parts": [
    {
      "code": "import json",
      "note": "The turns of Beatriz's conversation, read from the course's data."
    },
    {
      "code": "# What a support agent picking up Beatriz's conversation must still know, each as words that have to\n# appear. Written by a person who read the conversation; that is what makes it a test.\nESSENTIALS = {\n    \"order number\": [\"MG-20481937\"],\n    \"contact by email only\": [\"email only\"],\n    \"replacement for Persuasion\": [\"Persuasion\", \"replacement\"],\n    \"wrong book received\": [\"Mansfield Park\"],\n    \"money back for Middlemarch\": [\"Middlemarch\", \"money back\"],\n    \"new address\": [\"Rua das Flores 120\"],\n}\nTURNS = [json.loads(line)[\"text\"] for line in open(\"data/chat-a.jsonl\")]",
      "note": "Six facts, each as the words a text must contain to carry it. A person who read the conversation wrote them, which is what makes them a test of the summariser rather than of itself."
    },
    {
      "code": "def kept(text):\n    \"\"\"The essentials TEXT still carries: every word of each one has to be there.\"\"\"\n    return [name for name, words in ESSENTIALS.items() if all(w.lower() in text.lower() for w in words)]",
      "note": "A fact survives when every one of its words is in the text, ignoring case."
    }
  ]
}
```

Then every summary is scored against the list, at four lengths, beside the turns themselves:

```
ana@lab:~/rag$ python summaries.py
           tokens  essentials
all turns     182  6/6
 20 words      23  2/6  lost: order number, contact by email only, money back for Middlemarch, new address
 40 words      51  2/6  lost: order number, contact by email only, money back for Middlemarch, new address
 60 words      73  3/6  lost: order number, contact by email only, new address
100 words     129  4/6  lost: contact by email only, new address
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" aria-label=\"A scatter of six ways to keep Beatriz&#x27;s first eleven turns: tokens kept against essentials that survived, out of six. Summary in 20 words: 23 tokens, 2. In 40 words: 51, 2. In 60: 73, 3. In 100: 129, 4. Pinned sentences with a summary and the last three turns: 148, 6. All turns: 182, 6.\"><path d=\"M70 260 L640 260\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M70 260 L70 40\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M70.0 260 L70.0 265\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"70.0\" y=\"277\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><path d=\"M212.5 260 L212.5 265\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"212.5\" y=\"277\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">50</text><path d=\"M355.0 260 L355.0 265\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"355.0\" y=\"277\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">100</text><path d=\"M497.5 260 L497.5 265\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"497.5\" y=\"277\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">150</text><path d=\"M640.0 260 L640.0 265\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"640.0\" y=\"277\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">200</text><path d=\"M65 260.0 L70 260.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"61\" y=\"260.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><path d=\"M65 223.33333333333334 L70 223.33333333333334\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"61\" y=\"223.33333333333334\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1</text><path d=\"M65 186.66666666666669 L70 186.66666666666669\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"61\" y=\"186.66666666666669\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2</text><path d=\"M65 150.0 L70 150.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"61\" y=\"150.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">3</text><path d=\"M65 113.33333333333334 L70 113.33333333333334\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"61\" y=\"113.33333333333334\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">4</text><path d=\"M65 76.66666666666666 L70 76.66666666666666\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"61\" y=\"76.66666666666666\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">5</text><path d=\"M65 40.0 L70 40.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"61\" y=\"40.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">6</text><text x=\"355.0\" y=\"302\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">tokens of what is kept</text><text x=\"70\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">essentials that survived, of 6</text><circle cx=\"135.6\" cy=\"186.7\" r=\"5\" fill=\"var(--paper-dim)\"></circle><text x=\"143.55\" y=\"174.66666666666669\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">20 words</text><circle cx=\"215.3\" cy=\"186.7\" r=\"5\" fill=\"var(--paper-dim)\"></circle><text x=\"223.35\" y=\"200.66666666666669\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">40 words</text><circle cx=\"278.1\" cy=\"150.0\" r=\"5\" fill=\"var(--paper-dim)\"></circle><text x=\"286.05\" y=\"164.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">60 words</text><circle cx=\"437.6\" cy=\"113.3\" r=\"5\" fill=\"var(--paper-dim)\"></circle><text x=\"445.65\" y=\"127.33333333333334\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">100 words</text><circle cx=\"491.8\" cy=\"40.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"481.8\" y=\"56.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">pinned + summary + recent</text><circle cx=\"588.7\" cy=\"40.0\" r=\"5\" fill=\"var(--paper-dim)\"></circle><text x=\"580.7\" y=\"26.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">all turns</text></svg>", "caption": "A summary alone never reached six, whatever its length; the order number, the email-only request and the new address were the sentences it dropped first. Pinning them kept all six for 34 tokens less than the turns themselves."}
```

**No summary kept all six.** At 20 and 40 words, two of six; at 100 words, 129 tokens of an original
182, four of six, and still without the email-only request or the new address. Going from 40 words
to 100 brought back the refund for *Middlemarch* and the order number, and never the email-only
request or the address, each of which is one sentence in one turn. Length is not the dial: a longer summary keeps more of what the
conversation is mostly about, and the details that matter most to the next turn are often the ones
said exactly once.

The list is what makes this measurable, and writing it is the work. It is a test set in lesson 8's
sense, made of conversations rather than questions: for each conversation, the facts a successor must
know. A handful of real conversations, each with its list, turns "the summaries seem fine" into a
number that changes when the summariser does.
