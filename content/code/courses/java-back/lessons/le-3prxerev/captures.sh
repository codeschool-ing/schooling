#!/usr/bin/env bash
# The terminal sessions quoted in lesson 3 of java-back, as a script that
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
#   2. ana's environment (EXTRA_ENV) carries three things a student needs
#      none of: PATH with ~/bin first, which Ubuntu's ~/.profile does at login
#      and these non-login commands do not; this sandbox's HTTPS proxy, which
#      is the only way out of the machine; and BAZELISK_BASE_URL pointing
#      Bazelisk at Bazel's GitHub releases, because releases.bazel.build (its
#      default) is not reachable from here. The binary is the same one.
#   3. ~/.bazelrc, ana's own rc file, which Bazel reads beside the project's:
#        --registry  the Bazel Central Registry read from its GitHub
#                    repository (raw.githubusercontent.com), because
#                    bcr.bazel.build is not reachable from here. Same files.
#        --downloader_config  rewrites repo1.maven.org to Google's public
#                    mirror of Maven Central, which answers this machine with
#                    429; the sha256 in MODULE.bazel is checked either way,
#                    so the jars are provably Central's.
#        --extra_toolchains=@@rules_java++toolchains+local_jdk//:all and
#        --tool_java_runtime_version=local_jdk  compile and run Bazel's Java
#                    tools on the machine's OpenJDK 25, because the two JDKs
#                    rules_java downloads by default (Azul Zulu 25 for the
#                    compiler, Zulu 11 for the tools) come from cdn.azul.com
#                    and mirror.bazel.build, neither reachable from here. The
#                    lesson says a student's first build downloads both.
#      /etc/bazel.bazelrc (the sandbox's) adds the proxy's CA to Bazel's JVM.
#   4. The first `bazel version` downloads Bazel 9.3.0 and the first analysis
#      fetches rules_java and the jars; both run quietly before the quoted
#      commands, because their output names the lab's mirrors. The lesson says
#      what a first run downloads. The compile itself is quoted, cold.
#   5. The "missing load" detour deletes the two load lines with sed and puts
#      the file back from the lesson afterwards.
#   6. Block "jars" is not quoted: it counts the runtime jars of the bookshop
#      at lesson 4 and at lesson 22, the numbers the last section cites.
#
# Elapsed times, critical paths and the configuration hashes in cquery's
# output differ between runs and machines.
#
# Recorded on Ubuntu 24.04, OpenJDK 25.0.4, Bazelisk 1.29.0, Bazel 9.3.0,
# rules_java 9.9.0, TZ=America/Sao_Paulo.
source "$(dirname "$0")/../../capture.sh"
cd "$(dirname "$0")"
LESSON=$(pwd)
# The proxy's port changes when the sandbox restarts: take it from root's environment.
export EXTRA_ENV="PATH=/home/ana/bin:/usr/local/bin:/usr/bin:/bin HTTPS_PROXY=${HTTPS_PROXY:-http://127.0.0.1:40917} BAZELISK_BASE_URL=https://github.com/bazelbuild/bazel/releases/download"

# A schooling-example the lesson shows, written as ana: the parts joined with
# newlines, as the copy button joins them.
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

# A clean slate: no Bazel server, no project, no Bazel cache, no Bazelisk.
quiet 'cd ~/isbn-bazel 2>/dev/null && bazel shutdown'
quiet 'chmod -R u+w ~/.cache/bazel 2>/dev/null; rm -rf ~/.cache/bazel ~/isbn-bazel ~/isbn-check ~/bin/bazel'
asroot "cp -a '$COURSE/lab/projects/isbn-check' /home/ana/isbn-check && chown -R ana:ana /home/ana/isbn-check"
put .bazel-downloader.cfg <<'EOF'
rewrite repo1.maven.org/maven2/(.*) maven-central.storage-download.googleapis.com/maven2/$1
EOF
put .bazelrc <<'EOF'
common --registry=https://raw.githubusercontent.com/bazelbuild/bazel-central-registry/main/
common --downloader_config=/home/ana/.bazel-downloader.cfg
common --extra_toolchains=@@rules_java++toolchains+local_jdk//:all
common --tool_java_runtime_version=local_jdk
EOF

block install
run 'mkdir -p ~/bin'
run 'curl -fsSL -o ~/bin/bazel https://github.com/bazelbuild/bazelisk/releases/download/v1.29.0/bazelisk-linux-amd64'
run 'chmod +x ~/bin/bazel'

block project
run 'mkdir ~/isbn-bazel && cp -r ~/isbn-check/src ~/isbn-bazel/'
at '~/isbn-bazel'
run 'echo 9.3.0 > .bazelversion'
example a-module.md MODULE.bazel isbn-bazel/MODULE.bazel
take a-module.md '# Compile for Java 25' isbn-bazel/.bazelrc
example targets-and-labels.md BUILD.bazel isbn-bazel/src/main/java/com/example/isbn/BUILD.bazel
take targets-and-labels.md 'load("@rules_java//java:java_test.bzl"' isbn-bazel/src/test/java/com/example/isbn/BUILD.bazel
# Bazel itself, downloaded by Bazelisk, then a server started and stopped, so
# that `bazel version` below starts one the way a first command does.
quiet 'bazel version && bazel shutdown'

block version
run 'bazel version'
# Fetch rules_java and the jars without compiling anything.
quiet 'bazel build --nobuild //...'

block build
run 'bazel build //src/main/java/com/example/isbn:isbn-check'
run 'ls -A'
run 'bazel run //src/main/java/com/example/isbn:isbn-check -- 978-0-306-40615-7 0-306-40615-2 978-0-306-40615-8'

block test
run 'bazel test //... --test_output=all'
run 'bazel test //...'

block graph
run "bazel cquery --noimplicit_deps 'deps(//src/test/java/com/example/isbn:IsbnCheckTest)'"

block noload
quiet "sed -i '1,2d' src/main/java/com/example/isbn/BUILD.bazel"
run 'bazel build //...'
example targets-and-labels.md BUILD.bazel isbn-bazel/src/main/java/com/example/isbn/BUILD.bazel
run 'bazel build //... && echo restored'

# Leave no server behind.
quiet 'bazel shutdown'

block jars
at '~'
for id in le-djnvk025 le-p1p8dt26; do
  stage "$id"
  at '~/bookshop'
  run 'mvn -B -q dependency:list -DincludeScope=runtime -DoutputFile=/tmp/l3-jars.txt >/dev/null 2>&1; grep -c ":jar:" /tmp/l3-jars.txt'
  at '~'
done
