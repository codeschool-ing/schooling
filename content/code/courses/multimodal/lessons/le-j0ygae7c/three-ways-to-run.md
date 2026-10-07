---
title: One model, three ways to run it
version: 1
---

A model published on the Hub can be run in three broad ways, and the choice decides what you install, where the data goes and how fast it runs.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"One model published on the Hub, in the middle at the top: openai/whisper-base, its weights and its card. Three arrows lead down from it. Left: transformers, the original PyTorch weights run by Python, needing the Hub or a copy of it. Middle: an ONNX export, converted once and run by onnxruntime or sherpa-onnx, which is what this lab does. Right: a hosted provider, Inference Providers or an endpoint, where the audio leaves the machine.\"><defs><marker id=\"l11way-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l11way-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"240\" y=\"16\" width=\"240\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"250\" y=\"34.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">openai/whisper-base</text><text x=\"250\" y=\"50.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">weights + model card</text><line x1=\"360\" y1=\"70\" x2=\"120\" y2=\"118\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#l11way-ah-wire)\"></line><rect x=\"20\" y=\"120\" width=\"200\" height=\"64\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"144.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">transformers</text><text x=\"30\" y=\"160.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">PyTorch weights, Python</text><text x=\"30\" y=\"174.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">needs the Hub or a copy</text><line x1=\"360\" y1=\"70\" x2=\"360\" y2=\"118\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#l11way-ah-phosphor)\"></line><rect x=\"260\" y=\"120\" width=\"200\" height=\"64\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"270\" y=\"144.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">an ONNX export</text><text x=\"270\" y=\"160.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">converted once</text><text x=\"270\" y=\"174.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">this lab: sherpa-onnx</text><line x1=\"360\" y1=\"70\" x2=\"600\" y2=\"118\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#l11way-ah-wire)\"></line><rect x=\"500\" y=\"120\" width=\"200\" height=\"64\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"510\" y=\"144.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">a hosted provider</text><text x=\"510\" y=\"160.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Inference Providers</text><text x=\"510\" y=\"174.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the audio leaves</text><text x=\"20\" y=\"222\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Same weights, three ways to run them; the choice is about where the data goes and what has to be installed.</text></svg>", "caption": "Every model in this lab came down the middle path: published on the Hub, converted to ONNX, run on the machine."}
```

**transformers**, Hugging Face's Python library, runs the original weights. For speech recognition the whole program is a few lines:

```python
from transformers import pipeline

asr = pipeline("automatic-speech-recognition", model="openai/whisper-base")
print(asr("media/call-1042.wav")["text"])
```

**It was not run for this course.** The first line of `pipeline` downloads the model from the Hub, and the Hub refused the machine this course was recorded on:

```
ana@lab:~/mm$ curl -sS -m 10 -o /dev/null -w "%{http_code}\n" https://huggingface.co/api/models/openai/whisper-base
403
```

On a machine that reaches the Hub, those three lines are the quickest way to try a model, and they bring PyTorch with them, a dependency of several hundred megabytes.

**An ONNX export** is the model converted once to an open format and run by a small runtime (onnxruntime, or sherpa-onnx on top of it). That is how every model in this lab runs: no PyTorch, no Hub at run time, the same file on a laptop, a server or a phone. The cost is that somebody has to do the conversion, and not every model has one.

**A hosted provider** runs the model for you: Hugging Face's Inference Providers route a request to a partner company, and Inference Endpoints give you a dedicated machine. `ai-models` lesson 19 calls them through the Hugging Face SDK. Nothing is installed, and **the audio or the picture leaves your machine**, which lesson 8's privacy section and the shop's policy have to allow.

| | transformers | ONNX export | hosted |
|---|---|---|---|
| installs | PyTorch and the library | a small runtime | nothing |
| needs the Hub at run time | at first use | no | no |
| where the data goes | stays | stays | to the provider |
| cost | your machine | your machine | per call |
