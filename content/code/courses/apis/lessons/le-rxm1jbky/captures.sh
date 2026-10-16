#!/usr/bin/env bash
# The terminal sessions quoted in lesson 13 of apis, as a script that produces
# them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the machine, built by `lab.sh up` with
# every package of lesson 1's "The packages"; the files of lesson 1's "The
# shelf" and of this lesson's "The secured shelf" (`secure.py` and
# `site/page.html`), copied out of those sections by `shown` rather than pasted
# into nano. Both servers run in the background, where the lesson has the
# student run each in a terminal of its own, and `log` prints what those
# terminals showed. `chmod 600` on the keys and the order of the steps are as
# the lesson prints them.
#
# THE BROWSER. The lesson has the student open page.html in their own browser,
# on their own computer, at the VM's address; that was not done, because the
# machine has no address outside itself. What the lesson quotes as the
# browser's console is real Chromium (Playwright 1.56.0's headless build,
# chromium-1194, from /opt/pw-browsers on the recording computer), run OUTSIDE
# the lab machine but inside its network namespace (`nsenter -n` on the
# holder), so it reaches the machine's 127.0.0.1 the way the student's browser
# reaches the VM's address. `browser` below opens page.html from one origin,
# presses "Read it" then "Set the stock to 11", and prints the text of every
# console message, in order, and nothing else. Only those lines are quoted.
#
# What differs per run: dates, the Date header, the server logs' times, the
# keys, the certificates' serial numbers and validity dates.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.
source "$(dirname "$0")/../../capture.sh"
HERE_DIR=$(cd "$(dirname "$0")" && pwd)

machine l13

BROWSER_JS=$(mktemp --suffix=.cjs)
trap 'rm -f "$BROWSER_JS"; lab down l13' EXIT
cat > "$BROWSER_JS" <<'EOF'
const { chromium } = require('/home/user/schooling/node_modules/playwright');
(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage();
  page.on('console', (m) => console.log(m.text()));
  await page.goto(`${process.argv[2]}/page.html`);
  for (const id of ['#read', '#sell']) {
    const before = await page.locator('#out').textContent();
    await page.click(id);
    await page.waitForFunction((b) => document.getElementById('out').textContent !== b, before);
    await page.waitForTimeout(300);
  }
  await browser.close();
})();
EOF
browser() {
  nsenter -t "$(cat /var/lib/machines/apis-runs/l13/pid)" -n \
    env PLAYWRIGHT_BROWSERS_PATH=/opt/pw-browsers node "$BROWSER_JS" "$1" 2>&1 \
    | sed -e 's/[[:space:]]*$//' -e '/^$/d'
}

shown "$HERE_DIR/../le-f6652c1w/the-shelf.md" "$HERE_DIR/secure-shelf.md"

at '~/shelf'
block files
run 'ls; ls site'
serve 'python3 secure.py' api
at '~/shelf/site'
PORT=8080 serve 'python3 -m http.server 8080' web
at '~/shelf'
block api-start
log api

block simple
run "curl -si localhost:8000/v1/books/1 -H 'Origin: http://localhost:8080'"
run "curl -si localhost:8000/v1/books/1 -H 'Origin: http://127.0.0.1:8080'"

block browser-allowed
browser http://localhost:8080
block browser-blocked
browser http://127.0.0.1:8080
block api-log
log api
block web-log
log web

block preflight
run "curl -si -X OPTIONS localhost:8000/v1/books/1 -H 'Origin: http://localhost:8080' -H 'Access-Control-Request-Method: PATCH' -H 'Access-Control-Request-Headers: content-type'"
run "curl -si -X OPTIONS localhost:8000/v1/books/1 -H 'Origin: http://127.0.0.1:8080' -H 'Access-Control-Request-Method: PATCH' -H 'Access-Control-Request-Headers: content-type' | grep -iE '^(HTTP|allow|access-control|vary)'"
run "curl -si -X PATCH localhost:8000/v1/books/1 -H 'Origin: http://localhost:8080' -H 'Content-Type: application/json' -d '{\"stock\": 12}' | grep -iE '^(HTTP|access-control|vary)|stock'"

block mistakes
run "curl -si localhost:8000/v1/books/1 -H 'Origin: https://other.example' | grep -iE '^(HTTP|access-control|vary)'"
run "curl -si localhost:8000/v1/books/1 -H 'Origin: null' | grep -iE '^(HTTP|access-control|vary)'"
run "curl -s -X PATCH localhost:8000/v1/books/1 -H 'Origin: https://other.example' -H 'Content-Type: application/json' -d '{\"stock\": 0}'"
run "curl -s -X PATCH localhost:8000/v1/books/1 -H 'Content-Type: application/json' -d '{\"stock\": 12}'"

block headers
run 'curl -si -X FOO localhost:8000/v1/books/1'
run 'curl -si localhost:8000/v1/books/99'

block cleartext
run "curl -sv -u ana:correct-horse localhost:8000/v1/books/1 2>&1 | grep -i '^> authorization'"
run 'echo YW5hOmNvcnJlY3QtaG9yc2U= | base64 -d; echo'

block ca
run 'mkdir tls'
at '~/shelf/tls'
run "openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:P-256 -noenc -days 30 -subj '/CN=shelf lab CA' -keyout ca.key -out ca.crt"
run "openssl req -newkey ec -pkeyopt ec_paramgen_curve:P-256 -noenc -subj '/CN=localhost' -keyout server.key -out server.csr"
run "printf 'subjectAltName = DNS:localhost, IP:127.0.0.1\n' > server.ext"
run 'openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -days 30 -extfile server.ext -out server.crt'
run 'openssl x509 -in server.crt -noout -subject -issuer -ext subjectAltName'
run 'chmod 600 ca.key server.key; ls -l'

at '~/shelf'
stop api
block tls
PORT=8443 serve 'python3 secure.py --tls' tls
log tls
block verify
run 'curl -sS https://localhost:8443/v1/books/1'
run 'curl -sS --cacert tls/ca.crt https://localhost:8443/v1/books/1'
run 'curl -sS --cacert tls/ca.crt --resolve shelf.test:8443:127.0.0.1 https://shelf.test:8443/v1/books/1'
run "curl -si --cacert tls/ca.crt https://localhost:8443/v1/books/1 | grep -i '^strict'"
run "openssl s_client -connect 127.0.0.1:8443 -CAfile tls/ca.crt </dev/null 2>&1 | grep -E '^depth|^verify|^New,|Verify return code'"

block ssrf
run 'for a in 1.1.1.1 127.0.0.1 10.0.0.7 169.254.169.254 ::1; do python3 -c "import ipaddress, sys; a = sys.argv[1]; print(a, ipaddress.ip_address(a).is_global)" $a; done'

block tls-log
log tls
stop tls
stop web
