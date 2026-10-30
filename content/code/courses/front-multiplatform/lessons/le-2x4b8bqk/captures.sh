#!/usr/bin/env bash
# The terminal sessions quoted in lesson 14 of front-multiplatform, as a script
# that produces them; lab/fill.py pastes each block into its fence.
#
#   sudo bash captures.sh > out.txt
#
# It starts from what lesson 13 left, with its packages in ~/planner/release.
#
# STAGED, beyond what lab.sh says for every lesson:
#   - KEY_PASS is set in the environment of every command, and not typed: the
#     lesson has the student set it with `read -rs`, which needs a keyboard.
#     The value is a throwaway for the recording machine.
#   - gnupg is installed in the base (LESSON14 in lab.sh): Ubuntu Desktop has
#     it already, and the server image the machine is built from does not.
#   - The commit carries a fixed date.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
start_from 13
P=/home/ana/planner
R=$P/release
LAB as 'rm -rf ~/keys ~/.gnupg'
RUNENV="export KEY_PASS=recording-machine-only"

block keystore
run /home/ana 'mkdir -p ~/keys && chmod 700 ~/keys'
run /home/ana 'keytool -genkeypair -keystore ~/keys/planner-upload.jks -alias upload -keyalg RSA -keysize 4096 -validity 10000 -dname "CN=Ana, O=Study planner, C=BR" -storepass:env KEY_PASS'
block keystore-list
run /home/ana 'keytool -list -keystore ~/keys/planner-upload.jks -storepass:env KEY_PASS'
run /home/ana 'ls -l ~/keys'

block ignore
run $P 'printf "*.jks\n*.keystore\nkeystore.properties\n" >> .gitignore'
run $P 'git check-ignore -v android/app/planner-upload.jks android/keystore.properties'

block checksums
run $R 'sha256sum planner-0.1.0-x86_64.AppImage planner-0.1.0-amd64.deb > SHA256SUMS && cat SHA256SUMS'

block gpg-key
run $R 'gpg --batch --pinentry-mode loopback --passphrase "$KEY_PASS" --quick-generate-key "Ana <ana@example.com>" ed25519 sign 2y 2>&1 | grep -v "^gpg: directory"'
run $R 'gpg --list-keys --keyid-format short 2>&1 | grep -v "^gpg: "'

block gpg-sign
run $R 'gpg --batch --pinentry-mode loopback --passphrase "$KEY_PASS" --armor --detach-sign SHA256SUMS'
run $R 'ls SHA256SUMS*'
run $R 'gpg --armor --export ana@example.com > planner-signing-key.asc && head -n 1 planner-signing-key.asc'

block verify
run $R 'gpg --verify SHA256SUMS.asc SHA256SUMS 2>&1 | grep -E "Good|BAD"'
run $R 'sha256sum -c SHA256SUMS'

block tamper-sig
run $R 'sed "s/^./0/" SHA256SUMS > SHA256SUMS.edited'
run $R 'gpg --verify SHA256SUMS.asc SHA256SUMS.edited 2>&1 | grep -E "Good|BAD"'
block tamper-copy
run $R 'cp planner-0.1.0-amd64.deb /tmp/copy.deb && printf x >> /tmp/copy.deb && sha256sum /tmp/copy.deb planner-0.1.0-amd64.deb | cut -c1-16'

block commit
RUNENV="export GIT_AUTHOR_DATE='2026-10-23 20:00:00 -0300' GIT_COMMITTER_DATE='2026-10-23 20:00:00 -0300'"
run $P 'git add .gitignore && git commit -q -m "Keep signing keys out of the repository" && git log --oneline -1'
save_as 14
