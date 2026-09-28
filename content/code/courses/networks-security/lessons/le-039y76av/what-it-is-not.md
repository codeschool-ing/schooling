---
title: What Zero Trust is not
version: 1
---

Zero Trust is sold more than it is explained, and three misreadings do real damage.

**It is not a product.** A vendor can sell a policy enforcement point, an identity provider or a remote
access gateway, and each can be part of a Zero Trust design. None of them is one. The design is the
decision to authenticate and authorise every request on identity, applied service by service, and it
can be built, as this lesson did, from TLS and a certificate authority.

**It is not the end of network controls.** The lab kept its firewall. The application's port is open
only from the servers side, the DMZ still reaches only what it needs, and the staff LAN still cannot
touch the database. If an identity check has a flaw, the network limits who can even try it. The two
layers answer different questions, *can this packet arrive here* and *may this subject do this*, and a
design that drops the first has one control where it had two.

**It is not done once.** Every service brought under identity-based access is a migration: issue
identities, change the clients, remove the old path, which is the part people skip. The lesson's
firewall change that deleted the two rules to 8080 is the step that made the new check mean anything;
while the old port stays open, the identity check is a front door beside an open window.

A practical order of work, which most organisations follow in some form:

| step | what it covers |
|---|---|
| inventory | every service, who uses it, and how they authenticate today |
| identities | people through single sign-on with multiple factors; machines through certificates |
| the most valuable services first | admin interfaces, finance, the data that would hurt most to lose |
| remove the network-only path | the old port, the VPN route that bypassed the check |
| log every decision with its identity | so the next incident starts with *who* |
