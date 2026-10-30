---
title: Connect Sync and Cloud Sync
version: 1
---

**Microsoft offers two programs that copy Active Directory into Entra ID, and the difference between
them is where the work happens.** Both are described from Microsoft's documentation; neither was run.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l12-sync\" aria-label=\"The two synchronisation programs side by side. On the left, Connect Sync: in the office network, a server holds the whole engine and its database, reads Active Directory and writes to Entra ID. On the right, Cloud Sync: in the office network, two light provisioning agents answer requests from a provisioning service that runs in Entra ID, which holds the configuration and the engine. Both copy from Active Directory towards Entra ID.\"><defs><marker id=\"l12-sync-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l12-sync-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"185.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">Connect Sync</text><rect x=\"20.0\" y=\"40.0\" width=\"330.0\" height=\"76.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"34.0\" y=\"56.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">Microsoft Entra ID</text><rect x=\"20.0\" y=\"170.0\" width=\"330.0\" height=\"116.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"34.0\" y=\"186.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">office network</text><rect x=\"40.0\" y=\"240.0\" width=\"120.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"100.0\" y=\"257.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Active Directory</text><text x=\"535.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">Cloud Sync</text><rect x=\"370.0\" y=\"40.0\" width=\"330.0\" height=\"76.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"384.0\" y=\"56.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">Microsoft Entra ID</text><rect x=\"370.0\" y=\"170.0\" width=\"330.0\" height=\"116.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"384.0\" y=\"186.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">office network</text><rect x=\"390.0\" y=\"240.0\" width=\"120.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"450.0\" y=\"257.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Active Directory</text><rect x=\"190.0\" y=\"200.0\" width=\"140.0\" height=\"74.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"260.0\" y=\"230.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">engine</text><text x=\"260.0\" y=\"243.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">and database</text><path d=\"M141.0 257.0 L189.0 257.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-sync-af-ah-paper-dim)\"></path><path d=\"M260.0 199.0 L260.0 117.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l12-sync-af-ah-amber)\"></path><text x=\"180.0\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a copy of the directory</text><rect x=\"540.0\" y=\"64.0\" width=\"150.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"615.0\" y=\"77.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">engine and</text><text x=\"615.0\" y=\"90.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">configuration</text><rect x=\"540.0\" y=\"214.0\" width=\"70.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"575.0\" y=\"229.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">agent</text><path d=\"M575.0 213.0 L575.0 117.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l12-sync-af-ah-amber)\"></path><rect x=\"620.0\" y=\"214.0\" width=\"70.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"655.0\" y=\"229.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">agent</text><path d=\"M655.0 213.0 L655.0 117.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l12-sync-af-ah-amber)\"></path><path d=\"M491.0 257.0 L560.0 257.0 L560.0 245.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-sync-af-ah-paper-dim)\"></path><text x=\"455.0\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a copy of the directory</text></svg>", "caption": "The same copy, made by a whole engine on the ground or by agents answering one in the cloud."}
```

## Microsoft Entra Connect Sync

**Connect Sync is a full synchronisation engine installed on a server in the company's network.** It
reads Active Directory, keeps its own database of what it has seen, works out what changed, applies
the rules that say which attributes go where, and writes the result to Entra ID. Its scheduler runs a
cycle every thirty minutes by default, and password hashes, when the company syncs them, have a
process of their own that runs every two minutes.

It is the older and the more capable of the two. It handles several forests, complex rules for
joining accounts that exist in more than one of them, and every writeback Microsoft offers. That
capability has a price: a server to patch and keep running, a database on it, and an upgrade the
company has to remember. Its predecessor, Azure AD Connect version 1, stopped being supported in
August 2022, and Microsoft's documentation warns that installations still running it may stop working
without notice. A synchronisation server is the kind of machine everybody forgets until it is the
reason nobody new can sign in.

## Microsoft Entra Cloud Sync

**Cloud Sync moves the engine into Entra ID and leaves only an agent on the ground.** The
*provisioning agent* is a small program on a server in the network. It keeps an outbound connection
to Microsoft, listens for requests, queries Active Directory when the cloud service asks, and sends
back what it finds. The configuration, the scheduling and the processing live in the cloud.

**Several agents can run at once, on different servers**, and Microsoft's documentation describes the
failover between them as automatic: losing one server does not stop synchronisation. Nothing is
installed but the agent, so there is no database to keep. It suits a company with a simple directory,
a company joining several small directories after an acquisition, and any company that would rather
not run one more server.

## Choosing

| | Connect Sync | Cloud Sync |
|---|---|---|
| what sits on premises | the whole engine, with its database | a light agent |
| high availability | one active server, with a standby you configure | several active agents, failing over on their own |
| where it is configured | on the server | in Entra ID |
| complex directories and every writeback | yes | not every scenario |

Microsoft's own advice, in the Cloud Sync documentation, is to move from Connect Sync to Cloud Sync
where the scenario is supported, using its migration tool where the installation qualifies, and to
stay on Connect Sync where it is not. **The shop has one forest, one domain and a few hundred people**,
so Cloud Sync fits, with two agents on two servers. A company with several forests and accounts that
must be joined across them is the case Connect Sync still exists for.

Whichever runs, the synchronisation itself is now a dependency of signing in for everybody whose
account is born on the ground. **Monitor it as a service**, with an alert on its health: a
synchronisation that stopped on Friday is a Monday with new employees who do not exist in the cloud
and leavers who still do.
