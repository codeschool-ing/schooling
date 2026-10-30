#!/usr/bin/env bash
# The machine every transcript in the android-apps course was recorded on.
#
# THE STUDENT NEVER SEES THIS FILE (C-40). Lesson 1 tells the student to start
# from the machine the kotlin course built in its lesson 1 (Ubuntu 24.04,
# openjdk-21-jdk-headless from Ubuntu's archive, Kotlin 2.4.21 and Gradle 9.8.2
# unpacked in ~/.local/share), and then to add the Android SDK's command-line
# tools by hand:
#
#     curl -fsSLO https://dl.google.com/android/repository/commandlinetools-linux-16111833_latest.zip
#     unzip it into ~/Android/Sdk/cmdline-tools and rename the folder to latest
#     export ANDROID_HOME, and put cmdline-tools/latest/bin and platform-tools on PATH
#     android sdk install platforms/android-37.0 build-tools/36.1.0 platform-tools
#
# `android` is the Android CLI. The first time it (or the deprecated
# sdkmanager, which hands its work to it) runs, it downloads its own latest
# version from dl.google.com into ~/.android/cli: that download is the one
# thing in the machine that cannot be pinned, and lesson 1 says so.
#
# This script builds exactly that machine as a chroot of its own, because the
# computer the course was recorded on could not run a hypervisor (it has no
# /dev/kvm, which is also why no emulator was ever started here):
#
#   sudo bash lab.sh build             debootstrap Ubuntu 24.04 and run the kotlin
#                                      course's lesson 1 install into it (once)
#   sudo bash lab.sh install           copy it and run THIS course's lesson 1
#                                      install into the copy (once)
#   sudo bash lab.sh bare 'cmd'        run cmd as ana on the copy from before
#                                      the Android install
#   sudo bash lab.sh rebare            throw the bare copy away, take a new one
#   sudo bash lab.sh exec DIR 'cmd'    run cmd as ana, in ~/DIR, on the
#                                      installed machine
#   sudo bash lab.sh fresh DIR         empty ~/DIR and leave it there
#   sudo bash lab.sh extract MD NAME [K]   print the K-th block of MD that is
#                                      the file NAME (default: the last)
#   sudo bash lab.sh put DIR MD NAME [K]   write that block to ~/DIR/NAME
#
# WHAT A FILE BLOCK IS. An ordinary fence whose FIRST line is a comment naming
# the file, in the syntax of its language: `// app/build.gradle.kts` in a
# `kotlin` fence, `# gradle/libs.versions.toml` in a `toml` or `properties`
# fence, `<!-- app/src/main/AndroidManifest.xml -->` in an `xml` fence; or a
# `schooling-example` whose `file` is the name, its parts joined with one
# newline as the copy button joins them. So the file a capture builds is the
# block the student copies, and the two cannot drift.
#
# THE PROJECT. Lesson 1 writes the study planner's skeleton in ~/planner. Every
# later lesson starts from that skeleton, lifted out of lesson 1's own .md by
# `skeleton`, and adds the files its own .md shows — so each lesson's captures
# run in a directory of their own (~/w/<lesson>/planner) and the prompt prints
# ~/planner, which is where the student types.
#
# WHAT IS STAGED, AND WHY
#   - THE KOTLIN COURSE'S MACHINE. `build` runs the kotlin course's lesson 1
#     install (the three apt packages and the two zips) without recording it:
#     this course's lesson 1 assumes it and checks each tool answers.
#   - THE NETWORK. The recording computer reaches the internet only through an
#     HTTPS proxy that re-signs every certificate. Its certificate is added to
#     the machine's trust store before anything is installed (so the JDK's
#     cacerts trusts it too); ~ana/.curlrc names the proxy for curl;
#     ~ana/.gradle/gradle.properties names it for Gradle and its wrapper; and
#     SDKMANAGER_OPTS names it for sdkmanager; and SSL_CERT_FILE points the
#     Android CLI, which sdkmanager 23 downloads and hands its work to and which
#     otherwise trusts only its own built-in list of authorities, at the
#     machine's trust store. On the student's machine none
#     of these exists and none is needed. No lesson prints them.
#   - MAVEN CENTRAL. Through that proxy, repo.maven.apache.org answers "429 Too
#     Many Requests" to a build that fetches many files at once.
#     ~ana/.gradle/init.d/recording-mirror.init.gradle.kts points Gradle at
#     Google's mirror of Maven Central, which serves the same files, and tells
#     Robolectric (which downloads the Android framework it runs tests against
#     by itself, at test time) to fetch from the same mirror. A build on the
#     student's machine fetches from Maven Central itself.
#   - PATH and ANDROID_HOME. Lesson 1 appends lines to ~/.bashrc. A capture
#     runs a non-interactive shell, which never reads ~/.bashrc, so the same
#     values are written into the environment below instead. On the bare
#     machine they are absent, as they are before the student adds them.
#   - ~/planner. Each lesson's project is kept in ~/w/<lesson>/planner and
#     mounted on ~/planner for the length of each command, with a Gradle
#     daemon registry of its own (GRADLE_OPTS), so that several lessons could be
#     captured at once and every path a tool prints is the student's.
#   - SPEED. ~ana/.gradle/gradle.properties also shortens the Gradle daemon's
#     idle life to ten minutes and compiles Kotlin inside it, because several
#     lessons were captured at the same time on one machine. Neither prints
#     anything; both change only how long a build takes.
#   - ana may use sudo without a password, which keeps prompts out of the
#     transcripts.
#   - The environment of every command is fixed: HOME, PATH, TZ, LANG and the
#     two Android variables. JAVA_TOOL_OPTIONS, which the recording computer
#     sets and which makes every JVM print a line about it, is absent.
#   - Colour. Gradle paints some lines with ANSI escapes; the capture scripts
#     strip the escapes and keep the words.
#
# THE PROMPT in a transcript, ana@vm:~/DIR$, is printed by the capture
# scripts; the chroot's hostname is vm as well.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo, on 2026-10-30.
[[ "${BASH_SOURCE[0]}" != "$0" ]] || set -euo pipefail  # sourced by a captures.sh: leave its options alone

