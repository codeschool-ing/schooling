#!/usr/bin/env bash
# The terminal sessions quoted in lesson 21 of java-back, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# What is STAGED rather than typed:
#   - the bookshop as this lesson leaves it (lesson 20's, plus the Cucumber
#     dependencies, the feature file, the runner, the Spring configuration and
#     the step definitions). Every one of those files is compared with what the
#     lesson prints, byte for byte, at the end of this script;
#   - the two detours of a-step-with-no-code.md (a line added to the feature
#     file, then a total changed from 6400 to 6300) are applied by this script,
#     run, and undone; the added line is checked against the lesson's own fence;
#   - the tests need no database of ana's: Testcontainers starts PostgreSQL in
#     Docker for them, as lesson 19 set up. Docker pulls through mirror.gcr.io,
#     as lab.sh says, and the image was already in the cache;
#   - ana has no sudo in the lab; no command in this lesson needs it.
#
# Cucumber's pretty report marks an undefined step with U+25A0, which the
# interface's mono font does not have, so the transcript of the undefined step
# selects the snippet with a visible grep rather than showing that line.
#
# Run as root. Timestamps, PIDs, ports and durations differ on every run.
#
# Recorded on Ubuntu 24.04, OpenJDK 25.0.4, Maven 3.8.7, Docker Engine 29.8.2,
# TZ=America/Sao_Paulo.
source "$(dirname "$0")/../../capture.sh"
cd "$(dirname "$0")"
LESSON=$(pwd)
STAGE=$COURSE/lab/stages/le-fzjrd3nz
BS=/home/ana/bookshop
FEATURE=src/test/resources/features/ordering.feature
ACC=src/test/java/com/example/bookshop/acceptance

# replace, in a file of ~/bookshop, one exact piece of text with another
edit() { python3 - "$BS/$1" "$2" "$3" <<'PY' || { echo "!!! edit of $1 did not apply" >&2; exit 1; }
import sys
path, old, new = sys.argv[1:]
text = open(path, encoding='utf-8').read()
if text.count(old) != 1:
    sys.exit(1)
open(path, 'w', encoding='utf-8').write(text.replace(old, new))
PY
}
restore() { cp "$STAGE/$1" "$BS/$1" && chown ana:ana "$BS/$1"; }
same_as_stage() { for f in "$@"; do cmp -s "$STAGE/$f" "$BS/$f" || { echo "!!! $f differs from the stage" >&2; exit 1; }; done; }

stage le-fzjrd3nz
at '~/bookshop'

block tree
run "mvn dependency:tree | grep -E 'cucumber-(java|spring|junit)|junit-platform-suite:'"

block run
run "mvn verify -Dit.test=CucumberIT | grep -E ' # (classpath|com\.example)|Tests run:.*Cucumber|BUILD'"

block shared
run "mvn verify | grep -E 'Running .*IT$|Creating container for image: postgres|Started [A-Z]|BUILD'"

# --- a step nobody wrote code for -----------------------------------------------
ADDED='    And she receives an e-mail confirming the order'
grep -qxF "$ADDED" a-step-with-no-code.md || { echo '!!! the added line is not in the lesson' >&2; exit 1; }
edit $FEATURE "$(printf '    And "The War of the Worlds" has 3 copies left\n')" \
  "$(printf '    And "The War of the Worlds" has 3 copies left\n%s\n' "$ADDED")"
block undefined
run "mvn verify -Dit.test=CucumberIT | grep -A 8 UndefinedStepException"
restore $FEATURE

# --- a step that fails ------------------------------------------------------------
edit $FEATURE 'total of 6400 cents' 'total of 6300 cents'
block failing
run "mvn verify -Dit.test=CucumberIT | grep -E ' # (classpath|com\.example)|expected:|but was:'"
restore $FEATURE

# --- what the lesson shows is what the stage holds ---------------------------------
block check
for f in $(cd $STAGE && find . -type f ! -name .removed | sed 's|^\./||'); do same_as_stage "$f"; done
shown the-feature-file.md $FEATURE
shown step-definitions.md $ACC/OrderingSteps.java
shown running-the-features.md pom.xml $ACC/CucumberIT.java $ACC/CucumberSpringConfiguration.java
echo 'every file shown is the file the stage holds'
