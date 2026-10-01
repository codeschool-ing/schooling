---
title: RESTCONF, the same data over HTTPS
version: 1
---

RESTCONF serves the same datastore with the same models, as REST. **The address of a resource is
its path through the YANG tree**: module and container, `ietf-interfaces:interfaces`, then the
list with its key after `=`, `interface=eth2`. There is nothing to look up in a manual, because
the model is the manual.

```
ana@ctl:~$ curl -s -n --cacert lab-ca.pem -H "Accept: application/yang-data+json" https://nc1.example.net/restconf/data/ietf-interfaces:interfaces/interface=eth2
{
   "ietf-interfaces:interface": [
      {
         "name": "eth2",
         "description": "to pc1",
         "type": "iana-if-type:ethernetCsmacd",
         "enabled": true
      }
   ]
}
```

The body is JSON, in the encoding RFC 7951 defines for YANG data: **the first element of each
module carries the module's name as a prefix**, `ietf-interfaces:interface`, and a value from
another module does too, `iana-if-type:ethernetCsmacd`. It is the JSON form of the namespaces
NETCONF writes in XML.

The verbs are lesson 2's. `PATCH` merges, like NETCONF's default `edit-config`, and a single leaf
has an address of its own:

```
ana@ctl:~$ curl -si -n --cacert lab-ca.pem -X PATCH -H "Content-Type: application/yang-data+json" -d '{"ietf-interfaces:interface": [{"name": "eth2", "description": "to pc1, desk 4"}]}' https://nc1.example.net/restconf/data/ietf-interfaces:interfaces/interface=eth2
HTTP/2 204 

ana@ctl:~$ curl -s -n --cacert lab-ca.pem -H "Accept: application/yang-data+json" https://nc1.example.net/restconf/data/ietf-interfaces:interfaces/interface=eth2/description
{
   "ietf-interfaces:description": "to pc1, desk 4"
}
```

`POST` to the list creates an entry and answers with its address, and `DELETE` removes it:

```
ana@ctl:~$ curl -si -n --cacert lab-ca.pem -X POST -H "Content-Type: application/yang-data+json" -d '{"ietf-interfaces:interface": [{"name": "eth3", "type": "iana-if-type:ethernetCsmacd", "enabled": false}]}' https://nc1.example.net/restconf/data/ietf-interfaces:interfaces
HTTP/2 201 
location: https://nc1.example.net/restconf/data/ietf-interfaces:interfaces/interface=eth3
```

```
ana@ctl:~$ curl -si -n --cacert lab-ca.pem -X DELETE https://nc1.example.net/restconf/data/ietf-interfaces:interfaces/interface=eth3
HTTP/2 204 
```

Credentials are HTTP Basic, read by `curl -n` from `~/.netrc` so no password appears in a command.
**The client manages no candidate here**: each RESTCONF edit is validated and committed by the
server in one step, and an invalid one is refused before anything changes. The error is the NETCONF error
wrapped in JSON, with the same tag and the same message:

```
ana@ctl:~$ curl -si -n --cacert lab-ca.pem -X PATCH -H "Content-Type: application/yang-data+json" -d '{"ietf-interfaces:interface": [{"name": "eth2", "ietf-ip:ipv4": {"address": [{"ip": "192.0.2.99", "prefix-length": 33}]}}]}' https://nc1.example.net/restconf/data/ietf-interfaces:interfaces/interface=eth2
HTTP/2 400 
content-type: application/yang-data+json
content-length: 486

{
"ietf-restconf:errors" : {
   "error": {
      "error-type": "application",
      "error-tag": "bad-element",
      "error-info": {
         "bad-element": "prefix-length"
      },
      "error-severity": "error",
      "error-message": "Number 33 out of range: 0 - 32: yang node: \"leaf prefix-length\" with parent: \"choice subnet\" in file \"/etc/clixon/yang/ietf-ip.yang\" error-path: /interfaces/interface[name=\"eth2\"]/ipv4/address[ip=\"192.0.2.99\"]/prefix-length"
   }
}

}
```

The root of the API says what it serves, and `yang-library-version` points to the list of models
the server carries, which lesson 5 reads:

```
ana@ctl:~$ curl -s -n --cacert lab-ca.pem -H "Accept: application/yang-data+json" https://nc1.example.net/restconf
{
   "ietf-restconf:restconf": {
      "data": {},
      "operations": {},
      "yang-library-version": "2019-01-04"
   }
}
```

From Python, RESTCONF is `requests`, and `requests` reads `~/.netrc` by itself when no `auth` is
given:

```schooling-example
{
  "language": "python",
  "file": "restconf.py",
  "parts": [
    {
      "code": "import requests\n"
    },
    {
      "code": "BASE = \"https://nc1.example.net/restconf/data\"\nJSON = \"application/yang-data+json\"\nhttp = requests.Session()\nhttp.verify = \"lab-ca.pem\"\nhttp.headers.update({\"Accept\": JSON, \"Content-Type\": JSON})\n",
      "note": "**RESTCONF is HTTPS**, so this is lesson 2's `requests` again. HTTP Basic credentials come from `~/.netrc`, which `requests` reads by itself when no `auth` is given."
    },
    {
      "code": "r = http.get(f\"{BASE}/ietf-interfaces:interfaces/interface=eth1\", timeout=10)\nr.raise_for_status()\neth1 = r.json()[\"ietf-interfaces:interface\"][0]\nprint(eth1[\"name\"], eth1[\"description\"], eth1[\"enabled\"])\n",
      "note": "**The URL is the path through the model**: module and container, then the list with its key after `=`."
    },
    {
      "code": "r = http.patch(f\"{BASE}/ietf-interfaces:interfaces/interface=eth1\", timeout=10,\n               json={\"ietf-interfaces:interface\": [{\"name\": \"eth1\", \"description\": \"uplink to core1\"}]})\nprint(\"PATCH\", r.status_code)",
      "note": "**A PATCH merges.** The body is the same JSON shape a GET returns, with only the leaves being changed."
    }
  ]
}
```

```
ana@ctl:~$ python restconf.py
eth1 uplink to core1, port 7 True
PATCH 204
```

**And it is one datastore.** The description set over RESTCONF a few requests ago is what NETCONF
reads now:

```
ana@ctl:~$ python -c "from nc import connect, describe; print(describe(connect(), \"running\", \"eth2\"))"
running   eth2: description='to pc1, desk 4' enabled=true
```

Which to use is mostly a question of the device and the tool. NETCONF has the candidate, locks
and confirmed commits, which is why it is the protocol for changes that must not half-happen.
RESTCONF is lighter, needs nothing but an HTTP client, and suits reading state and single
changes. Many devices serve both from the same models, as `nc1` does.
