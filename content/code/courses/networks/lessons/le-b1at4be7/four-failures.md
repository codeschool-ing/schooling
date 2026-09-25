---
title: Four ways a certificate fails
version: 1
---

The same web server also answers for four more names, each with a broken certificate. Each failure has
its own message, and each points somewhere different.

**Expired.** The dates are in the past:

```
ana@laptop:~$ curl -sS -o /dev/null https://expired.example.com/
curl: (60) SSL certificate problem: certificate has expired
More details here: https://curl.se/docs/sslcerts.html

curl failed to verify the legitimacy of the server and therefore could not
establish a secure connection to it. To learn more about this situation and
how to fix it, please visit the web page mentioned above.
ana@laptop:~$ openssl s_client -connect expired.example.com:443 -servername expired.example.com </dev/null 2>/dev/null | openssl x509 -noout -dates
notBefore=Jun  1 00:00:00 2025 GMT
notAfter=Aug 30 00:00:00 2025 GMT
```

**Self-signed.** Nobody vouched for it; the `issuer` is the certificate itself:

```
ana@laptop:~$ curl -sS -o /dev/null https://selfsigned.example.com/
curl: (60) SSL certificate problem: self-signed certificate
More details here: https://curl.se/docs/sslcerts.html

curl failed to verify the legitimacy of the server and therefore could not
establish a secure connection to it. To learn more about this situation and
how to fix it, please visit the web page mentioned above.
ana@laptop:~$ openssl s_client -connect selfsigned.example.com:443 -servername selfsigned.example.com </dev/null 2>/dev/null | openssl x509 -noout -subject -issuer
subject=CN = selfsigned.example.com
issuer=CN = selfsigned.example.com
```

**Wrong name.** The certificate is perfectly valid, for other names. `--resolve` sends
`wrong.example.com` to the web server's address without touching DNS, as a typo in a bookmark or a
server answering for a name it was not set up for would:

```
ana@laptop:~$ curl -sS -o /dev/null --resolve wrong.example.com:443:192.0.2.80 https://wrong.example.com/
curl: (60) SSL: no alternative certificate subject name matches target host name 'wrong.example.com'
More details here: https://curl.se/docs/sslcerts.html

curl failed to verify the legitimacy of the server and therefore could not
establish a secure connection to it. To learn more about this situation and
how to fix it, please visit the web page mentioned above.
```

**Missing intermediate.** The certificate is fine and its issuer is fine, but the server sent only its
own certificate, `0`, and not `Issuing CA 1`:

```
ana@laptop:~$ curl -sS -o /dev/null https://nochain.example.com/
curl: (60) SSL certificate problem: unable to get local issuer certificate
More details here: https://curl.se/docs/sslcerts.html

curl failed to verify the legitimacy of the server and therefore could not
establish a secure connection to it. To learn more about this situation and
how to fix it, please visit the web page mentioned above.
ana@laptop:~$ openssl s_client -connect nochain.example.com:443 -servername nochain.example.com </dev/null 2>&1 | grep -E "^ *[0-9] s:|^ *i:|Verify return"
 0 s:CN = nochain.example.com
   i:O = Example Trust Services, CN = Example Issuing CA 1
Verify return code: 21 (unable to verify the first certificate)
```

The laptop has the root, and cannot reach it: the link in the middle is missing. **This one is
treacherous**, because some browsers remember intermediates they have seen elsewhere, or fetch them,
and show the site as fine, while `curl`, phones, and other programs fail. "It works in my browser" is
not a test of a certificate chain.

`openssl` gives each failure a number, which is what shows in logs:

```
ana@laptop:~$ for h in expired selfsigned nochain; do printf "%-11s " $h; openssl s_client -connect $h.example.com:443 -servername $h.example.com </dev/null 2>/dev/null | grep "Verify return"; done
expired     Verify return code: 10 (certificate has expired)
selfsigned  Verify return code: 18 (self-signed certificate)
nochain     Verify return code: 21 (unable to verify the first certificate)
```

| failure | curl says | the fix |
|---|---|---|
| expired | `certificate has expired` | renew it, and automate the renewal |
| self-signed | `self-signed certificate` | a certificate from a CA the clients trust |
| wrong name | `no alternative certificate subject name matches` | a certificate with that name in its SAN |
| missing intermediate | `unable to get local issuer certificate` | configure the server with the full chain |

**Never "fix" any of these by telling the client not to check**, `curl -k` or a browser's "proceed
anyway": the check is the only thing that tells a real server from somebody pretending to be one.
