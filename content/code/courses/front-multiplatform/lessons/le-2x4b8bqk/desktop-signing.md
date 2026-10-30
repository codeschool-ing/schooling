---
title: Signing a download for the desktop
version: 1
---

**On Windows a signature is a certificate somebody sells you**, and on Linux it is one you make yourself.
Both answer the same question for the person downloading: is this the file its author published?

## Windows: Authenticode, and a reputation

A Windows installer is signed with a **code signing certificate** bought from a certificate authority, which
checks who you are before it issues one. `signtool`, from Microsoft's Windows SDK, signs the `.exe` or `.msi`,
and electron-builder and Tauri call it when they are given the certificate. *Not run, for want of a Windows
machine and a certificate.*

**A signature alone does not stop SmartScreen's warning.** SmartScreen decides by reputation: how many people
have downloaded files signed by that certificate without trouble. A new certificate starts with none, so the
first downloads of a new app still show "Windows protected your PC", with the publisher's name under it
instead of "Unknown publisher". The certificate authorities' rules now keep the private key in a hardware
device or a cloud signing service, never in a file, which is also why CI signing on Windows goes through such
a service.

## Linux: a checksum, and a signature on it

Linux does not check a downloaded `.deb` or AppImage at all. What a careful project publishes beside the
packages is a list of their checksums and a signature on that list, so the person who downloads can check
both. A **checksum** is a short fingerprint of a file's bytes; `sha256sum` computes it:

```
ana@dev:~/planner/release$ sha256sum planner-0.1.0-x86_64.AppImage planner-0.1.0-amd64.deb > SHA256SUMS && cat SHA256SUMS
180cd8ba75dde288d5bc48a6c5606ec33cd8445cf5b8b8254027a500b4170961  planner-0.1.0-x86_64.AppImage
d717802a934e74a120b59498e647e71a372c9d6c64b78ee60fce26c205c97635  planner-0.1.0-amd64.deb
```

**One changed byte gives a different checksum**, which is the whole point. Here a copy of the `.deb` with one
character added at the end, beside the original, the first sixteen characters of each:

```
ana@dev:~/planner/release$ cp planner-0.1.0-amd64.deb /tmp/copy.deb && printf x >> /tmp/copy.deb && sha256sum /tmp/copy.deb planner-0.1.0-amd64.deb | cut -c1-16
9fce823710bad8bc
d717802a934e74a1
```

A checksum on the same page as the file proves little, because whoever could change the file could change the
page. **So the list is signed**, with a GnuPG key that is yours. `gpg` comes with Ubuntu Desktop; on a minimal
system it is `sudo apt install gnupg`. On your own computer, leave out `--batch --pinentry-mode loopback --passphrase "$KEY_PASS"`
and gpg asks for the passphrase in a window of its own, which is the safer form; the recording machine had
no keyboard to type one into:

```
ana@dev:~/planner/release$ gpg --batch --pinentry-mode loopback --passphrase "$KEY_PASS" --quick-generate-key "Ana <ana@example.com>" ed25519 sign 2y 2>&1 | grep -v "^gpg: directory"
gpg: keybox '/home/ana/.gnupg/pubring.kbx' created
gpg: /home/ana/.gnupg/trustdb.gpg: trustdb created
gpg: revocation certificate stored as '/home/ana/.gnupg/openpgp-revocs.d/EACD08FC9452E9C6A31F6E6016E3ED681D265E99.rev'
ana@dev:~/planner/release$ gpg --list-keys --keyid-format short 2>&1 | grep -v "^gpg: "
/home/ana/.gnupg/pubring.kbx
----------------------------
pub   ed25519/1D265E99 2026-10-24 [SC] [expires: 2028-10-23]
      EACD08FC9452E9C6A31F6E6016E3ED681D265E99
uid         [ultimate] Ana <ana@example.com>
```

```
ana@dev:~/planner/release$ gpg --batch --pinentry-mode loopback --passphrase "$KEY_PASS" --armor --detach-sign SHA256SUMS
ana@dev:~/planner/release$ ls SHA256SUMS*
SHA256SUMS
SHA256SUMS.asc
ana@dev:~/planner/release$ gpg --armor --export ana@example.com > planner-signing-key.asc && head -n 1 planner-signing-key.asc
-----BEGIN PGP PUBLIC KEY BLOCK-----
```

**`SHA256SUMS.asc` is the signature, and `planner-signing-key.asc` is the public key** you publish once, on
your site or in the project's README, so that people can check every release against it. Checking is two
commands, the signature first and then the sums:

```
ana@dev:~/planner/release$ gpg --verify SHA256SUMS.asc SHA256SUMS 2>&1 | grep -E "Good|BAD"
gpg: Good signature from "Ana <ana@example.com>" [ultimate]
ana@dev:~/planner/release$ sha256sum -c SHA256SUMS
planner-0.1.0-x86_64.AppImage: OK
planner-0.1.0-amd64.deb: OK
```

`[ultimate]` is gpg trusting its owner's own key. On somebody else's computer, after `gpg --import
planner-signing-key.asc`, the same line comes with a warning that the key is not certified with a trusted
signature: gpg checked the signature, and is reminding them that they decided by themselves that the key is
yours. And a list that somebody edited after it was signed is refused by name, whatever the edit:

```
ana@dev:~/planner/release$ sed "s/^./0/" SHA256SUMS > SHA256SUMS.edited
ana@dev:~/planner/release$ gpg --verify SHA256SUMS.asc SHA256SUMS.edited 2>&1 | grep -E "Good|BAD"
gpg: BAD signature from "Ana <ana@example.com>" [ultimate]
```

The `.gitignore` lines of the Android section go into the planner's repository in one commit, since the
key files are the one thing in this lesson that must never be committed:

```
ana@dev:~/planner$ git add .gitignore && git commit -q -m "Keep signing keys out of the repository" && git log --oneline -1
531775b Keep signing keys out of the repository
```
