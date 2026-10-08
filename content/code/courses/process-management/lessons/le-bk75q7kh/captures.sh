#!/usr/bin/env bash
# Reproduces every terminal transcript in lesson 4 (Extreme Programming), the
# test-driven development cycle in its third section.
#
# Run from anywhere: bash captures.sh
#
# What is staged rather than typed: the files. Each step below writes
# test_estimate.py or estimate.py with a heredoc, exactly as the lesson shows
# them, and then runs the test the way the lesson's reader would type it. The
# directory is /tmp/estimate, emptied first, so nothing from a previous run
# leaks in and the paths in the tracebacks are the same on every run.
#
# Last run with Python 3.13.16 on Linux. The timings unittest prints ("Ran 1
# test in 0.000s") are whatever that machine measured.
set -u
work=/tmp/estimate
rm -rf "$work" && mkdir -p "$work"
cd "$work" || exit 1
show() { printf '$ %s\n' "$*"; "$@" 2>&1; echo; }

echo '=== step 1: the test, before any code'
cat > test_estimate.py <<'PY'
import unittest

from estimate import pert


class PertTest(unittest.TestCase):
    def test_weights_the_most_likely_four_times(self):
        self.assertEqual(pert(3, 5, 13), 6.0)


if __name__ == "__main__":
    unittest.main()
PY
show python3 -m unittest test_estimate

echo '=== step 2: just enough code'
cat > estimate.py <<'PY'
def pert(optimistic, likely, pessimistic):
    return (optimistic + 4 * likely + pessimistic) / 6
PY
show python3 -m unittest test_estimate

echo '=== step 3: a second test, for the case nobody asked about'
cat > test_estimate.py <<'PY'
import unittest

from estimate import pert


class PertTest(unittest.TestCase):
    def test_weights_the_most_likely_four_times(self):
        self.assertEqual(pert(3, 5, 13), 6.0)

    def test_refuses_an_optimistic_above_the_pessimistic(self):
        with self.assertRaises(ValueError):
            pert(13, 5, 3)


if __name__ == "__main__":
    unittest.main()
PY
show python3 -m unittest test_estimate

echo '=== step 4: the code that makes it pass'
cat > estimate.py <<'PY'
def pert(optimistic, likely, pessimistic):
    if not optimistic <= likely <= pessimistic:
        raise ValueError("expected optimistic <= likely <= pessimistic")
    return (optimistic + 4 * likely + pessimistic) / 6
PY
show python3 -m unittest -v test_estimate

rm -rf "$work"
