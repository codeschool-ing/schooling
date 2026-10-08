#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of javascript, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   sudo bash ../../lab.sh up        # once: the user, Node.js, the browser
#   sudo bash captures.sh
#
# The first part needs the network, and the second runs in the lab.
#
# What is STAGED rather than typed: the files ana wrote (put below), whose
# contents the lesson shows in full.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0 and Chromium 141,
# TZ=America/Sao_Paulo.
set -uo pipefail
cd "$(dirname "$0")"
LAB_SH=${LAB_SH:-../../lab.sh}
lab() { bash "$LAB_SH" "$@"; }
# A line that starts with ana@dev:~/js$ is what ana typed, and what came back.
on() { printf 'ana@dev:~/js$ %s\n' "$*"; lab exec ana "$*" 2>&1 || true; }
# What a program printed, without the command, for a lesson that shows the
# program and its output side by side.
run() { lab exec ana "$*" 2>&1 || true; }
# A file ana wrote. The lesson shows it in full.
put() {
  local f=$1 body
  body=$(cat)
  printf '#####F %s\n%s\n#####E\n' "$f" "$body"
  lab exec ana "mkdir -p \"\$(dirname '$f')\" && cat > '$f'" <<<"$body"
}
block() { printf '##### %s\n' "$1"; }
# THE SETUP SECTION (your-computer, and the failures in when-setup-fails) is
# run as a student would run it, and not in the lab: a login shell as ana,
# with Ubuntu's own PATH and nothing of the lab's on it, so ~/.local/bin is
# only searched once it exists and a new terminal is a new login shell. The
# shell reads ana's ~/.profile, which is Ubuntu's, and not the recording
# machine's /etc/profile, which puts programs of its own on the PATH. It
# downloads Node.js from nodejs.org and Playwright from the npm registry. The
# recording machine reaches the network through a proxy, and the proxy
# variables are passed on unchanged, with NODE_EXTRA_CA_CERTS when it is set:
# the proxy's certificate, which npm needs to trust it and a student does not.
#
# STAGED in it: page.mjs and serve.mjs are taken out of your-computer.md by
# lab/extract.mjs, so the programs in the lesson are the ones that ran. And
# the browser: `npx playwright install` could not reach Playwright's download
# server from the recording machine, which already had the same build, so
# ~/.cache/ms-playwright is linked to it. The section says so.
STUDENT_PATH=/usr/sbin:/usr/bin:/sbin:/bin
NET=$(env | grep -iE '^(https?_proxy|no_proxy)=' | tr '\n' ' ')
# session 'command' ...: one terminal, opened fresh, with each command typed in it.
session() {
  local script="cd ~" c
  for c in "$@"; do
    script+=$'\n'"printf 'ana@dev:%s\$ %s\\n' \"\$(dirs +0)\" $(printf '%q' "$c")"$'\n'"$c 2>&1"
    # A command sent to the background is given a second to start, as a
    # person typing the next one would.
    [[ $c == *'&' ]] && script+=$'\n'"sleep 1"
  done
  # shellcheck disable=SC2086
  runuser -u ana -- env -i HOME=/home/ana USER=ana LOGNAME=ana LANG=C.UTF-8 TERM=dumb \
    PATH=$STUDENT_PATH TZ=America/Sao_Paulo $NET ${NODE_EXTRA_CA_CERTS:+NODE_EXTRA_CA_CERTS=$NODE_EXTRA_CA_CERTS} bash --noprofile -c ". ~/.profile; $script" 2>&1 || true
}
student_clean() {
  rm -rf /home/ana/.local /home/ana/js-tools /home/ana/js /home/ana/.cache/ms-playwright \
    /home/ana/.page-profile /home/ana/node-v22.22.0-linux-* /home/ana/Downloads /home/ana/.npm
}
EXTRACT="node $(cd ../.. && pwd)/lab/extract.mjs"
CHECK=$'echo \'<script>console.log("the browser works")</script>\' > check.html'
student_clean

block install
session 'uname -m' \
  'curl -fsSLO https://nodejs.org/dist/v22.22.0/node-v22.22.0-linux-x64.tar.xz' \
  'mkdir -p ~/.local/node ~/.local/bin' \
  'tar -xJf node-v22.22.0-linux-x64.tar.xz -C ~/.local/node --strip-components=1' \
  'ln -s ~/.local/node/bin/node ~/.local/node/bin/npm ~/.local/node/bin/npx ~/.local/bin/' \
  'node --version'

block node-version
session 'node --version' 'npm --version'

block playwright
session 'mkdir ~/js-tools ~/js' 'cd ~/js-tools' 'npm install playwright@1.56.0'

block dry-run
session 'cd ~/js-tools' 'npx playwright install --dry-run --only-shell chromium'

for f in page.mjs serve.mjs; do
  $EXTRACT your-computer.md "$f" | runuser -u ana -- tee "/home/ana/js-tools/$f" >/dev/null
done
WRAPPER=$(cat <<'SH'
cat > ~/.local/bin/page <<'EOF'
#!/bin/sh
exec node "$HOME/js-tools/page.mjs" "$@"
EOF
chmod +x ~/.local/bin/page
SH
)
printf '#####F wrapper\n%s\n#####E\n' "$WRAPPER"
session "$WRAPPER" >/dev/null

block no-browser
session 'cd ~/js' "$CHECK" 'page check.html 2>&1 | head -n 13'

