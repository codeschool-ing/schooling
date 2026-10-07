---
title: RICE
version: 1
---

**RICE** is a scoring formula from the product-management world, published by the product team at Intercom. It is popular with product managers because it asks for numbers that product teams usually have, and because it puts **confidence** into the formula explicitly.

```localised
RICE score = reach × impact × confidence / effort
```

- **Reach**: how many people the item affects in a period — patients, receptionists, clinics per quarter.
- **Impact**: how much it affects each of them, on a fixed scale: 3 for massive, 2 for high, 1 for medium, 0.5 for low, 0.25 for minimal.
- **Confidence**: how sure the team is about the other numbers, as a percentage: 100% for evidence, 80% for a reasonable guess, 50% for a hunch.
- **Effort**: person-months of work.

## Three of the Agenda team's candidates

| feature | reach per quarter | impact | confidence | effort | score |
|---|---|---|---|---|---|
| SMS reminders | 4,000 patients | 1 | 80% | 1 | 3,200 |
| online booking | 2,500 patients | 3 | 50% | 4 | 937.5 |
| reports for clinic owners | 300 owners and managers | 2 | 80% | 2 | 240 |

SMS reminders lead again, for a different reason from WSJF's: they reach many people for little effort. Online booking's high impact is cut by **50% confidence**, because the team does not yet know how many patients will book online rather than by phone. That is the formula working as intended. The cheapest way to move online booking up is not to argue its impact but to **raise the confidence**, by running a short experiment with one clinic.

## RICE or WSJF

The two formulas answer different questions. **RICE ranks by value per unit of effort**, and is strongest when the main uncertainty is about demand. **WSJF ranks by cost of delay per unit of size**, and is strongest when timing and risk matter. RICE has no term for time criticality, so the database upgrade, valuable mainly because support for the old version is ending, would score near zero; WSJF has no term for confidence, so a hunch and a measurement weigh the same. Using both on the same backlog, and looking at where they disagree, is a good way to find the assumptions worth checking.