BASE=/var/lib/machines/android-base
BARE=/var/lib/machines/android-bare
LIVE=/var/lib/machines/android-lab
MIRROR=${MIRROR:-http://archive.ubuntu.com/ubuntu}
PROXY=${HTTPS_PROXY:-}
CA=/root/.ccr/agent-proxy-ca.crt
KOTLIN=2.4.21
GRADLE=9.8.2
TOOLS=commandlinetools-linux-16111833_latest.zip
HERE_LAB=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

need_root() { [ "$(id -u)" = 0 ] || { echo "lab.sh: run me as root" >&2; exit 1; }; }

_proxy_opts() {
  [ -n "$PROXY" ] || return 0
  local host=${PROXY#*://}; host=${host%/}; local port=${host##*:}; host=${host%:*}
  printf -- '-Dhttps.proxyHost=%s -Dhttps.proxyPort=%s -Dhttp.proxyHost=%s -Dhttp.proxyPort=%s' "$host" "$port" "$host" "$port"
}

# Each command runs in a mount and hostname namespace of its own, chrooted into
# the machine's root: the machine's own /proc, the host's /dev and /sys, and a
# hostname of vm.
in_root() { # $1 = machine root, $2 = user, $3 = command, $4 = environment, [$5 = a project dir under ~/w]
  local R=$1 who=$2 cmd=$3 envs=$4 bind=${5:-} gopts=
  # A lesson's project lives in ~/w/<lesson>/planner and is mounted on ~/planner
  # for the length of one command, so that every path a tool prints is the one
  # the student has. Each lesson gets its own Gradle daemon registry, so that a
  # daemon started under one lesson's mount never builds another lesson's files.
  if [ -n "$bind" ]; then
    local tag=${bind#w/}; tag=${tag%%/*}
    gopts="GRADLE_OPTS=-Dorg.gradle.daemon.registry.base=/home/ana/.gradle/daemon-$tag"
  fi
  unshare -m -u --propagation private bash -c '
    R=$1; who=$2; bind=$3; shift 3
    hostname vm
    mount -t proc proc "$R/proc"
    mount --rbind /dev "$R/dev"
    mount --rbind /sys "$R/sys"
    if [ -n "$bind" ]; then mkdir -p "$R/home/ana/planner"; mount --bind "$R/home/ana/$bind" "$R/home/ana/planner"; fi
    exec chroot "$R" runuser -u "$who" -- "$@"' _ "$R" "$who" "$bind" \
    env -i $envs $gopts "SDKMANAGER_OPTS=$(_proxy_opts)" ${PROXY:+SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt HTTPS_PROXY=$PROXY NO_PROXY=localhost,127.0.0.1} bash -c "exec 2>&1; cd ~ 2>/dev/null; $cmd"
}

ENV_COMMON="HOME=/home/ana USER=ana LOGNAME=ana SHELL=/bin/bash TERM=dumb \
LANG=C.UTF-8 LC_ALL=C.UTF-8 TZ=America/Sao_Paulo COLUMNS=100"
KOTLIN_PATH=/home/ana/.local/share/kotlinc/bin:/home/ana/.local/share/gradle-$GRADLE/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
# Before lesson 1's install: the kotlin course's PATH and no Android variables.
BARE_ENV="$ENV_COMMON PATH=$KOTLIN_PATH"
# After it: what lesson 1 appends to ~/.bashrc.
LIVE_ENV="$ENV_COMMON ANDROID_HOME=/home/ana/Android/Sdk \
PATH=/home/ana/Android/Sdk/cmdline-tools/latest/bin:/home/ana/Android/Sdk/platform-tools:$KOTLIN_PATH"

stage_proxy() { # $1 = machine root
  [ -n "$PROXY" ] || return 0
  local R=$1 host=${PROXY#*://}; host=${host%/}; local port=${host##*:}; host=${host%:*}
  printf 'proxy = "%s"\nnoproxy = "localhost,127.0.0.1"\n' "$PROXY" > "$R/home/ana/.curlrc"
  mkdir -p "$R/home/ana/.gradle"
  printf 'systemProp.https.proxyHost=%s\nsystemProp.https.proxyPort=%s\nsystemProp.http.proxyHost=%s\nsystemProp.http.proxyPort=%s\nsystemProp.http.nonProxyHosts=localhost|127.0.0.1\n' \
    "$host" "$port" "$host" "$port" > "$R/home/ana/.gradle/gradle.properties"
  # Several lessons were captured at once on one recording machine: a Gradle
  # daemon gives its memory back after ten idle minutes rather than three
  # hours, and Kotlin compiles inside it rather than in a daemon of its own.
  printf 'org.gradle.daemon.idletimeout=600000\nkotlin.compiler.execution.strategy=in-process\n' >> "$R/home/ana/.gradle/gradle.properties"
  mkdir -p "$R/home/ana/.gradle/init.d"
  cat > "$R/home/ana/.gradle/init.d/recording-mirror.init.gradle.kts" <<'KTS'
// Recording machine only: Maven Central answers 429 to the recording proxy
// under load, so its artifacts are fetched from Google's copy of Central,
// and so is the Android framework Robolectric downloads at test time.
val mirror = "https://maven-central.storage-download.googleapis.com/maven2/"
fun RepositoryHandler.useMirror() = all {
    if (this is MavenArtifactRepository && url.host == "repo.maven.apache.org") url = uri(mirror)
}
settingsEvaluated {
    pluginManagement.repositories.useMirror()
    pluginManagement.repositories.maven(mirror)
    dependencyResolutionManagement.repositories.useMirror()
}
allprojects {
    buildscript.repositories.useMirror()
    repositories.useMirror()
    tasks.withType<Test>().configureEach {
        systemProperty("robolectric.dependency.repo.url", mirror)
        // the test JVM is a process of its own and does not inherit Gradle's proxy
        listOf("https.proxyHost", "https.proxyPort").forEach { k ->
            System.getProperty(k)?.let { systemProperty(k, it) }
        }
    }
}
KTS
  chown -R 1000:1000 "$R/home/ana/.curlrc" "$R/home/ana/.gradle"
}

# The kotlin course's lesson 1 install, as that lesson types it.
KOTLIN_INSTALL="sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq openjdk-21-jdk-headless unzip curl >/dev/null
mkdir -p ~/downloads ~/.local/share && cd ~/downloads
curl -fsSLO https://github.com/JetBrains/kotlin/releases/download/v$KOTLIN/kotlin-compiler-$KOTLIN.zip
curl -fsSLO https://services.gradle.org/distributions/gradle-$GRADLE-bin.zip
unzip -q kotlin-compiler-$KOTLIN.zip -d ~/.local/share
unzip -q gradle-$GRADLE-bin.zip -d ~/.local/share
echo 'export PATH=\"\$HOME/.local/share/kotlinc/bin:\$HOME/.local/share/gradle-$GRADLE/bin:\$PATH\"' >> ~/.bashrc"

build() {
  need_root
  if [ ! -x "$BASE/usr/bin/apt-get" ]; then
    debootstrap --include=sudo,ca-certificates,file,less,locales,tzdata,python3 \
      noble "$BASE" "$MIRROR"
  fi
  printf 'deb %s noble main universe\ndeb %s noble-updates main universe\ndeb http://security.ubuntu.com/ubuntu noble-security main universe\n' \
    "$MIRROR" "$MIRROR" > "$BASE/etc/apt/sources.list"
  rm -f "$BASE/etc/resolv.conf"; cp /etc/resolv.conf "$BASE/etc/resolv.conf"
  echo vm > "$BASE/etc/hostname"
  printf '127.0.0.1\tlocalhost\n127.0.1.1\tvm\n' > "$BASE/etc/hosts"
  ln -sf /usr/share/zoneinfo/America/Sao_Paulo "$BASE/etc/localtime"
  echo America/Sao_Paulo > "$BASE/etc/timezone"
  if [ -r "$CA" ]; then
    install -m 0644 "$CA" "$BASE/usr/local/share/ca-certificates/recording-proxy.crt"
  fi
  in_root "$BASE" root '
    update-ca-certificates >/dev/null
    id ana >/dev/null 2>&1 || useradd -m -u 1000 -s /bin/bash -G sudo ana
    echo "ana ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/ana
    chmod 0440 /etc/sudoers.d/ana
    apt-get update -qq' "$BARE_ENV"
  stage_proxy "$BASE"
  if [ ! -x "$BASE/home/ana/.local/share/kotlinc/bin/kotlinc" ]; then
    in_root "$BASE" ana "$KOTLIN_INSTALL" "$BARE_ENV"
  fi
  rm -rf "$BARE"; cp -a "$BASE" "$BARE"
}

# This course's lesson 1 install, as the lesson types it.
INSTALL="mkdir -p ~/Android/Sdk/cmdline-tools && cd ~/downloads
curl -fsSLO https://dl.google.com/android/repository/$TOOLS
unzip -q $TOOLS -d ~/Android/Sdk/cmdline-tools
mv ~/Android/Sdk/cmdline-tools/cmdline-tools ~/Android/Sdk/cmdline-tools/latest
echo 'export ANDROID_HOME=\"\$HOME/Android/Sdk\"' >> ~/.bashrc
echo 'export PATH=\"\$ANDROID_HOME/cmdline-tools/latest/bin:\$ANDROID_HOME/platform-tools:\$PATH\"' >> ~/.bashrc
export ANDROID_HOME=~/Android/Sdk
~/Android/Sdk/cmdline-tools/latest/bin/android sdk install platforms/android-37.0 build-tools/36.1.0 platform-tools >/dev/null"

install_android() {
  need_root
  rm -rf "$LIVE"; cp -a "$BASE" "$LIVE"
  in_root "$LIVE" ana "$INSTALL" "$BARE_ENV"
  in_root "$LIVE" ana 'java -version; android --version; android sdk list' "$LIVE_ENV"
}

_extract() {
python3 - "$@" <<'PY'
import json, re, sys
md, name = sys.argv[1], sys.argv[2]
k = int(sys.argv[3]) if len(sys.argv) > 3 and sys.argv[3] else 0
text = open(md, encoding='utf-8').read()
blocks = []
NAME = r'([\w./-]+)'
for m in re.finditer(r'^```([\w-]*)\n(.*?)^```$', text, re.S | re.M):
    lang, body = m.group(1), m.group(2)
    first = body.split('\n', 1)[0]
    f = None
    if lang in ('kotlin', 'kt', 'json', 'js', 'javascript'):
        f = re.fullmatch(r'// ' + NAME, first)
    elif lang in ('toml', 'properties', 'proguard', 'sh', 'bash', 'ini', 'conf'):
        f = re.fullmatch(r'# ' + NAME, first)
    elif lang == 'xml':
        f = re.fullmatch(r'<!-- ' + NAME + r' -->', first)
    elif lang == 'schooling-example':
        ex = json.loads(body)
        if ex.get('file'):
            blocks.append((ex['file'], '\n'.join(p['code'] for p in ex['parts']) + '\n'))
        continue
    if f:
        blocks.append((f.group(1), body))
mine = [b for n, b in blocks if n == name]
if not mine:
    sys.exit(f'{md}: no block is the file {name}')
if k > len(mine):
    sys.exit(f'{md}: {name} appears {len(mine)} times, not {k}')
sys.stdout.write(mine[k - 1] if k else mine[-1])
PY
}

_put() { # DIR MD NAME [K]  (relative to /home/ana)
  local dir=$1 md=$2 name=$3 k=${4:-} body
  body=$(_extract "$md" "$name" "$k"; printf x) || exit 1
  body=${body%x}
  local dest="$LIVE/home/ana/$dir/$name"
  mkdir -p "$(dirname "$dest")"
  printf '%s' "$body" > "$dest"
  chown -R 1000:1000 "$LIVE/home/ana/${dir%%/*}"
}

# The files of lesson 1's skeleton, in the order lesson 1 writes them.
SKELETON_MD=$HERE_LAB/lessons/le-0778yhkv/first-project.md
SKELETON_FILES="settings.gradle.kts build.gradle.kts gradle.properties gradle/libs.versions.toml app/build.gradle.kts app/src/main/AndroidManifest.xml app/src/main/res/values/strings.xml app/src/main/java/com/example/planner/MainActivity.kt app/src/test/resources/robolectric.properties"

# SOURCED by a lesson's captures.sh, this file gives it these words:
#   at DIR [SHOWN]    the directory the next commands run in, ~/DIR, printed
#                     in the prompt as ~/SHOWN (default: DIR)
#   fresh DIR [SHOWN] empty ~/DIR, make it the current one
#   project NAME      fresh ~/w/NAME/planner, holding lesson 1's skeleton and its
#                     Gradle wrapper; every command run in it sees it mounted
#                     on ~/planner, so prompts and printed paths say ~/planner
#   put MD NAME [K]   write the K-th block of MD that is the file NAME into the
#                     current directory
#   run CMD           print the prompt and CMD, then run it, with 2>&1
#   quiet CMD         run CMD and print nothing
#   block NAME        start a named block of output, ##### NAME
#   bare CMD          run CMD on the machine before lesson 1's Android install
#   bare_quiet CMD    the same, printing nothing: what a capture stages
#   shot NAME DEST    copy a screenshot the current project's tests wrote,
#                     app/NAME, to DEST on the recording computer
# PLAIN_PATH=1 in the environment runs a command with the PATH a terminal has
# before ~/.bashrc added the Android directories to it.
if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
  LAB_SH=$(readlink -f "${BASH_SOURCE[0]}")
  _D=.; _S=.
  _strip() { sed -e $'s/\x1b\\[[0-9;]*m//g'; }
  _prompt() { if [ "$1" = . ]; then printf 'ana@vm:~$ %s\n' "$2"; else printf 'ana@vm:~/%s$ %s\n' "$1" "$2"; fi; }
  at() { _D=$1; _S=${2:-$1}; }
  fresh() { _D=$1; _S=${2:-$1}; bash "$LAB_SH" fresh "$1"; }
  project() { fresh "w/$1/planner" planner; bash "$LAB_SH" skeleton "w/$1/planner"; }
  put() { bash "$LAB_SH" put "$_D" "$1" "$2" "${3:-}"; }
  run() { _prompt "$_S" "$*"; bash "$LAB_SH" exec "$_D" "$*" | _strip; }
  quiet() { bash "$LAB_SH" exec "$_D" "$*" >/dev/null 2>&1 || true; }
  block() { printf '##### %s\n' "$1"; }
  bare() { _prompt "${BARE_D:-.}" "$*"; bash "$LAB_SH" bare "${BARE_D:+cd ~/$BARE_D && }$*" | _strip; }
  bare_quiet() { bash "$LAB_SH" bare "${BARE_D:+cd ~/$BARE_D && }$*" >/dev/null 2>&1 || true; }
  rebare() { bash "$LAB_SH" rebare; }
  shot() { mkdir -p "$(dirname "$2")"; cp "/var/lib/machines/android-lab/home/ana/$_D/app/$1" "$2"; }
  return 0
fi

case "${1:-}" in
  build) build ;;
  install) install_android ;;
  bare)
    need_root
    # INSTALLED=1: the bare copy after a capture typed lesson 1's install
    # into it, with the environment ~/.bashrc now gives a new terminal.
    if [ -n "${INSTALLED:-}" ]; then in_root "$BARE" ana "$2" "$LIVE_ENV"; else in_root "$BARE" ana "$2" "$BARE_ENV"; fi
    ;;
  rebare) need_root; rm -rf "$BARE"; cp -a "$BASE" "$BARE" ;;
  exec)
    need_root
    [ $# -ge 3 ] || { echo "usage: lab.sh exec DIR 'command'" >&2; exit 2; }
    dir=$2 bind= env=$LIVE_ENV
    [ -n "${PLAIN_PATH:-}" ] && env=$BARE_ENV
    # ~/w/<lesson>/planner[/sub] runs as ~/planner[/sub]
    if [[ $dir =~ ^(w/[^/]+/planner)(/.*)?$ ]]; then bind=${BASH_REMATCH[1]}; dir=planner${BASH_REMATCH[2]}; fi
    in_root "$LIVE" ana "mkdir -p ~/'$dir' && cd ~/'$dir' && $3" "$env" "$bind"
    ;;
  fresh)
    need_root
    # Empty the directory rather than replace it: a Gradle daemon still running
    # from an earlier command holds a mount of this very directory, and a new
    # directory in its place would be invisible to that daemon.
    if [ -d "$LIVE/home/ana/$2" ]; then
      find "${LIVE:?}/home/ana/${2:?}" -mindepth 1 -maxdepth 1 -exec rm -rf {} +
    fi
    in_root "$LIVE" ana "mkdir -p ~/'$2'" "$LIVE_ENV"
    ;;
  skeleton)
    need_root
    for f in $SKELETON_FILES; do _put "$2" "$SKELETON_MD" "$f"; done
    in_root "$LIVE" ana "cd ~/planner && gradle wrapper --gradle-version $GRADLE -q" "$LIVE_ENV" "$2" >/dev/null
    ;;
  extract) _extract "$2" "$3" "${4:-}" ;;
  put) need_root; _put "$2" "$3" "$4" "${5:-}" ;;
  *) sed -n '2,40p' "$0" >&2; exit 2 ;;
esac
