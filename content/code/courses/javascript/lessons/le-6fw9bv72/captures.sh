#!/usr/bin/env bash
# The terminal sessions quoted in lesson 12 of javascript, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   sudo bash ../../lab.sh up        # once: the user, Node.js, the browser
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the files ana wrote (put below), whose
# contents the lesson shows in full.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0 and Chromium 141, every page
# Recorded on Ubuntu 24.04 with Node.js 22.22.0 and Chromium 141, every page
# opened with the lab's page command, TZ=America/Sao_Paulo.

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
lab reset >/dev/null

put listen.html <<'HTML'
<!doctype html>
<button id="lend">Lend</button>
<script>
  const button = document.querySelector("#lend");

  function onLend(event) {
    console.log(event.type, event.target.id, event.currentTarget === button);
  }
  button.addEventListener("click", onLend);
  button.addEventListener("click", () => console.log("second listener"), { once: true });
</script>
HTML
block listen
on "page listen.html --do 'click #lend' --do 'click #lend'"

put remove.html <<'HTML'
<!doctype html>
<button id="lend">Lend</button>
<script>
  const button = document.querySelector("#lend");
  let clicks = 0;
  function onLend() {
    clicks += 1;
    console.log("click", clicks);
    if (clicks === 2) button.removeEventListener("click", onLend);
  }
  button.addEventListener("click", onLend);
</script>
HTML
block remove
on "page remove.html --do 'click #lend' --do 'click #lend' --do 'click #lend'"

put bubble.html <<'HTML'
<!doctype html>
<ul id="books">
  <li class="book"><button class="lend">Lend</button></li>
</ul>
<script>
  const say = (where, phase) => (event) =>
    console.log(`${phase.padEnd(7)} ${where.padEnd(8)} target=${event.target.className}`);

  for (const [where, el] of [["document", document], ["ul", document.querySelector("ul")],
                             ["li", document.querySelector("li")], ["button", document.querySelector("button")]]) {
    el.addEventListener("click", say(where, "capture"), { capture: true });
    el.addEventListener("click", say(where, "bubble"));
  }
</script>
HTML
block bubble
on "page bubble.html --do 'click .lend'"

put stop.html <<'HTML'
<!doctype html>
<li class="book">Iracema <button class="lend">Lend</button></li>
<script>
  document.querySelector(".book").addEventListener("click", () => console.log("row opened"));
  document.querySelector(".lend").addEventListener("click", (event) => {
    event.stopPropagation();
    console.log("lent");
  });
</script>
HTML
block stop
on "page stop.html --do 'click .lend' --do 'click .book'"

put delegate.html <<'HTML'
<!doctype html>
<ul id="books">
  <li class="book" data-id="7">Iracema <button class="lend">Lend</button></li>
  <li class="book" data-id="12">Dom Casmurro <button class="lend">Lend</button></li>
</ul>
<button id="add">Add a book</button>
<script>
  const list = document.querySelector("#books");

  list.addEventListener("click", (event) => {
    const button = event.target.closest(".lend");
    if (!button) return;
    const row = button.closest(".book");
    console.log("lend book", row.dataset.id);
  });

  document.querySelector("#add").addEventListener("click", () => {
    const li = document.createElement("li");
    li.className = "book";
    li.dataset.id = "19";
    li.append("Macunaíma ");
    const b = document.createElement("button");
    b.className = "lend";
    b.textContent = "Lend";
    li.append(b);
    list.append(li);
  });
</script>
HTML
block delegate
on "page delegate.html --do 'click li:nth-child(2) .lend' --do 'click #add' --do 'click li:nth-child(3) .lend' --do 'click li:nth-child(1)'"

put default.html <<'HTML'
<!doctype html>
<a id="more" href="details.html">Details</a>
<script>
  document.querySelector("#more").addEventListener("click", (event) => {
    event.preventDefault();
    console.log("stayed on", location.pathname, "cancelled:", event.defaultPrevented);
  });
</script>
HTML
block default
on "page default.html --do 'click #more'"

put form.html <<'HTML'
<!doctype html>
<form id="loan">
  <label>Reader <input name="reader" required minlength="3"></label>
  <label>Copies <input name="copies" type="number" min="1" max="5" value="1"></label>
  <button>Lend</button>
</form>
<script>
  const form = document.querySelector("#loan");

  form.addEventListener("submit", (event) => {
    event.preventDefault();
    const data = new FormData(form);
    console.log("submitted:", JSON.stringify(Object.fromEntries(data)));
  });

  form.addEventListener("invalid", (event) => {
    console.log("invalid:", event.target.name, "-", event.target.validationMessage);
  }, { capture: true });

  form.elements.reader.addEventListener("input", (e) => console.log("input:", e.target.value));
  form.elements.reader.addEventListener("change", (e) => console.log("change:", e.target.value));
</script>
HTML
block form-invalid
on "page form.html --do 'click button'"
block form-short
on "page form.html --do 'fill [name=reader] an' --do 'click button'"
block form-ok
on "page form.html --do 'focus [name=reader]' --do 'press a' --do 'press n' --do 'press a' --do 'press Tab' --do 'fill [name=copies] 3' --do 'click button'"

put custom.html <<'HTML'
<!doctype html>
<form id="loan">
  <input name="reader" value="bia">
  <button>Lend</button>
</form>
<script>
  const blocked = new Set(["bia"]);
  const form = document.querySelector("#loan");
  const reader = form.elements.reader;

  form.addEventListener("submit", (event) => {
    event.preventDefault();
    reader.setCustomValidity(blocked.has(reader.value) ? "this reader has a book overdue" : "");
    if (!form.reportValidity()) {
      console.log("refused:", reader.validationMessage);
      return;
    }
    console.log("lent to", reader.value);
  });
</script>
HTML
put custom-fixed.html <<'HTML'
<!doctype html>
<form id="loan">
  <input name="reader" value="bia">
  <button>Lend</button>
</form>
<script>
  const blocked = new Set(["bia"]);
  const form = document.querySelector("#loan");
  const reader = form.elements.reader;

  reader.addEventListener("input", () => reader.setCustomValidity(""));

  form.addEventListener("submit", (event) => {
    event.preventDefault();
    reader.setCustomValidity(blocked.has(reader.value) ? "this reader has a book overdue" : "");
    if (!form.reportValidity()) {
      console.log("refused:", reader.validationMessage);
      return;
    }
    console.log("lent to", reader.value);
  });
</script>
HTML

block custom
on "page custom.html --do 'click button' --do 'fill [name=reader] ana' --do 'click button'"

put keys.html <<'HTML'
<!doctype html>
<div class="fake" onclick="console.log('div clicked')">Lend (a div)</div>
<button class="real">Lend (a button)</button>
<script>
  document.querySelector(".real").addEventListener("click", () => console.log("button clicked"));
  document.addEventListener("keydown", (event) => {
    console.log("keydown:", JSON.stringify(event.key), event.code, "on", document.activeElement.tagName);
  });
</script>
HTML
block custom-fixed
on "page custom-fixed.html --do 'click button' --do 'fill [name=reader] ana' --do 'click button'"

block keys
on "page keys.html --do 'press Tab' --do 'press Enter' --do 'press Space'"
