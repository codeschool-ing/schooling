"""Reads the debug output of `eapol_test` and prints what a lesson talks
about: the identity sent in clear, the method, the certificate the server
presented and whether it was accepted, what crossed inside the tunnel, and
the result. The keys and nonces, which differ on every run, are left out;
the debug output itself is the evidence, and this is a way of reading it."""
import re
import sys


def summary(lines):
    out, seen = [], set()

    def put(label, text):
        if text in seen:
            return
        seen.add(text)
        out.append(f"{label:27}{text}" if label else f"{'':27}{text}")

    attribute, certs = None, 0
    for raw in lines:
        line = raw.rstrip("\n")
        m = re.match(r"\s+Value: '(.+)'$", line)
        if m and attribute == "User-Name":
            put("outer identity, in clear:", m.group(1))
        m = re.match(r"\s+Attribute \d+ \(([\w-]+)\)", line)
        if m:
            attribute = m.group(1)
        m = re.search(r"CTRL-EVENT-EAP-METHOD EAP vendor 0 method \d+ \((\w+)\) selected", line)
        if m:
            put("method:", m.group(1))
        m = re.match(r"SSL: Using TLS version (\S+)", line)
        if m:
            put("TLS version:", m.group(1))
        m = re.search(r"CTRL-EVENT-EAP-PEER-CERT depth=(\d) subject='([^']+)'", line)
        if m:
            put("" if certs else "server certificate:", f"depth {m.group(1)}  {m.group(2)}")
            certs += 1
        m = re.search(r"CTRL-EVENT-EAP-PEER-ALT depth=(\d) (\S+)", line)
        if m:
            put("", f"depth {m.group(1)}  name {m.group(2)}")
        m = re.search(r"CTRL-EVENT-EAP-TLS-CERT-ERROR reason=\d+ depth=(\d) .* err='([^']+)'", line)
        if m:
            put("certificate REFUSED:", f"depth {m.group(1)}, {m.group(2)}")
        m = re.search(r"EAP: Status notification: local TLS alert \(param=(.+)\)", line)
        if m:
            put("", f"alert sent to the server: {m.group(1)}")
        if "EAP-PEAP: Phase 2 Request: type=1" in line:
            put("inside the tunnel:", "inner identity sent")
        if "EAP-MSCHAPV2: Generating Challenge Response" in line:
            put("", "MSCHAPv2 challenge answered")
        if "EAP-MSCHAPV2: Authentication succeeded" in line:
            put("", "MSCHAPv2: the server proved it knows the password")
        if line.startswith("PMK from EAPOL"):
            put("PMK:", "32 bytes, made by this session (not shown)")
        if line in ("SUCCESS", "FAILURE"):
            put("result:", line)
    return out


def main():
    for line in summary(sys.stdin):
        print(line)
