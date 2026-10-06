#!/usr/bin/env bash
# The terminal sessions quoted in lesson 18 of javascript, as a script that
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
# STAGED: the browser's profile lives in ~/.page-profile, so what a page
# stores survives from one page command to the next, as it would between two
# visits. --fresh empties it first. The position the browser reports is set by
# page --geo, from the approximate coordinates of Praça da Sé in São Paulo;
# without --geo the lab's browser answers a geolocation request with a denial,
# as a user clicking "Block" would. The browser is headless and cannot display
# a notification, so the notifications section captures permissions only.
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
lab reset >/dev/null

put shelf.html <<'HTML'
<!doctype html>
<script>
  const visits = Number(localStorage.getItem("visits") ?? 0) + 1;
  localStorage.setItem("visits", visits);
  console.log("visit number", visits);

  localStorage.setItem("lastBook", { title: "Iracema" });
  console.log(localStorage.getItem("lastBook"));

  localStorage.setItem("prefs", JSON.stringify({ theme: "dark", perPage: 50 }));
  const prefs = JSON.parse(localStorage.getItem("prefs"));
  console.log(prefs.perPage, typeof localStorage.getItem("visits"));

  console.log(localStorage.length, localStorage.getItem("nothing-here"));
</script>
HTML
block local
on 'page shelf.html --fresh'
on 'page shelf.html'
on 'page shelf.html --do newtab'

put draft.html <<'HTML'
<!doctype html>
<script>
  const before = sessionStorage.getItem("draft");
  console.log("draft found:", before);
  sessionStorage.setItem("draft", "half a review of Iracema");
  localStorage.setItem("seen", "yes");
</script>
HTML
block session
on 'page draft.html --fresh --do reload --do newtab'

put full.html <<'HTML'
<!doctype html>
<script>
  const chunk = "x".repeat(1024 * 1024);
  let stored = 0;
  try {
    for (let i = 0; i < 20; i++) {
      localStorage.setItem(`chunk${i}`, chunk);
      stored = i + 1;
    }
  } catch (err) {
    console.log(err.name, "after", stored, "items of", chunk.length, "characters");
  }
  for (let i = 0; i < stored; i++) localStorage.removeItem(`chunk${i}`);
</script>
HTML
block full
on 'page full.html --fresh'

put where.html <<'HTML'
<!doctype html>
<button id="where">Find libraries near me</button>
<script>
  document.querySelector("#where").addEventListener("click", () => {
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        const { latitude, longitude, accuracy } = pos.coords;
        console.log("at", latitude.toFixed(4), longitude.toFixed(4), "within", accuracy, "m");
      },
      (err) => console.log("no position:", err.code, err.message),
      { timeout: 5000 },
    );
  });
</script>
HTML
block geo-denied
on "page where.html --fresh --do 'click #where' --wait 500"
block geo-granted
on "page where.html --fresh --geo -23.5503,-46.6339 --do 'click #where' --wait 500"

put permissions.html <<'HTML'
<!doctype html>
<script>
  for (const name of ["geolocation", "notifications"]) {
    navigator.permissions.query({ name }).then((status) => console.log(name, status.state));
  }
</script>
HTML
block permissions
on 'page permissions.html --fresh'
on 'page permissions.html --fresh --geo -23.5503,-46.6339 --grant notifications'
