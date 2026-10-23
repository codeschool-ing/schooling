---
title: ZAP's baseline scan, a scanner that only reads
version: 1
---

ZAP, the Zed Attack Proxy, is an open-source web application scanner. Its Docker images carry three
ready-made scripts: `zap-baseline.py`, `zap-full-scan.py` and `zap-api-scan.py`. **The baseline is
the one that only reads.** It crawls the site for up to a minute with ZAP's spider, which follows
links and fills in forms the way a visitor would, and then runs ZAP's passive rules over every
response it collected. Passive means the rules look at traffic and add none of their own: the
requests are the ordinary ones a browser makes, and nothing is sent to see what breaks.

That is what makes it safe to run often, and safe to run against something you did not build for
the purpose. It is also why it finds what it finds: headers, cookies, banners and leaks, all
readable from a normal response.

### The command

With the staging network of the previous section still up, run the scan from a container on it.
ZAP prints a line for every rule that passed, so the output goes to a file, the shell prints ZAP's
exit status, and `grep -v ^PASS` shows everything but the passes:

```
ana@vm:~/linkbox$ docker run --rm --network linkbox-staging zaproxy/zap-stable:2.17.0 zap-baseline.py -t http://linkbox-app:8000 -z -silent > /tmp/baseline.log; echo "exit status $?"
exit status 2
ana@vm:~/linkbox$ grep -v ^PASS /tmp/baseline.log
Using the Automation Framework
Total of 4 URLs
WARN-NEW: Missing Anti-clickjacking Header [10020] x 1 
	http://linkbox-app:8000/search?q=ZAP (200 OK)
WARN-NEW: X-Content-Type-Options Header Missing [10021] x 2 
	http://linkbox-app:8000 (200 OK)
	http://linkbox-app:8000/search?q=ZAP (200 OK)
WARN-NEW: User Controllable HTML Element Attribute (Potential XSS) [10031] x 1 
	http://linkbox-app:8000/search?q=ZAP (200 OK)
WARN-NEW: Content Security Policy (CSP) Header Not Set [10038] x 3 
	http://linkbox-app:8000 (200 OK)
	http://linkbox-app:8000/search?q=ZAP (200 OK)
	http://linkbox-app:8000/sitemap.xml (404 Not Found)
FAIL-NEW: 0	FAIL-INPROG: 0	WARN-NEW: 4	WARN-INPROG: 0	INFO: 0	IGNORE: 0	PASS: 57
```

The command, piece by piece:

| part | what it does |
|---|---|
| `--network linkbox-staging` | the scanner joins the private network, so it can reach `linkbox-app` and nothing published on the host |
| `-t http://linkbox-app:8000` | the target, by its name on that network |
| `-z -silent` | `-z` hands options to ZAP itself, and `-silent` is the one that matters (below) |

**`-silent` keeps ZAP from making requests of its own.** Left to itself, ZAP checks for a newer
release when it starts, can download updated rules and add-ons, and fetches news to show in its
interface. In a CI job each of those is wrong. It needs an outbound connection the job should not
need. It tells a third party that you are scanning, and when. It makes the scan depend on somebody
else's server being up. And a rule set updated between Monday's run and Tuesday's would make the
two disagree for a reason no commit explains. With `-silent` the scan uses exactly what is in the
image, `zaproxy/zap-stable:2.17.0`, every time. The rule called `ZAP is Out of Date [10116]`
passes for the same reason: ZAP never asked.

### Reading the output

**`Total of 4 URLs` is the first line to read**, because it bounds everything after it. The spider
found the home page, and the search, which it submitted with the word `ZAP` in the box. The other
two, `robots.txt` and `sitemap.xml`, are files ZAP asks every site for, and linkbox answers both
with 404. It never saw `POST /links`, which needs the token, or any short link, because the
database is empty. Whatever is wrong there, this scan cannot say.

Each `WARN-NEW` line is one rule that matched: its name, its id in brackets, how many responses
matched, and the URLs as evidence. **The rule ids are stable from run to run; the counts after the
`x` are not.** The same scan run again lists a rule against one URL more or one fewer, as the next
section's run of the same image shows, so read the ids and treat the counts as examples. Four rules
matched:

| id | rule | what the missing protection is for |
|---|---|---|
| 10020 | Missing Anti-clickjacking Header | another site could load linkbox in an invisible frame and line a button up under a visitor's click |
| 10021 | X-Content-Type-Options Header Missing | a browser may guess a response's type from its bytes and treat text as a script |
| 10031 | User Controllable HTML Element Attribute | the word the scanner typed came back inside an HTML attribute |
| 10038 | Content Security Policy (CSP) Header Not Set | nothing limits what the page may load if hostile markup ever reaches it |

The first, second and fourth are the same kind of finding: a header that a browser reads and that
linkbox does not send. The third is different, and the section on the fix shows why it is a false
positive. `NEW` in `WARN-NEW` means not listed as in progress in a progress file (`-p`), which
this pipeline does not use, so every finding is new on every run.

### The exit status

The last line counts the verdicts: no FAIL, four WARN, 57 rules passed. ZAP's baseline exits with
a number a pipeline can act on:

| status | meaning |
|---|---|
| 0 | every rule passed |
| 1 | at least one rule set to FAIL matched |
| 2 | at least one WARN, and no FAIL |
| 3 | the scan itself failed, for any other reason |

Here it is 2. **With no configuration every rule is a WARN**, so the baseline as it ships never
says FAIL at all: it reports, and leaves the decision to whoever runs it. Writing that decision
down is the next section.

When the scan is finished, take the staging down. The pipeline's script does the same in a trap,
so a failed run leaves nothing behind either:

```
ana@vm:~/linkbox$ docker rm -f linkbox-app && docker network rm linkbox-staging
linkbox-app
linkbox-staging
```
