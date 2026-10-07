---
title: How much you may spend
version: 1
---

A rate limit bounds how fast money is spent; a cap bounds how much. Providers set one and let the
account set a lower one. Anthropic's, in its own words:

```
# https://platform.claude.com/docs/en/api/rate-limits, read 2026-10-07
 233: Each of the Start, Build, and Scale tiers carries a monthly spend cap, which is the
      maximum your organization can spend on the API each calendar month. You can view your
      organization's monthly spend cap and set your own limit on the
 307: Enter a new value. Your spend limit cannot exceed your current tier's cap.
 311: You have reached your specified API usage limits
```

A cap per tier, chosen by the provider, and a spend limit below it, chosen by ana. Past either, the
API refuses with a message that says so and says when access resumes. The cap is there to protect
the provider and the account's balance; **the spend limit is ana's own protection**, and its right
value is lesson 4's monthly estimate with room for a bad week, not the tier's cap.

A router adds a narrower one. OpenRouter's documentation lists three sources of credit limits, and
the second is the one that matters to a desk with several programs:

```
# OpenRouterTeam/docs@3e840a21 api_reference/limits.mdx
 130: 2. **Per-key credit limits**, an optional spending cap configured on an individual API
      key. The `limit`, `limit_reset`, and `limit_remaining` fields in the `GET /api/v1/key`
      response above describe this cap and how much of it remains.
```

**A limit per key.** One program's key can run dry while another keeps working. openrouter.ai was
refused by the network of the machine this course was recorded on, so the limit cannot be run into
here; the documentation says what a program sees when it is:

```
# OpenRouterTeam/docs@3e840a21 api_reference/limits.mdx
 164: - **Check `error.metadata.limit_source`** in the response body.
      `openrouter_in_flight_budget` means your running and recently completed requests filled
      your [in-flight spending budget](#in-flight-spending-budget), not your balance: wait for
      the `Retry-After` header and retry. `openrouter_key_limit` means the API key's credit
      limit is exhausted. `openrouter_credits` means your balance cannot cover the request, or
      the single request is too expensive for your in-flight budget.
```

The error carries a `limit_source` that says which limit it was: the key's, the account's
balance, or the budget OpenRouter holds for requests still running. That last one exists because
of a gap every cap has, and the documentation explains it:

```
# OpenRouterTeam/docs@3e840a21 api_reference/limits.mdx
 135: OpenRouter charges a request when it finishes, so many requests running at the same time
      could commit more than your balance covers before any of them settles. To prevent that,
      OpenRouter estimates each paid request's token cost up front, at the endpoint's prices:
      the input tokens, plus the completion tokens allowed by `max_tokens` up to a fixed per-
      request cap (the cap is used when `max_tokens` is not set). Only token prices are
      estimated; per-request fees, plugin charges, and image pricing are not part of the
      estimate, so a request whose cost has no token component is not held. The estimate is
      held against your account while the request runs. When the request completes or fails,
      the hold is replaced by the request's actual cost for a short settlement window, and
      then released.
```

A request is charged when it **ends**, so a limit checked when it starts can be passed by the
requests already running. OpenRouter narrows the gap by holding an estimate, built from
`max_tokens`; a request without one is estimated at a fixed cap. No cap anywhere can be read as a
promise to the cent: **a limit stops the next request, not the one already running.**
