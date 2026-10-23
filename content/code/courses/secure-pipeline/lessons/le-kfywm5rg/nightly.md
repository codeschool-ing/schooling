---
title: The scan in the nightly run, and the scan that is not run here
version: 1
---

The scan works and the build obeys it. Where it runs is the remaining decision, and lesson 2 set
the rule: **a check goes on every push only if it is fast enough that nobody waits for it.** The
dynamic stage is not. It needs the image built, a container started, ZAP's Java runtime up and a
spider that crawls for up to a minute. On this machine the stage takes about twenty seconds against
a service with four URLs, and the tests take one second.

So `dast` goes in the nightly list, beside lesson 2's rebuild. That costs little here, because the
three header rules have a fast twin: the unit test of the previous section fails on every push that
removes a header, and the scan confirms each night that the image, as built and started, still
sends them. Save the list as `ci/nightly`:

```
# The checks too slow to wait for on every push. They run once a day on
# main, after everything in ci/stages has passed.
rebuild
dast
```

### Commit, push, and the nightly run

```
ana@vm:~/linkbox$ git add -A
ana@vm:~/linkbox$ git status --short
M  app.py
A  ci/dast.sh
M  ci/nightly
A  ci/zap-rules.conf
M  tests/test_app.py
ana@vm:~/linkbox$ git commit -q -m "the security headers the baseline scan asked for, and the scan in the nightly run"
ana@vm:~/linkbox$ git push ci main
remote: run 1: main at 2034326        
remote: test: passed in 1s        
remote: sast: passed in 2s        
remote: build: passed in 1s        
remote: pipeline passed        
remote: run 1: passed        
To /home/ana/ci/linkbox.git
   3afa289..2034326  main -> main
```

The push ran `ci/stages`: tests, static analysis, build. The new test ran with the others, and no
scan ran. The nightly list runs once a day on main; by hand it is the same runner
with the list as its argument:

```
ana@vm:~/linkbox$ ci/pipeline.sh ci/nightly
rebuild: passed in 11s
dast: passed in 20s
pipeline passed
ana@vm:~/linkbox$ grep -v ^PASS ci-logs/dast.log
2026-10-23 04:48:03,393 Unable to copy yaml file to /zap/wrk/zap.yaml [Errno 30] Read-only file system: '/zap/wrk/zap.yaml'
Using the Automation Framework
Total of 4 URLs
WARN-NEW: User Controllable HTML Element Attribute (Potential XSS) [10031] x 1 
	http://linkbox-staging-8489-app:8000/search?q=ZAP (200 OK)
FAIL-NEW: 0	FAIL-INPROG: 0	WARN-NEW: 1	WARN-INPROG: 0	INFO: 0	IGNORE: 0	PASS: 60
```

The rebuild took eleven seconds, building the image with no cache, and the scan twenty. By hand,
with no `CI_COMMIT` set, the scan read `linkbox:dev`, the image the last manual build made; on the
CI server it reads `linkbox:<commit>`, the image that commit's push built. Its log says what the
run by hand said: one WARN, for 10031, and 60 rules passed.

### Active scanning: what it is

ZAP has a second mode, and it is the one people usually mean when they say "DAST". **An active
scan sends requests built to make the application fail.** After the spider has found the pages, the
active scanner takes every parameter of every request it found and sends variations of it: values
that would break a SQL query, a template, a file path or a shell command if the application put
them there unprotected. Then it reads the responses for the signs of each failure, such as a
database error, a delay, or its own value reflected where it should not be. `zap-full-scan.py` in
the same image is that: the spider, then the active scan, then the report.

It finds what the baseline cannot, because it goes looking. It also does what an attacker does,
except for the intent, and that has consequences for where it may run:

- **It writes.** On linkbox it would submit every form it can reach, so a scan with the token would
  fill the database with links made of test strings. On a real service it creates accounts, sends
  e-mails, places orders.
- **It can break the service.** Thousands of malformed requests in minutes look like an incident,
  trip rate limits, and on a fragile endpoint take the service down.
- **It takes a long time.** It sends many requests for every parameter it finds, so on a real
  application it runs for far longer than the baseline, which is why it is scheduled and never a
  push stage.

### Where an active scan may point

**Only at a target you own, made for the purpose: a staging built for the run, holding nothing
real.** The per-run staging of this lesson is exactly that, which is why it is worth building even
for a scan that only reads.

Never production. An active scan writes into real data, can page whoever is on call, and can take
the service down for real users. And never anybody else's system: scanning a service you have not
been authorised in writing to test can be a crime in many countries, and it is always a breach of
trust, whatever the reason for doing it. That includes a third-party service your application calls, a
customer's deployment and "just a quick look" at a competitor.

When a team does run one, it belongs in the nightly list, against the same throwaway staging the
baseline uses, with its own rules file deciding what fails. **This course does not run an active
scan**: linkbox's nightly list runs the baseline only, and everything above about the active mode
is from ZAP's documentation, not from a run on this machine.

### What no scan here can reach

The baseline found four URLs. `POST /links` is not one of them, because it needs the token, and so
nothing behind the token has been scanned at all. ZAP can authenticate: a context file passed with
`-n` and a user named with `-U`, or a header added to every request it sends. This pipeline does
not do it, and the course does not run it. An authenticated scan sees what a signed-in user sees,
and an authenticated active scan can do what a signed-in user can do, including delete. **Until
the scanner can sign in, what it reports is the anonymous surface only**, and a clean result means
"the pages a stranger can reach sent the right headers", nothing more.
