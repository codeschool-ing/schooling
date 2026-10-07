---
title: Um registro só seu
version: 1
---

**Esta aula instala pacotes, e depois publica um.** Uma versão publicada no registro público fica
lá para sempre, com o seu nome, então a prática aqui acontece onde ninguém mais vê: um registro
rodando no seu próprio computador, com alguns pacotes escritos para a aula. Ele se chama
**Verdaccio**, e fala a mesma língua que o `registry.npmjs.org`, então npm, pnpm e Yarn não
percebem a diferença.

Tudo aqui supõe o Node.js da aula 1. Esta seção acrescenta cerca de 80 MB: o Verdaccio no cache do
npm, e os outros dois gerenciadores de pacotes.

## pnpm e Yarn

O npm veio com o Node. Os outros dois são pacotes, e o npm os instala. O `--global` os põe ao lado do
Node em `~/.local/node` e não num projeto, e a linha do `ln` os torna comandos, como a aula 1 fez com
o `node`:

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

As versões são fixadas nas que gravaram esta aula, porque os dois imprimem a versão no que dizem. O
aviso no fim da instalação é o npm oferecendo uma versão mais nova de si mesmo, como na aula 1. O
Node também traz o **corepack**, que consegue instalar os dois para você; para o Yarn 4 ele baixa do
servidor do próprio Yarn, que a máquina em que este curso foi gravado não alcançava, então não foi
rodado aqui.

## O registro

O Verdaccio lê um arquivo de configuração. Salve isto como `~/js-registry/config.yaml`:

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

`storage` é onde os pacotes publicados ficam, e `htpasswd` o arquivo de contas, os dois ao lado do
arquivo de configuração. Qualquer um pode ler um pacote; só uma conta pode publicar. **O
`uplinks: {}` é a linha que o mantém privado**: o Verdaccio normalmente busca no registro público
o que não tem, e sem uplinks ele guarda só o que for publicado nele. O `listen` faz ele responder
apenas neste computador.

Abra um segundo terminal para ele, porque ele fica rodando até você pará-lo com Ctrl+C:

```
ana@dev:~/js-registry$ npx --yes verdaccio@6.1.6 --config ./config.yaml
npm warn deprecated @verdaccio/commons-api@10.2.0: Package no longer supported. Contact Support at https://www.npmjs.com/support for more info.
npm warn deprecated uuid@8.3.2: uuid@10 and below is no longer supported.  For ESM codebases, update to uuid@latest.  For CommonJS codebases, use uuid@11 (but be aware this version will likely be deprecated in 2028).
warn --- http address - http://127.0.0.1:4873/ - verdaccio/6.1.6
```

O `npx` baixou o Verdaccio 6.1.6 para o cache do npm e o iniciou, depois de dois avisos sobre
pacotes antigos dentro do Verdaccio que você pode ignorar. A última linha é o endereço em que ele
responde.

## Os pacotes da aula

Três pacotes pequenos, escritos para cada um mostrar um comportamento de um gerenciador de pacotes.
Salve isto como `~/js-registry/publish-shelf.sh`:

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

Cada versão é escrita numa pasta temporária e publicada de lá. De volta ao primeiro terminal, com o
registro rodando:

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

Sete versões de três pacotes. O script roda uma vez: uma segunda execução encontra a conta `shelf`
já criada e para na linha do `curl`. Para recomeçar, pare o registro e apague
`~/js-registry/storage` e `~/js-registry/htpasswd`.

## A sua conta

Publicar exige uma conta sua, que você cria pedindo uma ao registro:

```
ana@dev:~$ npm adduser --registry http://127.0.0.1:4873/
npm notice Log in on http://127.0.0.1:4873/
Username: ana
Password: 
Email: (this IS public) 
ana@example.com

Logged in on http://127.0.0.1:4873/.
```

O npm fez três perguntas. A senha não aparece enquanto você digita. O npm avisa que o e-mail é
público, o que no registro público ele é; este registro não o mostra a ninguém além de você. A
resposta é um **token**, uma sequência longa e aleatória que o npm escreveu em `~/.npmrc`, e o npm o
manda em toda requisição a este registro daqui em diante. A última seção da aula o usa.
