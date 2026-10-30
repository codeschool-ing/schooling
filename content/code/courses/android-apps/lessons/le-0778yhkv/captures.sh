#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of android-apps, as a script that
# produces them. Every block of output starts with `##### <name>`.
#
#   sudo bash ../../lab.sh build && sudo bash ../../lab.sh install   # once
#   sudo bash captures.sh
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every project file
# built here is lifted out of first-project.md by ../../lab.sh, so the file
# built is the block the student copies.
#
# What is STAGED rather than typed:
#   - the-sdk and when-setup-fails run on the BARE machine: the kotlin course's
#     machine before anything of this course was installed, thrown away
#     between failures with `rebare`;
#   - after the install, a bare command runs with INSTALLED=1, the environment
#     a new terminal has once ~/.bashrc carries lesson 1's two lines;
#   - fail-path runs `android` before ~/.bashrc gained its lines, which is the
#     terminal that was already open;
#   - fail-home runs a build with ANDROID_HOME removed from the environment
#     (`env -u`), which is a terminal opened before the `export` line existed.
#   - Android CLI and Gradle draw progress bars with carriage returns; the
#     captures keep the last state of each line, which is what a terminal
#     leaves on the screen.
#
# Recorded on Ubuntu 24.04 with openjdk-21-jdk-headless 21.0.12.1, Kotlin
# 2.4.21, Gradle 9.8.2, Android command-line tools 23.0 and Android CLI
# 1.1.16717390, TZ=America/Sao_Paulo, on 2026-10-30.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"
MD=$HERE/first-project.md
T=commandlinetools-linux-16111833_latest.zip
cr() { sed -e 's/.*\r//'; }

block kvm
run 'ls -l /dev/kvm'

block kotlin-check
rebare
bare 'java -version 2>&1 | head -1; kotlinc -version; gradle --version | grep ^Gradle'

block download
bare 'mkdir -p ~/Android/Sdk/cmdline-tools && cd ~/downloads'
BARE_D=downloads
bare "curl -fsSLO https://dl.google.com/android/repository/$T"
bare "sha256sum $T"
bare "ls -lh $T"
bare "unzip -q $T -d ~/Android/Sdk/cmdline-tools"
bare 'mv ~/Android/Sdk/cmdline-tools/cmdline-tools ~/Android/Sdk/cmdline-tools/latest'
bare 'ls ~/Android/Sdk/cmdline-tools/latest/bin'
unset BARE_D

block bashrc
bare "echo 'export ANDROID_HOME=\"\$HOME/Android/Sdk\"' >> ~/.bashrc"
bare "echo 'export PATH=\"\$ANDROID_HOME/cmdline-tools/latest/bin:\$ANDROID_HOME/platform-tools:\$PATH\"' >> ~/.bashrc"
bare 'source ~/.bashrc'
export INSTALLED=1
bare 'echo $ANDROID_HOME'

block first-run
bare 'android --version' | cr
bare 'ls ~/.android/cli'

block sdk-install
bare 'android sdk install platforms/android-37.0 build-tools/36.1.0 platform-tools' | cr | grep -v '^\s*$'
bare 'android sdk list'

block sdk-size
bare 'du -sh ~/Android/Sdk/* ~/.android/cli'
bare 'adb version | head -2'

block sdkmanager
bare 'sdkmanager --list_installed 2>&1 | head -2'
unset INSTALLED

block fail-path
rebare
bare_quiet "mkdir -p ~/Android/Sdk/cmdline-tools && cd ~/downloads && curl -fsSLO https://dl.google.com/android/repository/$T && unzip -q $T -d ~/Android/Sdk/cmdline-tools && mv ~/Android/Sdk/cmdline-tools/cmdline-tools ~/Android/Sdk/cmdline-tools/latest"
bare 'android --version; echo $?'
bare 'ls ~/Android/Sdk/cmdline-tools/latest/bin/android'

block fail-layout
rebare
bare_quiet "mkdir -p ~/Android/Sdk && cd ~/downloads && curl -fsSLO https://dl.google.com/android/repository/$T && unzip -q $T -d ~/Android/Sdk"
bare 'ls ~/Android/Sdk ~/Android/Sdk/cmdline-tools'
bare 'ANDROID_HOME=~/Android/Sdk ~/Android/Sdk/cmdline-tools/bin/sdkmanager --list_installed 2>&1 | tail -2'
# the two-line repair the section prints, checked here and not shown
bare_quiet 'mkdir -p ~/Android/Sdk/cmdline-tools/latest && mv ~/Android/Sdk/cmdline-tools/{bin,lib,NOTICE.txt,source.properties} ~/Android/Sdk/cmdline-tools/latest/'
bare 'ls ~/Android/Sdk/cmdline-tools/latest/bin/sdkmanager' >&2
rebare

block mkdir
fresh w/l01/planner planner
for f in settings.gradle.kts gradle/libs.versions.toml build.gradle.kts gradle.properties app/build.gradle.kts app/src/test/resources/robolectric.properties app/src/main/AndroidManifest.xml app/src/main/res/values/strings.xml app/src/main/java/com/example/planner/MainActivity.kt; do put "$MD" "$f"; done
at .
run 'mkdir -p ~/planner && cd ~/planner'
at w/l01/planner planner

block wrapper
run 'gradle wrapper --gradle-version 9.8.2 -q'
run 'find . -type f -not -path "./.gradle/*" | sort'
run 'cat gradle/wrapper/gradle-wrapper.properties'

block fail-home
run 'env -u ANDROID_HOME ./gradlew --console=plain assembleDebug 2>&1 | sed -n "/What went wrong/,/^$/p"'

block first-build
quiet './gradlew --stop; rm -rf ~/.gradle/caches ~/.gradle/wrapper ~/.gradle/daemon ~/.gradle/native'
run './gradlew --console=plain assembleDebug 2>&1 | grep -E "^(Downloading|BUILD|[0-9]+ actionable)"'
run 'ls -lh app/build/outputs/apk/debug/'

block second-build
run './gradlew --console=plain assembleDebug 2>&1 | grep -E "^(BUILD|[0-9]+ actionable)"'

block deps
run './gradlew -q :app:dependencies --configuration debugRuntimeClasspath | grep -E "^[+\\\\]---"'
run './gradlew -q :app:dependencies --configuration debugRuntimeClasspath | grep -oE "[a-z][a-z0-9.-]+:[a-z][a-z0-9.-]+" | sort -u | wc -l'

block merged
run 'sed -n 1,20p app/build/intermediates/merged_manifest/debug/processDebugMainManifest/AndroidManifest.xml'

block apk
at w/l01/planner/app/build/outputs/apk/debug planner/app/build/outputs/apk/debug
run 'unzip -l app-debug.apk | tail -1'
run 'unzip -l app-debug.apk | grep -E "classes[0-9]*\.dex|AndroidManifest|resources.arsc"'

block badging
run '$ANDROID_HOME/build-tools/36.1.0/aapt2 dump badging app-debug.apk | head -5'

block analyze
run 'android analyze app-debug.apk 2>&1 | sed -e "s/.*\r//" | grep -v "^Downloading"'

block values-pt
at w/l01/planner planner
put "$HERE/manifest-and-resources.md" app/src/main/res/values-pt/strings.xml
run './gradlew --console=plain assembleDebug 2>&1 | grep -E "^BUILD"'
run '$ANDROID_HOME/build-tools/36.1.0/aapt2 dump resources app/build/outputs/apk/debug/app-debug.apk | grep -A2 "string/welcome"'
run 'grep -E "string (app_name|welcome)" app/build/intermediates/runtime_symbol_list/debug/processDebugResources/R.txt'
