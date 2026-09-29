---
title: What the device serves
version: 1
---

`gnmic` reads its settings from `~/.gnmic.yaml`, so the username, the certificate authority and
the encoding are written once instead of on every command:

```yaml
username: netops
tls-ca: lab-ca.pem
encoding: json_ietf
```

The password goes into the same file, appended from `~/.netops-password` so it is never typed,
and the file is made readable by `ana` alone:

```
ana@ctl:~$ echo "password: $(cat .netops-password)" >> .gnmic.yaml; chmod 600 .gnmic.yaml
```

**`Capabilities` is the first question to ask any device**, for the same reason the NETCONF hello
was in lesson 3: it says what the rest of the conversation can use.

```
ana@ctl:~$ gnmic -a edge1.example.net:9339 capabilities
gNMI version: 0.8.0
supported models:
  - openconfig-interfaces, OpenConfig working group, 3.11.0
  - openconfig-system, OpenConfig working group, 3.3.0
supported encodings:
  - JSON
  - JSON_IETF
```

Three answers. The **models** are the YANG modules the device can answer from, each with the
organisation that publishes it and a version: here `openconfig-interfaces` 3.11.0 and
`openconfig-system` 3.3.0. The **encodings** are the forms the values can travel in; both are
JSON, `JSON_IETF` being the RFC 7951 flavour with module prefixes that RESTCONF used in lesson 3.
Real devices add `PROTO`, values as Protocol Buffers, which is smaller and faster to parse. The
**gNMI version** is the version of the protocol, not of the device's software.

**A model version matters more than it looks.** OpenConfig models change between versions, a
leaf moves or a list gains a key, and a collector written against 3.11.0 can ask a device running
an older version for a path that does not exist there. A script that reads the capabilities first
can say so plainly instead of failing on a `NotFound` it cannot explain.

A wrong password is refused before anything else, with gRPC's own status code:

```
ana@ctl:~$ gnmic -a edge1.example.net:9339 -p guess capabilities
target "edge1.example.net:9339", capabilities request failed: "edge1.example.net:9339" CapabilitiesRequest failed: rpc error: code = Unauthenticated desc = wrong or missing username and password
Error: one or more requests failed
```

`-p guess` on the command line overrides the file, which is why this one failed. The status,
`Unauthenticated`, is one of gRPC's own status codes, which play the part HTTP's status codes
played in lesson 2.
