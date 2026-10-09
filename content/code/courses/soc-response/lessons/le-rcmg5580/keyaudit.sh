#!/usr/bin/env bash
# keyaudit.sh INVENTORY: every key that can log in to this machine, checked against the inventory
inv=${1:?usage: keyaudit.sh INVENTORY}
for f in /root/.ssh/authorized_keys /home/*/.ssh/authorized_keys; do
  [ -f "$f" ] || continue
  ssh-keygen -lf "$f" | while read -r bits fp comment; do
    if grep -qF "$fp" "$inv"; then verdict=approved; else verdict="NOT IN INVENTORY"; fi
    printf '%s  %s  %s\n' "$f" "$fp" "$verdict"
  done
done
