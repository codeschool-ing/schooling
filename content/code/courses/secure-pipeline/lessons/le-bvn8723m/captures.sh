#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of secure-pipeline, as a script that
# produces them. Each block of output starts with `##### <name>`.
#
#   sudo bash captures.sh
#
# WHAT IS STAGED: ~/linkbox and ~/ci as they stand at the start of lesson 9
# (lessons 1 to 8, one commit each, fixed dates), and the registry lesson 8
# started, empty. The image linkbox:dev is built on screen, as the student
# has it from lesson 8. Files the lesson has the student save are copied out
# of its own fences (`place`): ~/threads.py and ci/dast.sh.
#
# What differs between runs: container ids, the short codes linkbox makes,
# the times in gunicorn's log, the commit hash of the commit made on screen,
# the timings of the pipeline, and how many threads start before the limit
# (the count includes whatever else holds a pid in the container).
#
# Recorded on Ubuntu 24.04 with Docker 29.9.1 (cgroup v1), TZ=America/Sao_Paulo.
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/../../lab/capture.sh"
MD=lessons/le-bvn8723m
runh() { run "$(cat)"; } # the command from a heredoc, quotes and all
lab project 9 >/dev/null 2>&1 || { echo "##### the project did not build" >&2; exit 1; }
docker rm -f linkbox hog >/dev/null 2>&1

block build
run 'cd ~/linkbox'
run 'docker build -q -t linkbox:dev .'

block defaults
run 'docker run -d --name linkbox -p 127.0.0.1:8000:8000 -e LINKBOX_TOKEN=local-only linkbox:dev'
quiet 'sleep 2'
runh <<'EOF'
docker inspect --format 'read-only={{.HostConfig.ReadonlyRootfs}} cap-drop={{.HostConfig.CapDrop}} security-opt={{.HostConfig.SecurityOpt}} memory={{.HostConfig.Memory}} pids-limit={{.HostConfig.PidsLimit}}' linkbox
EOF

block status
runh <<'EOF'
status='import re; print("".join(l for l in open("/proc/1/status") if re.match("(Uid|Cap|NoNewPrivs|Seccomp)", l)), end="")'
EOF
run 'docker exec linkbox python3 -c "$status"'

block writable
runh <<'EOF'
docker exec linkbox python3 -c "open('/tmp/dropped.py', 'w').write('print(1)'); print('written')"
EOF
runh <<'EOF'
docker exec linkbox python3 -c "open('/app/app.py', 'a')"
EOF
run 'docker rm -f linkbox'

block user-zero
run 'docker run --rm --user 0 --entrypoint python3 linkbox:dev -c "$status"'
runh <<'EOF'
docker run --rm --user 0 --entrypoint python3 linkbox:dev -c "open('/app/app.py', 'a').write('# changed'); print('app.py changed')"
EOF

block ro-fails
run 'docker run -d --name linkbox --read-only -p 127.0.0.1:8000:8000 -e LINKBOX_TOKEN=local-only linkbox:dev'
quiet 'sleep 3'
run 'docker ps -a --filter name=linkbox --format "{{.Status}}"'
run 'docker logs linkbox 2>&1 | tail -n 3'
run 'docker rm -f linkbox'

block ro-tmp
run 'docker run -d --name linkbox --read-only --tmpfs /tmp -p 127.0.0.1:8000:8000 -e LINKBOX_TOKEN=local-only linkbox:dev'
quiet 'sleep 2'
run 'curl -s -o /dev/null -w "%{http_code}\n" -X POST -H "X-Token: local-only" -d url=https://example.org/handbook http://127.0.0.1:8000/links'
run 'docker logs linkbox 2>&1 | grep Error'
run 'docker rm -f linkbox'

