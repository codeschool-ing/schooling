#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of front-delivery, as a script that
# produces them. Its output is pasted into the lesson by lab/fill.py and not
# committed.
#
#   sudo bash captures.sh > /tmp/l4.txt
#   for f in *.md; do python3 ../../lab/fill.py $f /tmp/l4.txt; done
#
# It runs on the planner as lesson 3 left it, the commit tagged lesson-3, and
# tags what it leaves lesson-4. STAGED: planner.test is a name in the .test
# domain, which never exists on the internet; curl reaches it through
# --resolve, and lab.sh adds it to no_proxy. The authority and the certificate
# are made by the commands shown, and deleted at the end.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/lib.sh

bash ../../lab.sh down >/dev/null 2>&1
quiet '~/planner' 'git switch -q main; git reset -q --hard lesson-3 && git clean -fdq'
quiet '~' 'rm -rf ~/tls /tmp/pages'

# The host grows.
shown the-host-grows.md host.mjs '~/planner/host.mjs'
block host-commit
session '~/planner' 'git add host.mjs' 'git commit -qm "Rules and HTTPS for the host"'

# A certificate at home.
block tls
session '~' 'mkdir -p ~/tls && cd ~/tls' \
  'openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:P-256 -out ca.key' \
  'openssl req -x509 -key ca.key -out ca.crt -days 30 -subj "/CN=Planner lab CA"' \
  'openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:P-256 -out planner.key' \
  'openssl req -new -key planner.key -out planner.csr -subj "/CN=planner.test"' \
  'openssl x509 -req -in planner.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out planner.crt -days 30 -extfile <(printf "subjectAltName=DNS:planner.test")' \
  'openssl x509 -in planner.crt -noout -subject -issuer -ext subjectAltName'
quiet '~/planner' 'npm run build'
bg tls '~/planner' 'CERT=~/tls/planner.crt KEY=~/tls/planner.key node host.mjs dist 8443'
wait_port 8443
block tls-start
bg_show tls
block tls-curl
session '~/planner' 'curl -sS --resolve planner.test:8443:127.0.0.1 https://planner.test:8443/ -o /dev/null' \
  "curl -sS --cacert ~/tls/ca.crt --resolve planner.test:8443:127.0.0.1 https://planner.test:8443/ -o /dev/null -w '%{http_code}\n'" \
  'curl -sS --cacert ~/tls/ca.crt https://127.0.0.1:8443/ -o /dev/null'
block to-https
session '~/planner' 'curl -sI --resolve planner.test:8080:127.0.0.1 http://planner.test:8080/course/git'
bg_stop tls INT
quiet '~' 'rm -rf ~/tls'

# Redirects.
shown redirects.md public/_redirects '~/planner/public/_redirects'
quiet '~/planner' 'npm run build'
bg host '~/planner' 'node host.mjs'
wait_port 8080
block redirect
session '~/planner' 'npm run build > /dev/null' 'curl -sI http://127.0.0.1:8080/courses/git' \
  "curl -sL -o /dev/null -w '%{http_code} %{url_effective}\n' http://127.0.0.1:8080/courses/git"

# The deep link.
bg preview '~/planner' 'npm run preview'
wait_port 4173
sleep 1
block preview
bg_show preview
block deep
session '~/planner' "curl -s -o /dev/null -w '%{http_code}\n' http://localhost:4173/course/git" \
  "curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:8080/course/git"
bg_stop preview INT
block rewrite
session '~/planner' "echo '/* /index.html 200' >> public/_redirects" 'cat public/_redirects' 'npm run build > /dev/null' \
  "curl -s -o /dev/null -w '%{http_code} %{content_type}\n' http://127.0.0.1:8080/course/git" \
  "curl -s -o /dev/null -w '%{http_code} %{content_type}\n' http://127.0.0.1:8080/course/nothing" \
  "curl -s -o /dev/null -w '%{http_code} %{content_type}\n' http://127.0.0.1:8080/assets/nothing.js"
quiet '~/planner' 'git add public/_redirects && git commit -qm "Redirect old addresses, rewrite deep links"'
bg pages '~/planner' 'node host.mjs /tmp/pages 8081'
wait_port 8081
block pages
session '~/planner' 'rm -rf /tmp/pages && cp -r dist /tmp/pages && rm /tmp/pages/_redirects' \
  'cp /tmp/pages/index.html /tmp/pages/404.html' \
  "curl -s -o /dev/null -w '%{http_code} %{size_download}\n' http://127.0.0.1:8081/course/git" \
  'wc -c < /tmp/pages/index.html'
bg_stop pages INT
bg_stop host INT
quiet '~' 'rm -rf /tmp/pages'
quiet '~/planner' 'git tag -f lesson-4'
