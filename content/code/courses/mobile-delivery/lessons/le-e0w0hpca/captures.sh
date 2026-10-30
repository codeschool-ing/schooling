#!/usr/bin/env bash
# The terminal session quoted in lesson 18 of mobile-delivery, as a script that
# produces it. lab/fill.py pastes each block into the fence that holds it.
#
#   bash captures.sh > out.txt
#
# It needs lab.sh's machine, lesson 1's ~/signing (AndroidManifest.xml and
# the stand-in key play-stand-in.jks) and ~/planner. photo.ts and
# conversion.ts are taken from the lesson by lab/extract.py.
#
# STAGED, beyond what lab.sh says for every lesson:
#   - PLAY_PASS is exported by RUNENV, as in lesson 1.
#   - The module's folder is rearranged into the bundle's layout with the same
#     unzip and zip lines as lesson 1, quietly.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
S=/home/ana/size
P=/home/ana/planner
RUNENV='export PLAY_PASS=a-key-only-google-holds'
LAB as 'rm -rf ~/size && mkdir -p ~/size && cp ~/signing/AndroidManifest.xml ~/size/'
put what-a-phone-downloads.md photo.ts $P/photo.ts

block size
run $S 'for d in mdpi:240 hdpi:360 xhdpi:480 xxhdpi:720 xxxhdpi:960; do node ~/planner/photo.ts res/drawable-${d%%:*}/cover.png ${d##*:} ${d##*:}; done; ls -l res/*/cover.png'
run $S 'aapt2 compile --dir res -o res.zip --no-crunch && aapt2 link --proto-format -o base.apk --manifest AndroidManifest.xml -I $ANDROID_HOME/platforms/android-36/android.jar --min-sdk-version 24 --target-sdk-version 36 res.zip'
quiet $S 'rm -rf m && mkdir m && cd m && unzip -q ../base.apk && mkdir manifest && mv AndroidManifest.xml manifest/ && zip -qr ../base.zip . && cd .. && rm -rf m'
run $S 'java -jar ~/android/bundletool.jar build-bundle --modules=base.zip --output=planner.aab && ls -l planner.aab'
run $S 'java -jar ~/android/bundletool.jar build-apks --bundle=planner.aab --output=planner.apks --ks=$HOME/signing/play-stand-in.jks --ks-key-alias=app --ks-pass=pass:$PLAY_PASS'
run $S 'java -jar ~/android/bundletool.jar get-size total --apks=planner.apks --dimensions=SCREEN_DENSITY'
run $S 'java -jar ~/android/bundletool.jar build-apks --bundle=planner.aab --output=universal.apks --mode=universal --ks=$HOME/signing/play-stand-in.jks --ks-key-alias=app --ks-pass=pass:$PLAY_PASS'
run $S 'java -jar ~/android/bundletool.jar get-size total --apks=universal.apks'

block conversion
put install-conversion.md conversion.ts $P/conversion.ts
run $P 'node conversion.ts 4200 1176 4180 1296'
run $P 'node conversion.ts 420 118 418 130'
