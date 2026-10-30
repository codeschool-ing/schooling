#!/usr/bin/env bash
# The terminal sessions quoted in lesson 22 of android-apps, as a script that
# produces them. Every block of output starts with `##### <name>`.
#
#   sudo bash ../../lab.sh build && sudo bash ../../lab.sh install   # once
#   sudo bash captures.sh
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every file built
# here is lifted out of this lesson's .md by ../../lab.sh, so the file built
# is the block the student copies.
#
# What is STAGED rather than typed:
#   - the project starts as lesson 1 section 05 leaves it (`project`);
#   - THE PASSWORD. Section 04 has the student type the upload key's password
#     into `read -rs`, which a script cannot do. Every command shown with
#     `runp` runs with PLANNER_UPLOAD_PASSWORD already exported, set to a
#     throwaway value that protects a key made for this recording and used for
#     nothing else; the commands shown with `run` have no such variable, which
#     is how the `no-password` block fails;
#   - the key in ~/keys is removed before it is made, so every run of this
#     script makes a new one, with a new fingerprint and new dates.
#   - Nothing was uploaded anywhere: section 08's Play Console steps were not
#     run.
#
# Recorded on Ubuntu 24.04 with OpenJDK 21, Gradle 9.8.2, AGP 9.5.0, build
# tools 36.1.0 and Android CLI 1.1.16717390, TZ=America/Sao_Paulo, on
# 2026-10-30.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"
B='$ANDROID_HOME/build-tools/36.1.0'
runp() { _prompt "$_S" "$*"; bash "$LAB_SH" exec "$_D" "export PLANNER_UPLOAD_PASSWORD=recording-only-not-a-real-secret; $*" | _strip; }

block variants
project l22
MD=$HERE/build-types.md
put "$MD" app/build.gradle.kts
put "$MD" app/proguard-rules.pro
run "./gradlew --console=plain assembleDebug 2>&1 | grep -E '^BUILD'"
run 'find app/build/outputs/apk -name "*.apk" | sort'
run "$B/aapt2 dump badging app/build/outputs/apk/play/debug/app-play-debug.apk | grep -o \"name='[^']*' versionCode='[^']*' versionName='[^']*'\""
run "$B/aapt2 dump badging app/build/outputs/apk/direct/debug/app-direct-debug.apk | grep -o \"name='[^']*' versionCode='[^']*' versionName='[^']*'\""

block buildconfig
run 'find app/build/generated -name BuildConfig.java | sort'
run 'grep -h -E "APPLICATION_ID|UPDATES_FROM" app/build/generated/source/buildConfig/direct/debug/com/example/planner/BuildConfig.java'

block keytool
quiet 'rm -rf ~/keys'
run 'mkdir -p ~/keys && chmod 700 ~/keys'
runp "keytool -genkeypair -keystore ~/keys/planner-upload.jks -alias upload -keyalg RSA -keysize 4096 -validity 9125 -dname 'CN=Ana Example, O=Example, C=BR' -storepass:env PLANNER_UPLOAD_PASSWORD -keypass:env PLANNER_UPLOAD_PASSWORD"
runp "keytool -list -v -keystore ~/keys/planner-upload.jks -storepass:env PLANNER_UPLOAD_PASSWORD | grep -E 'Alias name|Keystore type|Owner|Valid from|SHA256:|Key Algorithm'"

block no-password
run "./gradlew --console=plain assemblePlayRelease 2>&1 | grep -E -A2 'What went wrong'"

block release
runp "./gradlew --console=plain assembleRelease bundlePlayRelease 2>&1 | grep -E '^BUILD|actionable'"
run 'find app/build/outputs -name "*release*.apk" -o -name "*.aab" | sort | xargs ls -l'

block signers
run "$B/apksigner verify --print-certs app/build/outputs/apk/play/release/app-play-release.apk | grep -E 'DN|SHA-256'"
run "$B/apksigner verify --print-certs app/build/outputs/apk/play/debug/app-play-debug.apk | grep -E 'DN|SHA-256'"

block r8
run 'ls -l app/build/outputs/apk/play/debug/app-play-debug.apk app/build/outputs/apk/play/release/app-play-release.apk'
run 'android analyze app/build/outputs/apk/play/release/app-play-release.apk 2>&1 | sed -e "s/.*\r//" | grep -E "Dex|R8"'
run 'wc -l app/build/outputs/mapping/playRelease/mapping.txt'
run 'grep -E "^(com.example.planner.MainActivity|androidx.activity.ComponentActivity|androidx.compose.ui.platform.AndroidComposeView) " app/build/outputs/mapping/playRelease/mapping.txt'

block aab
run 'unzip -l app/build/outputs/bundle/playRelease/app-play-release.aab | tail -1'
run 'unzip -l app/build/outputs/bundle/playRelease/app-play-release.aab | grep -E " (BundleConfig.pb|base/manifest/AndroidManifest.xml|base/dex/classes.dex|base/resources.pb|META-INF/UPLOAD.RSA)$"'
run 'unzip -l app/build/outputs/bundle/playRelease/app-play-release.aab | grep -E "base/lib/" | awk "{print \$4}"'
