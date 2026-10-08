---
title: Counting what survived
version: 2
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

```schooling-example
{
  "language": "python",
  "file": "summaries.py",
  "parts": [
    {
      "code": "from compact import summarise, tokens\nfrom essentials import ESSENTIALS, TURNS, kept\n\nolder = TURNS[:11]\nprint(f\"{'':10} {'tokens':>6}  essentials\")\nprint(f\"{'all turns':10} {tokens(' '.join(older)):6}  {len(kept(' '.join(older)))}/{len(ESSENTIALS)}\")\nfor words in (20, 40, 60, 100):\n    summary = summarise(older, words)\n    print(f\"{words:3} words  {tokens(summary):6}  {len(kept(summary))}/{len(ESSENTIALS)}  lost: {', '.join(n for n in ESSENTIALS if n not in kept(summary))}\")",
      "note": "The eleven turns summarised at four lengths, and for each length how many tokens the summary takes and how many of the essentials it still carries."
    }
  ]
}
```

```
ana@vm:~/rag$ python summaries.py
           tokens  essentials
all turns     182  6/6
 20 words      23  0/6  lost: order number, contact by email only, replacement for Persuasion, wrong book received, money back for Middlemarch, new address
 40 words      53  2/6  lost: contact by email only, wrong book received, money back for Middlemarch, new address
 60 words      75  4/6  lost: contact by email only, money back for Middlemarch
100 words      95  3/6  lost: contact by email only, wrong book received, money back for Middlemarch
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" aria-label=\"A scatter of six ways to keep Beatriz&#x27;s first eleven turns: tokens kept against essentials that survived, out of six. Summary in 20 words: 23 tokens, 0. In 40 words: 53, 2. In 60: 75, 4. In 100: 95, 3. Pinned sentences with a summary and the last three turns: 141, 6. All turns: 182, 6.\"><path d=\"M70 260 L640 260\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M70 260 L70 40\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M70.0 260 L70.0 265\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"70.0\" y=\"277\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><path d=\"M212.5 260 L212.5 265\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"212.5\" y=\"277\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">50</text><path d=\"M355.0 260 L355.0 265\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"355.0\" y=\"277\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">100</text><path d=\"M497.5 260 L497.5 265\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"497.5\" y=\"277\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">150</text><path d=\"M640.0 260 L640.0 265\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"640.0\" y=\"277\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">200</text><path d=\"M65 260.0 L70 260.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"61\" y=\"260.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><path d=\"M65 223.33333333333334 L70 223.33333333333334\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"61\" y=\"223.33333333333334\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1</text><path d=\"M65 186.66666666666669 L70 186.66666666666669\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"61\" y=\"186.66666666666669\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2</text><path d=\"M65 150.0 L70 150.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"61\" y=\"150.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">3</text><path d=\"M65 113.33333333333334 L70 113.33333333333334\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"61\" y=\"113.33333333333334\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">4</text><path d=\"M65 76.66666666666666 L70 76.66666666666666\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"61\" y=\"76.66666666666666\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">5</text><path d=\"M65 40.0 L70 40.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"61\" y=\"40.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">6</text><text x=\"355.0\" y=\"302\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">tokens of what is kept</text><text x=\"70\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">essentials that survived, of 6</text><circle cx=\"135.6\" cy=\"260.0\" r=\"5\" fill=\"var(--paper-dim)\"></circle><text x=\"143.6\" y=\"246.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">20 words</text><circle cx=\"221.1\" cy=\"186.7\" r=\"5\" fill=\"var(--paper-dim)\"></circle><text x=\"229.1\" y=\"200.7\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">40 words</text><circle cx=\"283.8\" cy=\"113.3\" r=\"5\" fill=\"var(--paper-dim)\"></circle><text x=\"291.8\" y=\"127.3\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">60 words</text><circle cx=\"340.8\" cy=\"150.0\" r=\"5\" fill=\"var(--paper-dim)\"></circle><text x=\"348.8\" y=\"164.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">100 words</text><circle cx=\"471.9\" cy=\"40.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"461.9\" y=\"56.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">pinned + summary + recent</text><circle cx=\"588.7\" cy=\"40.0\" r=\"5\" fill=\"var(--paper-dim)\"></circle><text x=\"580.7\" y=\"26.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">all turns</text></svg>", "caption": "A summary alone never reached six, whatever its length, and none kept the email-only request; at 100 words it kept less than at 60. Pinning kept all six for 41 tokens less than the turns themselves."}
```

**No summary kept all six**, and none kept the email-only request. At 20 words, nothing at all; at
60, four of six in 75 tokens, the best of the four; at 100 words, three. A longer summary is not a
safer one: going from 60 words to 100 lost the wrong book. And the 40-word row kept two of six, where
the same request in the last section kept the order number, the address and both books: the same
program, the same turns, temperature 0, and a different summary. A summary checked once has been
checked once.

The check is strict, too. It looks for the words *money back*, and a summary that says *a refund for
Middlemarch*, as the last section's did, fails it. The last section of this lesson comes back to how
strict each fact's check should be; here, read the *lost* column as what the summary did not say in
the customer's words.

The list is what makes this measurable, and writing it is the work. It is a test set in lesson 8's
sense, made of conversations rather than questions: for each conversation, the facts a successor must
know. A handful of real conversations, each with its list, turns "the summaries seem fine" into a
number that changes when the summariser does.
