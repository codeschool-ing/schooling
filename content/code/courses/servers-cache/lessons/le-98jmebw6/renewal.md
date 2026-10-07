---
title: Renewal, and knowing it happened
version: 1
---

A ninety-day certificate is a promise that something will renew it within ninety days. certbot keeps
everything it needs for that in one file per certificate:

```
ana@web:~$ sudo cat /etc/letsencrypt/renewal/ipelivros.example.conf
# renew_before_expiry = 30 days
version = 2.9.0
archive_dir = /etc/letsencrypt/archive/ipelivros.example
cert = /etc/letsencrypt/live/ipelivros.example/cert.pem
privkey = /etc/letsencrypt/live/ipelivros.example/privkey.pem
chain = /etc/letsencrypt/live/ipelivros.example/chain.pem
fullchain = /etc/letsencrypt/live/ipelivros.example/fullchain.pem

# Options used in the renewal process
[renewalparams]
account = e5c02b0263be20818ae674d628c67786
server = https://localhost:14000/dir
authenticator = webroot
webroot_path = /var/www/ipe,
key_type = ecdsa
[[webroot_map]]
ipelivros.example = /var/www/ipe
www.ipelivros.example = /var/www/ipe
```

The server, the account, the method and the webroot are all remembered, so a renewal needs no
arguments. The first line, commented out, is the default: **a certificate is renewed when it has thirty
days or less left.** And Ubuntu's package already installed the thing that tries twice a day:

```
ana@web:~$ systemctl list-timers certbot.timer --no-pager
NEXT                        LEFT LAST PASSED UNIT          ACTIVATES
Wed 2026-10-07 13:06:54 -03  12h -         - certbot.timer certbot.service

1 timers listed.
Pass --all to see loaded but inactive timers, too.
ana@web:~$ systemctl cat certbot.service --no-pager | grep ExecStart
ExecStart=/usr/bin/certbot -q renew --no-random-sleep-on-renew
```

That timer is what makes the certificate automatic. If it is ever disabled, nothing renews and
nothing complains until the certificate expires.

## Reloading Nginx after a renewal

certbot writes new files and moves the links, and Nginx goes on serving the old certificate from
memory until it is reloaded. The fix is a **deploy hook**: an executable in
`/etc/letsencrypt/renewal-hooks/deploy/`, which certbot runs after every renewal that succeeded, and
only then.

```
ana@web:~$ sudo chmod +x /etc/letsencrypt/renewal-hooks/deploy/reload-nginx && sudo cat /etc/letsencrypt/renewal-hooks/deploy/reload-nginx
#!/bin/sh
# Run by certbot after every certificate it renews: load the new files.
systemctl reload nginx
```

## Testing it before you need it

`--dry-run` goes through a whole renewal and saves nothing:

```
ana@web:~$ sudo REQUESTS_CA_BUNDLE=/etc/pebble/api.crt certbot renew --dry-run --server https://localhost:14000/dir --no-random-sleep-on-renew 2>&1
Saving debug log to /var/log/letsencrypt/letsencrypt.log

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Processing /etc/letsencrypt/renewal/ipelivros.example.conf
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Simulating renewal of an existing certificate for ipelivros.example and www.ipelivros.example

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Congratulations, all simulated renewals succeeded: 
  /etc/letsencrypt/live/ipelivros.example/fullchain.pem (success)
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
```

**By default `--dry-run` uses Let's Encrypt's staging server, whatever the renewal file says**, so
that a test never uses up the production rate limits. Here it is pointed back at Pebble with
`--server`, because this machine cannot reach Let's Encrypt; on a real server you leave the flag out.
`--no-random-sleep-on-renew` skips a pause of up to a few minutes that certbot adds when no person is
watching, so that a million servers do not all renew at the same second.

A dry run proves that the CA would issue. It does not prove that Nginx picks up the result. Forcing a
real renewal once, and checking the certificate Nginx then serves, does:

```
ana@web:~$ sudo REQUESTS_CA_BUNDLE=/etc/pebble/api.crt certbot renew --force-renewal --no-random-sleep-on-renew 2>&1 | tail -n 6
Renewing an existing certificate for ipelivros.example and www.ipelivros.example

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Congratulations, all renewals succeeded: 
  /etc/letsencrypt/live/ipelivros.example/fullchain.pem (success)
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
ana@web:~$ echo | openssl s_client -connect ipelivros.example:443 -servername ipelivros.example 2>/dev/null | openssl x509 -noout -serial -dates
serial=7BE40AC0AB995243
notBefore=Oct  7 03:39:59 2026 GMT
notAfter=Jan  5 03:39:58 2027 GMT
```

The certificate Nginx served afterwards was signed ten seconds after the one certbot first received
(compare `notBefore` with the one in the section on certbot): a new certificate, picked up through
the hook. **Do this once, on the day you set it up**, because the alternative is finding out in ninety
days.

## Watching the date from outside

Automation fails quietly: a firewall change blocks port 80, a DNS record moves, the timer is disabled
during an upgrade. So something should watch the date that does not depend on the renewal working.
`openssl x509 -checkend` answers "will this expire within N seconds?" with an exit code a monitoring
script can use:

```
ana@web:~$ sudo openssl x509 -in /etc/letsencrypt/live/ipelivros.example/cert.pem -noout -checkend $((30*86400)); echo "exit $?"
Certificate will not expire
exit 0
ana@web:~$ sudo openssl x509 -in /etc/letsencrypt/live/ipelivros.example/cert.pem -noout -checkend $((100*86400)); echo "exit $?"
Certificate will expire
exit 1
ana@web:~$ openssl x509 -in /etc/ssl/ipelivros/self.crt -noout -checkend $((31*86400)); echo "exit $?"
Certificate will expire
exit 1
```

The renewed certificate has more than thirty days left and less than a hundred. The self-signed one
from the start of this lesson, made for thirty days, will expire within thirty-one. A monitoring
check that alerts at fourteen days left, run against the certificate the server is **actually
sending** (through `openssl s_client`, as in the previous section) and not the file on disk, catches
every one of the failures above with two weeks to fix it.
