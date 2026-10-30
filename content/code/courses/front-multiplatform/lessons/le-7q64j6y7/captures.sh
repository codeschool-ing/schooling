#!/usr/bin/env bash
# The terminal sessions quoted in lesson 16 of front-multiplatform, as a script
# that produces them; lab/fill.py pastes each block into its fence.
#
#   sudo bash captures.sh > out.txt
#
# It starts from what lesson 15 left, with the GnuPG key of lesson 14 in
# ~/.gnupg. RELEASE-NOTES.md is taken from a-worked-release.md by
# lab/extract.py.
#
# STAGED, beyond what lab.sh says for every lesson:
#   - KEY_PASS is set in the environment and not typed, as in lesson 14.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
start_from 15
P=/home/ana/planner
D=/home/ana/release-0.3.0
LAB as 'rm -rf ~/release-0.3.0 ~/download'
# An AppImage stopped by timeout leaves its unpacked copy in /tmp, a tmpfs.
LAB root 'rm -rf /tmp/appimage_extracted_* /tmp/copy.deb'

block history
run $P 'git log --oneline | wc -l'
run $P 'git log --oneline | head -n 8'
run $P 'git describe --tags'

block build
run $P 'npm run build > /dev/null && npx electron-builder --linux 2>&1 | grep -o "target=.*"'
run $P 'npx tauri build --bundles deb 2>&1 | tail -n 2'
run $P 'dpkg-deb -f src-tauri/target/release/bundle/deb/planner_0.3.0_amd64.deb Version'

block assemble
run $P 'mkdir ~/release-0.3.0 && cp release/planner-0.3.0-x86_64.AppImage release/planner-0.3.0-amd64.deb release/latest-linux.yml ~/release-0.3.0/'
put a-worked-release.md RELEASE-NOTES.md $D/RELEASE-NOTES.md
RUNENV="export KEY_PASS=recording-machine-only"
run $D 'sha256sum planner-0.3.0-x86_64.AppImage planner-0.3.0-amd64.deb > SHA256SUMS'
run $D 'gpg --batch --pinentry-mode loopback --passphrase "$KEY_PASS" --armor --detach-sign SHA256SUMS'
RUNENV=
run $D 'gpg --armor --export ana@example.com > planner-signing-key.asc'
run $D 'ls -sh1'

block check
run /home/ana 'mkdir download && cp release-0.3.0/* download/ && cd download && gpg --verify SHA256SUMS.asc SHA256SUMS 2>&1 | grep -E "Good|BAD" && sha256sum -c SHA256SUMS'
save_as 16
