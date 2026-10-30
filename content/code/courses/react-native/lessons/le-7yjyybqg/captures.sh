#!/usr/bin/env bash
# The terminal sessions quoted in lesson 20 of react-native, as a script that
# produces them; lab/fill.py pastes each block into its fence.
#
#   sudo bash captures.sh > out.txt
#
# It starts from the ~/planner lesson 19 left, and leaves it for lesson 21.
# Every file it writes is taken from this lesson's .md by lab/extract.py.
#
# STAGED, beyond what lab.sh says for every lesson:
#   - PLANNER_KEY_PASSWORD is set in the environment of every command, as the
#     section asks the student to set it from a password manager; its value
#     here is a throwaway, for a key made for this recording and discarded.
#   - `expo prebuild`'s and Gradle's reports go to /dev/null.
#   - Nothing here talks to Expo's servers: api.expo.dev refused the machine
#     that recorded this, so eas.json is written and checked as JSON only.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
start_from le-jngsbrfg
P=/home/ana/planner
RUNENV="export PLANNER_KEY_PASSWORD=recorded-and-thrown-away-4f9c"

block keystore
run /home/ana 'keytool -genkeypair -storetype PKCS12 -keystore planner-upload.p12 -alias upload -keyalg RSA -keysize 2048 -validity 10000 -storepass:env PLANNER_KEY_PASSWORD -dname "CN=Ana, O=Study planner, C=BR"'
run /home/ana 'keytool -list -v -keystore planner-upload.p12 -storepass:env PLANNER_KEY_PASSWORD | grep -E "Alias|Owner|Valid|SHA256:"'
run $P 'grep -n "p12\|jks" .gitignore'

block debugsigned
run $P 'npx expo prebuild --platform android --clean --no-install > /dev/null 2>&1'
run $P/android './gradlew :app:assembleRelease -PreactNativeArchitectures=arm64-v8a -q > /dev/null 2>&1'
run $P/android '$ANDROID_HOME/build-tools/37.0.0/apksigner verify --print-certs app/build/outputs/apk/release/app-release.apk | head -2'

block signed
run $P/android './gradlew :app:assembleRelease :app:bundleRelease -PreactNativeArchitectures=arm64-v8a -Pandroid.injected.signing.store.file=$HOME/planner-upload.p12 -Pandroid.injected.signing.store.password="$PLANNER_KEY_PASSWORD" -Pandroid.injected.signing.key.alias=upload -Pandroid.injected.signing.key.password="$PLANNER_KEY_PASSWORD" -q > /dev/null 2>&1'
run $P/android '$ANDROID_HOME/build-tools/37.0.0/apksigner verify --print-certs app/build/outputs/apk/release/app-release.apk | head -2'
run $P/android 'keytool -printcert -jarfile app/build/outputs/bundle/release/app-release.aab | grep -E "Owner|SHA256:"'
run $P/android 'du -h app/build/outputs/apk/release/app-release.apk app/build/outputs/bundle/release/app-release.aab'
run $P/android 'unzip -p app/build/outputs/apk/release/app-release.apk assets/index.android.bundle | head -c 64 | file -'

put eas.md eas.json $P/eas.json
block eas
run $P 'node -e "const e = require(\"./eas.json\"); console.log(Object.keys(e.build))"'
