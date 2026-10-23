"""example.py: turn a file into a schooling-example, or translate one.

    python3 lab/example.py split FILE NOTES.json   -> prints the fence (EN)

The file is cut at its blank lines; NOTES.json is a list of [first-line-prefix,
note] pairs, and a part starts at each chunk whose first line starts with a
prefix. Each part except the last keeps the blank line after it, so that the
copy button, which joins the parts with a newline, gives back the file.
"""
import json
import sys


def split(path, notes):
    body = open(path).read().rstrip("\n")
    chunks = body.split("\n\n")
    parts = []
    for c in chunks:
        hit = [n for pre, n in notes if c.startswith(pre)]
        if hit or not parts:
            parts.append({"code": c, "note": hit[0] if hit else ""})
        else:
            parts[-1]["code"] += "\n\n" + c
    for p in parts[:-1]:
        p["code"] += "\n"
    for p in parts:
        if not p["note"]:
            del p["note"]
    return parts


if __name__ == "__main__":
    cmd, path, notes, lang, name = sys.argv[1:6]
    ex = {"language": lang, "file": name, "parts": split(path, json.load(open(notes)))}
    print("```schooling-example\n" + json.dumps(ex, ensure_ascii=False) + "\n```")
