#!/usr/bin/env bash
# The machine every transcript in react-native was recorded on.
#
# ONE UBUNTU 24.04 COMPUTER CALLED `dev`, WITH ONE USER, ana. Lesson 1 tells the
# student to work on their own computer (Linux, WSL or a Mac), in an Ubuntu
# virtual machine, or online, and to install Node.js as lesson 1 of
# `javascript` does. Everything else is installed by the lessons, inside the
# project, with npm, at the exact versions the lessons pin.
#
#   ana          an ordinary user, uid 1500, home /home/ana
#   Node.js      22.22.0 in ~/.local/node, from nodejs.org's tarball, checked
#                against its published SHA-256, with node, npm and npx linked
#                into ~/.local/bin: exactly as lesson 1 of `javascript`
#                installs it
#   git          from Ubuntu's archive
#   JDK 17       openjdk-17-jdk-headless from Ubuntu's archive, the version
#                React Native's Gradle plugin asks for, for the Android builds
#                of lessons 3, 17, 18 and 20
#   Android SDK  the command-line tools from dl.google.com, and the packages
#                lesson 3 lists, installed with sdkmanager into ~/Android/Sdk,
#                the folder Android Studio uses
#
# WHAT IS STAGED, AND WHY
#   - Each lesson is recorded in a home of its own, /var/lib/rnlab/homes/LESSON,
#     mounted over /home/ana in a private mount namespace, and in a PID
#     namespace of its own. Lesson N starts from a copy of the ~/planner that
#     lesson N-1 left (capture-lib.sh's start_from), so a lesson can be
#     recorded again on its own; node_modules is copied as hard links, which
#     npm never writes through. A student has one home and one ~/planner.
#   - Node.js and the Android SDK are mounted into every home from one copy.
#   - The recording machine reaches the internet through a gateway that
#     re-signs TLS. Its certificate bundle is copied to /var/lib/rnlab/ca.crt
#     and npm, Node and Gradle are pointed at it (npm_config_cafile,
#     NODE_EXTRA_CA_CERTS, and a Java trust store named in
#     ~/.gradle/gradle.properties with the proxy). A student's computer talks to
#     the registry directly and needs none of it.
#   - Through that gateway Maven Central answers "429 Too Many Requests" to a
#     build that fetches many files at once, so
#     ~/.gradle/init.d/recording-mirror.init.gradle.kts points Gradle at
#     Google's mirror of Maven Central, which serves the same files. A
#     student's build fetches them from Maven Central itself.
#   - That gateway refuses api.expo.dev, which the Expo CLI asks about versions
#     and which every EAS command needs. The expo commands run with
#     EXPO_OFFLINE=1, set in the environment and not typed; nothing quoted
#     prints anything different for it. EAS (lessons 20 and 21) was never run.
#   - There is no /dev/kvm, so no Android emulator, and no Mac, so no Xcode
#     and no iOS simulator. The Android APKs of lessons 3, 17, 18 and 20 were
#     built and inspected and never installed on anything. The lessons say
#     so where they show those steps.
#   - Playwright's browser is the build already on the recording machine
#     (/opt/pw-browsers), the same version `npx playwright install chromium`
#     downloads for Playwright 1.63.0. PLAYWRIGHT_BROWSERS_PATH points at it.
#   - The clock is the recording machine's, TZ=America/Sao_Paulo. The planner's
#     data carries fixed dates in the week of Monday 2026-10-19, and the web
#     build is opened with ?today=2026-10-21 so its week is that week.
#
#   sudo bash lab.sh up                 create ana, install Node, the JDK and
#                                       the Android SDK (idempotent)
#   sudo bash lab.sh reset LESSON       empty that lesson's home
#   sudo bash lab.sh as LESSON 'cmd'    run cmd as ana, in a login-like shell,
#                                       with that lesson's home as /home/ana
#   sudo bash lab.sh path LESSON        print where that lesson's home is
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
set -euo pipefail

