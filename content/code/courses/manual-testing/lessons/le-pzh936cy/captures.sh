#!/usr/bin/env bash
# The terminal sessions quoted in lesson 15 of manual-testing, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it; each block of output starts with a
# line `##### <name>` naming it.
#
#   bash ../../lab.sh isolated bash captures.sh
#
# The lesson reports a defect lesson 4 found in 1.0 and 1.1 still carries: a
# quantity that is not a number answers 500 with a Python traceback. It works
# on boxoffice 1.1, the program of lesson 1 with the edits of lesson 9, both
# extracted from those lessons by ../../lab.sh. What is STAGED rather than
# typed:
#   - the server is started by lab.sh with BOXOFFICE_NOW=2026-10-10T14:00:00-03:00
#     and BOXOFFICE_SEED=lab, TZ=America/Sao_Paulo, and PYTHONUNBUFFERED=1 so
#     its log reaches the file as each request arrives;
#   - "browser" fills the booking form in a headless Chromium driven by the
#     repository's Playwright, the way the lesson's steps say to by hand, and
#     prints the status, the page title and the page's text;
#   - "server-log" sends the reproduction once more, out of the transcript, and
#     prints the one line the server wrote to its own terminal for it. The time
#     in that line is the machine's clock, which BOXOFFICE_NOW does not move.
#
# Recorded 2026-10-10 on Ubuntu 24.04 with Python 3.13.16 and curl 8.5.0,
# TZ=America/Sao_Paulo. Run as root with HOME=/home/ana, so the paths read as
# Ana's.

HERE=$(cd "$(dirname "$0")" && pwd)
LAB=$HERE/../../lab.sh
source "$LAB" lib
APP=$HOME/boxoffice
rm -rf "$APP"; bash "$LAB" app "$APP" || exit 1
bash "$LAB" release "$APP" || exit 1
bash "$LAB" serve "$APP" PYTHONUNBUFFERED=1 || exit 1
cd "$APP" || exit 1

block health
run 'curl http://127.0.0.1:8000/health'

block repro
run "curl -s -o /dev/null -w '%{http_code}\n' -d 'email=member@example.org&show=S2&quantity=two' http://127.0.0.1:8000/book"

block body
run "curl -s -d 'email=member@example.org&show=S2&quantity=two' http://127.0.0.1:8000/book"

block shrink
run "curl -s -d 'show=S2&quantity=two' http://127.0.0.1:8000/book | grep msg"
run "curl -s -d 'email=member@example.org&quantity=two' http://127.0.0.1:8000/book | grep msg"

block variants
run "curl -s -o /dev/null -w '%{http_code}\n' -d 'email=member@example.org&show=S2&quantity=' http://127.0.0.1:8000/book"
run "curl -s -o /dev/null -w '%{http_code}\n' -d 'email=member@example.org&show=S2&quantity=2.5' http://127.0.0.1:8000/book"
run "curl -s -o /dev/null -w '%{http_code}\n' -d 'email=member@example.org&show=S2&quantity=7' http://127.0.0.1:8000/book"
run "curl -s -d 'email=member@example.org&show=S2&quantity=7' http://127.0.0.1:8000/book | grep msg"

block student
run "curl -s -d 'email=member@example.org&show=S2&quantity=2&student=on' http://127.0.0.1:8000/book | grep -A1 'ticket(s)'"

block browser
( cd /home/user/schooling && node --input-type=module - <<'JS'
import { chromium } from 'playwright';
const b = await chromium.launch();
const p = await b.newPage();
await p.goto('http://127.0.0.1:8000/book?show=S2');
await p.fill('#email', 'member@example.org');
await p.fill('input[name=quantity]', 'two');
const [r] = await Promise.all([p.waitForNavigation(), p.click('button')]);
console.log(`Chromium ${b.version()}: ${r.status()} at ${p.url()}, title ${JSON.stringify(await p.title())}`);
console.log(await p.innerText('body'));
await b.close();
JS
)

block server-log
n=$(wc -l <"$APP/server.log")
curl -s -o /dev/null -d 'email=member@example.org&show=S2&quantity=two' http://127.0.0.1:8000/book
sleep 0.2
tail -n +$((n + 1)) "$APP/server.log"
