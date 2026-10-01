---
title: Which models a device has
version: 1
---

A device announces the models it supports, and reading that list is the first step before
automating it, for the same reason lesson 4 read gNMI's capabilities. NETCONF and RESTCONF servers
publish it in a model of its own, `ietf-yang-library`:

```
ana@ctl:~$ curl -s -n --cacert lab-ca.pem -H "Accept: application/yang-data+json" https://nc1.example.net/restconf/data/ietf-yang-library:yang-library | jq -r '.["ietf-yang-library:yang-library"]["module-set"][0].module[] | "\(.name) \(.revision)"' | sort
clixon-lib 2026-06-01
iana-if-type 2019-02-08
ietf-datastores 2018-02-14
ietf-inet-types 2021-02-22
ietf-interfaces 2018-02-20
ietf-ip 2018-02-22
ietf-list-pagination 2025-04-03
ietf-list-pagination-nc 2025-04-03
ietf-netconf 2011-06-01
ietf-netconf-acm 2018-02-14
ietf-netconf-monitoring 2010-10-04
ietf-netconf-nmda 2019-01-07
ietf-netconf-private-candidate 2025-10-30
ietf-netconf-with-defaults 2011-06-01
ietf-nmda-compare 2024-04-16
ietf-origin 2018-02-14
ietf-restconf 2017-01-26
ietf-system-capabilities 2021-04-02
ietf-yang-library 2019-01-04
ietf-yang-metadata 2016-08-05
ietf-yang-patch 2017-02-22
ietf-yang-types 2013-07-15
```

`nc1` carries `ietf-interfaces` and `ietf-ip`, the two lesson 3 configured, `iana-if-type` for
their interface types, and the modules the protocols themselves are defined in: `ietf-netconf`,
`ietf-restconf`, `ietf-yang-library` describing this very list. `clixon-lib` is Clixon's own. Each
comes with its **revision**, the date of the version the device implements, and two devices with
different revisions of the same module can disagree about what a path means.

`example-branches` is not in the list, and the device says so if anything asks it to store data
of that model:

```
ana@ctl:~$ curl -si -n --cacert lab-ca.pem -X POST -H "Content-Type: application/yang-data+json" -d @branches.json https://nc1.example.net/restconf/data
HTTP/2 400 
content-type: application/yang-data+json
content-length: 309

{
"ietf-restconf:errors" : {
   "error": {
      "error-type": "application",
      "error-tag": "unknown-namespace",
      "error-info": {
         "bad-namespace": "example-branches"
      },
      "error-severity": "error",
      "error-message": "No yang module found for corresponding prefix"
   }
}

}
```

`unknown-namespace`: **a device can only hold data for the models it has.** That is the
difference between a model the operator writes, like `example-branches`, which lives in the
automation's own repository and validates its data, and a model the device ships, which decides
what the device will accept. Lesson 12 keeps the branches in NetBox instead, and lesson 13 checks
that kind of data before it is turned into configuration.
