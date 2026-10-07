#!/usr/bin/env bash
# The terminal sessions quoted in lesson 21 of javascript, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   sudo bash ../../lab.sh up        # once: the user, Node.js, the managers
#   sudo bash captures.sh
#
# What is STAGED rather than typed:
#
#   - the registry, after the first section. Every later install comes from
#     a Verdaccio at 127.0.0.1:4873 started empty by `lab.sh registry` with
#     the lesson's config.yaml, and filled by the lesson's publish-shelf.sh.
#     Nothing is downloaded from the public registry;
#   - ana's login to it, which the first section makes with npm adduser:
#     lab.sh sends the same request with curl and writes her token into
#     ~/.npmrc, where npm adduser writes it;
#   - the files ana wrote (put below), whose contents the lesson shows in full.
#
# The times npm, pnpm and Yarn print ("in 541ms") are this run's and change
# from one run to the next; nothing else in the transcripts should.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, npm 10.9.4, pnpm 10.28.0,
# Yarn 4.10.3 and Verdaccio 6.1.6, TZ=America/Sao_Paulo.

set -uo pipefail
cd "$(dirname "$0")"
LAB_SH=${LAB_SH:-../../lab.sh}
lab() { bash "$LAB_SH" "$@"; }
# A line that starts with ana@dev:~/js$ is what ana typed, and what came back.
on() { printf 'ana@dev:~/js$ %s\n' "$*"; lab exec ana "$*" 2>&1 || true; }
# The same, typed in a folder inside ~/js: each part of this lesson has one,
# so that one manager's files never meet another's.
at() { local d=$1; shift; printf 'ana@dev:~/js/%s$ %s\n' "$d" "$*"; lab exec ana "cd $d && $*" 2>&1 || true; }
# A file ana wrote. The lesson shows it in full.
put() {
  local f=$1 body
  body=$(cat)
  printf '#####F %s\n%s\n#####E\n' "$f" "$body"
  lab exec ana "mkdir -p \"\$(dirname '$f')\" && cat > '$f'" <<<"$body"
}
block() { printf '##### %s\n' "$1"; }
# THE FIRST SECTION (your-registry) is run as a student would run it, and not
# in the lab: a login shell as ana, with Ubuntu's own PATH and Node.js
# installed the way lesson 1 installs it. The shell reads ana's ~/.profile,
# which is Ubuntu's, and not the recording machine's /etc/profile. pnpm, Yarn
# and Verdaccio come from the public npm registry. The proxy variables of the
# recording machine are passed on unchanged, with NODE_EXTRA_CA_CERTS when it
# is set: the proxy's certificate, which npm needs and a student does not.
#
# STAGED in it: Node.js, installed with lesson 1's commands and not shown
# again; config.yaml and publish-shelf.sh, taken out of your-registry.md by
# lab/extract.mjs, so the files in the lesson are the ones that ran; and the
# second terminal: the registry is started in the background, and its block
# shows the line typed there and what it printed. npm adduser asks its three
# questions on a terminal, so it is run on one (a pseudo-terminal opened by
# Python) and answered from here; the transcript is what that terminal showed.
STUDENT_PATH=/usr/sbin:/usr/bin:/sbin:/bin
NET=$(env | grep -iE '^(https?_proxy|no_proxy)=' | tr '\n' ' ')
STUDENT_ENV="HOME=/home/ana USER=ana LOGNAME=ana LANG=C.UTF-8 TERM=dumb PATH=$STUDENT_PATH TZ=America/Sao_Paulo $NET ${NODE_EXTRA_CA_CERTS:+NODE_EXTRA_CA_CERTS=$NODE_EXTRA_CA_CERTS}"
# session 'command' ...: one terminal, opened fresh, with each command typed in it.
session() {
  local script="cd ~" c
  for c in "$@"; do
    script+=$'\n'"printf 'ana@dev:%s\$ %s\\n' \"\$(dirs +0)\" $(printf '%q' "$c")"$'\n'"$c 2>&1"
  done
  # shellcheck disable=SC2086
  runuser -u ana -- env -i $STUDENT_ENV bash --noprofile -c ". ~/.profile; $script" 2>&1 || true
}
student_clean() {
  pkill -u ana -f verdaccio 2>/dev/null; sleep 0.5
  rm -rf /home/ana/.local /home/ana/js-tools /home/ana/js /home/ana/js-registry /home/ana/.npm \
    /home/ana/.npmrc /home/ana/node-v22.22.0-linux-* /home/ana/.cache/node
}
EXTRACT="node $(cd ../.. && pwd)/lab/extract.mjs"
lab down >/dev/null
student_clean
session 'curl -fsSLO https://nodejs.org/dist/v22.22.0/node-v22.22.0-linux-x64.tar.xz' \
  'mkdir -p ~/.local/node ~/.local/bin' \
  'tar -xJf node-v22.22.0-linux-x64.tar.xz -C ~/.local/node --strip-components=1' \
  'ln -s ~/.local/node/bin/node ~/.local/node/bin/npm ~/.local/node/bin/npx ~/.local/bin/' >/dev/null

