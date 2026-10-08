# load.py: read the week's three files into one table, every field named the same way
import csv, re, sqlite3, datetime as dt

SP = dt.timezone(dt.timedelta(hours=-3))
db = sqlite3.connect("siem.db")
db.execute("DROP TABLE IF EXISTS logs")
db.execute("""CREATE TABLE logs (timestamp TEXT, host TEXT, product TEXT, action TEXT,
              detail TEXT, user TEXT, method TEXT, src_ip TEXT, dst_ip TEXT,
              dst_port INTEGER, bytes INTEGER, raw TEXT)""")


def utc(when):
    return when.astimezone(dt.timezone.utc).strftime("%Y-%m-%d %H:%M:%S")


SSH = re.compile(r"(?P<ts>\S+) (?P<host>\S+) sshd: (?:Accepted (?P<method>\S+) for (?P<ok>\S+)"
                 r"|Failed password for (?P<bad>\S+)|Invalid user (?P<unknown>\S+)) from (?P<src>\S+)")
rows = []
for line in open("auth.log"):
    m = SSH.match(line)
    if not m:
        continue
    when = dt.datetime.strptime(m["ts"], "%Y-%m-%dT%H:%M:%S%z")
    action = "success" if m["ok"] else "failure"
    detail = "unknown_user" if m["unknown"] else ("wrong_password" if m["bad"] else None)
    user = m["ok"] or m["bad"] or m["unknown"]
    rows.append((utc(when), m["host"], "sshd", action, detail, user, m["method"],
                 m["src"], None, 22, None, line.strip()))

for line in open("fw.log"):
    # the firewall writes no year and no zone: both are assumed here, out loud
    when = dt.datetime.strptime("2026 " + line[:15], "%Y %b %d %H:%M:%S").replace(tzinfo=SP)
    f = dict(p.split("=", 1) for p in line.split() if "=" in p)
    rows.append((utc(when), "fw", "firewall", "connection", None, None, None,
                 f["SRC"], f["DST"], int(f["DPT"]), None, line.strip()))

for r in csv.DictReader(open("flows.csv")):
    when = dt.datetime.strptime(r["start"], "%Y-%m-%d %H:%M:%S").replace(tzinfo=SP)
    rows.append((utc(when), "fw", "flow", "flow", None, None, None,
                 r["src"], r["dst"], int(r["dport"]), int(r["bytes"]), ",".join(r.values())))

db.executemany("INSERT INTO logs VALUES (?,?,?,?,?,?,?,?,?,?,?,?)", rows)
db.commit()
print(len(rows), "rows in siem.db")
