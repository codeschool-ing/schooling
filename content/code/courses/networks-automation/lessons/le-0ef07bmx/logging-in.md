---
title: Logging in, and what comes back
version: 2
---

Most device APIs authenticate in one of two ways. **HTTP Basic** sends the username and password
with every request; it is what RESTCONF uses in lesson 3. **A token** is obtained once, with the
password, and sent instead of it afterwards. The lab's routers use tokens:

```
ana@ctl:~$ jq -n --arg p "$(cat .netops-password)" '{username: "netops", password: $p}' > login.json
ana@ctl:~$ curl -s --cacert lab-ca.pem -H "Content-Type: application/json" -d @login.json https://edge1.example.net/api/v1/auth/login
{
  "token": "81cd674ef3160c308dfbaf02c16cb9ee",
  "token_type": "Bearer",
  "expires_in": 900
}
```

The password never appears in the command. It is read from `~/.netops-password`, a file only
`ana` can read, which `netlab.sh` writes into her home on every build, and `jq` builds the JSON body from it into `login.json`. **A password typed on a
command line ends up in the shell's history and in the process list**, where anyone on the
machine can see it while the command runs.

The answer is a **bearer token**: whoever holds it is treated as `netops`, for `expires_in`
seconds, fifteen minutes here. It goes in the `Authorization` header of every request after
that:

```
ana@ctl:~$ curl -s --cacert lab-ca.pem -H "Content-Type: application/json" -d @login.json https://edge1.example.net/api/v1/auth/login | jq -r .token > .token
ana@ctl:~$ curl -s --cacert lab-ca.pem -H "Authorization: Bearer $(cat .token)" https://edge1.example.net/api/v1/system
{
  "hostname": "edge1",
  "software": "FRRouting 8.4.4",
  "uptime_seconds": 17,
  "management_address": "192.0.2.12"
}
```

A wrong password is refused with the same `401` as a missing token, and a body that does not say
which half was wrong. That is deliberate, and it is how any login should answer: telling a
stranger that the username exists is telling them half of what they need.

```
ana@ctl:~$ curl -si --cacert lab-ca.pem -H "Content-Type: application/json" -d '{"username": "netops", "password": "guess"}' https://edge1.example.net/api/v1/auth/login
HTTP/1.1 401 Unauthorized
Server: devapi/1.0
Date: Tue, 29 Sep 2026 11:00:43 GMT
Content-Type: application/json
Content-Length: 44
WWW-Authenticate: Bearer realm="devapi"

{
  "error": "wrong username or password"
}
```

**Authentication says who you are; authorisation says what you may do.** The router has a
second account, `audit`, which may read everything and change nothing. Its token reads an
interface, and then tries to change it:

```
ana@ctl:~$ jq -n --arg p "$(cat .audit-password)" '{username: "audit", password: $p}' > audit.json
ana@ctl:~$ curl -s --cacert lab-ca.pem -H "Content-Type: application/json" -d @audit.json https://edge1.example.net/api/v1/auth/login | jq -r .token > .audit-token
ana@ctl:~$ curl -s --cacert lab-ca.pem -H "Authorization: Bearer $(cat .audit-token)" https://edge1.example.net/api/v1/interfaces/eth2
{
  "name": "eth2",
  "description": "branch LAN",
  "enabled": true,
  "oper_status": "up",
  "mtu": 1500,
  "mac_address": "52:54:00:00:71:01",
  "addresses": [
    "203.0.113.1/26"
  ]
}
ana@ctl:~$ curl -si --cacert lab-ca.pem -X PATCH -H "Authorization: Bearer $(cat .audit-token)" -H "Content-Type: application/json" -d '{"description": "branch 1 LAN"}' https://edge1.example.net/api/v1/interfaces/eth2
HTTP/1.1 403 Forbidden
Server: devapi/1.0
Date: Tue, 29 Sep 2026 11:00:43 GMT
Content-Type: application/json
Content-Length: 60

{
  "error": "audit may read and may not change anything"
}
```

`403 Forbidden` is not `401`. The server knows exactly who is asking and refuses anyway, so
logging in again will not help. **A script that monitors should run with an account like
`audit`**, because the worst a leaked read-only token can do is read.
