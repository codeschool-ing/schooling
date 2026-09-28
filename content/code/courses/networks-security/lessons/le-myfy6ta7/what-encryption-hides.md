---
title: What encryption hides from the inspector
version: 1
---

Suricata wrote a record for each protocol it could parse. Compare the one for HTTPS with the one for
plain HTTP:

```
root@fw:~# jq -c "select(.event_type==\"tls\") | .tls | {sni, version, subject, issuerdn}" /var/log/suricata/eve.json
{"sni":"www.example.com","version":"TLS 1.3","subject":null,"issuerdn":null}
root@fw:~# jq -c "select(.event_type==\"http\") | .http | {hostname, url, http_user_agent, status}" /var/log/suricata/eve.json
{"hostname":"192.168.20.10","url":"/","http_user_agent":"curl/8.5.0","status":200}
```

**From plain HTTP the inspector read everything**: the host, the path, the program making the
request, the server's answer. From TLS 1.3 it read one thing, the **SNI**, the server name the
client puts in its first message so the server knows which certificate to present. The certificate's
`subject` and `issuer` are `null`, because TLS 1.3 encrypts the certificate too. In TLS 1.2 the
certificate crossed the wire in clear, and older inspection products depended on reading it.

```
root@fw:~# jq -c "select(.event_type==\"ssh\") | .ssh | {client: .client.software_version, server: .server.software_version}" /var/log/suricata/eve.json
{"client":"OpenSSH_9.6p1","server":"OpenSSH_9.6p1"}
```

SSH is similar: the greeting lines are readable, and everything after the key exchange is not.

So against encrypted traffic, DPI is limited to **metadata**: which protocol, which server name,
how much, how often. That is still a lot. "SSH to a stranger on 443" and "TLS to a name on a
blocklist" are both decidable from it. What it cannot see is what was said.

## Decrypting on purpose: TLS inspection

Some organisations close that gap with **TLS inspection**, also called break-and-inspect. The
firewall acts as a proxy: it completes the TLS connection with the client using a certificate it
makes on the spot for the requested name, signed by the company's own authority, and opens a second
TLS connection to the real server. In between, it reads everything.

That only works because every managed computer has been told to trust the company's authority, and
the trade-offs are real:

- **The firewall now holds every employee's traffic in clear**, banking and health included, and
  becomes the most valuable machine to compromise. Most policies exempt those categories.
- **Programs that pin their certificates break**, and so does anything checking a client
  certificate, because the firewall cannot present the client's key.
- **The firewall now decides whether the real server's certificate is valid.** If its checking is
  weaker than a browser's, users are safer without it. Lesson 13 shows what an unchecked certificate
  costs.

Whether to decrypt is a policy decision with legal weight: in Brazil the LGPD applies to what the
firewall reads. Lesson 23 comes back to what may be kept.
