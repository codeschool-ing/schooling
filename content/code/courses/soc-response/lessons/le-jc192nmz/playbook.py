# playbook.py DB ADDRESS [--approve NAME]
# For the alert "login accepted from an address that tried many accounts":
# gather the facts, propose what to do, and act only when a named person approves.
import ipaddress, json, sqlite3, subprocess, sys, datetime as dt

NEVER_BLOCK = {"203.0.113.11", "203.0.113.17", "203.0.113.23", "203.0.113.31",
               "203.0.113.41",                  # staff, working from home
               "203.0.113.150"}                 # the backup provider
OURS = [ipaddress.ip_network(n) for n in ("198.51.100.0/24", "192.168.20.0/24", "192.168.99.0/24")]
db_path, address = sys.argv[1], sys.argv[2]
approver = sys.argv[sys.argv.index("--approve") + 1] if "--approve" in sys.argv else None

# 1. enrich: what else did this address do this week?
db = sqlite3.connect(db_path)
failures, accounts = db.execute(
    "SELECT count(*), count(DISTINCT user) FROM logs WHERE src_ip = ? AND action = 'failure'",
    (address,)).fetchone()
logins = db.execute(
    "SELECT timestamp, host, user, method FROM logs WHERE src_ip = ? AND action = 'success'",
    (address,)).fetchall()
print(f"{address}: {failures} failed logins over {accounts} accounts, {len(logins)} accepted")
for when, host, user, method in logins:
    print(f"  accepted {when} UTC on {host}: {user} by {method}")

# 2. guard: some addresses are never blocked by a machine, whatever the alert says
reasons = []
if address in NEVER_BLOCK:
    reasons.append("on the never-block list")
if any(ipaddress.ip_address(address) in net for net in OURS):
    reasons.append("one of the company's own addresses")

# 3. propose
actions = [] if reasons else [f"block {address} at fw"]
for user, host in sorted({(user, host) for _, host, user, _ in logins}):
    actions.append(f"disable {user} on {host} and reset the password (a person does this)")
ticket = {"opened": dt.datetime.now(dt.timezone.utc).isoformat(timespec="seconds"),
          "alert": "login accepted after many accounts tried", "address": address,
          "failures": failures, "accounts_tried": accounts,
          "accepted": [list(row) for row in logins], "not_automated": reasons,
          "proposed": actions, "approved_by": approver}
for a in actions:
    print("  proposed:", a)
for r in reasons:
    print(f"  refused to block: {address} is {r}")

# 4. act, only what was approved and only what a machine may do
if approver and not reasons:
    subprocess.run(["ip", "netns", "exec", "fw", "nft", "insert", "rule", "ip", "fw", "forward",
                    "ip", "saddr", address, "drop", "comment", f'"playbook, approved by {approver}"'],
                   check=True)
    print(f"  done: {address} blocked at fw, approved by {approver}")
with open(f"ticket-{address}.json", "w") as f:
    json.dump(ticket, f, indent=2)
print(f"  ticket written: ticket-{address}.json")
