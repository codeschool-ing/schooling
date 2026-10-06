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
#   - the registry. Every install in this lesson comes from the lab's own
#     Verdaccio at 127.0.0.1:4873, started empty by `lab.sh registry` and
#     filled by lab/registry.sh with shelf-slug, shelf-format and shelf-banner.
#     Nothing is downloaded from the public registry, and the packages are
#     the lab's, written for this lesson;
#   - ana's login to it. registry.sh writes her token into ~/.npmrc, which is
#     what `npm login` does after asking for a password;
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
