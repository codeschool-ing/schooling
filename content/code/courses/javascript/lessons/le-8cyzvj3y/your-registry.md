---
title: A registry of your own
version: 1
---

**This lesson installs packages, and then publishes one.** A version published to the public
registry stays there for good, under your name, so the practice here happens somewhere nobody else
can see: a registry running on your own computer, holding a few packages written for the lesson. It
is called **Verdaccio**, and it speaks the same language as `registry.npmjs.org`, so npm, pnpm and
Yarn cannot tell the difference.

Everything here assumes Node.js from lesson 1. This section adds about 80 MB: Verdaccio in npm's
cache, and the two other package managers.

## pnpm and Yarn

npm came with Node. The other two are packages themselves, and npm installs them. `--global` puts
them beside Node in `~/.local/node` rather than in a project, and the `ln` line makes them commands,
as lesson 1 did for `node`:

```
ana@dev:~$ npm install --global pnpm@10.28.0 @yarnpkg/cli-dist@4.10.3

added 2 packages in 1s

1 package is looking for funding
  run `npm fund` for details
npm notice
npm notice New major version of npm available! 10.9.4 -> 12.2.0
npm notice Changelog: https://github.com/npm/cli/releases/tag/v12.2.0
npm notice To update run: npm install -g npm@12.2.0
npm notice
ana@dev:~$ ln -s ~/.local/node/bin/pnpm ~/.local/node/bin/yarn ~/.local/bin/
ana@dev:~$ pnpm --version
10.28.0
ana@dev:~$ yarn --version
4.10.3
```

The versions are pinned to the ones this lesson was recorded with, because both print their
version in what they say. The notice at the end of the install is npm offering a newer version of
itself, as in lesson 1. Node also ships **corepack**, which can install the two for you; for
Yarn 4 it downloads from Yarn's own server, which the machine this course was recorded on could not
reach, so it was not run here.

## The registry

Verdaccio reads one settings file. Save this as `~/js-registry/config.yaml`:

```yaml
# config.yaml: a private npm registry on this computer, for lesson 21.
storage: ./storage
auth:
  htpasswd:
    file: ./htpasswd
packages:
  '**':
    access: $all
    publish: $authenticated
    unpublish: $authenticated
uplinks: {}
listen: 127.0.0.1:4873
log: { type: stdout, format: pretty, level: warn }
```

`storage` is where published packages go, and `htpasswd` the file of accounts, both beside the
settings file. Anybody may read a package; only an account may publish one. **`uplinks: {}` is
the line that keeps it private**: Verdaccio normally fetches from the public registry whatever it
does not have, and with no uplinks it holds only what is published into it. `listen` makes it answer
on this computer alone.

Open a second terminal for it, because it keeps running until you stop it with Ctrl+C:

```
ana@dev:~/js-registry$ npx --yes verdaccio@6.1.6 --config ./config.yaml
npm warn deprecated @verdaccio/commons-api@10.2.0: Package no longer supported. Contact Support at https://www.npmjs.com/support for more info.
npm warn deprecated uuid@8.3.2: uuid@10 and below is no longer supported.  For ESM codebases, update to uuid@latest.  For CommonJS codebases, use uuid@11 (but be aware this version will likely be deprecated in 2028).
warn --- http address - http://127.0.0.1:4873/ - verdaccio/6.1.6
```

`npx` downloaded Verdaccio 6.1.6 into npm's cache and started it, after two warnings about old
packages inside Verdaccio that you can ignore. The last line is the address it answers on.

## The lesson's packages

Three small packages, written so that each one shows one behaviour of a package manager. Save this
as `~/js-registry/publish-shelf.sh`:

```sh
# publish-shelf.sh: the packages lesson 21 installs, published into the
# registry in ~/js-registry. Run it once, while the registry is running.
#
#   shelf-slug     1.0.0; 1.1.0, which adds an option; 1.1.1, which fixes
#                  accented letters; 1.2.0, which adds a second option; and
#                  2.0.0, which renames the function and so breaks what 1.x
#                  promised. Five versions, so that each kind of range picks a
#                  different one
#   shelf-format   1.0.0, which depends on shelf-slug ^1.1.0: a dependency of
#                  a dependency
#   shelf-banner   1.0.0, with a postinstall script that writes one file into
#                  the project that installed it
set -euo pipefail

REGISTRY=http://127.0.0.1:4873
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

# The packages belong to an account called "shelf", created with the same
# request npm adduser sends. Its token goes into a settings file that only
# this script reads.
curl -fsS -X PUT -H 'content-type: application/json' \
  -d '{"name": "shelf", "password": "shelf-registry-password"}' \
  "$REGISTRY/-/user/org.couchdb.user:shelf" > "$WORK/answer.json"
TOKEN=$(node -p 'require(process.argv[1]).token' "$WORK/answer.json")
printf 'registry=%s/\n//127.0.0.1:4873/:_authToken=%s\n' "$REGISTRY" "$TOKEN" > "$WORK/npmrc"

# publish NAME VERSION: publishes the files written into $WORK/NAME-VERSION.
publish() {
  ( cd "$WORK/$1-$2" && npm publish --userconfig "$WORK/npmrc" --ignore-scripts --loglevel=error )
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
```

Each version is written into a temporary folder and published from there. Back in the first
terminal, with the registry running:

```
ana@dev:~$ cd ~/js-registry
ana@dev:~/js-registry$ bash publish-shelf.sh
+ shelf-slug@1.0.0
+ shelf-slug@1.1.0
+ shelf-slug@1.1.1
+ shelf-slug@1.2.0
+ shelf-slug@2.0.0
+ shelf-format@1.0.0
+ shelf-banner@1.0.0
```

Seven versions of three packages. The script runs once: a second run finds the account `shelf`
already there and stops at the `curl` line. To start over, stop the registry and delete
`~/js-registry/storage` and `~/js-registry/htpasswd`.

## Your account

Publishing needs an account of your own, which you create by asking the registry for one:

```
ana@dev:~$ npm adduser --registry http://127.0.0.1:4873/
npm notice Log in on http://127.0.0.1:4873/
Username: ana
Password: 
Email: (this IS public) 
ana@example.com

Logged in on http://127.0.0.1:4873/.
```

npm asked three questions. The password is not shown as you type it. npm warns that the e-mail is
public, which on the public registry it is; this registry shows it to nobody but you. The answer is a **token**, a long random string that npm wrote into `~/.npmrc`, and npm
sends it with every request to this registry from now on. The last section of the lesson uses it.
