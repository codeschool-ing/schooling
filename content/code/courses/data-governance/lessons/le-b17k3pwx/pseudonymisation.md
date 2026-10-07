---
title: Pseudonyms for analysis
version: 1
---

Analysts at Ipê want to study buying behaviour: how often a customer comes back, how a basket
changes over a year. They need to know that two orders belong to **the same** customer, and never
**which** customer it is. That is the job of a **pseudonym**: a code that replaces the identity,
consistently, so that records still join.

The first draft is the one everybody writes:

```sql
-- A FIRST DRAFT of the analysts' export: the customer replaced by an md5.
SET ROLE ipe_owner;
COPY (
  SELECT md5(o.customer_id::text) AS customer_ref,
         date_trunc('month', o.ordered_at)::date AS month,
         o.total_cents
  FROM sales.orders o WHERE o.customer_id IS NOT NULL
  ORDER BY o.order_id LIMIT 3
) TO STDOUT WITH (FORMAT csv, HEADER true);
```

```
ana@lab:~/gov$ psql -X -q -f naive.sql
customer_ref,month,total_cents
c81e728d9d4c2f636f067f89cc14862c,2026-01-01,5990
c81e728d9d4c2f636f067f89cc14862c,2021-07-01,690
eccbc87e4b5ce2fe28308fd9f2a7baf3,2023-09-01,7970
ana@lab:~/gov$ psql -X -q -Atc "SELECT customer_id FROM generate_series(1, 6012) AS customer_id WHERE md5(customer_id::text) = '$(psql -X -q -At -f naive.sql | sed -n 2p | cut -d, -f1)'"
2
```

The export replaces `customer_id` with its MD5 and looks opaque — 32 hexadecimal characters. The
second command is what anybody holding the export can do in under a second: hash every possible id,
1 to 6,012, and see which matches. **Customer 2.** An unkeyed hash of a value from a small, known
range is not a pseudonym, it is the value written differently. The same is true of a hash of a CPF,
an e-mail address or a phone number: the space is large to a person and small to a computer.

## A pseudonym with a key

The fix is the one the CPF index used: a keyed HMAC, with a key the analysts do not hold. A separate
key, because the purpose is separate — an analytics pseudonym should never be joinable to the
support index:

```
ana@lab:~/gov$ bao write -f transit/keys/ipe-analytics-ref
Key                       Value
---                       -----
allow_plaintext_backup    false
auto_rotate_period        0s
deletion_allowed          false
derived                   false
exportable                false
imported_key              false
keys                      map[1:1791344086]
latest_version            1
min_available_version     0
min_decryption_version    1
min_encryption_version    0
name                      ipe-analytics-ref
soft_deleted              false
supports_decryption       true
supports_derivation       true
supports_encryption       true
supports_signing          false
type                      aes256-gcm96
ana@lab:~/gov$ bao write -field=hmac transit/hmac/ipe-analytics-ref input=$(printf '2' | base64); echo
vault:v1:5Vv5pnFMJl2xg+behW50khtDjpaUnl6g+cJbyySjvL4=
```

The same customer 2 now becomes a string nobody can compute without `ipe-analytics-ref`, which never
leaves OpenBao. An export built with it keeps every join an analyst needs and gives them no way back.

## What a pseudonym still is

**Pseudonymised data is personal data.** The LGPD defines pseudonymisation, in its article on
research in public health (art. 13, §4), as processing after which data can no longer be associated
with a person *except with additional information kept separately by the controller* — and Ipê holds
that information: the key, and the customer table. GDPR says the same in its own words (lesson 8).

So a pseudonymised export reduces risk and keeps every obligation:

- the analysts' access to it is still access to personal data, decided by lesson 2's rules;
- a customer's request to have their data deleted (lesson 7) reaches the export too;
- and **the pseudonym does not hide what travels with it.** An export with a pseudonym, a city, an age
  band and every purchase is a profile; if one of those purchases is unusual enough, the profile is a
  person. The next section measures how quickly that happens.
