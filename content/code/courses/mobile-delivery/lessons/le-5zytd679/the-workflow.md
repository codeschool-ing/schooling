---
title: The whole workflow
version: 1
---

**The release pipeline is the earlier lessons in order, each one a step that can stop it.** Nothing
in it is new; what is new is that it runs on every release, on a machine nobody configured by hand,
and that the decision to submit is made by the checks rather than by somebody's memory.

Here it is as a GitHub Actions workflow, `.github/workflows/release.yml`. *It was not run: GitHub's
runners are not reachable from the recording machine, and the iOS job needs a Mac. Every command in
the Linux jobs is one that ran earlier in this course.*

```yaml
# .github/workflows/release.yml: build, check and sign a release of the planner
name: release
on:
  push:
    tags: ["v*"]
  schedule:
    - cron: "17 9 * * *"

jobs:
  checks:
    runs-on: ubuntu-24.04
    timeout-minutes: 10
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 22.22.0
          cache: npm
      - run: npm ci
      - run: node expiry.ts certs
      - if: github.event_name == 'push'
        run: node preflight.ts

  android:
    needs: checks
    if: github.event_name == 'push'
    runs-on: ubuntu-24.04
    timeout-minutes: 30
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: 21
          cache: gradle
      - run: node version.ts "${GITHUB_REF_NAME#v}" "$((GITHUB_RUN_NUMBER % 100))"
      - run: ./gradlew bundleRelease
      - run: bash ci-sign-bundle.sh app/build/outputs/bundle/release/app-release.aab
        env:
          UPLOAD_KEYSTORE_B64: ${{ secrets.UPLOAD_KEYSTORE_B64 }}
          UPLOAD_PASS: ${{ secrets.UPLOAD_PASS }}
      - run: bundle exec fastlane android internal

  ios:
    needs: checks
    if: github.event_name == 'push'
    runs-on: macos-15
    timeout-minutes: 45
    steps:
      - uses: actions/checkout@v4
      - run: bundle exec fastlane ios beta
        env:
          MATCH_PASSWORD: ${{ secrets.MATCH_PASSWORD }}
          APP_STORE_CONNECT_API_KEY: ${{ secrets.APP_STORE_CONNECT_API_KEY }}
```

## Reading it

- **Two triggers.** A tag such as `v1.5.0` runs the release; the schedule runs only the checks every
  morning, so the certificate check of lesson 2 goes red a month before the day it would have
  stopped a release. The minute in the cron line is 17, not 0, because every scheduled job in the
  world starts on the hour.
- **`checks` gates everything.** The two build jobs `need` it, so a red preflight, lesson 6, means
  nothing is built, signed or uploaded.
- **The build counter is the run number**, lesson 9, kept to two digits by the remainder. The
  version name is the tag.
- **The keystore secret reaches one step**, the signing one, as section "Signing inside the pipeline"
  asks. `ci-sign-bundle.sh` is the bundle's twin of `ci-sign.sh`, with `jarsigner` in place of
  `apksigner`.
- **The macOS job starts only when the checks pass**, so a typo in the listing costs Linux minutes,
  not Mac ones.
- **The last step of each build job is Fastlane**, lesson 11, uploading to the internal track and to
  TestFlight. From there, promotion is by a person, lesson 7.

## Pinning what runs

`actions/checkout@v4` names a tag, and a tag can be moved by whoever controls that repository. In a
real workflow, **pin every action to a full commit hash** with the version in a comment beside it,
such as `actions/checkout@<40-character hash> # v4.2.2`. The pipeline that holds your signing key
should not run code that somebody else can change without telling you.
