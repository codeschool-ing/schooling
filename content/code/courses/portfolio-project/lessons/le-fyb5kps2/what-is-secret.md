---
title: What counts as a secret
version: 1
---

A secret is anything that **grants access or proves identity**, so that a stranger holding it could act
as you or as your system. Configuration is anything that **changes how the program behaves** without
granting anything. The two are handled differently, and confusing them causes both kinds of mistake.

| secret: never in the repository | configuration: fine to commit a default |
|---|---|
| passwords for a database, an e-mail account, an admin page | the port the server listens on |
| API keys and tokens for paid or private services | the path of the database file |
| the key that signs sessions or cookies | how many days a loan lasts |
| private keys, for SSH or for TLS certificates | the name of the site, a feature switch |
| a connection string that contains a password | a connection string that does not |

**loanbook has no secrets at all.** No accounts, so no session key; SQLite, so no database password; no
e-mail, so no mail password. That is not an accident. **The cheapest secret to protect is the one you
decided not to need**, and several of lesson 6's cuts removed a secret along with a feature.

Most projects are not that lucky. An app that calls a weather API, sends e-mail or stores files in the
cloud has a key, and the rest of this lesson is about keeping it out.
