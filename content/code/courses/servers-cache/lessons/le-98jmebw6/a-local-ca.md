---
title: A certificate authority of your own, for practice
version: 1
---

Pebble is in Ubuntu's archive, and lesson 1 installed it. It needs three things
before it runs: a certificate for its own API, which is HTTPS like every ACME server; a small
configuration file; and a systemd unit to keep it running.

Its API certificate is self-signed, made exactly like the one in the previous section, for the name
`localhost`, because that is where `certbot` will reach it:

```
ana@web:~$ sudo mkdir -p /etc/pebble && cd /etc/pebble && sudo openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:P-256 -nodes -days 365 -subj "/CN=Lab ACME API" -addext "subjectAltName=DNS:localhost" -keyout api.key -out api.crt 2>&1; ls
-----
api.crt
api.key
```

```json
{
  "pebble": {
    "listenAddress": "127.0.0.1:14000",
    "managementListenAddress": "127.0.0.1:15000",
    "certificate": "/etc/pebble/api.crt",
    "privateKey": "/etc/pebble/api.key",
    "httpPort": 80,
    "tlsPort": 443,
    "ocspResponderURL": "",
    "externalAccountBindingRequired": false,
    "certificateValidityPeriod": 7776000
  }
}
```

Three of these lines are choices worth reading. **`httpPort: 80`** tells Pebble to check HTTP-01
challenges on port 80, where Let's Encrypt checks them and where Nginx already answers; Pebble's own
default is 5002, so that a test suite needs no root. **`certificateValidityPeriod`** is 7,776,000
seconds, ninety days, to match what Let's Encrypt issues. And both listening addresses are on
`127.0.0.1`, so nothing outside this machine can ask Pebble for anything.

```ini
[Unit]
Description=Pebble, Let's Encrypt's ACME server for testing
After=network.target

[Service]
Environment=PEBBLE_VA_NOSLEEP=1 PEBBLE_WFE_NONCEREJECT=0
ExecStart=/usr/bin/pebble -config /etc/pebble/pebble.json
User=nobody

[Install]
WantedBy=multi-user.target
```

The two environment variables switch off two things Pebble does on purpose to test clients: a random
pause of up to fifteen seconds before each validation, and rejecting a share of valid requests to see
whether the client retries. Both are useful to somebody writing an ACME client and only slow down
somebody learning to use one. It runs as `nobody`, which can read the API key only because the
permissions say so; on a real server, a key readable by every user would be a defect. Start it and
ask for its **directory**, the one URL an ACME client needs to know:

```
ana@web:~$ sudo chmod 644 /etc/pebble/api.key && sudo systemctl daemon-reload && sudo systemctl start pebble && sleep 1 && systemctl is-active pebble
active
ana@web:~$ curl -s --cacert /etc/pebble/api.crt https://localhost:14000/dir | jq .
{
  "keyChange": "https://localhost:14000/rollover-account-key",
  "meta": {
    "externalAccountRequired": false,
    "termsOfService": "data:text/plain,Do%20what%20thou%20wilt"
  },
  "newAccount": "https://localhost:14000/sign-me-up",
  "newNonce": "https://localhost:14000/nonce-plz",
  "newOrder": "https://localhost:14000/order-plz",
  "revokeCert": "https://localhost:14000/revoke-cert"
}
```

Every step of the protocol is a URL in that list. The names are Pebble's own jokes; Let's Encrypt's
directory has the same keys with plainer URLs.

## The root nobody trusts yet

Pebble generates a new root and a new intermediate **every time it starts**, and publishes the root
on its management port. Fetch it and save it where Ubuntu looks for extra roots:

```
ana@web:~$ curl -s --cacert /etc/pebble/api.crt https://localhost:15000/roots/0 | sudo tee /usr/local/share/ca-certificates/pebble-root.crt | openssl x509 -noout -subject
subject=CN = Pebble Root CA 435937
```

The number after its name is random, which is how you can tell two Pebble roots apart. Nothing
trusts it yet; the section after next tells this machine to. This is the step that has no
equivalent with Let's Encrypt, whose roots are already in `/etc/ssl/certs` on every system, and it is
the reason a certificate from Pebble works only on the machine that chose to trust it.
