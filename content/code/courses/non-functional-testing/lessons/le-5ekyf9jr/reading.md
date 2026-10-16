---
title: Reading a finding without panicking
version: 1
---

A scanner's report arrives as a list of identifiers next to a package name, often in red, and the
first reaction is to treat every line as a fire. **Most lines in most reports are not fires in your
system.** A finding says that a version of a library has a published flaw. Whether that flaw can
hurt *this* application is a second question, and the report cannot answer it, because it has
never read your code. Triage is answering it, one advisory at a time, with four questions.

## 1. What is it called, everywhere?

One flaw has several names, because several databases record it. pip-audit prints PyPI's, and
asks for the others with `-f json`. The `jq` below keeps the identifier, its aliases and the fixed
version, one line per advisory:

```
ana@nft:~/audit$ ~/venv/bin/pip-audit -r requirements.txt -f json 2>/dev/null | jq -r '.dependencies[].vulns[] | [.id, (.aliases | join(" ")), (.fix_versions | join(" "))] | @tsv' | sort -u
PYSEC-2026-1872	CVE-2024-47081 GHSA-9hjg-9r4m-mvj7	2.32.4
PYSEC-2026-1873	CVE-2024-35195 GHSA-9wx4-h78v-vm56	2.32.0
PYSEC-2026-2275	CVE-2026-25645 GHSA-gc5v-m9x4-r6x2	2.33.0
```

- **`PYSEC-…`** is the Python advisory database's id, the one pip-audit printed.
- **`GHSA-…`** is the GitHub advisory database's id for the same flaw, usually where the most
  readable write-up lives.
- **`CVE-…`** is the identifier from the CVE programme, the one that is the same in every
  database, every scanner and every vendor's bulletin. **Search by the CVE**: it is how you find
  out that the finding in this report is the one a colleague already triaged in another.

The year in a `PYSEC` id is when that database recorded it, and the CVE says when it was
assigned: `CVE-2024-35195` reached the Python database as `PYSEC-2026-1873`. Neither date is how
old the flaw is in your code. That is the version you pinned, `2.31.0`, and how long it has been
pinned.

## 2. How bad is it, in general and here?

The usual measure is **CVSS**, the Common Vulnerability Scoring System: a score from 0 to 10, with
bands named low, medium, high and critical. The score an advisory publishes is the **base score**.
It describes the flaw in the abstract, assuming the worst plausible use of the library, and it is
the same for everybody who installs that version.

pip-audit prints no score. The advisory pages carry one, and the recording computer could not
reach them, so this lesson quotes none. Copying a number from memory into a lesson is exactly the
mistake to avoid in a triage table, too.

**The base score is where triage starts, not where it ends.** CVSS also defines an
**environmental** score, which the people who run the system work out for themselves: the same
flaw, adjusted for where the library sits, what data it touches, and what an attacker would need
already to use it. A flaw rated high in general can be low in a script that runs once a day on a
machine with no users; a medium one can be the worst thing in a payment service.

## 3. Is the vulnerable code reachable from yours?

This is the question that decides most findings, and the advisory's own text usually says what has
to be true for the flaw to matter. Ask for the description of the third one:

```
ana@nft:~/audit$ ~/venv/bin/pip-audit -r requirements.txt -f json --desc on 2>/dev/null | jq -r '[.dependencies[].vulns[] | select(.id == "PYSEC-2026-2275")][0].description'
### Impact The `requests.utils.extract_zipped_paths()` utility function uses a predictable filename when extracting files from zip archives into the system temporary directory. If the target file already exists, it is reused without validation. A local attacker with write access to the temp directory could pre-create a malicious file that would be loaded in place of the legitimate one.  ### Affected usages **Standard usage of the Requests library is not affected by this vulnerability.** Only applications that call `extract_zipped_paths()` directly are impacted.  ### Remediation Upgrade to at least Requests 2.33.0, where the library now extracts files to a non-deterministic location.  If developers are unable to upgrade, they can set `TMPDIR` in their environment to a directory with restricted write access.
```

