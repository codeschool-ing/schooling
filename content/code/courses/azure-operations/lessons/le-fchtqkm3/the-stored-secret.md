---
title: A secret in the settings, and why it is the problem
version: 1
---

**A workflow that deploys to Azure acts as an identity in Microsoft Entra ID**: an app registration
with its service principal, given a role on the shop's resource group. `azure-foundations` lessons 7
and 9 build that identity and that role. This lesson is about the other half: how the workflow proves,
at run time, that it is that identity.

For years the answer was a **client secret**. You created one on the app registration, copied it with
the tenant and client ids into a JSON blob, and pasted the blob into the repository's secrets:

```yaml
# the old way: a secret that lives as long as somebody remembers it
- uses: azure/login@v2
  with:
    creds: ${{ secrets.AZURE_CREDENTIALS }}
```

It works, and everything about it is the problem.

- **The secret is the identity.** Whoever holds the string is the service principal, from any machine,
  until it expires. It does not know it was meant for one workflow in one repository.
- **It lives for months or years**, because rotating it means somebody remembering to, and the maximum
  lifetime Microsoft allows is long enough to forget.
- **It travels.** It was in somebody's clipboard, perhaps in a chat, perhaps in a log line a step
  printed by mistake. Each copy is as good as the original, and none of them shows up anywhere.
- **Revoking it is a guess about what breaks.** Nothing records which workflows use it.

A secret masked in logs and kept in an encrypted store is better than one in a file, and it is still a
long-lived credential that a step of your own workflow could leak. What removes the problem is not
storing one at all.
