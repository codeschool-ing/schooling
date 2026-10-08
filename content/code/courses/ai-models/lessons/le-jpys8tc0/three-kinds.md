---
title: Closed, open-weight and open source
version: 1
---

The everyday words for this are *closed* and *open*, and they hide a third case that is the
commonest of all. Sort models by **what you are given**, and there are three:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Three kinds of model by what you are given. Closed: an endpoint and a key, with the weights kept by the provider. Open-weight: the weights, under a licence with conditions. Open source: the weights under a licence without conditions, and in the strictest definition also the training code and information about the data.\"><defs><marker id=\"l2kinds-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"30\" y=\"20\" width=\"180\" height=\"200\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"120\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--phosphor)\">closed</text><text x=\"120\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">you get</text><text x=\"120\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">an endpoint</text><text x=\"120\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">an API key</text><text x=\"120\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">the provider keeps the weights</text><rect x=\"270\" y=\"20\" width=\"180\" height=\"200\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--phosphor)\">open-weight</text><text x=\"360\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">you get</text><text x=\"360\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the weights</text><text x=\"360\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a licence</text><text x=\"360\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">with conditions</text><rect x=\"510\" y=\"20\" width=\"180\" height=\"200\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"600\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--phosphor)\">open source</text><text x=\"600\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">you get</text><text x=\"600\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the weights</text><text x=\"600\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a licence</text><text x=\"600\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">without conditions</text><text x=\"600\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">and, strictly, the</text><text x=\"600\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">training code and</text><text x=\"600\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">data information</text><line x1=\"40\" y1=\"245\" x2=\"680\" y2=\"245\" stroke=\"var(--wire)\" stroke-width=\"1.2\" marker-end=\"url(#l2kinds-ah)\"></line><text x=\"360\" y=\"260\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">more of the model is in your hands</text></svg>", "caption": "Sorted by what you are given. Most “open models” are the middle column, and the licence is where the openness is measured."}
```

**Closed.** You get an endpoint. The weights never leave the provider; you send a request, pay
per token, and accept their terms of service. Claude, Gemini and the GPT family are offered this
way. Lessons 6 to 9 go through them one by one.

**Open-weight.** You get the weights, to download and run wherever you like, under a **licence the
makers wrote**. This is what most people mean by an "open model", and the licence is where the
openness is measured. Meta's grant for Llama 3.1 is generous in its verbs and careful in its
adjectives:

```
# meta-llama/llama-models@0e0b8c51 models/llama3_1/LICENSE
  21: a. Grant of Rights. You are granted a non-exclusive, worldwide, non-transferable and
      royalty-free limited license under Meta’s intellectual property or other rights owned by
      Meta embodied in the Llama Materials to use, reproduce, distribute, copy, create
      derivative works of, and make modifications to the Llama Materials.
```

*Non-exclusive, non-transferable, limited*: it is permission, with conditions that section 03
reads. The weights are yours to run; the terms come with them.

**Open source.** The weights under a licence that sets no conditions on use, often one of the
licences software has used for decades. DeepSeek says this of R1, in its own README:

```
# deepseek-ai/DeepSeek-R1@0cf78561 README.md
 257: This code repository and the model weights are licensed under the [MIT
      License](https://github.com/deepseek-ai/DeepSeek-R1/blob/main/LICENSE).
```

The Open Source Initiative's definition of open-source AI asks for more still: enough information
about the training data, and the code that trained it, for somebody else to study and rebuild the
model. Very few released models meet that. **For choosing, the line that matters is the licence**:
whether it sets conditions you have to check against your use.

## What each one costs you

| | closed | open-weight | open source |
|---|---|---|---|
| you hold | an API key | the weights, under conditions | the weights, without conditions |
| you pay | per token | for the machine that runs it, or a host per token | the same |
| it changes when | the provider decides | you download a new version | the same |
| your data goes | to the provider | wherever you run it | the same |

The rest of this lesson takes those rows one at a time: the conditions (section 03), the licences
that apply to code and not to weights (04), the price (05), the change (06), and the data (07).
