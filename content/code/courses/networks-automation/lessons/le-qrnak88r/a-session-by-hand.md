---
title: A NETCONF session, by hand
version: 3
---

Before any library, the protocol itself. NETCONF runs over SSH, on port 830, as an SSH
**subsystem** called `netconf`: the connection carries XML messages instead of a shell. This is
the whole conversation of one session, written into a file, `hello.xml`:

```
<hello xmlns="urn:ietf:params:xml:ns:netconf:base:1.0">
  <capabilities><capability>urn:ietf:params:netconf:base:1.0</capability></capabilities>
</hello>]]>]]>
<rpc message-id="1" xmlns="urn:ietf:params:xml:ns:netconf:base:1.0">
  <get-config><source><running/></source>
    <filter type="subtree">
      <interfaces xmlns="urn:ietf:params:xml:ns:yang:ietf-interfaces"><interface><name>eth1</name></interface></interfaces>
    </filter>
  </get-config>
</rpc>]]>]]>
<rpc message-id="2" xmlns="urn:ietf:params:xml:ns:netconf:base:1.0"><close-session/></rpc>]]>]]>
```

Three messages, each ended by the marker `]]>]]>`. The first is the client's **hello**, saying
which versions of the protocol it speaks. The second is an **rpc**, a request, asking for part of
the running configuration. The third closes the session. `ssh -s` opens the subsystem, the file
goes in, and `frames.py` only indents what comes back so a person can read it. It is nine lines,
and the standard library's XML parser does the work:

```python
# Split NETCONF 1.0 messages on their end marker and indent each one, so a
# person can read what went over the wire. The bytes themselves are unchanged.
import sys
from xml.dom import minidom

for message in sys.stdin.read().split("]]>]]>"):
    if message.strip():
        print(minidom.parseString(message.strip()).toprettyxml(indent="  ").split("\n", 1)[1].rstrip())
        print("]]>]]>")
```

With both files in `ana`'s home on `ctl`:

```
ana@ctl:~$ (cat hello.xml; sleep 2) | ssh -p 830 -s netops@nc1.example.net netconf | python3 frames.py
<hello xmlns="urn:ietf:params:xml:ns:netconf:base:1.0">
  <capabilities>
    <capability>urn:ietf:params:netconf:base:1.1</capability>
    <capability>urn:ietf:params:netconf:base:1.0</capability>
    <capability>urn:ietf:params:netconf:capability:yang-library:1.1?revision=2019-01-04&amp;module-set-id=0</capability>
    <capability>urn:ietf:params:netconf:capability:candidate:1.0</capability>
    <capability>urn:ietf:params:netconf:capability:validate:1.1</capability>
    <capability>urn:ietf:params:netconf:capability:startup:1.0</capability>
    <capability>urn:ietf:params:netconf:capability:xpath:1.0</capability>
    <capability>urn:ietf:params:netconf:capability:with-defaults:1.0?basic-mode=explicit&amp;also-supported=report-all,trim,report-all-tagged</capability>
    <capability>urn:ietf:params:netconf:capability:notification:1.0</capability>
    <capability>urn:ietf:params:xml:ns:yang:ietf-netconf-monitoring</capability>
    <capability>urn:ietf:params:netconf:capability:confirmed-commit:1.1</capability>
  </capabilities>
  <session-id>1</session-id>
</hello>
]]>]]>
<rpc-reply xmlns="urn:ietf:params:xml:ns:netconf:base:1.0" message-id="1">
  <data>
    <interfaces xmlns="urn:ietf:params:xml:ns:yang:ietf-interfaces">
      <interface xmlns:ianaift="urn:ietf:params:xml:ns:yang:iana-if-type">
        <name>eth1</name>
        <description>uplink to core1</description>
        <type>ianaift:ethernetCsmacd</type>
        <enabled>true</enabled>
      </interface>
    </interfaces>
  </data>
</rpc-reply>
]]>]]>
<rpc-reply xmlns="urn:ietf:params:xml:ns:netconf:base:1.0" message-id="2">
  <ok/>
</rpc-reply>
]]>]]>
```

**The server's hello lists its capabilities**, and each one is a promise. `candidate` means
there is a candidate datastore. `validate` means it can check a configuration without applying
it. `confirmed-commit` means commits can undo themselves. A client that needs one of them reads
the hello first, because a device without `candidate` has to be configured differently.

Then the reply to `message-id="1"`. The filter asked for the interface named `eth1`, and the
server sent back exactly that entry, **with every element in its namespace**: `interfaces` belongs
to `urn:ietf:params:xml:ns:yang:ietf-interfaces`, the model that defines it, and the value of
`type` is written with the prefix of another model, `iana-if-type`. The last reply, `<ok/>`,
acknowledges the close.

Nobody writes this by hand twice. The framing, the message ids and the SSH subsystem are what
`ncclient` does for you, and the rest of the lesson uses it. **What it does not hide is the XML**,
and the namespaces in it are the first thing that goes wrong.
