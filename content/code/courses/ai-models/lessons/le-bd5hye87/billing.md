---
title: Who sends the bill
version: 1
---

Hugging Face's pricing page opens with the same claim as OpenRouter's:

```
# huggingface/hub-docs@08175d0f docs/inference-providers/pricing.md
   3| Access 200+ models from leading AI inference providers with centralized, transparent, pay-as-you-go pricing. No infrastructure management required—just pay for what you use, with no markup from Hugging Face.
```

What the account starts with is small, and the page says so:

```
# huggingface/hub-docs@08175d0f docs/inference-providers/pricing.md
   9| | Account Type                     | Monthly Credits          | Can be spent on                   | Extra usage (pay-as-you-go)     |
  10| | -------------------------------- | ------------------------ | --------------------------------- | ------------------------------- |
  11| | Free Users                       | $0.10, subject to change | Inference Providers               | yes (credits purchase required) |
  12| | PRO Users                        | $2.00                    | All Hugging Face compute services | yes                             |
```

Ten cents a month is enough to try a model on lesson 5's forty cases and not enough to run a desk:
past it, credits are bought. And there are two ways for the money to flow:

```
# huggingface/hub-docs@08175d0f docs/inference-providers/pricing.md
  24| | Feature | **Routed by Hugging Face** | **Custom Provider Key** |
  25| | :--- | :--- | :--- |
  26| | **How it Works** | Your request routes through HF to the provider | You set a custom provider key in HF settings |
  27| | **Billing** | Pay-as-you-go on your HF account | Billed directly by the provider |
```

**Routed by Hugging Face**, the provider is paid through ana's Hugging Face account, one bill for
every provider, with the monthly credits applied first. **With a custom provider key**, the request
still goes through Hugging Face, but the provider bills ana directly, under the account and the
terms ana has with that provider, and the credits do not apply.

Set beside lesson 15, the two routers make the same offer with different defaults:

| | OpenRouter | Hugging Face |
|---|---|---|
| per-token price | the provider's, no markup | the provider's, no markup |
| fee on buying credits | 5.5%, at least $0.80 | none stated on the pricing page |
| default provider choice | weighted to the cheapest | the fastest |
| choosing a provider | `provider.order`, `only`, `ignore` | a suffix on the model, or `provider=` |
| bring your own provider key | yes, with a fee past a free allowance | yes |

Which is cheaper depends on the volume and on which default the code relies on, and the second is
the one to settle first, because it is decided per request and invisible in the answer. For ana,
whose evaluation in lesson 5 was of one model at one provider, a named provider in the model string
is the setting that keeps the evaluation true.
