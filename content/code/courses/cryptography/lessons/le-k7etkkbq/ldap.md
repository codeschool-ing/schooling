---
title: LDAP and LDAPS: the directory that checks every password
version: 1
---

**LDAP is the protocol that applications use to ask a directory, Active Directory or OpenLDAP,
whether a user exists and whether their password is right.** That second question is a *bind*: the
application sends the user's name and password to the directory. Over plain LDAP, the password
crosses the network in clear text on every sign-in of every application that uses the directory.
Few things on a corporate network are more valuable to intercept.

## Vereda's directory refuses the plain way

Vereda's directory listens on both ports, and it was configured with one line,
`security simple_bind=128`, to refuse a password over a connection that is not encrypted. A plain
bind:

```
ana@lab:~/lab$ ldapwhoami -x -H ldap://ldap.vereda.example:3389 -D cn=admin,dc=vereda,dc=example -w directory-admin-lab
ldap_bind: Confidentiality required (13)
	additional info: confidentiality required
```

The server says `confidentiality required` and nothing is checked. The password still crossed the
network in that attempt, because the client sent it before the server could object, so the refusal
is a guard against **misconfigured clients**, which it makes fail loudly instead of quietly working.
The client-side rule of the previous section is what stops the password leaving at all.

## The same bind, encrypted, two ways

With StartTLS made mandatory by `-ZZ`, and the client told to trust Vereda's root:

```
ana@lab:~/lab$ LDAPTLS_CACERT=pki/root.pem ldapwhoami -x -ZZ -H ldap://ldap.vereda.example:3389 -D cn=admin,dc=vereda,dc=example -w directory-admin-lab
dn:cn=admin,dc=vereda,dc=example
```

And over LDAPS, implicit TLS on its own port:

```
ana@lab:~/lab$ LDAPTLS_CACERT=pki/root.pem ldapwhoami -x -H ldaps://ldap.vereda.example:6636 -D cn=admin,dc=vereda,dc=example -w directory-admin-lab
dn:cn=admin,dc=vereda,dc=example
```

## And without trusting the root

The same LDAPS command, without `LDAPTLS_CACERT`, so the client uses the system's trust store, which
does not contain Vereda's internal root (lesson 8):

```
ana@lab:~/lab$ ldapwhoami -x -H ldaps://ldap.vereda.example:6636 -D cn=admin,dc=vereda,dc=example -w directory-admin-lab
ldap_sasl_bind(SIMPLE): Can't contact LDAP server (-1)
```

The client refused the certificate and gave up. The message is unhelpful, *Can't contact LDAP
server*, and that is a known trap: it is the same message as a server that is down, so people
diagnose the network when the problem is trust. Adding `-d 1` to the command shows the TLS error
behind it. The fix is to install the internal root on the client, not to set `TLS_REQCERT never` in
`ldap.conf`, which turns verification off for every LDAP connection on the machine.

## In Active Directory

Microsoft's domain controllers offer LDAP on 389 and LDAPS on 636, like any directory, and have long
accepted unsigned simple binds by default. Microsoft has been moving them towards **requiring LDAP
signing and channel binding**, which ties an authenticated LDAP session to its TLS channel. On a
Windows network the audit question is the same as here: which applications still bind in clear text,
and how soon can the domain controllers refuse them.
