#!/usr/bin/env python3
"""Check the auditor's request list: does each request name evidence, and is it in the repository?"""
import csv
import subprocess


def last_change(path):
    """The date and author of the last commit that touched path, or None if git has never seen it."""
    out = subprocess.run(["git", "log", "-1", "--format=%ad %an", "--date=short", "--", path],
                         capture_output=True, text=True, check=True).stdout.strip()
    return out or None


for row in csv.DictReader(open("pbc.csv")):
    if not row["evidence"]:
        status = "NOTHING NAMED"
    else:
        seen = last_change(row["evidence"])
        status = f"ok, {seen}" if seen else "MISSING"
    print(f"{row['id']}  {status:19}  {row['request']}")
