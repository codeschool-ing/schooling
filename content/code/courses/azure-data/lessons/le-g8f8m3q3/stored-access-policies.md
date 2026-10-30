---
title: Stored access policies, the SAS you can revoke
version: 1
---

**A stored access policy moves the permission and the expiry out of the SAS and onto the container,
where they can be changed or deleted later.** The SAS then carries only the policy's name and a
signature. When the policy goes, every SAS that names it stops working, and the account key stays
where it was. It is the answer to the question the previous section left open: how to take back a
SAS without rotating the key that every other client also uses.

The finance team's analysts need to list and read the exports for the month-end close. A policy on
the container, called `analysts`, gives them that for one day:

```
ana@laptop:~/azure$ az storage container policy create -c orders-raw -n analysts --permissions rl --expiry "$(date -u -d "+1 day" +%Y-%m-%dT%H:%MZ)" -o none
ana@laptop:~/azure$ az storage container policy list -c orders-raw -o table
Name      Expiry                Permissions
--------  --------------------  -------------
analysts  2026-10-31T19:15:00Z  rl
ana@laptop:~/azure$ CSAS=$(az storage container generate-sas -n orders-raw --policy-name analysts -o tsv 2>/dev/null)
ana@laptop:~/azure$ echo "$CSAS" | tr "&" "\n"
sv=2026-04-06
si=analysts
sr=c
sig=t3GqcW01uPtpONUBQAS2tbv8k8DfoF9rn4Gbcz%2BmjeU%3D
ana@laptop:~/azure$ curl -s "$CONTAINER?restype=container&comp=list&$CSAS" | grep -o "<Name>[^<]*</Name>"
<Name>exports/2026/10/orders-2026-10-29.csv</Name>
ana@laptop:~/azure$ az storage container policy delete -c orders-raw -n analysts -o none
ana@laptop:~/azure$ curl -s "$CONTAINER?restype=container&comp=list&$CSAS" | grep -o "<Code>.*</Code>"
<Code>AuthorizationFailure</Code>
```

**The SAS has no `sp` and no `se`.** It names the policy with `si=analysts`, the resource with
`sr=c` for the container, and the signature. The permissions `rl`, read and list, and the expiry are
the policy's, and the listing it allowed found the one export. The `2>/dev/null` on the line that made
it hides a warning the command line printed anyway, telling the user not to give an expiry or
permissions that the policy already holds, which the command had not done.

Then the policy was deleted, and the same URL, unchanged, was refused with `AuthorizationFailure`.
Nobody had to find the URL, and no other client noticed anything. Microsoft's documentation adds a
detail Azurite does not show: a change to a stored access policy can take up to 30 seconds to apply on
Azure.

## What a policy costs and limits

**A container holds at most five stored access policies**, by Microsoft's documentation. That limit
shapes the design: a policy is per group of users or per purpose, `analysts`, `auditors`,
`partner-x`, never per person and never per link. A policy can also be edited in place: shortening its
expiry shortens every SAS that names it, at once.

A policy only helps a SAS that names it. A SAS signed with `--permissions` and `--expiry` directly,
like the ones in the previous section, has nothing on the container to delete, and is revoked only by
rotating the key that signed it. **For anything handed outside the team, sign against a policy or as
a user delegation SAS.** Both can be taken back in seconds; a plain service SAS cannot.
