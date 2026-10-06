---
title: The smoke test after every deploy
version: 1
---

A deploy that finished is not a deploy that worked. The files can be in place and the process
started while the program answers nothing, answers on the wrong port, or answers as the old version
because the restart did not happen. A **smoke test** is the short check run right after a deploy,
against the deployed program, that asks the two questions that matter first: **is it up, and is it
the version we meant?**

`shipquote`'s smoke test is twelve lines of shell:

```sh
#!/usr/bin/env bash
# The smoke test: is the deployed program up, and is it the version we meant?
#   ops/smoke.sh http://127.0.0.1:8200 1.4.0
set -uo pipefail
url=$1 want=$2
health=$(curl -s --max-time 2 "$url/health") || { echo "smoke: $url does not answer"; exit 1; }
[ "$health" = '{"status": "ok"}' ] || { echo "smoke: /health said $health"; exit 1; }
version=$(curl -s --max-time 2 "$url/version")
case $version in
  *"\"version\": \"$want\""*) echo "smoke: $url is up and running $want" ;;
  *) echo "smoke: $url runs $version, expected $want"; exit 1 ;;
esac
```

It asks `/health` and expects `{"status": "ok"}`, then asks `/version` and expects the version the
artifact's name promised. Either answer wrong, or no answer within two seconds, and it exits 1, so
the deploy that called it fails.

The name comes from electronics: switch the new board on and see whether smoke comes out. It is not
a test suite, and should not try to be one. **It runs against the real environment**, with its real
configuration, which is the one thing no earlier stage could test.

## A deploy that a smoke test stops

Here is a third environment, `preview`, whose configuration has a typo nobody would see at a glance:

```
ana@laptop:~/shipquote$ cat ~/envs/preview/config.env
SHIPQUOTE_PORT=84OO
ana@laptop:~/shipquote$ ops/deploy.sh preview dist/shipquote-1.4.0.tar.gz; echo "exit status $?"
restart: preview did not answer on port 84OO
exit status 1
ana@laptop:~/shipquote$ tail -1 ~/envs/preview/app.log
ValueError: invalid literal for int() with base 10: '84OO'
```

The port is `84OO`, with two capital letters O. The files were unpacked and the process started, and
it died at once: its log ends with `ValueError: invalid literal for int() with base 10: '84OO'`. The
deploy waited for an answer on that port, got none, said so, and **exited 1**.

That `ValueError` comes from `main()` in `app.py`, the function lesson 4 section 08 kept in the
coverage count rather than excluding, because no test in the suite runs it. This is the check that
covers it: **the smoke test is the test of the code that only runs in a deployment**, the entry
point, the reading of configuration, the binding to a port. Without it, this mistake would have
been found by the first customer.

## What else belongs in a smoke test

Keep it short, fast and safe to run against production:

- the health and version checks above;
- one real read through the main path, such as a quote for a known CEP, which proves the program
  can do its job and not only answer `/health`;
- **nothing that writes data** a customer could see, and nothing that costs money, such as a paid
  carrier call.

The acceptance test of lesson 1 section 08, free shipping from R$ 199,00 in every region, is a good
candidate to run against staging after the smoke test: it is the promise, checked through the
deployed program.
