#!/usr/bin/env bash
# The terminal sessions quoted in lesson 22 of gcp-operations.
#
#   bash captures.sh
#
# util.py is taken out of the lesson; its utilisation is generated, as it
# says. Nothing here comes from the Recommender API.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"
cd "$HOME/gcp" || exit 1
from_lesson "$HERE/utilisation.md" util.py > util.py
block util
run 'python3 util.py'
