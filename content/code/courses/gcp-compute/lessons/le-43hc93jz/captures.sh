#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of gcp-compute, as a script that
# produces them. THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   bash lab.sh tools                   # once, beside course.json
#   bash lessons/le-43hc93jz/captures.sh
#
# Every run is in a network namespace with only loopback, so nothing here
# reached Google.
#
# What is STAGED rather than typed:
#   - `terraform init` is run quietly, and again if another run holds the
#     shared provider cache; lesson 1 shows its output;
#   - group/main.tf is built from the lesson's blocks as the student builds it:
#     the template, the group, the health check, and then the fragments the
#     lesson says to put INSIDE the group's resource, which `inside` below
#     inserts before the group's last closing brace; the canary replaces the
#     single version block the same way.
#
# Recorded 2026-10-30 on Ubuntu 24.04, no Google Cloud account,
# TZ=America/Sao_Paulo.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"

# inside FILE FRAGMENT: put FRAGMENT before the closing brace of the group
inside() {
  python3 - "$1" "$2" <<'PY'
import sys
path, frag = sys.argv[1], open(sys.argv[2]).read()
s = open(path).read()
start = s.index('resource "google_compute_region_instance_group_manager"')
end = s.index('\n}\n', start)
open(path, 'w').write(s[:end] + '\n' + frag.rstrip('\n') + s[end:])
PY
}

mkdir -p group
from_lesson "$HERE/templates.md" group/main.tf > group/main.tf
cd group || exit 1
quiet 'for i in $(seq 200); do terraform init && break; sleep 3; done'

block template-plan
run "terraform plan -no-color | grep -E '^  #|name_prefix|^      \\+ name |machine_type|^Plan'"

block group-plan
from_lesson "$HERE/the-group.md" 'group/main.tf, continued' >> main.tf
run "terraform plan -no-color | grep -E '^  #|^      \\+ target_size +=|base_instance_name|^Plan'"

block health-plan
from_lesson "$HERE/zones-and-health.md" 'group/main.tf, health' >> main.tf
from_lesson "$HERE/zones-and-health.md" 'group/main.tf, inside the group' > /tmp/frag.$$
inside main.tf /tmp/frag.$$
run "terraform plan -no-color | grep -E '^  #|initial_delay_sec|request_path|unhealthy_threshold|^Plan'"

block policy-typo
from_lesson "$HERE/rolling-updates.md" 'group/main.tf, update policy' > /tmp/frag.$$
sed 's/"PROACTIVE"$/"SOMETIMES"/' /tmp/frag.$$ | sed '0,/SOMETIMES/!s/"SOMETIMES"/"PROACTIVE"/' > /tmp/frag2.$$
inside main.tf /tmp/frag2.$$
run 'grep -n "type " main.tf'
run 'terraform plan -no-color'
quiet "sed -i '0,/\"SOMETIMES\"/s/\"SOMETIMES\"/\"PROACTIVE\"/' main.tf"

block policy-plan
run "terraform plan -no-color | grep -E 'max_surge_fixed|max_unavailable_fixed|minimal_action|\"PROACTIVE\"|^Plan'"

block canary-plan
from_lesson "$HERE/rolling-updates.md" 'group/main.tf, canary' > /tmp/frag.$$
python3 - main.tf /tmp/frag.$$ <<'PY'
import sys, re
path, frag = sys.argv[1], open(sys.argv[2]).read()
s = open(path).read()
old = '  version {\n    instance_template = google_compute_instance_template.web.id\n  }\n'
assert old in s
open(path, 'w').write(s.replace(old, frag.split('\n', 1)[1]))
PY
run "terraform plan -no-color | grep -E '^      \\+ version|instance_template = |name += \"(stable|canary)\"|^              \\+ fixed|^Plan'"
rm -f /tmp/frag.$$ /tmp/frag2.$$
