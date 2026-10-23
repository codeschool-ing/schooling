"""The composition gate: pip-audit's JSON on stdin, ci/exceptions.txt beside
it, and one verdict as the exit status.

    1  an advisory with a fixed version, and no exception in force for it
    3  a warning: an advisory nobody can fix yet, or an exception that
       expires within a week
    0  nothing to report
"""
import datetime
import json
import sys
from pathlib import Path

BREAK, WARN, PASS = 1, 3, 0


def judge(audit, exceptions, today):
    """The verdict and one line per advisory, for a pip-audit report."""
    until = {}
    for line in exceptions.splitlines():
        if line.strip() and not line.startswith("#"):
            advisory, day, _why = line.split(maxsplit=2)
            until[advisory] = datetime.date.fromisoformat(day)
    verdict, lines = PASS, []
    for dep in audit["dependencies"]:
        for vuln in dep.get("vulns", []):
            what = f"{dep['name']} {dep['version']} {vuln['id']}"
            if any(what in line for line in lines):
                continue
            day = until.get(vuln["id"])
            if day is not None and day >= today:
                lines.append(f"excepted until {day}: {what}")
                if (day - today).days < 7 and verdict == PASS:
                    verdict = WARN
            elif vuln["fix_versions"]:
                lines.append(f"BREAKS: {what}, fixed in {', '.join(vuln['fix_versions'])}")
                verdict = BREAK
            else:
                lines.append(f"warns: {what}, no fixed version yet")
                if verdict == PASS:
                    verdict = WARN
    return verdict, lines


if __name__ == "__main__":
    verdict, lines = judge(json.load(sys.stdin), Path("ci/exceptions.txt").read_text(),
                           datetime.date.today())
    print("\n".join(lines) or "no advisories")
    sys.exit(verdict)
