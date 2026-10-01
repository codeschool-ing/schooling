---
title: An identity for a machine
version: 1
---

The proxy needs to prove who it is. It holds a **client certificate**, issued by the company's CA the
way lesson 12 issued a server's:

```
root@www:~# openssl x509 -in tls/www-client.crt -noout -subject -issuer -dates -ext extendedKeyUsage
subject=CN = www-client
issuer=O = Example Corp, CN = Example Corp Issuing CA
notBefore=Sep 28 00:00:00 2026 GMT
notAfter=Dec 28 00:00:00 2026 GMT
X509v3 Extended Key Usage: 
    TLS Web Client Authentication
```

`CN = www-client`, issued by the issuing CA, valid for three months, with an extended key usage of
**client authentication**: it can prove an identity to a server and cannot be used to run one. Its
private key never leaves `www`. Presented by hand:

```
root@www:~# curl -sS --resolve app.corp.example.com:8443:192.168.20.10 --cert tls/www-client.crt --key tls/www-client.key https://app.corp.example.com:8443/health
status: ok
```

`status: ok`. Then the proxy's configuration is changed to reach the application over TLS, verifying
the application's certificate as well as presenting its own:

```
root@www:~# grep -m1 -A8 "location / {" /etc/nginx/sites-enabled/shop | sed "s/^ *//"
location / {
proxy_pass https://192.168.20.10:8443;
proxy_ssl_name app.corp.example.com;
proxy_ssl_server_name on;
proxy_ssl_verify on;
proxy_ssl_trusted_certificate /etc/ssl/certs/ca-certificates.crt;
proxy_ssl_certificate /root/tls/www-client.crt;
proxy_ssl_certificate_key /root/tls/www-client.key;
proxy_set_header Host $host;
```

**Both ends now prove who they are**: `proxy_ssl_verify` checks that the server is really
`app.corp.example.com`, and `proxy_ssl_certificate` presents `www-client` in return. That is **mutual
TLS** (mTLS). It also closes the gap lesson 3 left open: the hop from the DMZ to the servers used to
travel in clear, and now it is encrypted. From the internet, through all of it:

```
ana@remote:~$ curl -s https://www.example.com/health
status: ok
```

The customer notices nothing. Between the proxy and the application, the request now carries the
proxy's identity, proved with a key the network cannot supply.

**Machine identities have one hard problem, which is distribution.** Every service needs a key and a
certificate, renewed before expiry, and revoked when the service is retired. Doing that by hand for two
services is what this lab did; doing it for two hundred is what service meshes and certificate
automation exist for, with lifetimes measured in hours so that revocation (lesson 12) matters less.
