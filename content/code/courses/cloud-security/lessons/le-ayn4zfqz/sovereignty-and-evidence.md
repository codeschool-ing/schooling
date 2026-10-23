---
title: Whose law reaches the data, and what you show the auditor
version: 1
---

**Keeping the data in Brazil decides which country's disks it sits on. It does not decide which
governments can order the provider to hand it over, because that follows the provider as well as the
data. And none of it counts for compliance until the clinic can show it.** This section takes the
two in turn. Everything in it comes from published law and the providers' documentation; none of it
is something a lab can run.

## Sovereignty: three dates worth knowing

**2018, the United States CLOUD Act.** It made explicit that a provider subject to United States
law must produce data in its possession, custody or control when served with a valid legal order,
**whether the data is stored in the United States or abroad**. The three large cloud providers are
United States companies. So a patient record on a disk in São Paulo, held by one of them, is within
reach of a United States order as well as a Brazilian one. The Act also gives a provider a way to
challenge an order that conflicts with the law of certain other countries, and the providers publish
how many orders they receive; neither changes the reach.

**2020, *Schrems II*.** The Court of Justice of the European Union struck down the Privacy Shield,
the arrangement under which personal data had flowed from the European Union to the United States,
on the ground that United States surveillance law did not give Europeans equivalent protection. For
a while every transfer to a United States provider needed its own justification.

**2023, the EU-US Data Privacy Framework.** The European Commission adopted a new adequacy decision
for United States companies that certify under it. It is the third arrangement of its kind, after
Safe Harbour and the Privacy Shield, and both of those ended in court.

None of these is Brazilian law, and the clinic is not in Europe. They are here because they are the
clearest record of the question sovereignty asks — **can a foreign government reach this data
through the company holding it?** — and because the LGPD's own adequacy test, in its article 34,
asks it of every country data is sent to.

What the providers sell in reply goes by names such as *sovereign cloud*: regions run by local staff,
under a local legal entity, sometimes with the encryption keys held outside the provider altogether,
one step beyond the customer managed keys of lesson 11. AWS announced a European
Sovereign Cloud in 2023. Whether any of it answers the question for a given law is a legal judgement,
and the useful engineering contribution is to know exactly where every copy and every key is.

## Compliance: evidence, from both sides of the line

An auditor asks one thing in many forms: **show me**. Lesson 2's line divides the answer.

**The provider's half is proved by the provider.** AWS, Microsoft and Google publish reports by
independent auditors on their own controls — SOC 2 reports, ISO 27001 certificates, PCI DSS
attestations — and make them available to customers; AWS through a console service called AWS
Artifact. **Not run**: it needs a real account. The clinic downloads them and files them. It does not
need to verify the provider's data centre, and could not.

**The clinic's half is proved by the clinic**, and this course has been producing that evidence
since lesson 1:

| the auditor asks | the evidence | lesson |
|---|---|---|
| where is the personal data? | the region inventory of this lesson, with its date | 17 |
| who can reach it? | the credential report, the policies attached to each identity | 6 |
| is it encrypted, and with whose key? | the bucket's default encryption and the key policy | 11 |
| who changed what, and when? | the audit trail, kept where its subjects cannot delete it | 15 |
| how do you know the configuration stays right? | the posture scan, its findings and its dated exceptions | 16 |

The `security-fundamentals` course's lessons 13 and 14 described what an auditor is for and what
ISO 27001 asks. What the cloud adds is that **most of this evidence is the output of a command**, so
it can be produced again on the morning of the audit rather than reconstructed from memory. A
screenshot shows a moment somebody chose. A command anybody can rerun, with its output and its date,
shows the state as it was, and that is what an auditor can trust.

## The course in one line, again

Lesson 1 said that in the cloud almost every defence is a setting, and so is almost every failure.
Compliance is the same sentence read by somebody outside the clinic: **every setting that protects the
patients has to be one the clinic can show.**
