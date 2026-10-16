---
title: Guardrails and the success criterion
version: 1
---

A change can raise its primary metric and do damage somewhere else. A one-step checkout that hides
the delivery fee until the order arrives will raise conversion and refunds together. **Guardrail
metrics** are the numbers that must not get worse, written down with the primary one:

- **refund and complaint rate**, so that conversion is not bought with disappointment;
- **page load time and error rate**, so that a slow or broken version is caught;
- **average first-order value**, so that a version selling smaller boxes is noticed.

A guardrail is not tested for improvement. It is watched for harm, and a clear harm stops the test
whatever the primary metric says.

## The success criterion

The last part, and the one most often skipped, is the rule that turns the result into a decision,
written before the data exists. For Panela's test it reads:

| | |
|---|---|
| **ship** | conversion rises, the difference is significant at 5 per cent two-sided, and no guardrail is clearly worse |
| **do not ship** | conversion falls significantly, or a guardrail is clearly worse |
| **inconclusive** | anything else; the test ran for its planned length and the effect, if any, is smaller than it could detect |

and two practical lines:

- the test runs for **the number of visitors lesson 8 computes, in whole weeks**, and is not stopped
  early because it looks good (lesson 11 shows what early stopping does);
- **an inconclusive result is a result**: it says the effect is smaller than 0.6 points, if it
  exists, and that is enough to decide whether the change is worth keeping on other grounds.

## Write it all down

Everything in this lesson fits on one page, and teams that run many tests keep that page as a
template: the change, the hypothesis with its size and reason, the primary metric and its unit, the
secondary metrics, the guardrails, the success criterion, the planned sample and duration, and the
date it was written. **Writing it before the test is the whole point**: a criterion chosen after
seeing the data is a description of the data, not a test of it.
