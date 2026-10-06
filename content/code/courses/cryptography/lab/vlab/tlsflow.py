"""Reads the output of `openssl s_client -trace` and prints the handshake as
a list of messages, with the fields a lesson talks about and none of the
random bytes, which differ on every connection. The trace itself is the
evidence; this is a way of reading it."""
import re
import sys


def flow(lines):
    out, direction, encrypted = [], None, False
    msg = None
    pending_versions, in_versions = [], False
    for raw in lines:
        line = raw.rstrip("\n")
        if line.startswith("Sent Record"):
            direction, msg = "client -> server", None
            continue
        if line.startswith("Received Record"):
            direction, msg = "server -> client", None
            continue
        m = re.match(r"  Content Type = (\w+)", line)
        if m and m.group(1) == "ChangeCipherSpec":
            out.append(f"{direction}  ChangeCipherSpec")
            continue
        if line.startswith("  Inner Content Type") and not encrypted:
            encrypted = True
            out.append("---- everything below is encrypted with the handshake keys ----")
        m = re.match(r"  Inner Content Type = (\w+)", line)
        if m and m.group(1) == "ApplicationData":
            out.append(f"{direction}  application data (encrypted)")
            continue
        m = re.match(r"    ([A-Z][A-Za-z]+), Length=\d+", line)
        if m:
            msg = m.group(1)
            out.append(f"{direction}  {msg}")
            in_versions = False
            continue
        if msg is None:
            m = re.match(r"\s+Level=(\w+)\(\d+\), description=(.+)\(\d+\)", line)
            if m:
                out.append(f"{direction}  Alert: {m.group(1)}, {m.group(2)}")
            continue
        s = line.strip()
        if msg == "ClientHello":
            if "extension_type=server_name" in s:
                out.append("    server_name: (see below)")
            if s.startswith("extension_type=supported_versions"):
                in_versions = True
                continue
            if in_versions:
                m = re.match(r"(TLS \d\.\d)", s)
                if m:
                    pending_versions.append(m.group(1))
                    continue
                out.append("    offers versions: " + ", ".join(pending_versions))
                pending_versions, in_versions = [], False
            m = re.match(r"NamedGroup: (\S+)", s)
            if m:
                out.append(f"    key_share: {m.group(1)}")
            m = re.match(r"cipher_suites \(len=(\d+)\)", s)
            if m:
                out.append(f"    offers {int(m.group(1)) // 2} cipher suites")
        elif msg == "ServerHello":
            m = re.match(r"cipher_suite \{.*\} (\S+)", s)
            if m:
                out.append(f"    chosen cipher suite: {m.group(1)}")
            m = re.match(r"(TLS \d\.\d) \(\d+\)", s)
            if m:
                out.append(f"    chosen version: {m.group(1)}")
            m = re.match(r"NamedGroup: (\S+)", s)
            if m:
                out.append(f"    key_share: {m.group(1)}")
        elif msg == "Certificate":
            m = re.match(r"Subject: (.*)", s)
            if m:
                out.append(f"    certificate: {m.group(1).split('CN = ')[-1]}")
        elif msg == "CertificateVerify":
            m = re.match(r"Signature Algorithm: (\S+)", s)
            if m:
                out.append(f"    signed with: {m.group(1)}")
    # the server name sits in a hex dump; take it from the dump's text column
    text = "".join(lines)
    for i, l in enumerate(out):
        if l.endswith("(see below)"):
            m = re.search(r"server_name\(0\)[^\n]*\n((?:\s+[0-9a-f]{4} - .*\n)+)", text)
            name = ""
            if m and m.group(1):
                name = "".join(row.split("   ")[-1].strip() for row in m.group(1).splitlines())
                name = re.sub(r"^\.+", "", name)
            out[i] = f"    server_name: {name}"
    for l in lines:
        s = l.strip()
        if s.startswith("verify error:"):
            out.append("client: " + s)
        if s.startswith("New, ") or s.startswith("Verify return code") or s.startswith("Verification error"):
            out.append("result: " + s)
    return out


def main():
    print("\n".join(flow(sys.stdin.readlines())))
