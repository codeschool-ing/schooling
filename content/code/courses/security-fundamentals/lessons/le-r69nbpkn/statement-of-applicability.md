---
title: The statement of applicability
version: 1
---

Annex A is a list of 93 controls, and no organisation needs all of them in the same way. A shop with no
software developers has little use for secure coding; an organisation with no premises of its own has
little to say about secure areas. 27001 does not require every control. It requires something more
demanding: that the organisation **decides about each one and says why.**

That decision is recorded in the **statement of applicability (SoA)**, one of the documents 27001
requires. For each of the 93 controls it states:

| column | what goes in it | example row |
|---|---|---|
| control | the Annex A number and name | 8.13 information backup |
| applicable? | yes or no | yes |
| justification | why it is included or excluded, usually pointing at a risk | R2 ransomware, R5 flood (lesson 3) |
| status | implemented, partly, planned | implemented: nightly job, monthly restore test |
| reference | where the detail and evidence are | backup procedure; restore test log (lesson 12) |

And one that is excluded:

| control | applicable? | justification |
|---|---|---|
| 8.28 secure coding | no | the shop develops no software; its website is a hosted platform, covered by 5.19 to 5.22 on supplier security |

### Why it matters so much

The SoA is the **bridge between the risk assessment and the controls**. Every "yes" should trace back
to a risk in the register, and every "no" should be defensible: an auditor reads the exclusions with
particular care, because an exclusion is the easiest place to hide a control nobody wanted to
implement. "Not applicable because we have never done it" is not a justification; "not applicable
because the activity does not exist in scope" is.

It is also the document outsiders ask for. A customer evaluating the shop as a supplier can learn more
from its SoA than from its certificate: which controls apply, which are complete and which are still
planned. Many organisations share it under a confidentiality agreement for exactly that reason.

### Adding controls beyond Annex A

Annex A is not a ceiling. If the risk assessment calls for a control that is not in the list, the
organisation adds it, and 27001 expects it to. The SoA then includes it with the others. The list is a
reference to check against, so that nothing important is overlooked; the controls themselves come from
the risks.
