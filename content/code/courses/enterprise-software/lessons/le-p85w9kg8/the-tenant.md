---
title: The tenant
version: 1
---

At the fintech, Joana had written the sign-in service herself: a table of users, a password hash, a
token. Identity was a component she designed. At Serra Alta it is something she inherited, and it
is bigger than any system she has looked at so far. **A Microsoft tenant is the one integration
that every system in the company already has with every person in it**, and most of its
consequences are decided by people who do not think of themselves as integrators.

A tenant is one organisation's instance of Microsoft's cloud: its users and groups, its domains, its
licences and the list of applications it trusts. The directory and sign-in service inside it is
Microsoft Entra ID, which was called Azure Active Directory until Microsoft renamed it in 2023, and
you will meet both names in the same document for years. Exchange mailboxes, Teams, SharePoint,
Power Platform and Business Central online all sign their users in through it. So can any other
application that accepts one of the two common standards for delegated sign-in, SAML and OpenID
Connect.

Serra Alta's tenant was set up in 2017 and holds about 2,150 accounts. Not everybody has one: most
plant-floor staff use shared terminals and appear in no directory at all.

## Who trusts the tenant

When an application trusts the tenant, a person signs in once, to Entra ID, and the application
accepts the token it is handed instead of asking for a password of its own. That is single sign-on,
and at Serra Alta it reaches about half the estate.

