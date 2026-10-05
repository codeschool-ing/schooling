---
title: One model, five addresses
version: 1
---

Claude is reached through Anthropic's own API and through the large clouds, and lesson 2 section 05
showed the prices barely move between them. What does move is **the name you call it by**:

```
ana@desk:~/desk$ python lab/card.py "Claude Haiku 4.5" "Claude API ID" "Claude API alias" "Amazon Bedrock ID" "Google Cloud ID" "Microsoft Foundry ID"
# https://platform.claude.com/docs/en/about-claude/models/overview, read 2026-10-05
Claude Haiku 4.5
  Claude API ID               claude-haiku-4-5-20251001
  Claude API alias            claude-haiku-4-5
  Amazon Bedrock ID           anthropic.claude-haiku-4-5
  Google Cloud ID             claude-haiku-4-5@20251001
  Microsoft Foundry ID        claude-haiku-4-5
```

The same weights under five spellings. On Anthropic's API the dated identifier ends in
`-20251001` and the alias drops it. Bedrock prefixes the vendor, `anthropic.`. Google Cloud puts the
date after an `@`. Microsoft Foundry uses the alias form. Lesson 2 showed Bedrock's regional
prefixes on top of that: `us.`, `eu.`, `global.`.

## Why choose a cloud over the maker's API

Not price, as lesson 2 showed. The reasons are about the account the model sits in:

- **one bill and one contract**: a company that already buys its servers from a cloud adds the model
  to the same invoice, under terms its lawyers have already read;
- **the region and the network**: requests stay inside the cloud's regions (lesson 2 section 07),
  and can be reached from the company's private network;
- **the cloud's own identity and access rules**: who may call the model is managed like who may
  read a database.

And the reasons to stay with the maker's API: new models and features usually arrive there first,
and its documentation describes it rather than a translation of it.

## What changes in the code

The request shape changes with the platform, which is one reason lesson 17 teaches Anthropic's
Messages API directly and lesson 20 the OpenAI-compatible shape many platforms also offer. **Keep
the model's name in configuration, never in code**: the same program then moves between Anthropic,
Bedrock and Vertex by changing a setting, and lesson 5's evaluation is re-run on the new address as
if it were a new candidate, which in billing, region and rate limits it is.
