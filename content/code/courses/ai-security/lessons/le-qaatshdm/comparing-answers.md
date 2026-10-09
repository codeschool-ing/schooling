---
title: Three providers against one list
version: 1
---

Three providers answered the questionnaire. **The providers and their answers are invented by the
course**; no real company's terms are described here, and a real assessment reads each provider's
current contract, which changes. For every answer there is also its evidence: the clause, the signed
document or the report it rests on, or `null` when the answer is only the provider's word. Paste
them:

```sh
cat > ~/guard/data/providers.json <<'EOF'
{
 "provider-a": {
  "training": {"value": false, "evidence": "contract 4.2"},
  "retention_days": {"value": 30, "evidence": "contract 5.1"},
  "dpa": {"value": true, "evidence": "DPA signed 2026-03-10"},
  "region": {"value": "US", "evidence": "contract 2.3"},
  "incident_hours": {"value": 72, "evidence": "contract 9.1"},
  "subprocessors": {"value": true, "evidence": "published list, 2026-08"},
  "audit": {"value": true, "evidence": "SOC 2 Type II report, 2026"},
  "pinning": {"value": true, "evidence": "versioning policy page"},
  "exit_deletion": {"value": true, "evidence": null}
 },
 "provider-b": {
  "training": {"value": true, "evidence": "terms 7: used unless the customer opts out"},
  "retention_days": {"value": 0, "evidence": "contract annex B"},
  "dpa": {"value": true, "evidence": "DPA signed 2026-05-02"},
  "region": {"value": "EU", "evidence": "contract 3.1"},
  "incident_hours": {"value": 24, "evidence": "contract 11"},
  "subprocessors": {"value": false, "evidence": null},
  "audit": {"value": true, "evidence": "ISO/IEC 27001 certificate, 2025"},
  "pinning": {"value": false, "evidence": null},
  "exit_deletion": {"value": true, "evidence": "contract 14.2"}
 },
 "provider-c": {
  "training": {"value": false, "evidence": null},
  "retention_days": {"value": 30, "evidence": null},
  "dpa": {"value": true, "evidence": "DPA signed 2026-06-18"},
  "region": {"value": "BR", "evidence": "contract 2.1"},
  "incident_hours": {"value": 24, "evidence": "contract 8.4"},
  "subprocessors": {"value": true, "evidence": null},
  "audit": {"value": false, "evidence": null},
  "pinning": {"value": true, "evidence": null},
  "exit_deletion": {"value": true, "evidence": null}
 }
}
EOF
```

The program applies the list. Save it as `~/guard/tools/vendor.py`:

```python
# vendor.py: model providers' answers held against Tarefa's requirements.
#
#   guard vendor [--evidence]
#
# data/requirements.json is what Tarefa asks of any provider it sends data
# to, each question a MUST or a SHOULD with the answer it accepts.
# data/providers.json is what each provider answered, and for every answer
# the evidence behind it: a contract clause, a signed agreement, an audit
# report, or null when the answer is only the provider's word.
#
# A provider failing any MUST is out, whatever else it offers. The SHOULDs
# are counted. An answer that meets a requirement with nothing behind it is
# UNBACKED: a questionnaire answer is a claim until something else says it,
# and the claims that matter are the ones a decision rests on. --evidence
# lists them.
import argparse
import json
import os


def meets(req, value):
    if "want" in req:
        return value == req["want"]
    if "max" in req:
        return isinstance(value, int) and value <= req["max"]
    return value in req["allowed"]


p = argparse.ArgumentParser(prog="guard vendor")
p.add_argument("--evidence", action="store_true")
a = p.parse_args()

home = os.path.expanduser("~/guard/data")
with open(os.path.join(home, "requirements.json"), encoding="utf-8") as f:
    reqs = json.load(f)
with open(os.path.join(home, "providers.json"), encoding="utf-8") as f:
    providers = json.load(f)

for name, answers in providers.items():
    failed, should, claims = [], 0, []
    for r in reqs:
        ans = answers[r["id"]]
        ok = meets(r, ans["value"])
        if r["kind"] == "must" and not ok:
            failed.append("%s = %s" % (r["id"], json.dumps(ans["value"])))
        if r["kind"] == "should" and ok:
            should += 1
        if ok and ans["evidence"] is None:
            claims.append("%s %s" % (r["kind"].upper(), r["id"]))
    n_should = sum(1 for r in reqs if r["kind"] == "should")
    verdict = "OUT" if failed else "in"
    print("%-11s %-3s  should %d/%d  unbacked %d%s" % (
        name, verdict, should, n_should, len(claims),
        "  fails " + "; ".join(failed) if failed else ""))
    if a.evidence:
        for c in claims:
            print("            unbacked: %s" % c)
```

```
ana@lab:~/guard$ guard vendor
provider-a  OUT  should 4/4  unbacked 1  fails incident_hours = 72
provider-b  OUT  should 2/4  unbacked 0  fails training = true
provider-c  in   should 3/4  unbacked 5
```

**The provider with the best score is out.** `provider-a` meets all four SHOULDs, has an audit report
and a published list of subprocessors, and tells customers of an incident within 72 hours, which is
after Tarefa's own deadline to tell the ANPD has passed. A score that added MUSTs and SHOULDs
together would have ranked it first; that is why the two are kept apart.

`provider-b` is out for a different reason: its terms use customer data for training unless the
customer opts out. That is a MUST that a contract can fix. **A failing MUST is a question to the
provider, not always the end of the conversation**: if `provider-b` signs a clause turning training
off for Tarefa, the answer changes, its evidence becomes that clause, and the program is run again.
What does not happen is Tarefa deciding that the opt-out is probably fine and signing anyway.

`provider-c` is in, with three SHOULDs of four. On this list it is the only provider Tarefa could sign
with today, and the next section is about how much of that result rests on anything.

## The comparison is the start

`vendor.py` decides nothing about price, quality or latency, and it should not: those are compared
only among the providers that pass, by whoever owns the product. What the program guarantees is
narrower and more important. **No provider reaches the price comparison while failing a line Tarefa
wrote down in advance**, and the reason it failed is printed beside its name for the person who has
to explain the choice later.
