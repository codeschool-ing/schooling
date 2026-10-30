---
title: Signing inside the pipeline
version: 1
---

**A pipeline that signs has to hold the key, and the whole question is how it holds it without the
key ending up anywhere else.** Lesson 1 kept the upload keystore out of the repository. The pipeline
gets it the other way: as an **encrypted secret** of the CI service, given to the one job that signs,
written to a temporary file, used and deleted.

## The keystore as a secret

CI secrets are text, and a keystore is a binary file, so it is stored as **Base64**, a text encoding
of the bytes. On your computer:

```sh
base64 -w0 ~/signing/upload.jks
```

The output, one long line, is pasted into the repository's secrets as `UPLOAD_KEYSTORE_B64`, and
the password as `UPLOAD_PASS`. On a Mac, `base64 -i upload.jks` does the same. **The secret store
is now the second copy of the key**, and the encrypted backup of lesson 1 the first; the file on the
laptop can be deleted.

## The signing step, runnable here

The step a pipeline runs is a short script, and it runs the same on your computer when the two
secrets are in the environment. Save this as `ci-sign.sh` in `~/planner`:

```sh
# ci-sign.sh: the signing step of the release pipeline, runnable on your own computer
set -euo pipefail
: "${UPLOAD_KEYSTORE_B64:?the keystore secret is missing}"
: "${UPLOAD_PASS:?the keystore password is missing}"

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
printf '%s' "$UPLOAD_KEYSTORE_B64" | base64 -d > "$work/upload.jks"

apksigner sign --ks "$work/upload.jks" --ks-key-alias upload --ks-pass env:UPLOAD_PASS \
  --out "$1" "$2"
apksigner verify --print-certs "$1" | grep DN
```

`set -euo pipefail` stops at the first failure and at an unset variable. The two `:` lines refuse to
start without the secrets, with a sentence saying which one is missing. The keystore is written to a
fresh temporary folder that `trap` removes when the script ends, however it ends. Here it signs the
aligned APK of lesson 1, first with the two secrets exported the way a CI service exports them,
then with the keystore's secret left out, as in a job that was not given it:

```
ana@dev:~/planner$ bash ci-sign.sh planner-ci.apk ~/signing/planner-aligned.apk
Signer #1 certificate DN: CN=Ana Souza, O=Study Planner, C=BR
ana@dev:~/planner$ bash ci-sign.sh planner-ci.apk ~/signing/planner-aligned.apk
ci-sign.sh: line 3: UPLOAD_KEYSTORE_B64: the keystore secret is missing
```

## Rules that keep the key in the secret store

- **Never print a secret, and never turn on `set -x` in a step that has one.** Tracing echoes every
  command with its variables expanded. CI services mask a secret's exact value in logs, and the
  Base64 of a keystore, split across lines or decoded, is not that exact value.
- **Give the secret only to the job that signs.** Tests, lint and the listing check run without it,
  so a test that prints its environment cannot leak it.
- **Never give it to pull requests from forks.** GitHub Actions does not pass secrets to them by
  default, and a workflow that changes that hands the key to anybody who opens a pull request.
- **Sign the upload, not the release.** With Play App Signing the pipeline holds only the upload key,
  so a leaked pipeline costs a reset, lesson 1, not the app.

## The iOS half

The iOS job needs the distribution certificate with its private key, and a profile. Lesson 2's
three answers apply: **fastlane match** fetches them from an encrypted repository using one
passphrase as the secret; **App Store Connect API keys**, a `.p8` key with its issuer and key IDs as
secrets, let Xcode download what it needs; **EAS** holds them itself. A raw `.p12` file in a secret,
imported into a temporary keychain, is the manual version of the same thing. *Not run: these need a
Mac and an Apple account.*
