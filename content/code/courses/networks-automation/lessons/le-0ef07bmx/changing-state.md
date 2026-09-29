---
title: Creating, changing and removing
version: 1
---

Reading is half of an API. The other half changes the device, and each verb answers in its own
way. **`POST` creates** a static route inside the collection:

```
ana@ctl:~$ curl -si --cacert lab-ca.pem -H "Authorization: Bearer $(cat .token)" -H "Content-Type: application/json" -d '{"prefix": "192.0.2.128/25", "next_hop": "198.51.100.1"}' https://edge1.example.net/api/v1/static-routes
HTTP/1.1 201 Created
Server: devapi/1.0
Date: Tue, 29 Sep 2026 11:00:43 GMT
Content-Type: application/json
Content-Length: 80
Location: /api/v1/static-routes/192.0.2.128%2F25

{
  "prefix": "192.0.2.128/25",
  "next_hop": "198.51.100.1",
  "distance": 1
}
```

`201 Created`, and a `Location` header with the address of the new resource. The `/` inside the
prefix is written `%2F`, because a slash in a URL separates parts of the path; this is called
**percent-encoding**, and every API that uses an address as a key needs it. The route is really on
the router, as a line of configuration that `vtysh` shows:

```
ana@ctl:~$ ssh netops@edge1 "show running-config" | grep "ip route"
ip route 192.0.2.128/25 198.51.100.1
```

**`POST` is not safe to repeat.** The same request again:

```
ana@ctl:~$ curl -si --cacert lab-ca.pem -H "Authorization: Bearer $(cat .token)" -H "Content-Type: application/json" -d '{"prefix": "192.0.2.128/25", "next_hop": "198.51.100.1"}' https://edge1.example.net/api/v1/static-routes
HTTP/1.1 409 Conflict
Server: devapi/1.0
Date: Tue, 29 Sep 2026 11:00:43 GMT
Content-Type: application/json
Content-Length: 121

{
  "error": "a static route to 192.0.2.128/25 already exists",
  "existing": "/api/v1/static-routes/192.0.2.128%2F25"
}
```

`409 Conflict`: the route exists. The server said so instead of creating a second copy, which a
careless API would have done, and it pointed at the existing one.

**`PATCH` changes only the fields it sends.** The interface keeps its address, MTU and state; only
the description moves:

```
ana@ctl:~$ curl -s --cacert lab-ca.pem -X PATCH -H "Authorization: Bearer $(cat .token)" -H "Content-Type: application/json" -d '{"description": "branch 1 LAN"}' https://edge1.example.net/api/v1/interfaces/eth2
{
  "name": "eth2",
  "description": "branch 1 LAN",
  "enabled": true,
  "oper_status": "up",
  "mtu": 1500,
  "mac_address": "52:54:00:00:71:01",
  "addresses": [
    "203.0.113.1/26"
  ]
}
```

**`DELETE` removes, and removing twice is not an error of the network**: the second request
finds nothing and says `404`, and the route is gone either way.

```
ana@ctl:~$ curl -si --cacert lab-ca.pem -X DELETE -H "Authorization: Bearer $(cat .token)" https://edge1.example.net/api/v1/static-routes/192.0.2.128%2F25
HTTP/1.1 204 No Content
Server: devapi/1.0
Date: Tue, 29 Sep 2026 11:00:44 GMT
Content-Length: 0

ana@ctl:~$ curl -si --cacert lab-ca.pem -X DELETE -H "Authorization: Bearer $(cat .token)" https://edge1.example.net/api/v1/static-routes/192.0.2.128%2F25
HTTP/1.1 404 Not Found
Server: devapi/1.0
Date: Tue, 29 Sep 2026 11:00:44 GMT
Content-Type: application/json
Content-Length: 51

{
  "error": "no static route to 192.0.2.128/25"
}
```

Two more refusals, and both are the server protecting the router. A prefix with host bits set is
refused with `422 Unprocessable Entity`, which means the JSON was fine and its meaning was not:

```
ana@ctl:~$ curl -si --cacert lab-ca.pem -H "Authorization: Bearer $(cat .token)" -H "Content-Type: application/json" -d '{"prefix": "192.0.2.130/25", "next_hop": "198.51.100.1"}' https://edge1.example.net/api/v1/static-routes
HTTP/1.1 422 Unprocessable Entity
Server: devapi/1.0
Date: Tue, 29 Sep 2026 11:00:44 GMT
Content-Type: application/json
Content-Length: 107

{
  "error": "'192.0.2.130/25' is not a network in CIDR form, such as 192.0.2.0/24",
  "field": "prefix"
}
```

And a verb the resource does not support is `405`, with an `Allow` header listing the ones it does:

```
ana@ctl:~$ curl -si --cacert lab-ca.pem -X DELETE -H "Authorization: Bearer $(cat .token)" https://edge1.example.net/api/v1/interfaces/eth2
HTTP/1.1 405 Method Not Allowed
Server: devapi/1.0
Date: Tue, 29 Sep 2026 11:00:44 GMT
Content-Type: application/json
Content-Length: 66
Allow: GET, PATCH

{
  "error": "DELETE is not allowed on /api/v1/interfaces/eth2"
}
```

**A script should create with `PUT` to the item's own address when it can**, because `PUT` is
idempotent: sending the same body twice leaves the router as sending it once. This one reads
first, writes only when the route differs, and says which happened:

```schooling-example
{
  "language": "python",
  "file": "static.py",
  "parts": [
    {
      "code": "import sys\n\nfrom devapi import Device\n"
    },
    {
      "code": "WANT = {\"prefix\": \"192.0.2.128/25\", \"next_hop\": \"198.51.100.1\", \"distance\": 10}\npath = \"/static-routes/\" + WANT[\"prefix\"].replace(\"/\", \"%2F\")\n\nedge1 = Device(sys.argv[1] if len(sys.argv) > 1 else \"edge1\")",
      "note": "**The route this script is responsible for**, as data. `PUT` to the route's own address means \"make it exactly this\", so running the script twice gives the same result."
    },
    {
      "code": "current = next((r for r in edge1.all(\"/static-routes\") if r[\"prefix\"] == WANT[\"prefix\"]), None)\nif current == WANT:\n    print(f\"{WANT['prefix']}: already as intended\")\nelse:\n    edge1.request(\"PUT\", path, json=WANT)\n    print(f\"{WANT['prefix']}: {'created' if current is None else 'updated'}\")",
      "note": "**Read first, then write only if it differs**, and report which it was."
    }
  ]
}
```

```
ana@ctl:~$ python static.py
192.0.2.128/25: created
ana@ctl:~$ python static.py
192.0.2.128/25: already as intended
```