**"Standard usage of the Requests library is not affected."** The flaw is in one function,
`extract_zipped_paths()`, and only code that calls it is exposed. The other two descriptions name
their conditions the same way: `PYSEC-2026-1873` matters only to a session that once sent a
request with `verify=False`, and `PYSEC-2026-1872` only to an application that sends requests to
URLs somebody else crafted, while a `.netrc` file holds credentials. Now look for those conditions
in the code:

```
ana@nft:~/audit$ grep -n -e 'verify=False' -e 'trust_env' -e 'extract_zipped_paths' notify.py; echo "exit $?"
exit 1
ana@nft:~/audit$ grep -n -e 'url' notify.py
9:    url = os.environ["NOTIFY_URL"]          # set by whoever deploys it, never typed by a customer
10:    session.post(url, json={"text": f"show {show_id} is sold out"}, timeout=5)
```

None of the three patterns is in `notify.py`; `grep` found nothing and exited with 1. The URL comes
from one place, an environment variable set by whoever deploys the helper, and never from a
customer. A search like this is a first answer, not a proof: a call through a variable, or through
another library, would not show up in a `grep`. **Reachability is what turns *the library has a
flaw* into *we are exposed to it*,** and it deserves the same care as a test.

## 4. Is it real at all?

A **false positive** is a finding that is wrong about your system: the scanner matched the wrong
package of the same name, it read a version that is not the one installed, or the vendor of your
system patched the flaw without changing the version number. A finding that is right about the
library and unreachable from your code is not a false positive. It is a **true positive with a low
priority**, and keeping those two apart is what lets the next person trust the triage. The
vocabulary of true and false positives and negatives has a lesson of its own,
`security-fundamentals` lesson 11.

## The triage, written down

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l21-triage\" aria-label=\"The pip-audit report on requests 2.31.0, narrowed step by step. Six lines in the report. Three advisories once the duplicates are removed: PYSEC-2026-1873, PYSEC-2026-1872 and PYSEC-2026-2275. None of the three reachable from notify.py. One decision that settles all three: upgrade to 2.33.0.\"><text x=\"360.0\" y=\"20.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">count decisions, not lines</text><rect x=\"160.0\" y=\"44.0\" width=\"400.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"182.0\" y=\"64.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"16\" font-weight=\"600\" fill=\"var(--paper)\">6</text><text x=\"204.0\" y=\"57.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">lines in the report</text><text x=\"204.0\" y=\"73.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">each advisory printed twice</text><rect x=\"190.0\" y=\"94.0\" width=\"340.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"212.0\" y=\"114.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"16\" font-weight=\"600\" fill=\"var(--paper)\">3</text><text x=\"234.0\" y=\"107.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">advisories</text><text x=\"234.0\" y=\"123.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">one per CVE</text><rect x=\"215.0\" y=\"144.0\" width=\"290.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"237.0\" y=\"164.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"16\" font-weight=\"600\" fill=\"var(--paper)\">0</text><text x=\"259.0\" y=\"157.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">reachable from notify.py</text><text x=\"259.0\" y=\"173.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">grep found none of the conditions</text><rect x=\"240.0\" y=\"194.0\" width=\"240.0\" height=\"40.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"262.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"16\" font-weight=\"600\" fill=\"var(--amber)\">1</text><text x=\"284.0\" y=\"207.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">decision</text><text x=\"284.0\" y=\"223.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">requests==2.33.0</text></svg>", "caption": "Six lines became three advisories, none reachable, and one upgrade that closes all of them."}
```

| advisory | aliases | matters if | in notify.py | decision |
|---|---|---|---|---|
| `PYSEC-2026-1873` | `CVE-2024-35195` | a session ever sends with `verify=False` | no | fix: upgrade to 2.32.0 or later |
| `PYSEC-2026-1872` | `CVE-2024-47081` | URLs come from outside, and a `.netrc` holds credentials | no: the URL is the deployer's | fix: upgrade to 2.32.4 or later |
| `PYSEC-2026-2275` | `CVE-2026-25645` | the code calls `extract_zipped_paths()` | no | fix: upgrade to 2.33.0 or later |

**Three findings, none reachable, and still three decisions to fix.** Unreachable today is not
unreachable after the next change, and here one upgrade, to `2.33.0`, removes all three. When the
fix is that cheap, the triage only decides how urgent it is. The next section takes the other
case, where the fix cannot happen yet.
