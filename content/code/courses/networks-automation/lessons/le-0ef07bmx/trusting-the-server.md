---
title: Trusting the server you talk to
version: 2
---

Every request in this lesson went over HTTPS and named `lab-ca.pem`, the certificate of the lab's
own certificate authority, which `netlab.sh` made and copied into `ana`'s home. That file is the reason the
password was safe to send. Without it:

```
ana@ctl:~$ curl -sS https://edge1.example.net/api/v1/system; echo "exit status $?"
curl: (60) SSL certificate problem: unable to get local issuer certificate
More details here: https://curl.se/docs/sslcerts.html

curl failed to verify the legitimacy of the server and therefore could not
establish a secure connection to it. To learn more about this situation and
how to fix it, please visit the web page mentioned above.
exit status 60
ana@ctl:~$ python -c "import requests; requests.get('https://edge1.example.net/api/v1/system')" 2>&1 | tail -1
requests.exceptions.SSLError: HTTPSConnectionPool(host='edge1.example.net', port=443): Max retries exceeded with url: /api/v1/system (Caused by SSLError(SSLCertVerificationError(1, '[SSL: CERTIFICATE_VERIFY_FAILED] certificate verify failed: unable to get local issuer certificate (_ssl.c:1000)')))
```

Both refused to talk. The router's certificate was issued by the lab's own certificate authority,
which is in no browser and no operating system, so **nothing on `ctl` could check that the machine
answering at `edge1.example.net` was `edge1`**. That is exactly the situation an attacker in the
middle creates, and refusing is the correct behaviour.

With the certificate authority named, `openssl` shows what is being checked:

```
ana@ctl:~$ openssl s_client -connect edge1.example.net:443 -CAfile lab-ca.pem </dev/null 2>/dev/null | grep -E "^subject=|^issuer=|^Verify return code"
subject=CN = edge1.example.net
issuer=O = Lab, CN = Lab Root CA
Verify return code: 0 (ok)
```

The certificate names `edge1.example.net`, it was issued by `Lab Root CA`, and the chain
verified: `0 (ok)`. A company's own devices are usually in this position, with certificates from
an internal authority, and the fix is always the same one: **give the client the authority's
certificate**, with `verify=` in `requests` or `--cacert` in `curl`.

The tempting fix is the other one. `requests` accepts `verify=False` and `curl` accepts `-k`,
and both make the error go away by checking nothing. **A script with `verify=False` sends the
router's password to whoever answers**, and the warning `requests` prints about it is the kind
people learn to scroll past. It never appears in this course, and it should not appear in a
script that touches a production network.

**The token is a password too.** It sits in `~/.token` during this lesson because the lesson
needed it between commands. A program keeps it in memory, never writes it to a log, and lets it
expire; a leaked token is only valid for the fifteen minutes the router gives it.
