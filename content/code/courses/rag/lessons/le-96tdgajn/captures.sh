#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of rag, as a script that produces
# them. THE AUTHOR'S, NOT THE STUDENT'S: the lesson shows every command and
# every program, and nothing here names a file the student does not have.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# Every program comes out of the lessons through lab/shown.py. Every vector is
# all-minilm (Ollama tag 1b226e2802db) served by Ollama 0.40.0; this lesson
# calls no generator.
#
# Recorded on Ubuntu 24.04, Python 3.12, TZ=America/Sao_Paulo, on 2026-10-08.
. "$(dirname "${LAB_SH:-../../lab.sh}")/lab/capture.sh"
L=le-96tdgajn
lab reset $L >/dev/null
use vectors.py chunking.py truncation.py boundaries.py structure.py boundaries_semantic.py compare.py small_to_big.py

block truncation
on 'python truncation.py'
block fixed
on 'python boundaries.py 60 0'
block overlap
on 'python boundaries.py 60 15'
block structure
on 'python structure.py'
block semantic
on 'python boundaries_semantic.py'
block compare
on 'python compare.py'
block small
on 'python small_to_big.py'
