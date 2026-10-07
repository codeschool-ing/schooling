---
title: The EU AI Act in one page
version: 1
---

The **Artificial Intelligence Act**, Regulation (EU) 2024/1689, entered into force on **1 August
2024**. It is not a data protection law: the GDPR keeps applying to any personal data an AI system
touches. It is a **product safety law for AI systems**, which sorts them by the risk of what they are
used for and puts obligations on whoever builds and whoever uses them.

## Who it is talking to

- the **provider** develops an AI system, or has it developed, and places it on the market or puts it
  into service under its own name;
- the **deployer** uses an AI system under its authority in a professional activity.

Ipê is a **provider** of the models it builds itself and a **deployer** of the ones it buys. The Act
reaches providers and deployers established in the Union, and those outside it **where the system's
output is used in the Union** (art. 2). That is how the Lisbon company brings it in: a system used
there, or whose output is used there, is under the Act whoever wrote it.

## Four levels of risk

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l8-ai-tiers\" aria-label=\"The four levels of risk in the EU AI Act, from the top: prohibited practices, high-risk systems, systems with transparency obligations, and minimal risk. Each of Ipê's systems sits on one level: the CV screening tool is high-risk, the support chatbot carries transparency obligations, and the fraud score and the recommender are minimal risk.\"><rect x=\"80.0\" y=\"20.0\" width=\"320.0\" height=\"45.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"240.0\" y=\"35.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">prohibited</text><text x=\"240.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">art. 5 · may not be used at all</text><text x=\"600.0\" y=\"42.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">nothing at Ipê</text><rect x=\"62.0\" y=\"75.0\" width=\"356.0\" height=\"45.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"240.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">high-risk</text><text x=\"240.0\" y=\"107.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Annex III · most of the Act</text><path d=\"M420.0 97.0 L500.0 97.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 3\"></path><rect x=\"500.0\" y=\"81.0\" width=\"200.0\" height=\"32.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"600.0\" y=\"97.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">cv-screen</text><rect x=\"44.0\" y=\"130.0\" width=\"392.0\" height=\"45.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"240.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">transparency</text><text x=\"240.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">art. 50 · say it is an AI</text><path d=\"M438.0 152.0 L500.0 152.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 3\"></path><rect x=\"500.0\" y=\"136.0\" width=\"200.0\" height=\"32.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"600.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">support-bot</text><rect x=\"26.0\" y=\"185.0\" width=\"428.0\" height=\"45.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"240.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">minimal</text><text x=\"240.0\" y=\"217.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">no specific duties</text><path d=\"M456.0 207.0 L500.0 207.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 3\"></path><rect x=\"500.0\" y=\"191.0\" width=\"200.0\" height=\"32.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"600.0\" y=\"207.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">fraud-score · recommender</text></svg>", "caption": "The class follows from what the system is used for, not from how it is built."}
```

- **Prohibited practices** (art. 5): manipulation that exploits vulnerabilities, social scoring,
  predicting crime from profiling alone, untargeted scraping of faces to build recognition databases,
  emotion recognition at work and in education, biometric categorisation inferring sensitive traits,
  and real-time remote biometric identification in public spaces for law enforcement, with narrow
  exceptions.
- **High-risk systems** (art. 6): safety components of products already regulated (Annex I), and the
  uses listed in **Annex III** — biometrics, critical infrastructure, education, **employment**,
  access to essential services including **credit scoring**, law enforcement, migration, justice and
  elections. These carry most of the Act: risk management, data governance, technical documentation,
  logging, transparency to deployers, human oversight, accuracy and robustness, registration.
- **Transparency obligations** (art. 50): people must be told they are interacting with an AI system;
  synthetic audio, images, video and text must be marked as such in a machine-readable way; deep
  fakes must be disclosed.
- **Minimal risk**: everything else, which the Act leaves alone apart from AI literacy.

General-purpose models — the large language models the others are built on — have their own chapter
(Chapter V), with obligations on their providers that apply since 2 August 2025.

## The data governance article

For a data team, **article 10** is where the Act meets this course. A high-risk system's training,
validation and test data must be subject to data governance practices: the design choices, the
collection process and the **origin** of the data, the purpose for which personal data was originally
collected, the preparation (labelling, cleaning, enrichment), the assumptions, an assessment of
whether the data is **sufficient and representative**, an examination of **possible biases**, and the
gaps found. That list is lessons 6 and 9 written as a legal obligation, for one kind of system.

## Fines

Up to **€35 million or 7%** of worldwide annual turnover for a prohibited practice; up to **€15
million or 3%** for most other obligations; up to **€7.5 million or 1%** for supplying wrong
information to authorities (art. 99). For small and medium companies, whichever of the two is lower.
