#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of mobile-delivery, as a script that
# produces them. The output is not committed: lab/fill.py pastes each block
# into the fence that holds it, and `fill.py --check` holds them equal.
#
#   bash captures.sh > out.txt
#
# It needs lab.sh's machine, and starts from no ~/planner and no ~/signing.
# package.json, check.ts and AndroidManifest.xml are taken from the lesson by
# lab/extract.py, so the file each transcript used is the one it prints.
#
# STAGED, beyond what lab.sh says for every lesson:
#   - The keystore passwords are exported by RUNENV before each command; the
#     lesson tells the student to type them with `read -rs`, which cannot be
#     recorded.
#   - "playsigning" makes a second keystore standing in for the key Google
#     Play holds. Google's real key never leaves Google.
#   - keytool and apksigner print a fresh key's digests and dates; they differ
#     on every run, and the lesson's prose quotes none of them.
#   - "nojava" runs keytool with a PATH that reaches nothing at all.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
P=/home/ana/planner
S=/home/ana/signing
LAB as 'rm -rf ~/planner ~/signing'
RUNENV='export UPLOAD_PASS=correct-horse-battery-staple PLAY_PASS=a-key-only-google-holds'

block versions
run /home/ana 'node --version'
run /home/ana 'java -version'
run /home/ana 'apksigner --version'
run /home/ana 'java -jar ~/android/bundletool.jar version'
run /home/ana 'sdkmanager --list_installed'

block project
LAB as 'mkdir -p ~/planner'
put your-computer.md package.json $P/package.json
run $P 'npm install -E better-sqlite3@13.0.3'
put your-computer.md check.ts $P/check.ts
run $P 'node check.ts'

block keystore
LAB as 'mkdir -p ~/signing'
run $S 'keytool -genkeypair -keystore upload.jks -storetype PKCS12 -alias upload -keyalg RSA -keysize 4096 -validity 10000 -dname "CN=Ana Souza, O=Study Planner, C=BR" -storepass:env UPLOAD_PASS'
run $S 'keytool -list -keystore upload.jks -storepass:env UPLOAD_PASS'

block apk
put a-signed-apk.md AndroidManifest.xml $S/AndroidManifest.xml
run $S 'aapt2 link -o planner-unsigned.apk --manifest AndroidManifest.xml -I $ANDROID_HOME/platforms/android-36/android.jar --min-sdk-version 24 --target-sdk-version 36'
run $S 'zipalign -p -f 4 planner-unsigned.apk planner-aligned.apk'
run $S 'apksigner sign --ks upload.jks --ks-key-alias upload --ks-pass env:UPLOAD_PASS --out planner.apk planner-aligned.apk'
run $S 'ls -l *.apk'

block verify
run $S 'apksigner verify --verbose --print-certs planner.apk'

block unsigned
run $S 'apksigner verify planner-aligned.apk'

block bundle
quiet $S 'aapt2 link --proto-format -o base-proto.apk --manifest AndroidManifest.xml -I $ANDROID_HOME/platforms/android-36/android.jar --min-sdk-version 24 --target-sdk-version 36 && rm -rf base && mkdir -p base/manifest && cd base && unzip -q ../base-proto.apk && mv AndroidManifest.xml manifest/ && zip -qr ../base.zip . && cd .. && rm -rf base base-proto.apk'
run $S 'java -jar ~/android/bundletool.jar build-bundle --modules=base.zip --output=planner.aab'
run $S 'jarsigner -keystore upload.jks -storepass:env UPLOAD_PASS planner.aab upload'
run $S 'jarsigner -verify planner.aab'

block playsigning
run $S 'keytool -genkeypair -keystore play-stand-in.jks -storetype PKCS12 -alias app -keyalg RSA -keysize 4096 -validity 10000 -dname "CN=Play stand-in, C=US" -storepass:env PLAY_PASS'
run $S 'java -jar ~/android/bundletool.jar build-apks --bundle=planner.aab --output=planner.apks --ks=play-stand-in.jks --ks-key-alias=app --ks-pass=pass:$PLAY_PASS'
run $S 'unzip -o -q planner.apks -d from-play && ls from-play/splits'
run $S 'apksigner verify --print-certs from-play/splits/base-master.apk | grep DN'
run $S 'apksigner verify --print-certs planner.apk | grep DN'

block nojava
run $S 'PATH=/nonexistent keytool -list -keystore upload.jks'

block wrongpass
run $S 'keytool -list -keystore upload.jks -storepass not-the-password'