runuser -u ana -- mkdir -p /home/ana/.cache
runuser -u ana -- ln -s "${PLAYWRIGHT_BROWSERS_PATH:-/opt/pw-browsers}" /home/ana/.cache/ms-playwright

block check
session 'cd ~/js' "$CHECK" 'page check.html'

block port-taken
session 'cd ~/js' 'node ~/js-tools/serve.mjs &' 'page check.html 2>&1 | head -n 5' 'kill %1'

# STAGED: the two programs saved in ~/Downloads as well, which is where a
# browser puts a file somebody saved from a page.
runuser -u ana -- mkdir -p /home/ana/Downloads
runuser -u ana -- cp /home/ana/js-tools/page.mjs /home/ana/js-tools/serve.mjs /home/ana/Downloads/
block no-playwright
session 'cd ~/js' 'node ~/Downloads/page.mjs check.html 2>&1 | head -n 5'

block wrong-arch
session 'curl -fsSLO https://nodejs.org/dist/v22.22.0/node-v22.22.0-linux-arm64.tar.xz' \
  'tar -xJf node-v22.22.0-linux-arm64.tar.xz' \
  './node-v22.22.0-linux-arm64/bin/node --version'

# STAGED: Ubuntu's package lists, refreshed as root, so that apt-cache answers
# with what Ubuntu 24.04 offers today.
apt-get update >/dev/null 2>&1
block ubuntu-nodejs
session 'apt-cache policy nodejs | head -n 3'

student_clean

lab reset >/dev/null

block version
on 'node --version'

put hello.js <<'JS'
console.log("Hello from Node");
console.log(2 + 3);
JS
block hello-node
on 'node hello.js'

put hello.html <<'HTML'
<!doctype html>
<title>Hello</title>
<script>
  console.log("Hello from the browser");
  console.log(2 + 3);
</script>
HTML
block hello-page
on 'page hello.html'

block print
on "node -p '2 ** 10'"

put where.js <<'JS'
console.log(typeof process, typeof document);
JS
put where.html <<'HTML'
<!doctype html>
<script src="where.js"></script>
HTML
block where
on 'node where.js'
on 'page where.html'

block typo
on 'node helo.js'

put quotes.js <<'JS'
console.log(“Hello”);
JS
block quotes
on 'node quotes.js 2>&1 | head -n 5'

block html-in-node
on 'node hello.html 2>&1 | head -n 5'

put asi-return.js <<'JS'
function book() {
  return
  {
    title: "Dom Casmurro"
  };
}

console.log(book());
JS
block asi-return
on 'node asi-return.js'

put asi-join.js <<'JS'
const shelf = "fiction"
const label = shelf
(function () {
  console.log("sorting the shelf")
})()
JS
block asi-join
on 'node asi-join.js 2>&1 | head -n 5'

put const.js <<'JS'
const title = "Dom Casmurro";
title = "Iracema";
JS
block const
on 'node const.js 2>&1 | head -n 5'

put const-array.js <<'JS'
const shelf = ["Dom Casmurro"];
shelf.push("Iracema");
console.log(shelf);

let read = 0;
read = read + 1;
console.log(read);
JS
block const-array
on 'node const-array.js'

put block.js <<'JS'
const year = 1899;
if (year < 1900) {
  let century = "nineteenth";
  console.log(century);
}
console.log(century);
JS
block block
on 'node block.js 2>&1 | head -n 6'

put shelf.js <<'JS'
function double(n) {
  return n * 2;
}

const triple = function (n) {
  return n * 3;
};

const half = (n) => n / 2;

const square = n => n * n;

const describe = (title, year = "unknown") => {
  const age = typeof year === "number" ? 2026 - year : "?";
  return title + " (" + year + "), " + age + " years old";
};

console.log(double(4), triple(4), half(4), square(4));
console.log(describe("Dom Casmurro", 1899));
console.log(describe("Iracema"));
JS
block shelf-out
run 'node shelf.js'

put object-arrow.js <<'JS'
const wrong = (title) => { title: title };
const right = (title) => ({ title: title });

console.log(wrong("Iracema"));
console.log(right("Iracema"));
JS
block object-arrow
on 'node object-arrow.js'

put new-arrow.js <<'JS'
const Shelf = () => {};
const s = new Shelf();
JS
block new-arrow
on 'node new-arrow.js 2>&1 | head -n 5'

put template.js <<'JS'
const title = "Dom Casmurro";
const year = 1899;

console.log("'" + title + "' came out in " + year + ", " + (2026 - year) + " years ago.");
console.log(`'${title}' came out in ${year}, ${2026 - year} years ago.`);
console.log(`${title.toUpperCase()} has ${title.length} characters`);
console.log(`Is it old? ${year < 1950 ? "yes" : "no"}`);
JS
block template-out
run 'node template.js'

put multiline.js <<'JS'
const card = `Title:  Dom Casmurro
Author: Machado de Assis
Year:   1899`;

console.log(card);
console.log(card.split("\n").length, "lines");
JS
block multiline
on 'node multiline.js'

put tagged.js <<'JS'
console.log(`C:\notes\today`);
console.log(String.raw`C:\notes\today`);

function shout(strings, ...values) {
  console.log(strings);
  console.log(values);
  return strings.reduce((out, s, i) => out + s + (i < values.length ? String(values[i]).toUpperCase() : ""), "");
}

const who = "ana";
console.log(shout`hello ${who}, it is ${2026}`);
JS
block tagged
on 'node tagged.js'
