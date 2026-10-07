#!/bin/bash
# chain.sh FILE: one hash per line, each one covering every line before it
prev=$(printf 'start' | sha256sum | cut -c1-16)
while IFS= read -r line; do
  prev=$(printf '%s%s' "$prev" "$line" | sha256sum | cut -c1-16)
  printf '%s  ...%s\n' "$prev" "${line: -44}"
done < "$1"
