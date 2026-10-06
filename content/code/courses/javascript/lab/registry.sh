#!/usr/bin/env bash
# The packages in the lab's registry, and ana's account on it.
#
# Run by `lab.sh registry`, after the registry has started EMPTY: every run
# begins from no packages and no users, so what lesson 21 shows is what this
# file publishes and nothing that was left over.
#
# EVERY PACKAGE HERE IS THE LAB'S OWN, written below and published by the user
# "lab". None of them exists to be useful; each one is the smallest thing that
# shows one behaviour of a package manager:
#
#   shelf-slug     1.0.0; 1.1.0, which adds an option; 1.1.1, which fixes
#                  accented letters; 1.2.0, which adds a second option; and
#                  2.0.0, which renames the function and so breaks what 1.x
#                  promised, as a major version is allowed to. Five versions,
#                  so that each kind of range picks a different one
#   shelf-format   1.0.0, which depends on shelf-slug ^1.1.0: a dependency of
#                  a dependency
#   shelf-banner   1.0.0, with a postinstall script that writes one file into
#                  the project that installed it, so that the lesson can show
#                  an install running code, and the switches that stop it
#
# STAGED: ana's account. registry.sh creates the user "ana" and writes her
# token into /home/ana/.npmrc, which is what `npm login` would do after
# asking for a password. The lesson says so where it publishes.
set -euo pipefail

REGISTRY=http://127.0.0.1:4873
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

# adduser NAME PASSWORD: prints the new user's token.
adduser() {
  curl -fsS -X PUT -H 'content-type: application/json' \
    -d "{\"name\":\"$1\",\"password\":\"$2\"}" \
    "$REGISTRY/-/user/org.couchdb.user:$1" |
    node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>console.log(JSON.parse(s).token))'
}

LAB_TOKEN=$(adduser lab lab-registry-password)
printf 'registry=%s/\n//127.0.0.1:4873/:_authToken=%s\n' "$REGISTRY" "$LAB_TOKEN" > "$WORK/npmrc"

# pkg NAME VERSION: publishes the files written into $WORK/NAME-VERSION.
publish() {
  ( cd "$WORK/$1-$2" && npm publish --userconfig "$WORK/npmrc" --ignore-scripts >/dev/null 2>&1 ) ||
    { echo "could not publish $1@$2" >&2; exit 1; }
}

slug_version() {  # slug_version VERSION BODY
  mkdir -p "$WORK/shelf-slug-$1"
  cat > "$WORK/shelf-slug-$1/package.json" <<JSON
{
  "name": "shelf-slug",
  "version": "$1",
  "description": "Turns a book title into a slug for an address.",
  "type": "module",
  "exports": "./index.js",
  "license": "MIT"
}
JSON
  printf '%s\n' "$2" > "$WORK/shelf-slug-$1/index.js"
  publish shelf-slug "$1"
}

slug_version 1.0.0 'export function slug(title) {
  return title.toLowerCase().trim().replace(/\s+/g, "-");
}'

slug_version 1.1.0 'export function slug(title, { max = Infinity } = {}) {
  return title.toLowerCase().trim().replace(/\s+/g, "-").slice(0, max);
}'

slug_version 1.1.1 'export function slug(title, { max = Infinity } = {}) {
  return title
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase()
    .trim()
    .replace(/\s+/g, "-")
    .slice(0, max);
}'

slug_version 1.2.0 'export function slug(title, { max = Infinity, sep = "-" } = {}) {
  return title
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase()
    .trim()
    .replace(/\s+/g, sep)
    .slice(0, max);
}'

# 2.0.0 renames the export: code written for 1.x stops working.
slug_version 2.0.0 'export function toSlug(title, { max = Infinity, sep = "-" } = {}) {
  return title
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase()
    .trim()
    .replace(/\s+/g, sep)
    .slice(0, max);
}'

mkdir -p "$WORK/shelf-format-1.0.0"
cat > "$WORK/shelf-format-1.0.0/package.json" <<'JSON'
{
  "name": "shelf-format",
  "version": "1.0.0",
  "description": "One line per book.",
  "type": "module",
  "exports": "./index.js",
  "dependencies": { "shelf-slug": "^1.1.0" },
  "license": "MIT"
}
JSON
cat > "$WORK/shelf-format-1.0.0/index.js" <<'JS'
import { slug } from "shelf-slug";

export function line(book) {
  return `${book.title} (${book.year}) /books/${slug(book.title)}`;
}
JS
publish shelf-format 1.0.0

mkdir -p "$WORK/shelf-banner-1.0.0"
cat > "$WORK/shelf-banner-1.0.0/package.json" <<'JSON'
{
  "name": "shelf-banner",
  "version": "1.0.0",
  "description": "Prints a banner. Its install script writes a file, to show that it ran.",
  "type": "module",
  "exports": "./index.js",
  "scripts": { "postinstall": "node postinstall.js" },
  "license": "MIT"
}
JSON
cat > "$WORK/shelf-banner-1.0.0/index.js" <<'JS'
export const banner = "== shelf ==";
JS
cat > "$WORK/shelf-banner-1.0.0/postinstall.js" <<'JS'
import { writeFileSync } from "node:fs";
import { join } from "node:path";
import { userInfo } from "node:os";

// INIT_CWD is the directory the install was started in.
const where = join(process.env.INIT_CWD ?? process.cwd(), "banner-was-here.txt");
writeFileSync(where, `written by shelf-banner's postinstall, running as ${userInfo().username}\n`);
JS
publish shelf-banner 1.0.0

ANA_TOKEN=$(adduser ana ana-registry-password)
printf '//127.0.0.1:4873/:_authToken=%s\n' "$ANA_TOKEN" > /home/ana/.npmrc
chown ana: /home/ana/.npmrc
chmod 0600 /home/ana/.npmrc
echo "registry: shelf-slug 1.0.0 1.1.0 1.1.1 1.2.0 2.0.0, shelf-format 1.0.0, shelf-banner 1.0.0; users lab and ana"