block ro-data
run 'docker run -d --name linkbox --read-only --tmpfs /tmp --tmpfs /data:uid=65532,gid=65532 -p 127.0.0.1:8000:8000 -e LINKBOX_TOKEN=local-only linkbox:dev'
quiet 'sleep 2'
run 'curl -s -X POST -H "X-Token: local-only" -d url=https://example.org/handbook http://127.0.0.1:8000/links'
runh <<'EOF'
docker exec linkbox python3 -c "print(open('/proc/mounts').read(), end='')" | grep -E ' (/|/tmp|/data) ' | sed -E 's/,(lower|upper|work)dir=[^, ]*//g'
EOF
run 'docker rm -f linkbox'
runh <<'EOF'
docker run --rm --read-only --user 0 --entrypoint python3 linkbox:dev -c "open('/app/app.py', 'a')"
EOF

block restricted
run 'docker run -d --name linkbox --read-only --tmpfs /tmp --tmpfs /data:uid=65532,gid=65532 --cap-drop ALL --security-opt no-new-privileges -p 127.0.0.1:8000:8000 -e LINKBOX_TOKEN=local-only linkbox:dev'
quiet 'sleep 2'
run 'curl -s -X POST -H "X-Token: local-only" -d url=https://example.org/handbook http://127.0.0.1:8000/links'
run 'docker exec linkbox python3 -c "$status"'

block root-no-caps
runh <<'EOF'
docker run --rm --user 0 --entrypoint python3 linkbox:dev -c "import os; os.chown('/data', 0, 0); print('chowned')"
EOF
runh <<'EOF'
docker run --rm --user 0 --cap-drop ALL --entrypoint python3 linkbox:dev -c "import os; os.chown('/data', 0, 0); print('chowned')"
EOF

block setuid
runh <<'EOF'
docker exec linkbox python3 -c "import os, stat; print([os.path.join(d, f) for d, _, fs in os.walk('/usr') for f in fs if os.path.isfile(os.path.join(d, f)) and os.stat(os.path.join(d, f)).st_mode & stat.S_ISUID])"
EOF

block seccomp
run 'docker info --format "{{.SecurityOptions}}"'
runh <<'EOF'
docker run --rm --user 0 --entrypoint python3 linkbox:dev -c "import os; os.unshare(os.CLONE_NEWUSER); print('in a new user namespace')"
EOF
runh <<'EOF'
docker run --rm --user 0 --security-opt seccomp=unconfined --entrypoint python3 linkbox:dev -c "import os; os.unshare(os.CLONE_NEWUSER); print('in a new user namespace')"
EOF

block memory
runh <<'EOF'
docker run --name hog --memory 128m --memory-swap 128m --entrypoint python3 linkbox:dev -c "b = bytearray(300 * 1024 * 1024)"; echo "exit $?"
EOF
run 'docker inspect --format "{{.State.OOMKilled}}" hog'
run 'docker rm hog'

block pids
place "$MD/seccomp-and-limits.md" "~/threads.py"
run 'docker run --rm -i --pids-limit 32 --entrypoint python3 linkbox:dev - < ~/threads.py'

block stats
run 'docker rm -f linkbox'
run 'docker run -d --name linkbox --read-only --tmpfs /tmp --tmpfs /data:uid=65532,gid=65532 --cap-drop ALL --security-opt no-new-privileges --memory 256m --pids-limit 64 -p 127.0.0.1:8000:8000 -e LINKBOX_TOKEN=local-only linkbox:dev'
quiet 'sleep 2'
run 'docker stats --no-stream --format "{{.Name}}  memory {{.MemUsage}}  pids {{.PIDs}}" linkbox'
run 'docker rm -f linkbox'

block staging
place "$MD/staging.md" ci/dast.sh
run 'git diff ci/dast.sh'

block nightly
run 'ci/pipeline.sh ci/nightly'

block commit
run 'git commit -q -am "staging runs the image read-only, as nobody, with no capabilities"'
run 'git push ci main'

block end
docker rm -f linkbox hog >/dev/null 2>&1
bash "$COURSE/lab.sh" as sh -c 'rm -f ~/threads.py; rm -rf ~/linkbox/ci-logs'
docker rmi -f $(docker images -q linkbox) $(docker images -q localhost:5000/linkbox) >/dev/null 2>&1
docker image prune -f >/dev/null 2>&1
exit 0
