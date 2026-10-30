#!/usr/bin/env bash
# The terminal sessions quoted in lesson 16 of azure-compute (Consumption,
# Premium and Dedicated plans: the cold-start arithmetic), as a script that
# produces them. THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   bash lessons/le-ekwf1wp6/captures.sh
#
# What answers here, with no Azure account:
#   - the Azure CLI 2.91.0's help for `az functionapp create` and
#     `az functionapp plan create`;
#   - the Bicep compiler 0.48.1, compiling a Flex Consumption plan and app;
#   - the Functions host, version 4, in Microsoft's image
#     mcr.microsoft.com/azure-functions/python:4-python3.12, running lesson
#     15's app, with Azurite 3.37.0 as its storage account;
#   - python3, running the arithmetic of the last section with ILLUSTRATIVE
#     rates that the lesson says are not Azure's prices.
# No plan, instance or cold start in Azure is run: those sections are read.
#
# EVERY TIMING IN THIS SCRIPT IS THE RECORDING LAPTOP'S (4 CPUs, shared with
# other work), and the lesson says so; none of them is Azure's.
#
# What is STAGED rather than typed:
#   - both images were on the machine before the run; the student pulled them
#     in lesson 15. The Functions image, like every base image this course
#     builds FROM, carries this machine's proxy certificate (see lab.sh), and
#     pip inside the build reaches PyPI through it; nothing else differs;
#   - the student edits slow/function_app.py with an editor; here `sed` does
#     it, and the command is shown;
#   - lesson 15's files (the first version of function_app.py, host.json,
#     requirements.txt, the Dockerfile and storage.sh) are read out of that
#     lesson's sections, where the student wrote them;
#   - flex.bicep is read out of `what-a-plan-decides`, the shell function
#     `first200` out of the example in `measuring-it`, and plans.py out of the
#     example in `the-arithmetic`; the student types or pastes them;
#   - the containers, the network and the images are removed at the end.
#
# Recorded 2026-10-30 on Ubuntu 24.04, Docker 29, no Azure account,
# TZ=America/Sao_Paulo.

HERE=$(cd "$(dirname "$0")" && pwd)
L15=$HERE/../le-sjk8bw8s
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"

# fence MD LANG N: the Nth fence labelled LANG in MD
fence() {
  python3 - "$1" "$2" "$3" <<'PY'
import re, sys
md, lang, n = sys.argv[1], sys.argv[2], int(sys.argv[3])
found = re.findall(r'^```' + re.escape(lang) + r'\n(.*?)^```$', open(md).read(), re.S | re.M)
if not 1 <= n <= len(found):
    sys.exit(f'{md}: no {lang} fence number {n}')
sys.stdout.write(found[n - 1])
PY
}

quiet 'docker rm -f cold azurite'
quiet 'docker network rm functions'

# lesson 15's app, as the student left it after that lesson's first section
eval "$(fence "$L15/a-function-app.md" sh 1)" >/dev/null 2>&1
cd ~/azure || exit 1
from_example "$L15/a-function-app.md" function_app.py > shopfn/function_app.py
fence "$L15/a-function-app.md" json 1 > shopfn/host.json
from_lesson "$L15/a-function-app.md" Dockerfile > shopfn/Dockerfile
from_lesson "$L15/running-it-locally.md" storage.sh > storage.sh

from_lesson "$HERE/what-a-plan-decides.md" flex.bicep > flex.bicep
from_example "$HERE/measuring-it.md" first200.sh > first200.sh
from_example "$HERE/the-arithmetic.md" plans.py > plans.py
quiet '. ./first200.sh'
quiet 'rm first200.sh'

block help
run "az functionapp create --help | grep -E '^    --(flexconsumption-location|instance-memory|maximum-instance-count|always-ready-instances) '"
run "az functionapp plan create --help | grep -A2 'elastic premium'"

block bicep
run 'bicep build flex.bicep'
run "sed -i 's/instanceMemoryMB: 2048/instanceMemoryMB: 1024/; s/maximumInstanceCount: 100/maximumInstanceCount: 2000/' flex.bicep"
run 'bicep build flex.bicep'
run 'jq ".resources[1].properties.functionAppConfig.scaleAndConcurrency" flex.json'

block start
run 'source storage.sh'
run 'docker network create functions'
run 'docker run -d --name azurite --network functions -p 10000-10002:10000-10002 mcr.microsoft.com/azure-storage/azurite:3.37.0'
run 'docker build -q -t shopfn:1 shopfn'

block light
run 'first200 shopfn:1'
run 'first200 shopfn:1'
run 'first200 shopfn:1'

block phases
run "docker inspect -f '{{.State.StartedAt}}' cold"
run "docker logs -t cold 2>&1 | grep -E 'CLOUD_CERTS|Initializing Host\\.|Loading functions metadata|functions loaded|Host started|Executed ' | cut -c1-125"

block slow
run 'cp -r shopfn slow'
run "sed -i 's/^import logging\$/&\\nimport time\\ntime.sleep(8)/' slow/function_app.py"
run 'head -6 slow/function_app.py'
run 'docker build -q -t shopfn:slow slow'

block slowrun
run 'first200 shopfn:slow'
run 'first200 shopfn:slow'
run 'first200 shopfn:slow'
run "docker logs -t cold 2>&1 | grep -E 'CLOUD_CERTS|Initializing Host\\.|Loading functions metadata|functions loaded|Host started|Executed ' | cut -c1-125"

block cpus
run 'nproc'
run 'first200 shopfn:1 1'
run 'first200 shopfn:1 0.5'
run 'first200 shopfn:1 0.25'

block plans
run 'python3 plans.py'

quiet 'docker rm -f cold azurite'
quiet 'docker network rm functions'
quiet 'docker image rm shopfn:1 shopfn:slow'
