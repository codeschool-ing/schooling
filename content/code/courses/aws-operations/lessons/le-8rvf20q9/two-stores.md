---
title: Two stores, and what each is for
version: 1
---

A program needs values it should not carry: a database password, an API key for the payment provider,
the address of the database itself. Written into the code, they are in every copy of the repository,
every container image and every laptop that ever cloned it, and changing one is a release. **They
belong outside the code, in a store the program asks at run time**, and AWS has two such stores that
overlap more than their names suggest.

**Parameter Store**, part of Systems Manager, keeps named values in a hierarchy, `/shop/prod/db/host`,
of three types: `String`, `StringList`, and `SecureString`, which is encrypted with a KMS key. Standard
parameters are free, up to 10,000 of them and 4 KB each. Advanced parameters hold up to 8 KB, accept
expiry policies, and cost a monthly fee each.

Secrets Manager keeps secrets: encrypted values, usually a small JSON document, with
**versions labelled by stage** and a built-in way to rotate them, run a function that changes the
password in the database and in the secret together. It can generate passwords, replicate a secret to
other regions, and carry a resource policy saying who may read it. Every secret costs a monthly fee,
and so do the calls.

| | Parameter Store, standard | Secrets Manager |
|---|---|---|
| holds | strings, lists, encrypted strings, 4 KB | encrypted values, 64 KB |
| versions | numbered, with labels | numbered, with stages `AWSCURRENT`, `AWSPREVIOUS`, `AWSPENDING` |
| rotation | none built in | a function on a schedule, or managed by RDS |
| price | free | a fee per secret and per 10,000 calls |

## The prices, from the list

```
ana@laptop:~/aws$ python3 price.py AWSSecretsManager
AWSSecretsManager, sa-east-1, published 2026-09-11
  SAE1-AWSSecretsManager-Secrets           0.400000 USD per Secrets    $0.40 per Secret
  SAE1-AWSSecretsManagerAPIRequest         0.000005 USD per API Requests $0.05 per 10000 API Requests
ana@laptop:~/aws$ python3 price.py AWSSystemsManager Parameter
AWSSystemsManager, sa-east-1, published 2026-10-08
  SAE1-PS-Advanced-Param-Tier1             0.000070 USD per Hour       $0.05 per Advanced Parameter per Month in South America (Sao Paulo)
  SAE1-PS-Param-Processed-Tier1            0.000005 USD per API Request $0.05 per 10,000 Advanced Parameter API interaction_Standard throughput in South America (Sao Paulo)
  SAE1-PS-Param-Processed-Tier2            0.000005 USD per API Request $0.05 per 10,000 Parameter API Interaction_Higher throughput in South America (Sao Paulo)
```

**40 cents a month per secret, and 5 cents per 10,000 calls.** Parameter Store prints no line for a standard parameter because it has none. The lines it prints are the
advanced tier, 5 cents a month per parameter (the program shows its hourly rate), and the
higher-throughput setting, which charges 5 cents per 10,000 calls for every parameter once it is
switched on. An encrypted value, in either store, also
costs the KMS calls that decrypt it, which lesson 18 prices.

So the shop's six secrets cost 2.40 USD a month to keep. What they cost to read depends entirely on how
often the code asks, and the section on reading is about that number.

## Which one

A rule that holds up in practice: **configuration goes in Parameter Store, and credentials that should
change go in Secrets Manager.** A database password, which rotation can change every thirty days without
anybody touching it, is worth 40 cents a month. A feature flag or a host name is not a secret, and a
`SecureString` holding an API key that nobody will ever rotate is a reasonable use of the free tier. The
one wrong answer is the code.
