---
title: The list of authorities a machine trusts
version: 1
---

Every system ships a **trust store**: the root certificates it will accept at the top of a chain. On
Ubuntu they are in `/etc/ssl/certs`, gathered into one bundle file that programs such as `curl` read:

```
ana@laptop:~$ ls /etc/ssl/certs/*.pem | wc -l
123
ana@laptop:~$ grep -c "BEGIN CERTIFICATE" /etc/ssl/certs/ca-certificates.crt
122
ana@laptop:~$ openssl x509 -in /etc/ssl/certs/example-root-ca.pem -noout -subject -issuer -enddate
subject=O = Example Trust Services, CN = Example Root CA
issuer=O = Example Trust Services, CN = Example Root CA
notAfter=Sep 22 17:03:47 2036 GMT
```

122 certificates in the bundle, and each one is an organisation that can vouch for any name on the
internet. The lab's own root is among them, added when the lab was built; its `subject` and `issuer`
are the same, which is what makes it a root. It is valid until 2036, as roots usually are for a decade
or more.

On a real Ubuntu the list comes from the `ca-certificates` package, which follows Mozilla's list, and
updates arrive with the system's updates (operating-systems lesson 16). Windows keeps its own list,
updated by Windows Update; macOS keeps one in the system keychain; Firefox carries its own; Java
programs often carry another. **A certificate can be accepted by one program and refused by another
on the same machine**, and when that happens the two trust stores are the first thing to compare.