block managers
session 'npm install --global pnpm@10.28.0 @yarnpkg/cli-dist@4.10.3' \
  'ln -s ~/.local/node/bin/pnpm ~/.local/node/bin/yarn ~/.local/bin/' \
  'pnpm --version' 'yarn --version'

runuser -u ana -- mkdir -p /home/ana/js-registry
for f in config.yaml publish-shelf.sh; do
  $EXTRACT your-registry.md "$f" | runuser -u ana -- tee "/home/ana/js-registry/$f" >/dev/null
done

block registry-start
START='npx --yes verdaccio@6.1.6 --config ./config.yaml'
printf 'ana@dev:~/js-registry$ %s\n' "$START"
# shellcheck disable=SC2086
runuser -u ana -- env -i $STUDENT_ENV bash --noprofile -c \
  ". ~/.profile; cd ~/js-registry && setsid $START > /tmp/student-registry.out 2>&1 < /dev/null &"
for _ in $(seq 120); do
  curl -s -o /dev/null http://127.0.0.1:4873/-/ping 2>/dev/null && break
  sleep 0.5
done
sleep 1
cat /tmp/student-registry.out
rm -f /tmp/student-registry.out

block publish-shelf
session 'cd ~/js-registry' 'bash publish-shelf.sh'

block adduser
printf 'ana@dev:~$ %s\n' 'npm adduser --registry http://127.0.0.1:4873/'
# shellcheck disable=SC2086
runuser -u ana -- env -i $STUDENT_ENV npm_config_color=false python3 -c '
import os, pty, select, sys, time
pid, fd = pty.fork()
if pid == 0:
    os.chdir(os.environ["HOME"])
    os.execvp("bash", ["bash", "--noprofile", "-c", ". ~/.profile; npm adduser --registry http://127.0.0.1:4873/"])
answers = [(b"Username:", b"ana\r"), (b"Password:", b"ana-registry-password\r"), (b"Email:", b"ana@example.com\r")]
out = b""
end = time.time() + 60
while time.time() < end:
    if select.select([fd], [], [], 0.5)[0]:
        try:
            chunk = os.read(fd, 1024)
        except OSError:
            break
        if not chunk:
            break
        out += chunk
        for asked, answer in list(answers):
            if asked in out:
                os.write(fd, answer)
                answers.remove((asked, answer))
sys.stdout.write(out.decode().replace("\r\n", "\n"))
'

student_clean

lab reset >/dev/null
lab registry >/dev/null

# ---- package.json and a first install --------------------------------------
put first/.npmrc <<'X'
registry=http://127.0.0.1:4873/
audit=false
X
put first/package.json <<'X'
{
  "name": "shelf",
  "version": "1.0.0",
  "type": "module",
  "private": true
}
X
block first-install
at first 'npm install shelf-slug@1'
at first 'cat package.json'
at first 'ls node_modules'
put first/slug.js <<'X'
import { slug } from "shelf-slug";

console.log(slug("Grande Sertão: Veredas"));
X
block first-run
at first 'node slug.js'
block first-script
at first 'npm pkg set scripts.start="node slug.js"'
at first 'npm start'

# ---- versions and ranges ---------------------------------------------------
block versions
at first 'npm view shelf-slug versions'
block ranges
at first 'npm view shelf-slug@1.1.0 version'
at first 'npm view shelf-slug@~1.1.0 version'
at first 'npm view shelf-slug@^1.1.0 version'
at first 'npm view shelf-slug@latest version'
block outdated
at first 'npm install shelf-slug@1.0.0'
at first 'node slug.js'
at first 'npm outdated'
block major
at first 'npm install shelf-slug@2'
at first 'node slug.js 2>&1 | head -n 5'

# ---- the lockfile -----------------------------------------------------------
put lock/.npmrc <<'X'
registry=http://127.0.0.1:4873/
audit=false
X
put lock/package.json <<'X'
{
  "name": "lock",
  "version": "1.0.0",
  "type": "module",
  "private": true
}
X
block lock-install
at lock 'npm install shelf-format'
at lock 'npm ls --all'
block lock-file
at lock 'cat package-lock.json'
block lock-ci
at lock 'rm -rf node_modules'
at lock 'npm ci'
block lock-drift
at lock 'npm pkg set dependencies.shelf-slug=^2.0.0'
at lock 'npm ci 2>&1 | head -n 6'

