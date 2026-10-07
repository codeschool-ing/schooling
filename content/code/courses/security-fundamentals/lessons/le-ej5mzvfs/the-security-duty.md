---
title: The duty to protect, and to report
version: 1
---

The LGPD turns much of this course into a legal obligation, in a few articles worth knowing by number.

**Article 46**: controllers and operators must adopt **security measures, technical and administrative**,
able to protect personal data from unauthorised access and from accidental or unlawful destruction, loss,
alteration, communication or any improper processing. It does not list controls. It states lesson 1's
triad in legal language (unauthorised access is confidentiality, alteration is integrity, destruction and
loss are availability) and leaves the how to the organisation, as the NIST CSF does with its outcomes.

**Article 46**, paragraph 2, adds that those measures must be considered **from the design** of a product
or service through its execution: privacy and security by design.

**Article 49**: systems used to process personal data must be structured to meet security requirements,
good-practice and governance standards, and the law's principles.

### When something goes wrong: article 48

**Article 48** requires the controller to communicate to the **ANPD** and to the **affected data subjects**
any **security incident that may create relevant risk or damage** to them. The ANPD's regulation on
incident communication, **Resolution CD/ANPD no. 15 of 2024**, sets the deadline: **three working days**
from when the controller learns that the incident affected personal data.

| | what it means in practice |
|---|---|
| **what triggers it** | an incident involving personal data that may cause relevant risk or damage: sensitive data, data of children, financial data, data that enables identity fraud, large volumes, and so on |
| **who is told** | the ANPD, through its form, and the people affected, in clear language |
| **what is said** | what happened, what data, how many people, the risks, the measures taken and planned |
| **what is kept** | a record of every incident involving personal data, including those not communicated, with the reasoning |

The last row matters as much as the deadline. **Every incident is recorded**, and the decision not to
communicate one is itself documented, because the ANPD can ask why. That is lesson 3's risk acceptance in
another form: a decision with a reason and a name on it.

Three working days is short. It is only achievable if the organisation already knows what personal data it
holds and where (lesson 16's inventory), can tell what an incident touched (lessons 10 and 11's logs), and
has decided in advance who decides and who writes the communication (lesson 10's tabletop exercise).
`soc-response` lesson 21 covers breach notification under the LGPD in detail.

### The sanctions

**Article 52** lists the administrative sanctions the ANPD can apply, after a proceeding with the right of
defence. Among them:

- a **warning**, with a deadline for corrective measures;
- a **simple fine of up to 2% of the revenue** of the company, group or conglomerate in Brazil in its last
  financial year, **limited to R$ 50 million per infraction**;
- a **daily fine**, with the same limit;
- **publicising** the infraction once confirmed;
- **blocking** or **deleting** the personal data involved;
- partial suspension of the database, or of the processing activity, or prohibition of activities
  related to processing.

For a small shop, the fine is rarely the largest cost. Publicising the infraction and losing customers'
trust is lesson 2's reputational impact, and an order to delete the customer database would stop the
business. The cheapest protection against all of them is the same as against the incidents themselves.
