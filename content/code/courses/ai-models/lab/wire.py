#!/opt/aimodels/bin/python
"""wire: what the last request to standin looked like on the wire.

standin writes one JSON line per request it receives to
/var/log/standin/requests.jsonl: the method, the path, the headers (keys cut
short) and the body, exactly as the SDK sent them. This prints the last one,
or the last N, so a lesson can show what an SDK call turns into.

    wire                 the last request: method, path, headers, body
    wire --headers H,H   only these headers
    wire --body          only the body
    wire --count N       the last N, one summary line each
"""
import argparse
import json

LOG = "/var/log/standin/requests.jsonl"
SKIP = {"host", "content-length", "connection", "accept-encoding"}


def main():
    p = argparse.ArgumentParser(prog="wire")
    p.add_argument("--headers", default="")
    p.add_argument("--body", action="store_true")
    p.add_argument("--count", type=int, default=0)
    a = p.parse_args()
    rows = [json.loads(line) for line in open(LOG)]
    if a.count:
        for r in rows[-a.count:]:
            extra = f" routed={r['routed']}" if "routed" in r else ""
            print(f"{r['method']} {r['path']} -> {r.get('status')} {r.get('provider')} {r.get('model', '')}{extra}")
        return
    r = rows[-1]
    if not a.body:
        print(f"{r['method']} {r['path']}")
        wanted = [h.strip().lower() for h in a.headers.split(",") if h.strip()]
        for k, v in r["headers"].items():
            if (k in wanted) if wanted else (k not in SKIP):
                print(f"{k}: {v}")
        print()
    print(json.dumps(r.get("request", {}), indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
