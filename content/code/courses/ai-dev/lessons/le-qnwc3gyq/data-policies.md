---
title: Where the data goes
version: 1
---

Everything in a request leaves your servers: the system prompt, the conversation, the documents
retrieved for it, the tool results. **Sending it to a provider is handing it to another company**,
under that company's terms. This section is the list of questions to answer before a feature
ships, because the answers differ by provider, by product and by plan, and they change.

The course does not quote any provider's terms here. They are long, they change, and a paraphrase
in a lesson goes out of date silently. Read the current text for the plan you are on.

## The questions

- **Is the data used to train models?** Ask it of the API plan you pay for. The same provider's
  consumer apps can have different terms, so the product's name settles nothing.
- **How long is it kept, and why?** A provider can keep requests for a while to look for abuse,
  and some plans offer shorter retention or none, sometimes by agreement rather than by a setting.
- **Where is it processed?** A provider may process a request in another country than the one the
  user is in. Laws on personal data, such as Brazil's LGPD or the EU's GDPR, can require you to
  know and to say so.
- **Who else touches it?** A model reached through a cloud platform or a gateway passes through
  that company too, under its own terms.
- **What does your own log keep?** The requests your relay logs are your copy of the same data,
  and the same questions apply to it.

## What to do in the code

- **Send less.** The cheapest way to protect data is not to send it: an order number instead of the
  customer's name and address, the three relevant handbook passages instead of the whole handbook.
- **Remove what the model does not need**, before the request. Lesson 11 does this for secrets and
  personal data that slip into prompts.
- **Write the answers down where the code is.** A short note beside the adapter saying which
  provider, which plan, which region and what retention gives the next person something to check
  when the terms change.
