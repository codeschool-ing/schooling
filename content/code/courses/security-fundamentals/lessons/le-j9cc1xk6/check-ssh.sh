#!/bin/bash
# Four lines of the shop's hardening checklist for the SSH server, checked
# against the settings sshd would really use, not against what the file says.
effective=$(sshd -T)

check() {
  actual=$(awk -v key="$1" '$1 == key { print $2 }' <<< "$effective")
  if [ "$actual" = "$2" ]; then
    echo "PASS  $1 $actual"
  else
    echo "FAIL  $1 $actual, expected $2"
  fi
}

check permitrootlogin no
check passwordauthentication no
check x11forwarding no
check maxauthtries 4
