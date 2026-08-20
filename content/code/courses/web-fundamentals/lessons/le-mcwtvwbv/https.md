---
title: HTTPS: the same HTTP, inside a tunnel
---

**HTTPS is HTTP going through TLS.** The methods, headers and codes are identical; what changes is that all of it travels encrypted.

TLS delivers three things at once, and it is worth knowing which: **confidentiality** (nobody along the path reads it), **integrity** (nobody alters it without giving themselves away) and **authenticity** (the certificate proves that server really does own the domain). The third is what the padlock stands for — and that is why a padlock does not mean "trustworthy site", it means "this really is the site whose name is in the bar".

What TLS does **not** hide: the domain name you visited and the volume of data transferred stay visible to the network. The path, the parameters and the content do not.
