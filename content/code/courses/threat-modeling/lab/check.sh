#!/bin/sh
# What CI runs on every change to the model. Any failure stops the merge.
set -e
python3 model.py --json model.json
python3 check_model.py "$@"
