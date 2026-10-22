#!/usr/bin/env bash
# The terminal sessions quoted in lesson 2 of java-back, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# What is STAGED rather than typed, and never shown in the lesson:
#   1. ~/isbn-check is lesson 1's project, copied from lab/projects/isbn-check:
#      this lesson only copies its src/ and never reprints it.
#   2. ~/.gradle/gradle.properties names this sandbox's HTTPS proxy as JVM
#      system properties, because Gradle (and the wrapper's own download)
#      reach the internet only through it. A student's machine needs nothing.
#   3. ~/.gradle/init.d/central-mirror.init.gradle.kts points every
#      mavenCentral() at Google's public mirror of Maven Central, because
#      Central answers this machine with "429 Too Many Requests" (it did, on
#      the first try, for junit-platform-launcher's pom). The artifacts and
#      their checksums are Central's. No transcript here shows a download from
#      a Maven repository, so no output names the mirror.
#   4. curl reaches services.gradle.org through the same proxy, passed as
#      https_proxy in ana's environment (EXTRA_ENV) for those commands only.
#      The zip itself is served from GitHub's release storage after a
#      redirect, exactly as for a student.
#   5. The .sha256 file beside the zip redirects to downloads.gradle.org,
#      which this machine cannot reach; the lesson reads the same checksum
#      from services.gradle.org/versions/all instead, and says where else it
#      is published.
#   6. `sudo apt install unzip` is shown in the prose as a command a fresh
#      Ubuntu Server may need. ana has no sudo here and unzip is installed, so
#      it was not run.
#   7. The Gradle daemon is stopped at the end so it does not outlive the run.
#
# Durations ("BUILD SUCCESSFUL in 2s"), daemon PIDs and the wrapper's
# download progress differ on every run.
#
# Recorded on Ubuntu 24.04, OpenJDK 25.0.4, Gradle 9.8.1, TZ=America/Sao_Paulo.
source "$(dirname "$0")/../../capture.sh"
cd "$(dirname "$0")"
LESSON=$(pwd)
# The sandbox's proxy, wherever it listens today (its port changes when the
# machine restarts).
PROXY_URL=${HTTPS_PROXY:-${https_proxy:?the sandbox proxy is not set}}
PROXY_PORT=${PROXY_URL##*:}; PROXY_PORT=${PROXY_PORT%/}
PROXY="https_proxy=$PROXY_URL"

# The build script the lesson shows as an annotated example, written as ana:
# the parts joined with newlines, as the copy button joins them.
example() {
  python3 - "$1" "$2" <<'PY' | put "$3"
import json, sys
md, name = sys.argv[1], sys.argv[2]
body, cur = [], None
for line in open(md, encoding='utf-8').read().split('\n'):
    if line.startswith('```'):
        if cur is None:
            cur = [] if line[3:].strip() == 'schooling-example' else False
        else:
            if cur is not False:
                ex = json.loads('\n'.join(cur))
                if ex.get('file') == name:
                    body.append('\n'.join(p['code'] for p in ex['parts']))
            cur = None
    elif cur not in (None, False):
        cur.append(line)
assert len(body) == 1, (md, name, len(body))
sys.stdout.write(body[0] + '\n')
PY
}

# A clean slate: no Gradle, no project, no wrapper download, no daemon.
quiet 'cd ~/isbn-gradle 2>/dev/null && ./gradlew --stop'
quiet 'rm -rf ~/isbn-check ~/isbn-gradle ~/opt ~/gradle-9.8.1-bin.zip ~/.gradle'
asroot "cp -a '$COURSE/lab/projects/isbn-check' /home/ana/isbn-check && chown -R ana:ana /home/ana/isbn-check"
put .gradle/gradle.properties <<EOF
systemProp.https.proxyHost=127.0.0.1
systemProp.https.proxyPort=$PROXY_PORT
systemProp.http.nonProxyHosts=localhost|127.0.0.1
EOF
put .gradle/init.d/central-mirror.init.gradle.kts <<'EOF'
// Maven Central answers this machine with 429: fetch Central's artifacts from
// Google's public mirror of it instead.
allprojects {
    repositories.withType<MavenArtifactRepository>().configureEach {
        if (url.toString().startsWith("https://repo.maven.apache.org/maven2")) {
            url = uri("https://maven-central.storage-download.googleapis.com/maven2/")
        }
    }
}
EOF

block install
EXTRA_ENV=$PROXY run 'curl -sLO https://services.gradle.org/distributions/gradle-9.8.1-bin.zip'
run 'ls -l gradle-9.8.1-bin.zip'
run 'sha256sum gradle-9.8.1-bin.zip'
EXTRA_ENV=$PROXY run "curl -s https://services.gradle.org/versions/all | python3 -c 'import json, sys; print(next(v[\"checksum\"] for v in json.load(sys.stdin) if v[\"version\"] == \"9.8.1\"))'"
run 'mkdir -p ~/opt && unzip -q gradle-9.8.1-bin.zip -d ~/opt'
run 'ls ~/opt/gradle-9.8.1'
run '~/opt/gradle-9.8.1/bin/gradle --version'
run 'command -v gradle || echo "not on PATH"'

block project
run 'mkdir ~/isbn-gradle && cp -r ~/isbn-check/src ~/isbn-gradle/'
at '~/isbn-gradle'
take the-build-script.md 'rootProject.name' isbn-gradle/settings.gradle.kts
example "$LESSON/the-build-script.md" build.gradle.kts isbn-gradle/build.gradle.kts
take the-build-script.md 'org.gradle.console=plain' isbn-gradle/gradle.properties
run 'find . -type f | sort'

block wrapper
run '~/opt/gradle-9.8.1/bin/gradle wrapper --gradle-version 9.8.1 --gradle-distribution-sha256-sum dce76f55f8e251a3a1f130eb120f30b3d271de2b76c9b0729d316b5a1b6dc01f'
run 'find . -type f -not -path "./src/*" -not -path "./.gradle/*" | sort'
run 'cat gradle/wrapper/gradle-wrapper.properties'
run './gradlew --version'
run 'ls ~/.gradle/wrapper/dists/'

block tasks
run './gradlew tasks --group build'
run './gradlew build'
run 'ls build/libs build/distributions'
run "grep -o 'tests=\"[0-9]*\" skipped=\"[0-9]*\" failures=\"[0-9]*\"' build/test-results/test/*.xml"
run './gradlew build --dry-run'
run './gradlew -q run --args="978-0-306-40615-7 0-306-40615-2 978-0-306-40615-8"'
run './gradlew -q dependencies --configuration runtimeClasspath'

block launcher
run "sed -i '/junit-platform-launcher/d' build.gradle.kts"
run './gradlew test'
example "$LESSON/the-build-script.md" build.gradle.kts isbn-gradle/build.gradle.kts
run './gradlew build'

block incremental
run './gradlew build'
run 'touch src/main/java/com/example/isbn/IsbnCheck.java && ./gradlew build'
run "sed -i 's/\": \"/\" -> \"/' src/main/java/com/example/isbn/IsbnCheck.java"
run './gradlew build'
run './gradlew -q run --args="0-306-40615-2"'
run "sed -i 's/\" -> \"/\": \"/' src/main/java/com/example/isbn/IsbnCheck.java"
run "./gradlew build --info | grep -A1 'is not up-to-date'"

block caches
take incremental-builds.md 'org.gradle.console=plain' isbn-gradle/gradle.properties
run 'cat gradle.properties'
run './gradlew clean build'
run './gradlew clean build'

block daemon
run './gradlew --status'
run './gradlew --stop'

quiet 'cd ~/isbn-gradle && ./gradlew --stop'