| system | how staff sign in | what disabling the Entra account does there |
|---|---|---|
| Microsoft 365 (mail, Teams, SharePoint) | Entra ID | blocks every new sign-in |
| Salesforce | SAML, through Entra ID, since 2020 | blocks new sign-ins; the Salesforce user and its licence stay |
| Rota | OpenID Connect, through Entra ID | blocks new sign-ins |
| Portal B2B, staff back office | OpenID Connect, through Entra ID | blocks new sign-ins |
| SAP ECC | its own user and password | nothing |
| Documentum | its own accounts | nothing |
| Coleta | its own IBM i user profile | nothing |
| Business Central | Mantiqueira's old tenant | nothing: it is a different tenant |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 380\" role=\"img\" data-fig=\"l03-identity\" aria-label=\"Serra Alta's tenant, Entra ID with about 2,150 accounts, sits in the middle. On the left, the payroll run by an outside provider reaches it only through an HR ticket, about three working days late. On the right, four systems sign in through the tenant: Microsoft 365, Salesforce by SAML, Rota by OpenID Connect and the Portal B2B back office. Below, three systems keep their own passwords and the tenant reaches none of them: SAP ECC, Documentum and Coleta. At the bottom right, inside Mantiqueira's old tenant, Business Central and its 41 users, each with a second identity.\"><defs><marker id=\"l03-identity-es-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l03-identity-es-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"15.0\" y=\"108.0\" width=\"140.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"85.0\" y=\"123.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">payroll</text><text x=\"85.0\" y=\"136.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">outside provider</text><path d=\"M157.0 130.0 L233.0 130.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"5 3\" marker-end=\"url(#l03-identity-es-ah-amber)\"></path><text x=\"195.0\" y=\"93.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">HR ticket,</text><text x=\"195.0\" y=\"106.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">~3 working days</text><rect x=\"235.0\" y=\"98.0\" width=\"170.0\" height=\"64.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"320.0\" y=\"116.3\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Serra Alta's tenant</text><text x=\"320.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Entra ID</text><text x=\"320.0\" y=\"143.7\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">~2,150 accounts</text><text x=\"600.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">sign in through the tenant</text><rect x=\"505.0\" y=\"33.0\" width=\"190.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Microsoft 365</text><path d=\"M406.0 111.2 L503.0 50.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03-identity-es-ah-phosphor)\"></path><rect x=\"505.0\" y=\"83.0\" width=\"190.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Salesforce, SAML</text><path d=\"M406.0 123.8 L503.0 100.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03-identity-es-ah-phosphor)\"></path><rect x=\"505.0\" y=\"133.0\" width=\"190.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Rota, OpenID Connect</text><path d=\"M406.0 136.2 L503.0 150.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03-identity-es-ah-phosphor)\"></path><rect x=\"505.0\" y=\"183.0\" width=\"190.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Portal B2B back office</text><path d=\"M406.0 148.8 L503.0 200.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03-identity-es-ah-phosphor)\"></path><text x=\"240.0\" y=\"238.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--amber)\">own passwords: the tenant reaches none of these</text><rect x=\"25.0\" y=\"270.0\" width=\"130.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 3\"></rect><text x=\"90.0\" y=\"290.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">SAP ECC</text><rect x=\"175.0\" y=\"270.0\" width=\"130.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 3\"></rect><text x=\"240.0\" y=\"290.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Documentum</text><rect x=\"325.0\" y=\"270.0\" width=\"130.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 3\"></rect><text x=\"390.0\" y=\"290.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Coleta, IBM i</text><rect x=\"490.0\" y=\"250.0\" width=\"220.0\" height=\"120.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"600.0\" y=\"268.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Mantiqueira's old tenant</text><rect x=\"510.0\" y=\"293.0\" width=\"180.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"311.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Business Central</text><text x=\"600.0\" y=\"324.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">41 users, second identity</text></svg>", "caption": "Who the tenant reaches. Disabling one account closes the right-hand column and leaves the four systems at the bottom to separate tickets."}
```

Two things in that table are worth reading twice.

The first is the right-hand column for Salesforce. **Single sign-on removes a password; it does not
remove an account.** The Salesforce user record still exists after its owner leaves. It still holds
a paid licence and still owns records and reports, and anything else that authenticates as that
user, such as an API token issued last month, is untouched by the directory. The other half of the
job is provisioning: the tenant creating, changing and disabling the account inside the application
itself. Entra ID can do that for applications that support SCIM, an open standard for exactly this,
and Microsoft ships ready-made provisioning connectors for common SaaS products. Serra Alta set up
single sign-on for Salesforce and never set up provisioning, so Talita Gomes deactivates leavers by
hand when somebody remembers to tell her.

The second is the bottom four rows. Three systems keep their own passwords, and they are the three
oldest: **the systems a leaver is most likely to keep access to are the ones holding the money and
the milk.** Edson Prado's team has planned single sign-on for SAP twice and postponed it twice, both
times for a project that seemed more urgent.

## Joiners, movers and leavers

Every account in every one of those systems is created, changed and closed by some process, and
identity people call the three cases joiners, movers and leavers. At Serra Alta the source of truth
for who works there is the payroll, which an outside provider runs. Nothing connects the payroll to
the tenant. When somebody leaves, HR opens a ticket for IT, and the ticket arrives on average three
working days after the person's last day.

IT then disables the Entra account, and the four systems in the bottom half of the table wait for
somebody to open a second, a third and a fourth ticket. The external auditors found the result in
2025: 37 active SAP users belonging to people who had left, five of them with authority to release
payments. Nobody had used them, and nobody could have proved that before the audit either.

Joana's first reaction was the fintech one: automate it. Her second, better one was to draw it.
**A leaver is an integration with a deadline**: an event in one system that has to reach eight
others, and that fails silently when it reaches seven. Drawn that way it has the same questions as
any integration in lessons 9 to 11. What is the source event, who consumes it, what happens when a
consumer misses it, and how would anybody know?

Movers are worse, because nothing fails at all. A buyer who moves from purchasing to sales keeps her
purchasing authorisations unless somebody removes them, and gains the sales ones on top. After
enough moves, a long-serving employee can create a purchase order, confirm the goods arrived and
release the payment. That is the combination segregation of duties exists to prevent, and it gets
built one sensible request at a time.

## Groups as authorisation

Inside the tenant, access is granted mostly through groups. A Teams team is backed by a Microsoft
365 group, a SharePoint site grants permissions to groups, and an application that trusts the
tenant can receive a person's groups in the sign-in token and map them to its own roles. Groups can
also be dynamic: their membership is a rule over directory attributes, such as "department equals
Qualidade", recalculated when the attributes change.

That is convenient, and it has a consequence that surprised Cláudia Mendes. A lab technician at
Barbacena could not open the quality team's SharePoint site, because the department field on her
account said "Produção". HR had typed her cost centre into it, which is what the field held for
everybody hired that year. **Once a group grants access, the data that decides membership is
security data**, and whoever maintains it is making access decisions without being told. Here that
was a clerk filling in a hiring form.

## One company, two tenants

Mantiqueira came with its own tenant, under its own domain. In 2022 its mailboxes and Teams moved
into Serra Alta's tenant and its people received Serra Alta accounts. Business Central did not
move. A Business Central online environment belongs to a tenant and signs its users in through it,
so the 41 people who use Mantiqueira's ERP still sign in with their old Mantiqueira accounts. Those
accounts therefore still exist, still licensed, in a tenant whose leaver process is Felipe Arruda
remembering.

Every one of those 41 people has two identities, and every leaver among them has to be closed
twice, by two different people. Moving the ERP into Serra Alta's tenant is a project with its own
plan and its own downtime, and nobody has scheduled it. It belongs on the list of things the
acquisition left half done, and the last section of this lesson comes back to it, because any
integration with Business Central will authenticate in that old tenant too.

## Where the documents actually live

The tenant is also where Serra Alta's files are. Teams keeps the files of a channel in a SharePoint
site and the files shared in a chat in the sender's OneDrive, so the company's 400 or so teams are,
among other things, 400 document libraries nobody designed.

Officially, quality documents live in Documentum: the standard operating procedures, the lab
certificates and the audit reports, each with an approved version (lesson 5 is about what that
means). In practice the plants keep copies in their Teams channels, because a Teams folder is two
clicks away and Documentum is six. In the FSSC 22000 audit of 2025 the auditor found a superseded
pasteurisation procedure, printed from the Barbacena team's channel and taped beside the
pasteuriser. It differed from the approved one in a single temperature.

**A copy of a controlled document is an uncontrolled document.** Banning Teams would not fix that,
and neither would moving everything into SharePoint without the approval workflow. The architect's
answer is to decide which system is the record for each kind of document and to make the other one
link to it instead of holding a copy. Lesson 5 takes that up.
