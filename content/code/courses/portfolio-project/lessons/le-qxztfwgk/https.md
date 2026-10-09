---
title: HTTPS in front
version: 2
---

A browser, and a reviewer, expect `https://`. **Caddy** is a web server that obtains and renews
certificates by itself, and the whole configuration for loanbook is four lines:

```
ana@srv:~/loanbook$ systemctl is-active caddy
active
ana@srv:~/loanbook$ cat deploy/Caddyfile
loans.lab {
	tls internal
	reverse_proxy 127.0.0.1:8000
}
ana@srv:~/loanbook$ sudo cp deploy/Caddyfile /etc/caddy/Caddyfile
ana@srv:~/loanbook$ sudo systemctl reload caddy
```

Caddy has been running since srv.yaml installed it, serving a placeholder page, so `reload` is what
makes it read the new file; `enable --now` would leave it running the old one. `loans.lab` is the name
it answers to. `reverse_proxy` hands every request to the container on port 8000. And `tls internal` tells Caddy to issue the certificate from **its own local authority**, because
`loans.lab` is not a real domain and no public authority would issue one for it. On the internet, that
line goes away, last section.

From laptop, after telling it where `loans.lab` is, the first request fails:

```
ana@laptop:~$ echo '10.20.0.20 loans.lab' | sudo tee -a /etc/hosts
10.20.0.20 loans.lab
ana@laptop:~$ curl -sS https://loans.lab/healthz
curl: (60) SSL certificate problem: unable to get local issuer certificate
More details here: https://curl.se/docs/sslcerts.html

curl failed to verify the legitimacy of the server and therefore could not
establish a secure connection to it. To learn more about this situation and
how to fix it, please visit the web page mentioned above.
```

That failure is correct. The certificate is signed by an authority laptop has never heard of, and `curl`
refuses to trust it, which is exactly what should happen with an unknown certificate. The fix is to
make laptop trust that authority, deliberately, by installing its root certificate:

```
ana@laptop:~$ ssh srv sudo cat /var/lib/caddy/.local/share/caddy/pki/authorities/local/root.crt > lab-root.crt
ana@laptop:~$ openssl x509 -in lab-root.crt -noout -subject -enddate
subject=CN = Caddy Local Authority - 2026 ECC Root
notAfter=Aug 15 10:58:54 2036 GMT
ana@laptop:~$ sudo cp lab-root.crt /usr/local/share/ca-certificates/loans-lab-root.crt
ana@laptop:~$ sudo update-ca-certificates
Updating certificates in /etc/ssl/certs...
rehash: warning: skipping ca-certificates.crt,it does not contain exactly one certificate or CRL
1 added, 0 removed; done.
Running hooks in /etc/ca-certificates/update.d...
done.
ana@laptop:~$ curl -sS https://loans.lab/healthz
{"ok": true}
ana@laptop:~$ curl -sS https://loans.lab/api/items | python3 -m json.tool | head -12
[
    {
        "id": 8,
        "name": "Conference speaker",
        "loan": null
    },
    {
        "id": 6,
        "name": "Document camera",
        "loan": {
            "borrower": "Dora Okafor",
            "lent_on": "2026-10-06",
```

`openssl` shows what is being trusted before trusting it: Caddy's local root, valid for ten years.
`update-ca-certificates` adds it to the system's list, and from then on the same request succeeds, over
HTTPS, with the seeded data. Those two commands are Ubuntu's. On macOS the same file goes into the
System keychain, through Keychain Access, marked *Always Trust*; on Windows, into *Trusted Root
Certification Authorities*, through the certificate manager, `certmgr.msc`. A phone or another laptop
takes the same file, which is what makes a lab with HTTPS behave like the real thing.

`/etc/hosts` is Ubuntu's and macOS's file for names; on Windows it is
`C:\Windows\System32\drivers\etc\hosts`, edited as administrator, with the same line.
