#!/usr/bin/env bash
# The terminal sessions quoted in lesson 16 of qa-fundamentals, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it:
#
#   bash ../../lab.sh image          # once
#   bash captures.sh > out.txt && python3 ../../lab/splice.py . out.txt
#
# The machine is the one lesson 1 builds, with behave 1.3.3 in its virtual
# environment. coupons.py, features/coupons.feature and the step definitions
# are read out of the lessons by lab/extract.py, every version printed; a path
# with a folder in it is kept in ~/.versions with the slash as an underscore,
# so those are copied by hand rather than with `version`. The first block
# removes the step definitions, because the first run is the one without them.
#
# Recorded on Ubuntu 24.04, Python 3.12.3, behave 1.3.3, on 2026-10-11.
set -uo pipefail
cd "$(dirname "$0")"
LAB=../../lab.sh

bash $LAB run le-x8mbsf28 <<'S'
version coupons.py 5
rm -f features/steps/coupons_steps.py
cp ~/.versions/features_coupons.feature@1 features/coupons.feature
block undefined
on 'behave'

cp ~/.versions/features_steps_coupons_steps.py@1 features/steps/coupons_steps.py
block defined
on 'behave'

cp ~/.versions/features_coupons.feature@2 features/coupons.feature
block three
on 'behave'

cp ~/.versions/features_coupons.feature@3 features/coupons.feature
block estreia-red
on 'behave'

version coupons.py 6
block estreia-green
on 'behave'
S
