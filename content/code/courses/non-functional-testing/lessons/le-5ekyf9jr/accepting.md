---
title: Fixing, and accepting what cannot be fixed yet
version: 1
---

Lesson 1 wrote the security requirement this lesson has to make testable: **no finding rated high
or critical left open at release.** Read with the previous section, every word of it has a
meaning. *Rated* is the triage's rating, the environmental one, not the base score copied from the
advisory. *Open* means neither fixed nor accepted by somebody with the authority to accept it. And
*at release* means the check runs in the pipeline, where a release cannot go around it.

Fixing is the usual answer, and the cheapest. Sometimes it cannot happen today: the fixed version
needs a newer Python than the servers have, or it changes behaviour another team depends on. Then
the finding is **accepted**, which is a decision with four parts, none of them optional: the
advisory, the reason, an **owner** who answers for it, and an **expiry date** after which it is
decided again. `security-fundamentals` lesson 3 is where accepting a risk sits beside mitigating,
transferring and avoiding it.

## A gate that knows what was accepted

pip-audit takes `--ignore-vuln` to leave one advisory out. On its own that flag is a way to make a
report go quiet and forget why. Wrapped in a small script that carries the reason and refuses to
work after the end date, it is the record of a decision. In `~/audit`, create it with
`nano audit.sh`, and change the date on the `UNTIL` line to about a month after the day you type
it:

```sh
# audit/audit.sh
# The dependency gate: it fails on every advisory nobody has accepted. Run: sh audit.sh
# An accepted risk names the advisory, why it is accepted, who owns it, and when that ends.
cd "$(dirname "$0")" || exit 2
ACCEPTED=PYSEC-2026-2275          # extract_zipped_paths() is never called by notify.py. Owner: ana.
UNTIL=${UNTIL:-2026-11-15}        # after this day the acceptance is void and the gate fails again
if [ "$(date +%F)" \> "$UNTIL" ]; then
    echo "accepted risk $ACCEPTED expired on $UNTIL: fix it, or decide again" >&2
    exit 1
fi
exec ~/venv/bin/pip-audit -r requirements.txt --ignore-vuln "$ACCEPTED"
```

Suppose the team cannot move past `2.32` yet and accepts the one advisory whose function nobody
calls. Run the gate, then run it again as if the end date had already passed, which the
`UNTIL=` in front of the command does for that one run:

```
ana@nft:~/audit$ sh audit.sh; echo "exit $?"
Found 4 known vulnerabilities, ignored 2 in 1 package
Name     Version ID              Fix Versions
-------- ------- --------------- ------------
requests 2.31.0  PYSEC-2026-1873 2.32.0
requests 2.31.0  PYSEC-2026-1872 2.32.4
requests 2.31.0  PYSEC-2026-1873 2.32.0
requests 2.31.0  PYSEC-2026-1872 2.32.4
exit 1
ana@nft:~/audit$ UNTIL=2026-10-01 sh audit.sh; echo "exit $?"
accepted risk PYSEC-2026-2275 expired on 2026-10-01: fix it, or decide again
exit 1
```

The first run **ignored two lines, the accepted advisory printed twice, and still failed**: the
other two are not accepted, and nobody said they were. That is the gate working. The second run
did not get as far as pip-audit, because the acceptance had expired, and it said so in words. An
acceptance with no end date is how a finding that was temporary in March is still in the report in
December, accepted by somebody who has left.

## The fix

Here the fix exists and is one line: the version `2.33.0` that the third advisory named.

```
ana@nft:~/audit$ sed -i 's/requests==2.31.0/requests==2.33.0/' requirements.txt
ana@nft:~/audit$ ~/venv/bin/pip-audit -r requirements.txt; echo "exit $?"
No known vulnerabilities found
exit 0
ana@nft:~/audit$ sh audit.sh; echo "exit $?"
No known vulnerabilities found
exit 0
```

**No known vulnerabilities, and exit 0**, from pip-audit and from the gate. The audit resolved
`requests` 2.33.0 and everything it pulls in, and found nothing against any of them on the day it
ran. The acceptance in `audit.sh` now ignores an advisory that no longer appears; take it out of
the script the same day, because an acceptance that outlives its finding is a decision nobody is
checking any more.

The virtual environment's own finding is fixed the same way, by upgrading pip:

```
ana@nft:~/audit$ ~/venv/bin/pip install -q --upgrade pip
ana@nft:~/audit$ ~/venv/bin/pip --version
pip 26.2.1 from /home/ana/venv/lib/python3.12/site-packages/pip (python 3.12)
ana@nft:~/audit$ ~/venv/bin/pip-audit; echo "exit $?"
No known vulnerabilities found
exit 0
```

Whatever pip is newest on the day you run it is what you get, so your version may be later than
this one. The audit of the environment is clean.

## Where it runs

The rule from lesson 1 holds only if this check is a step in the pipeline that builds the release:
`sh audit.sh`, failing the build on a non-zero exit, on every change and **on a schedule**, nightly
or weekly, on the branch that is in production. The scheduled run is the one that notices a new
advisory against code nobody has touched, and its failure goes to whoever owns the dependencies,
not to whoever happened to push last.
