---
title: Password hash sync, pass-through and federation
version: 1
---

**Copying the account answers who a person is in Entra ID. It does not answer how they prove it.**
When `ana@shop.example` types a password into Microsoft's sign-in page, somebody has to check it, and
there are three choices of who. Microsoft's documentation calls the first two *cloud authentication*
and the third *federation*.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l12-methods\" aria-label=\"Who checks the password in each of the three sign-in methods. With password hash synchronisation, Entra ID checks it against a hash it was sent. With pass-through authentication, Entra ID passes it to an agent in the office, which asks Active Directory. With federation, Entra ID sends the person to the company's own federation server, which checks it and sends them back with a signed statement.\"><defs><marker id=\"l12-methods-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"130.0\" y=\"26.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">method</text><text x=\"450.0\" y=\"26.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">who checks the password</text><text x=\"660.0\" y=\"26.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">needs the office</text><rect x=\"30.0\" y=\"50.0\" width=\"200.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"130.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">password hash sync</text><path d=\"M231.0 70.0 L269.0 70.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-methods-af-ah-paper-dim)\"></path><rect x=\"270.0\" y=\"50.0\" width=\"360.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"450.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Entra ID, against a synchronised hash</text><text x=\"660.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">no</text><rect x=\"30.0\" y=\"108.0\" width=\"200.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"130.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">pass-through</text><path d=\"M231.0 128.0 L269.0 128.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-methods-af-ah-paper-dim)\"></path><rect x=\"270.0\" y=\"108.0\" width=\"360.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"450.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">an agent in the office, asking Active Directory</text><text x=\"660.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">yes</text><rect x=\"30.0\" y=\"166.0\" width=\"200.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"130.0\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">federation</text><path d=\"M231.0 186.0 L269.0 186.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-methods-af-ah-paper-dim)\"></path><rect x=\"270.0\" y=\"166.0\" width=\"360.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"450.0\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the company's federation server</text><text x=\"660.0\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">yes</text></svg>", "caption": "The further the check sits from the cloud, the more the office must be up for anybody to sign in."}
```

## Password hash synchronisation

**Entra ID checks the password itself, against a hash it was sent.** The synchronisation copies, every
two minutes, a hash derived from the hash Active Directory already stores; Microsoft's documentation
is explicit that no password is stored in clear text or in a form that can be reversed. Signing in
then needs nothing on the ground at all: the office can lose its power and its internet, and people
working from home still sign in to Azure.

Microsoft's documentation describes it as the method with the least effort to deploy and run. It
also carries a benefit the other two do not have: with the hashes in the cloud, **Entra ID can tell a
company that one of its users' passwords has appeared in a leak**, and it needs those hashes for that
report whichever sign-in method the company chose. Its weakness is timing: an account disabled on the
ground is still enabled in the cloud until the next synchronisation carries the change.

## Pass-through authentication

**Entra ID receives the password and hands it to an agent on the ground, which asks Active Directory.**
The agents, light programs on servers in the network, keep only outbound connections to Microsoft,
so nothing has to be opened to the internet. Microsoft recommends three of them for availability.

It suits a company that must enforce, at the moment of sign-in, what Active Directory says: an account
just disabled, a password just expired, hours outside which a person may not log in. The price is
that signing in now depends on those agents and the domain controllers behind them. **A company that
chooses it should sync the hashes as well**, as Microsoft's documentation advises: a fallback the day
the agents cannot answer, and the source of the leaked-credentials report.

## Federation

**Entra ID sends the person away to another system, which checks the password and sends them back
with a signed statement.** For most companies that system was Active Directory Federation Services,
AD FS, a farm of servers on the ground and proxies in front of them. Federation can do things the other
two cannot, such as sign-in with a smart card checked on premises, and it moves the whole of signing in
onto infrastructure the company runs, patches and keeps available.

That is why Microsoft's documentation offers *staged rollout*, a way to move groups of users from
federation to cloud authentication a few at a time, and why the direction of travel for most
companies is towards the first method. **The shop chose password hash synchronisation**: it has no
requirement the other two answer, and the fewer servers that stand between a person and Azure, the
fewer that can be down.

## Asking Entra ID how a domain signs in

Before a person types a password, Microsoft's sign-in page has to know where to send them: to its own
password box, or to a company's federation server. It asks Entra ID, at an address anybody can call.
**Microsoft does not document this address as an API**, so read its fields as an observation rather
than a contract; the answers below are Entra ID's own:

```
ana@laptop:~/azure$ curl -sS 'https://login.microsoftonline.com/getuserrealm.srf?login=ana@shop.example&json=1' | jq '{NameSpaceType, DomainName}'
{
  "NameSpaceType": "Unknown",
  "DomainName": null
}
ana@laptop:~/azure$ curl -sS 'https://login.microsoftonline.com/getuserrealm.srf?login=ana@microsoft.com&json=1' | jq '{NameSpaceType, DomainName}'
{
  "NameSpaceType": "Managed",
  "DomainName": "microsoft.com"
}
```

`shop.example` is a name reserved for examples, which no tenant can own, and the answer says so:
`Unknown`, no domain. `microsoft.com` is Microsoft's own, and its answer is `Managed`: **people at
Microsoft sign in with cloud authentication**, at Entra ID's own page, rather than through a
federation server. A company that federates gets `Federated`, with the address of its federation
server beside it, and that is exactly how the sign-in page knows to send its people there.

This is the only part of the lesson the lab can show, and it shows the end of the chain rather than
the chain: which of the three methods a domain uses, as Entra ID tells everybody who asks.
