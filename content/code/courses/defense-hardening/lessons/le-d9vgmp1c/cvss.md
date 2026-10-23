---
title: Reading a severity score
version: 1
---

**CVSS, the Common Vulnerability Scoring System, describes how bad a flaw is in eight answers, and a
formula turns them into a number from 0 to 10.** The number is what people quote; the eight answers
are what you read. The feed carries them as a **vector**:

```
AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H
```

| metric | the question | in this vector |
|---|---|---|
| `AV` attack vector | from where can it be reached? Network, Adjacent, Local, Physical | `N`, over the network |
| `AC` attack complexity | does it need conditions the attacker does not control? Low or High | `L`, no |
| `PR` privileges required | must the attacker already have an account? None, Low, High | `N`, no account |
| `UI` user interaction | must somebody click something? None or Required | `N`, nobody |
| `S` scope | does it reach beyond the component that has the flaw? Unchanged or Changed | `U`, no |
| `C`, `I`, `A` | the effect on confidentiality, integrity and availability: High, Low or None | it can stop the service, nothing else |

This is the nginx advisory in the feed: anybody on the network can make the portal stop answering,
with no account and no help, and nothing is read or changed. The formula is published by FIRST, the
organisation that maintains CVSS, and it is short enough to write out. This is version 3.1, which is
what most advisories still carry:

```schooling-example
{"language": "python", "file": "cvss.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"cvss.py VECTOR...: the CVSS 3.1 base score of each vector, as the specification computes it.\"\"\"\nimport math, sys\n\nW = {\"AV\": {\"N\": 0.85, \"A\": 0.62, \"L\": 0.55, \"P\": 0.2}, \"AC\": {\"L\": 0.77, \"H\": 0.44},\n     \"UI\": {\"N\": 0.85, \"R\": 0.62}, \"CIA\": {\"H\": 0.56, \"L\": 0.22, \"N\": 0.0}}\n", "note": "The weights are the specification's own numbers, for the attack vector, the attack complexity, user interaction and the three impacts. Privileges required has a weight that depends on scope, so it is worked out below."}, {"code": "def roundup(x):\n    i = round(x * 100000)\n    return i / 100000.0 if i % 10000 == 0 else (math.floor(i / 10000) + 1) / 10.0\n", "note": "CVSS rounds up to one decimal, and the specification gives this exact function, written to avoid the floating-point error that makes `4.000000001` round up to 4.1."}, {"code": "def score(vector):\n    m = dict(part.split(\":\") for part in vector.split(\"/\"))\n    changed = m[\"S\"] == \"C\"\n    pr = {\"N\": 0.85, \"L\": 0.68 if changed else 0.62, \"H\": 0.5 if changed else 0.27}[m[\"PR\"]]\n    iss = 1 - (1 - W[\"CIA\"][m[\"C\"]]) * (1 - W[\"CIA\"][m[\"I\"]]) * (1 - W[\"CIA\"][m[\"A\"]])\n    impact = 7.52 * (iss - 0.029) - 3.25 * (iss - 0.02) ** 15 if changed else 6.42 * iss\n    exploitability = 8.22 * W[\"AV\"][m[\"AV\"]] * W[\"AC\"][m[\"AC\"]] * pr * W[\"UI\"][m[\"UI\"]]\n    if impact <= 0:\n        return 0.0\n    return roundup(min((1.08 if changed else 1) * (impact + exploitability), 10))\n", "note": "The formula: an impact subscore from confidentiality, integrity and availability, an exploitability subscore from how the flaw is reached, and a sum capped at 10. A changed scope, where the flaw reaches beyond the component that has it, uses a different impact curve and multiplies by 1.08."}, {"code": "if __name__ == \"__main__\":\n    for v in sys.argv[1:]:\n        print(f\"{score(v):4}  {v}\")"}]}
```

Run it on the feed's vectors, and on one more that every list of examples includes, the score of a
flaw that gives a stranger full control:

```
ana@admin:~$ python3 cvss.py AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:H $(jq -r ".[].cvss" feed.json)
 9.8  AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:H
 8.1  AV:N/AC:H/PR:N/UI:N/S:U/C:H/I:H/A:H
 7.5  AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H
 7.8  AV:L/AC:L/PR:L/UI:N/S:U/C:H/I:H/A:H
 4.3  AV:N/AC:L/PR:N/UI:R/S:U/C:L/I:N/A:N
 7.5  AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:N/A:N
 9.8  AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:H
 5.9  AV:N/AC:H/PR:N/UI:N/S:U/C:H/I:N/A:N
```

The first line is that full-control case, 9.8. The nginx denial of service scores 7.5, although it
reads nothing and changes nothing, because it is reachable by anybody without help. The OpenSSH flaw
scores 8.1, lower than a full-control flaw only because its attack complexity is high. The `sudo`
flaw scores 7.8 with the worst possible impact, held down by `AV:L`: somebody has to be logged in to
the machine first.

## What the number does not say

**A base score describes the flaw, not your situation.** It knows nothing about whether the package
listens on the network on your machine, whether anybody is exploiting it, or whether the machine
matters. Two flaws of 7.5 can be a week's emergency on an internet-facing portal and nothing at all
on a workstation where the service is not running. CVSS 4.0, published in 2023, splits the score
further into base, threat and environmental groups for this reason. The next section adds the two
pieces of information the base score leaves out, and lets the firm's own policy combine them.
