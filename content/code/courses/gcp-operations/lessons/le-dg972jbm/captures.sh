#!/usr/bin/env bash
# The terminal sessions quoted in lesson 21 of gcp-operations.
#
#   bash captures.sh
#
# cud.py is taken out of the lesson. Its prices are relative and its
# discounts are the pricing page's, as it says.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"
cd "$HOME/gcp" || exit 1
from_lesson "$HERE/commitment.md" cud.py > cud.py
block cud
run 'python3 cud.py'
