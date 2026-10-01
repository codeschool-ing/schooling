---
title: Community clouds and sovereign clouds
version: 1
---

A **community cloud** sits between the other two. It is provisioned for a group of organisations
that share concerns — a mission, security requirements, a policy, a regulator — and it may be run
by one of them, by several, or by a third party, on or off their premises. The tenants are not
anybody who signs up, and not one organisation either: **membership is the boundary**.

The clearest large examples are the government regions of the big providers. AWS GovCloud (US)
and Azure Government are regions set apart for US government agencies and the companies that work
for them, physically and logically separate from the providers' commercial regions, and operated
under rules about who the staff may be. They run the provider's software, and they are not open to
the public: an organisation has to qualify before the provider lets it in. That is the community model at
continental scale. Smaller ones exist wherever a sector pools infrastructure, such as universities
sharing a research cloud.

## Sovereign: a label, not a model

*Sovereign cloud* is not one of NIST's four, and no single definition of it exists. It is a label
that providers and governments use for offers that promise **control over jurisdiction and over
operators**, and the promises break into separate questions:

- where the data and the machines physically are;
- who may operate them and reach the data: staff of which nationality, resident where;
- which country's courts can order the provider to hand the data over;
- who holds the encryption keys, which `cloud-security` covers in depth.

The first question is the one people think of, and a region answers it: data in `sa-east-1` is in
São Paulo. **The third question is the one a region does not answer.** A provider incorporated in
one country is subject to that country's law wherever its datacentres stand. The United States'
CLOUD Act, of 2018, is the example usually cited: it lets US authorities require a US provider to
produce data in its possession or control, including data stored outside the United States. A
company that needs the answer to be "only our own country's courts" is asking about the legal
entity that runs the service, and no choice of region changes that.

That is why sovereign offers take different shapes: a region operated by a separate local company,
a partnership in which a local firm runs the provider's software, staff restricted to citizens or
residents, keys held outside the provider. Each fixes some of the four questions and not
necessarily the others. **Read what a particular offer fixes**, rather than what the word
suggests, and check it against the rule you are actually trying to meet. The data-residency
section does that for the Brazilian rule.