BASE=/var/lib/rnlab
NODE_VERSION=22.22.0
NODE_SHA256=9aa8e9d2298ab68c600bd6fb86a6c13bce11a4eca1ba9b39d79fa021755d7c37
NODE_TAR=node-v$NODE_VERSION-linux-x64.tar.xz
CA_SRC=${CA_SRC:-/root/.ccr/ca-bundle.crt}
TOOLS=commandlinetools-linux-16111833_latest.zip
# What lesson 3 asks sdkmanager for, the versions React Native 0.88 names.
SDK_PACKAGES="platform-tools platforms;android-37.0 build-tools;37.0.0 ndk;27.1.12297006 cmake;3.22.1"

up() {
  id ana >/dev/null 2>&1 || useradd -m -u 1500 -s /bin/bash ana
  mkdir -p $BASE/homes
  if [ ! -x $BASE/node/bin/node ]; then
    local t; t=$(mktemp -d)
    curl -fsSL -o "$t/$NODE_TAR" "https://nodejs.org/dist/v$NODE_VERSION/$NODE_TAR"
    echo "$NODE_SHA256  $t/$NODE_TAR" | sha256sum -c --quiet
    mkdir -p $BASE/node
    tar -xJf "$t/$NODE_TAR" -C $BASE/node --strip-components=1
    rm -rf "$t"
    chown -R ana:ana $BASE/node
  fi
  [ -f "$CA_SRC" ] && install -m 0644 "$CA_SRC" $BASE/ca.crt || true
  [ -x /usr/lib/jvm/java-17-openjdk-amd64/bin/javac ] || DEBIAN_FRONTEND=noninteractive apt-get install -y -q openjdk-17-jdk-headless >/dev/null
  if [ ! -d $BASE/sdk/platforms ]; then
    local t; t=$(mktemp -d)
    curl -fsSL -o "$t/$TOOLS" "https://dl.google.com/android/repository/$TOOLS"
    mkdir -p $BASE/sdk/cmdline-tools
    unzip -q "$t/$TOOLS" -d "$t" && mv "$t/cmdline-tools" $BASE/sdk/cmdline-tools/latest
    rm -rf "$t"
    yes | ANDROID_HOME=$BASE/sdk $BASE/sdk/cmdline-tools/latest/bin/sdkmanager --licenses >/dev/null || true
    # shellcheck disable=SC2086
    ANDROID_HOME=$BASE/sdk $BASE/sdk/cmdline-tools/latest/bin/sdkmanager $SDK_PACKAGES >/dev/null
    chown -R ana:ana $BASE/sdk
  fi
  if [ ! -f $BASE/cacerts ]; then
    # The gateway's certificates in a Java trust store, for Gradle.
    cp /etc/ssl/certs/java/cacerts $BASE/cacerts
    keytool -importcert -noprompt -keystore $BASE/cacerts -storepass changeit \
      -alias gateway -file $BASE/ca.crt >/dev/null 2>&1 || true
  fi
  if [ ! -d $BASE/skel ]; then
    mkdir -p $BASE/skel/.local/node $BASE/skel/.local/bin $BASE/skel/Android/Sdk
    for b in node npm npx; do ln -s /home/ana/.local/node/bin/$b $BASE/skel/.local/bin/$b; done
    cat > $BASE/skel/.gitconfig <<'GIT'
[user]
	name = Ana Lima
	email = ana@example.org
[init]
	defaultBranch = main
GIT
    # As lesson 3 tells the student to add to ~/.bashrc.
    cat >> $BASE/skel/.bashrc <<'RC'
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH
RC
    chown -R ana:ana $BASE/skel
  fi
  if [ ! -f $BASE/skel/.gradle/init.d/recording-mirror.init.gradle.kts ]; then
    mkdir -p $BASE/skel/.gradle/init.d
    cat > $BASE/skel/.gradle/init.d/recording-mirror.init.gradle.kts <<'KTS'
// Recording machine only: Maven Central answers 429 to the recording proxy
// under load, so its artifacts are fetched from Google's copy of Central.
val mirror = "https://maven-central.storage-download.googleapis.com/maven2/"
fun RepositoryHandler.useMirror() = all {
    if (this is MavenArtifactRepository && url.host == "repo.maven.apache.org") url = uri(mirror)
}
beforeSettings {
    pluginManagement.repositories.maven(mirror)
}
settingsEvaluated {
    pluginManagement.repositories.useMirror()
    pluginManagement.repositories.maven(mirror)
    pluginManagement.repositories.gradlePluginPortal()
    dependencyResolutionManagement.repositories.useMirror()
}
allprojects {
    buildscript.repositories.useMirror()
    repositories.useMirror()
}
KTS
    chown -R ana:ana $BASE/skel/.gradle
  fi
}

