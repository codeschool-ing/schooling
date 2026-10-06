---
title: Residual risk and appetite
version: 1
---

No treatment except avoidance brings a risk to zero. After the controls are in, some risk is
left, and the vocabulary has a word for each end:

- **inherent risk** is the risk before any control, as if nothing had been done;
- **residual risk** is what remains after the chosen controls are in place.

R2 had an ALE of R$ 4,000 a year before the offline backup and R$ 400 after it. The R$ 400 is the
residual risk, and it has to be accepted by somebody, exactly as an untreated risk would be. **Every
treatment ends with an acceptance of what is left.** Mitigating does not end the conversation; it
changes what is being accepted.

### How much is acceptable

**Risk appetite** is how much risk an organisation is willing to take on in pursuit of its goals,
stated in advance by its leadership. A start-up selling something new has a large appetite; a
bank, a small one. The shop's owners wrote theirs in one sentence: *"We accept risks scoring up to
6 on the matrix without further approval; anything above 6 needs a treatment plan or our signature."*

**Risk tolerance** is the acceptable deviation for a specific objective, usually as a number: the
website may be down for at most four hours a month; no more than one laptop a year may go missing
without a review. Appetite is the policy; tolerance is where the policy meets a measurement.

With an appetite written down, most decisions stop being arguments:

| risk | inherent score | after treatment | within appetite (≤ 6)? |
|---|---|---|---|
| R1 default portal password | 16 | 2 × 4 = 8 | no: needs the owners' signature |
| R2 ransomware | 10 | 2 × 2 = 4 | yes |
| R3 lost laptop | 9 | 3 × 1 = 3 | yes |
| R4 failed update | 6 | 6 | yes, accepted as it is |
| R5 flood | 4 | 4 | yes, accepted as it is |

R1 is the interesting row. After the password change and MFA, the residual score is 8, still
above the appetite of 6. The table makes the next step plain: either another control (taking the
portal off the internet brings the likelihood down to 1 and the score to 4), or the owners sign
for 8. The person who decides is the one who owns the risk, never IT on its own behalf.

### Who owns a risk

Every risk has a **risk owner**: the person accountable for deciding its treatment and for
accepting what remains. It is usually the owner of the asset at stake. The payroll file belongs
to finance, so R1's owner is bruno, who runs finance. ana in IT proposes the controls and does the
work; bruno decides whether the residual risk is acceptable. That split keeps IT from quietly
accepting risks on the business's behalf, and keeps the business from pretending a risk is
somebody else's problem.
