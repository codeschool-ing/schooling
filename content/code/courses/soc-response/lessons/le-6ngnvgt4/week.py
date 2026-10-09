# week.py: one week of logs from the company in the lab, 14 to 20 September 2026.
# Ordinary days, plus one night somebody has to find. Same output on every run.
import random, datetime as dt

random.seed(7)
Z = dt.timezone(dt.timedelta(hours=-3))
STAFF = {"ana": "203.0.113.11", "bruno": "203.0.113.17", "carla": "203.0.113.23",
         "diego": "203.0.113.31", "helena": "203.0.113.41"}
KEYS = {"ana", "diego"}                      # who logs in with a key
GUESSES = ["root", "admin", "test", "oracle", "ubuntu", "user", "backup", "git"]
auth, fw, flows = [], [], []


def t(day, h, m, s=0):
    return dt.datetime(2026, 9, day, h, m, s, tzinfo=Z)


def port():
    return random.randint(32768, 60999)


def ssh(when, host, text):
    auth.append((when, f"{when:%Y-%m-%dT%H:%M:%S%z} {host} sshd: {text}"))


def conn(when, inn, out, src, dst, dport):
    fw.append((when, f"{when:%b %e %H:%M:%S} fw fw-new  IN={inn} OUT={out} "
                     f"SRC={src} DST={dst} PROTO=TCP SPT={port()} DPT={dport}"))


def flow(when, src, dst, dport, seconds, nbytes):
    flows.append((when, f"{when:%Y-%m-%d %H:%M:%S},{seconds},{src},{dst},{dport},{nbytes}"))


def attempt(when, src, name, known):
    conn(when, "eth0", "eth1", src, "198.51.100.22", 22)
    if known:
        ssh(when, "gw", f"Failed password for {name} from {src} port {port()} ssh2")
    else:
        ssh(when, "gw", f"Invalid user {name} from {src} port {port()}")


def login(when, user, src, how):
    conn(when, "eth0", "eth1", src, "198.51.100.22", 22)
    ssh(when, "gw", f"Accepted {how} for {user} from {src} port {port()} ssh2")


for day in range(14, 21):
    conn(t(day, 1, 0), "eth2", "eth0", "192.168.20.10", "203.0.113.150", 443)
    flow(t(day, 1, 0), "192.168.20.10", "203.0.113.150", 443,
         random.randint(500, 700), random.randint(330, 380) * 1_000_000)  # nightly backup
    for n in range(random.randint(4, 8)):              # strangers trying common names
        src = f"203.0.113.{random.randint(100, 199)}"
        when = t(day, random.randint(0, 23), random.randint(0, 59), random.randint(0, 59))
        for name in random.sample(GUESSES, random.randint(1, 3)):
            when += dt.timedelta(seconds=random.randint(2, 9))
            attempt(when, src, name, name == "root")
    if dt.date(2026, 9, day).weekday() < 5:            # staff start work from home
        for user, src in STAFF.items():
            when = t(day, 8, random.randint(0, 59), random.randint(0, 59))
            if user not in KEYS and random.random() < 0.15:   # a typo first
                attempt(when, src, user, True)
                when += dt.timedelta(seconds=random.randint(4, 12))
            login(when, user, src, "publickey" if user in KEYS else "password")
            if user == "diego":                         # IT: on to the file server
                when += dt.timedelta(minutes=random.randint(2, 20))
                conn(when, "eth1", "eth2", "198.51.100.22", "192.168.20.10", 22)
                ssh(when, "files", f"Accepted publickey for diego from 198.51.100.22 port {port()} ssh2")

# Thursday night
names = list(STAFF) + GUESSES + ["finance", "hr", "scanner", "printer", "support", "dev"]
when = t(17, 2, 10)
for _ in range(3):
    for name in names:
        when += dt.timedelta(seconds=random.randint(5, 9))
        attempt(when, "203.0.113.66", name, name in STAFF or name == "root")
login(t(17, 2, 33, 7), "bruno", "203.0.113.66", "password")
conn(t(17, 2, 35, 40), "eth1", "eth2", "198.51.100.22", "192.168.20.10", 22)
ssh(t(17, 2, 35, 40), "files", "Accepted password for bruno from 198.51.100.22 port 40112 ssh2")
conn(t(17, 2, 41, 12), "eth2", "eth0", "192.168.20.10", "203.0.113.200", 443)
flow(t(17, 2, 41, 12), "192.168.20.10", "203.0.113.200", 443, 1104, 612_408_119)
login(t(17, 3, 5, 22), "bruno", "203.0.113.66", "publickey")

for name, rows in (("auth.log", auth), ("fw.log", fw), ("flows.csv", flows)):
    with open(name, "w") as f:
        if name == "flows.csv":
            f.write("start,seconds,src,dst,dport,bytes\n")
        f.writelines(line + "\n" for _, line in sorted(rows))
