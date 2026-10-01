---
title: Every request checked, and written down
version: 1
---

The application's access log now answers a question the addresses alone never could:

```
root@app:~# cat /var/log/lab/nginx-access.log
192.168.10.20 - NONE /admin/ 400
192.0.2.80 CN=www-client SUCCESS /health 200
192.0.2.80 CN=www-client SUCCESS /health 200
```

Three requests, three lines. `laptop`'s attempt, with no certificate: `NONE`, refused with `400`. The
proxy's two, one by hand and one on behalf of the customer: `CN=www-client`, `SUCCESS`, `200`. **Every
decision carries the identity it was made about.** An investigation that starts from this log begins
with *who*, not with *which address, and who had it at the time*.

## Identity that expires

A Zero Trust decision is made per request, so it can take into account things that change: the time,
the state of the device, the validity of the credential. The last one is built into certificates. The
proxy still has an old client certificate, from before its renewal:

```
root@www:~# openssl x509 -in tls/www-client-old.crt -noout -subject -enddate
subject=CN = www-client-old
notAfter=Aug 31 00:00:00 2026 GMT
```

It expired on 31 August 2026. Presented today:

```
root@www:~# curl -sS --resolve app.corp.example.com:8443:192.168.20.10 --cert tls/www-client-old.crt --key tls/www-client-old.key https://app.corp.example.com:8443/health | grep -o "<title>.*</title>"
<title>400 The SSL certificate error</title>
root@app:~# tail -1 /var/log/lab/nginx-access.log
192.0.2.80 CN=www-client-old FAILED:certificate has expired /health 400
```

**Refused**, and the log says why: `FAILED:certificate has expired`, with the subject that presented it.
Nothing had to be revoked and nobody had to remember; the credential carried its own end date and the
check read it on this request. That is the property **continuous verification**, lesson 21's subject,
generalises: every request is judged by what is true now, not by what was true when the session began.
