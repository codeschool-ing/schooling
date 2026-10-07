---
title: A certificate nobody validated
version: 1
---

Everything in lessons 10 to 12 comes down to one decision the client makes: **is this certificate,
for this name, signed by an authority I trust?** Skip that check and the encryption still happens,
perfectly, with whoever answered.

On `remote`, a machine that is not the shop runs a TLS server with a certificate it made for itself,
claiming to be `www.example.com`. `laptop` connects to it as the shop, the way traffic arrives at the
wrong machine through a bad DNS answer (lesson 8) or a lie in ARP (lesson 7). The impostor is two
commands on `remote`, as root:

```sh
cd /root; openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:P-256 -nodes -days 30 -subj "/CN=www.example.com" -keyout fake.key -out fake.crt 2>/dev/null
setsid openssl s_server -accept 8443 -cert fake.crt -key fake.key -www -quiet </dev/null >/dev/null 2>&1 &
```

```
ana@laptop:~$ curl -sS -o /dev/null --connect-to www.example.com:443:203.0.113.50:8443 https://www.example.com/; echo "exit $?"
curl: (60) SSL certificate problem: self-signed certificate
More details here: https://curl.se/docs/sslcerts.html

curl failed to verify the legitimacy of the server and therefore could not
establish a secure connection to it. To learn more about this situation and
how to fix it, please visit the web page mentioned above.
exit 60
```

`curl` refused: **`self-signed certificate`**, exit 60. The certificate claims the right name, and the
check still fails, because nothing the client trusts vouches for it:

```
ana@laptop:~$ openssl s_client -connect 203.0.113.50:8443 -servername www.example.com </dev/null 2>/dev/null | grep -E "^ *0 s:|^ *i:|^Verify return code"
 0 s:CN = www.example.com
   i:CN = www.example.com
Verify return code: 18 (self-signed certificate)
```

The subject and the issuer are the same, `CN = www.example.com`; return code 18. Now the same request
with `-k`, which tells `curl` to skip the check:

```
ana@laptop:~$ curl -sk -o /dev/null -w "%{http_code} from %{remote_ip}\n" --connect-to www.example.com:443:203.0.113.50:8443 https://www.example.com/
200 from 203.0.113.50
```

**`200` from `203.0.113.50`.** The connection was encrypted, and it was encrypted to the wrong machine.
Anything sent over it, a password, a session cookie, an order, went to whoever runs `remote`. Nothing
on the screen distinguished it from the real shop.

That is the whole danger of turning verification off, and why it is turned off so often: it makes an
error go away. The error was the defence. The fix for `self-signed certificate` on an internal service
is lesson 12's: a certificate from the company's CA and its root in the client's trust store. It is
never `-k`.
