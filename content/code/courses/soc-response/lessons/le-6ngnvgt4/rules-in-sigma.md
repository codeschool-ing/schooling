---
title: Rules in Sigma
version: 1
---

A detection written in one SIEM's query language is locked in that SIEM. **Sigma** is an open format for
writing the detection once, in YAML, and converting it into whichever language the SIEM speaks; the
converter is `sigma-cli`, with one plugin per target. Install it, with the SQLite plugin, in a virtual
environment of its own:

```
ana@soc:~/week$ python3 -m venv ~/sigma && ~/sigma/bin/pip install -q sigma-cli==3.1.0 pySigma-backend-sqlite==2.0.0
ana@soc:~/week$ ~/sigma/bin/sigma list targets
+------------+-----------------------+------------------------------+--------+
| Identifier | Target Query Language | Processing Pipeline Required | Plugin |
+------------+-----------------------+------------------------------+--------+
| sqlite     | SQLite backend        | No                           | sqlite |
+------------+-----------------------+------------------------------+--------+
```

The simplest rule is one condition on one event. Save this as `failures.yml`:

```yaml
title: SSH login failure
name: ssh_login_failure
id: 3f1d2c6a-8b7e-4e0f-9a52-6c1b0e7d4a10
status: test
description: One failed SSH login, for a known or an unknown account.
logsource:
  product: linux
  service: sshd
detection:
  selection:
    product: sshd
    action: failure
  condition: selection
level: low
```

`logsource` says which kind of log the rule is about; `detection` names a selection of field values and a
`condition` over the selections; `level` says how much attention a match deserves. The `id` is a UUID, so
that a rule can be renamed and still be tracked. Convert it:

```
ana@soc:~/week$ ~/sigma/bin/sigma convert -t sqlite failures.yml
Parsing Sigma rules
SELECT * FROM logs WHERE product='sshd' AND `action`='failure'
```

That is the whole point of Sigma, visible in one line: the YAML became a `WHERE` clause over the table
`load.py` built, with the field names it chose. Here the fields match because the table was designed
for it. In a real SIEM the field names differ (`src_ip` in one product, `source.ip` in another), and
Sigma's **processing pipelines** translate them during conversion. **A rule is only as portable as its field
names are mapped**: the most common reason a downloaded rule matches nothing is that it asks for a field
your SIEM calls something else.

One failed login is an event, not an alert. On this week it matches 150 rows, and nobody wants 150
alerts. What makes a failure interesting is its company, which is the next section.