home() { # home LESSON: create it from the skeleton when it is missing
  local h=$BASE/homes/$1
  [ -d "$h" ] || { cp -a $BASE/skel "$h"; chown ana:ana "$h"; }
  printf '%s' "$h"
}

as() { # as LESSON 'cmd'
  local h; h=$(home "$1"); shift
  local cmd=$*
  # The proxy and the trust store, for Gradle, in the place Gradle reads them:
  # JAVA_TOOL_OPTIONS would print a line into every transcript with java in it.
  mkdir -p "$h/.gradle"
  {
    echo "systemProp.javax.net.ssl.trustStore=$BASE/cacerts"
    echo "systemProp.javax.net.ssl.trustStorePassword=changeit"
    local p=${HTTPS_PROXY:-}
    if [ -n "$p" ]; then
      local hp=${p#*://}; hp=${hp%/}
      for k in https http; do
        echo "systemProp.$k.proxyHost=${hp%:*}"
        echo "systemProp.$k.proxyPort=${hp##*:}"
      done
      echo "systemProp.http.nonProxyHosts=localhost|127.0.0.1"
    fi
  } > "$h/.gradle/gradle.properties"
  chown -R ana:ana "$h/.gradle"
  unshare -m --propagation private --pid --fork --mount-proc -- bash -c '
    mount --bind "$1" /home/ana
    mount --bind '"$BASE"'/node /home/ana/.local/node
    mount --bind '"$BASE"'/sdk /home/ana/Android/Sdk
    exec runuser -u ana -- env -i HOME=/home/ana USER=ana LOGNAME=ana SHELL=/bin/bash \
      PATH=/home/ana/.local/bin:/usr/local/bin:/usr/bin:/bin \
      TZ=America/Sao_Paulo LANG=C.UTF-8 LC_ALL=C.UTF-8 TERM=dumb \
      NO_COLOR=1 NODE_DISABLE_COLORS=1 FORCE_COLOR=0 CI=1 EXPO_OFFLINE=1 \
      EXPO_NO_TELEMETRY=1 PLAYWRIGHT_BROWSERS_PATH=/opt/pw-browsers \
      npm_config_update_notifier=false npm_config_fund=false npm_config_audit=false \
      npm_config_cafile='"$BASE"'/ca.crt NODE_EXTRA_CA_CERTS='"$BASE"'/ca.crt \
      HTTPS_PROXY="${HTTPS_PROXY:-}" HTTP_PROXY="${HTTP_PROXY:-}" NO_PROXY="127.0.0.1,localhost" \
      https_proxy="${HTTPS_PROXY:-}" http_proxy="${HTTP_PROXY:-}" no_proxy="127.0.0.1,localhost" \
      bash -c ". ~/.bashrc; cd /home/ana && $2"
  ' _ "$h" "$cmd"
}

case ${1:-} in
  up) up ;;
  reset) up; rm -rf "${BASE:?}/homes/${2:?lesson}"; home "$2" >/dev/null ;;
  as) up; as "${2:?lesson}" "${3:?command}" ;;
  path) up; home "${2:?lesson}"; echo ;;
  *) sed -n '2,57p' "$0"; exit 2 ;;
esac