# ---- pnpm -------------------------------------------------------------------
put pnpm/.npmrc <<'X'
registry=http://127.0.0.1:4873/
X
put pnpm/package.json <<'X'
{
  "name": "with-pnpm",
  "version": "1.0.0",
  "type": "module",
  "private": true
}
X
block pnpm-add
at pnpm 'pnpm add shelf-format'
at pnpm 'ls -A node_modules'
at pnpm 'readlink node_modules/shelf-format'
at pnpm 'ls node_modules/.pnpm'
at pnpm 'readlink node_modules/.pnpm/shelf-format@1.0.0/node_modules/shelf-slug'
at pnpm 'pnpm store path'
put shelf.js <<'X'
import { line } from "shelf-format";

console.log(line({ title: "A Hora da Estrela", year: 1977 }));
X
put phantom.js <<'X'
import { slug } from "shelf-slug";

console.log(slug("Dom Casmurro"));
X
block phantom-npm
on 'cp shelf.js phantom.js lock/ && cp shelf.js phantom.js pnpm/'
at lock 'node shelf.js'
at lock 'node phantom.js'
block phantom-pnpm
at pnpm 'node shelf.js'
at pnpm 'node phantom.js 2>&1 | head -n 5'

# ---- Yarn -------------------------------------------------------------------
put yarn/.yarnrc.yml <<'X'
npmRegistryServer: "http://127.0.0.1:4873"
unsafeHttpWhitelist:
  - 127.0.0.1
X
put yarn/package.json <<'X'
{
  "name": "with-yarn",
  "version": "1.0.0",
  "type": "module",
  "private": true
}
X
block yarn-add
at yarn 'yarn add shelf-format | cut -b5-'
at yarn 'ls -A'
at yarn 'ls ~/.yarn/berry/cache'
block yarn-run
on 'cp shelf.js phantom.js yarn/'
at yarn 'node shelf.js 2>&1 | head -n 5'
at yarn 'yarn node shelf.js'
at yarn 'yarn node phantom.js 2>&1 | head -n 8'

# ---- install scripts --------------------------------------------------------
put scripts/.npmrc <<'X'
registry=http://127.0.0.1:4873/
audit=false
X
put scripts/package.json <<'X'
{
  "name": "scripts",
  "version": "1.0.0",
  "type": "module",
  "private": true
}
X
block scripts-npm
at scripts 'npm install shelf-banner'
at scripts 'ls'
at scripts 'cat banner-was-here.txt'
block scripts-ignore
at scripts 'rm -rf node_modules banner-was-here.txt'
at scripts 'npm ci --ignore-scripts'
at scripts 'ls'
block scripts-pnpm
at pnpm 'pnpm add shelf-banner'
at pnpm 'ls'
block scripts-yarn
at yarn 'yarn add shelf-banner | cut -b5-'
at yarn 'ls'
at yarn 'rm banner-was-here.txt'
at yarn 'echo "enableScripts: false" >> .yarnrc.yml'
at yarn 'rm -rf .yarn/install-state.gz && yarn install | cut -b5- | grep YN0004'
at yarn 'ls'

# ---- publishing -------------------------------------------------------------
put shelf-count/.npmrc <<'X'
registry=http://127.0.0.1:4873/
X
put shelf-count/package.json <<'X'
{
  "name": "shelf-count",
  "version": "1.0.0",
  "description": "Counts books by decade.",
  "type": "module",
  "exports": "./index.js",
  "files": ["index.js"],
  "license": "MIT"
}
X
put shelf-count/index.js <<'X'
export function byDecade(books) {
  const counts = {};
  for (const { year } of books) {
    const decade = Math.floor(year / 10) * 10;
    counts[decade] = (counts[decade] ?? 0) + 1;
  }
  return counts;
}
X
put shelf-count/index.test.js <<'X'
import assert from "node:assert/strict";
import { byDecade } from "./index.js";

assert.deepEqual(byDecade([{ year: 1956 }, { year: 1958 }, { year: 1977 }]), { 1950: 2, 1970: 1 });
console.log("byDecade: ok");
X
block publish-check
at shelf-count 'node index.test.js'
at shelf-count 'npm whoami'
at shelf-count 'npm pack --dry-run 2>&1 | tail -n +3'
block publish
at shelf-count 'npm publish --loglevel=warn'
at shelf-count 'npm view shelf-count versions'
block publish-again
at shelf-count 'npm publish --loglevel=warn 2>&1 | head -n 2'
at shelf-count 'npm version patch'
at shelf-count 'npm publish --loglevel=warn'
at shelf-count 'npm view shelf-count versions'
block publish-use
at first 'npm install shelf-count'
put first/decades.js <<'X'
import { byDecade } from "shelf-count";

const books = [
  { title: "Dom Casmurro", year: 1899 },
  { title: "Grande Sertão: Veredas", year: 1956 },
  { title: "Vidas Secas", year: 1938 },
  { title: "A Hora da Estrela", year: 1977 },
  { title: "O Tempo e o Vento", year: 1949 },
  { title: "Sagarana", year: 1946 },
];
console.log(byDecade(books));
X
block publish-out
at first 'node decades.js'

lab down >/dev/null
