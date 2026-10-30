#!/usr/bin/env bash
# The computer every transcript in mobile-delivery was recorded on.
#
# ONE UBUNTU 24.04 COMPUTER WITH ONE USER, ana. Lesson 1 tells the student to
# work on their own computer (Linux, WSL on Windows, or a Mac), or in an
# Ubuntu virtual machine, with Node.js 22 installed exactly as lesson 1 of
# `javascript` installs it, and with the Android signing tools that lesson 1
# itself installs. The recording machine is itself Ubuntu 24.04, so this
# script makes ana an ordinary user on it and runs every command in her login
# shell with an empty environment. The prompt the transcripts print, ana@dev,
# is the one the student's own terminal shows on a computer called dev.
#
# WHAT IS IN IT
#   Node.js        22.22.0 in ~/.local/node, as `javascript` lesson 1 installs it.
#   OpenJDK 21     Ubuntu's openjdk-21-jdk-headless, for keytool and jarsigner
#                  (the APT line below; lesson 1 installs it the same way).
#   Android tools  command-line tools 13114758 in ~/android/cmdline-tools/latest,
#                  then build-tools 36.0.0 and platforms;android-36 through
#                  sdkmanager, and bundletool 1.18.3 (Google's bundletool-all jar, from its GitHub
#                  releases) as ~/android/bundletool.jar.
#                  Lesson 13 adds R8 8.13.25 as ~/android/r8.jar.
#   everything     else is installed by the lessons, in ~/planner, with npm, at
#                  the exact versions the lessons pin.
#
# WHAT IS STAGED, AND WHY
#   - The recording machine reaches the internet through a gateway that
#     re-signs TLS. NODE_EXTRA_CA_CERTS points Node at its certificate, the
#     proxy variables are passed through, and sdkmanager is run with
#     --proxy flags naming the gateway. A student's computer talks to npm,
#     Google and Maven directly and needs none of it. Because of those flags,
#     the sdkmanager install itself is run here and not printed; lesson 1
#     prints `sdkmanager --list_installed` afterwards, which is real.
#   - There is no Mac and no KVM. So no iOS build was signed, no emulator ran
#     and nothing was installed on a phone: every Xcode, App Store Connect,
#     TestFlight and Play Console step in the course is quoted from the
#     platform's documentation, dated, and marked as not run where it appears.
#     The Android APKs and the app bundle in lessons 1, 13 and 18 are built
#     with aapt2 and bundletool, signed, verified and measured for real; none
#     of them was run on a device.
#   - The clock is the recording machine's, TZ=America/Sao_Paulo. Every date in
#     the planner's data is fixed, in October 2026, and the programs take
#     "today" as an argument rather than reading the clock, so a capture taken
#     on another day prints the same lines. Key generation is the exception:
#     keytool stamps a certificate with the day it was made, and lessons 1 and
#     2 print those dates as they came out.
#
#   sudo bash lab.sh build        the user, Node.js, the JDK and the SDK (once)
#   sudo bash lab.sh as 'cmd'     run a command as ana, in a login shell, in ~
#   sudo bash lab.sh root 'cmd'   the same as root
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.
set -euo pipefail

NODE=v22.22.0
APT="openjdk-21-jdk-headless unzip sqlite3 ruby-full ruby-bundler build-essential"
TOOLS=commandlinetools-linux-13114758_latest.zip
BUNDLETOOL=1.18.3
R8=8.13.25

build() {
  id ana >/dev/null 2>&1 || useradd -m -s /bin/bash ana
  install -m 644 /root/.ccr/ca-bundle.crt /usr/local/share/lab-gateway-ca.crt
  apt-get update -q >/dev/null || true
  DEBIAN_FRONTEND=noninteractive apt-get install -y -q --no-install-recommends $APT >/dev/null
  as "test -x ~/.local/node/bin/node || {
      curl -fsSLO https://nodejs.org/dist/$NODE/node-$NODE-linux-x64.tar.xz &&
      mkdir -p ~/.local/node ~/.local/bin &&
      tar -xJf node-$NODE-linux-x64.tar.xz -C ~/.local/node --strip-components=1 &&
      ln -sf ~/.local/node/bin/node ~/.local/node/bin/npm ~/.local/node/bin/npx ~/.local/bin/ &&
      rm node-$NODE-linux-x64.tar.xz; }"
  as "test -x ~/android/cmdline-tools/latest/bin/sdkmanager || {
      mkdir -p ~/android/cmdline-tools && cd ~/android/cmdline-tools &&
      curl -fsSLO https://dl.google.com/android/repository/$TOOLS &&
      unzip -q $TOOLS && mv cmdline-tools latest && rm $TOOLS; }"
  grep -q ANDROID_HOME /home/ana/.profile || cat >> /home/ana/.profile <<'EOF'

# Android signing tools (mobile-delivery, lesson 1)
export ANDROID_HOME="$HOME/android"
PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/build-tools/36.0.0:$PATH"
EOF
  local p=${HTTPS_PROXY:-${https_proxy:-}}; local port=${p##*:}; port=${port%/}
  as "test -x ~/android/build-tools/36.0.0/apksigner || {
      yes | sdkmanager --proxy=http --proxy_host=127.0.0.1 --proxy_port=$port --licenses >/dev/null &&
      sdkmanager --proxy=http --proxy_host=127.0.0.1 --proxy_port=$port 'build-tools;36.0.0' 'platforms;android-36' >/dev/null; }"
  as "test -f ~/android/bundletool.jar ||
      curl -fsSL -o ~/android/bundletool.jar https://github.com/google/bundletool/releases/download/$BUNDLETOOL/bundletool-all-$BUNDLETOOL.jar"
  as "test -f ~/android/r8.jar ||
      curl -fsSL -o ~/android/r8.jar https://dl.google.com/dl/android/maven2/com/android/tools/r8/$R8/r8-$R8.jar"
}

# as 'command': ana's login shell, in her home, with nothing of the recording
# machine's environment except the proxy and its certificate.
as() {
  # shellcheck disable=SC2046
  runuser -u ana -- env -i HOME=/home/ana USER=ana LOGNAME=ana SHELL=/bin/bash \
    LANG=C.UTF-8 TZ=America/Sao_Paulo TERM=dumb PATH=/usr/bin:/bin \
    $(env | grep -iE '^(https?_proxy|no_proxy)=' | tr '\n' ' ') \
    NODE_EXTRA_CA_CERTS=/usr/local/share/lab-gateway-ca.crt \
    NO_UPDATE_NOTIFIER=1 npm_config_update_notifier=false npm_config_fund=false \
    npm_config_audit=false NO_COLOR=1 FORCE_COLOR=0 \
    bash -c 'cd ~; . ~/.profile; eval "$1"' bash "$*"
}

root() { bash -c "$*"; }

case ${1:-} in
  build) build ;;
  as) shift; as "$@" ;;
  root) shift; root "$@" ;;
  *) echo "usage: $0 build|as 'cmd'|root 'cmd'" >&2; exit 2 ;;
esac
