---
title: What running a model involves
version: 1
---

"Self-hosting" sounds like one decision. It is four, stacked, and each layer is something an API
provider was doing for you without mentioning it:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Four layers a self-hosted model needs, from the bottom: the hardware with its accelerator memory, the weights loaded into it, the runtime that generates tokens, and a server that exposes an endpoint. Around all four, the work of keeping it running. An API provider runs all of it for you.\"><defs><marker id=\"l3stack-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"14\" width=\"680\" height=\"272\" rx=\"4\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"360\" y=\"32\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">keeping it running</text><text x=\"360\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">updates, patches, monitoring, scaling, on call</text><rect x=\"160\" y=\"220\" width=\"400\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"232.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the hardware</text><text x=\"360.0\" y=\"248.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">accelerator memory decides what fits</text><rect x=\"160\" y=\"174\" width=\"400\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the weights</text><text x=\"360.0\" y=\"202.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a file, at some precision</text><rect x=\"160\" y=\"128\" width=\"400\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the runtime</text><text x=\"360.0\" y=\"156.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">loads them, generates tokens</text><rect x=\"160\" y=\"82\" width=\"400\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">a server</text><text x=\"360.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">an endpoint, a queue, logs</text><line x1=\"630\" y1=\"82\" x2=\"562\" y2=\"102\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" marker-end=\"url(#l3stack-ah)\"></line><text x=\"640\" y=\"76\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">your program calls here</text></svg>", "caption": "An API provider runs every layer, and the frame around them, for every customer at once."}
```

**The weights**, a file or a set of files: billions of numbers at some precision. Section 03
works out how big, section 04 how to make them smaller.

**A runtime**, the program that loads the weights onto the hardware and generates tokens: reading
the prompt, producing one token at a time, applying the chat template from lesson 1 section 04.
llama.cpp, vLLM and Ollama are three; lesson 14 runs the last. Each supports some model formats and
some hardware and not others.

**The hardware**, and in practice the one number that decides whether a model runs at all: **the
memory of the accelerator** it runs on. A model whose weights do not fit in memory does not run
slowly; it does not run, or runs from slower memory at a fraction of the speed.

**A server**, which turns the runtime into something a program can call: an HTTP endpoint,
authentication, a queue for when two requests arrive together, logs, a health check, and a way to
restart it at three in the morning. Most runtimes ship a basic one, usually shaped like OpenAI's
API so that existing code can point at it (lesson 20).

## The part nobody draws

Around all four sits the work of **keeping it running**: updating the runtime, patching the
machine, watching memory and latency, adding a second machine when one is not enough, and
noticing when it stops. Section 07 is about that work, because it is the line of the bill that
is easiest to leave out and the one that decides most often.

The question for the rest of this lesson is simple to state. **An API charges per token for all
of this. When does doing it yourself cost less, or give you something an API cannot?**
