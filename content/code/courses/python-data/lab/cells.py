#!/usr/bin/env python3
"""Run a lesson's notebook cells in a real Jupyter kernel, and hold its prose to what they print.

THE STUDENT NEVER SEES THIS FILE. It is how every cell output in python-data was recorded.

A lesson of this course is a notebook written as prose. Its cells are the fences labelled
`python` in the lesson's sections, in the order `lesson.json` gives the sections and the order
each file gives its fences, and its outputs are the unlabelled fences that follow a cell with
nothing but blank lines between them. A `schooling-example` whose language is `python` is a
cell too: its parts joined are the code, and its `output` is what the cell printed.

    cells.py run LESSON_DIR RESULT.json     as the lab's user, in the project directory: start a
                                            kernel from the project's environment, run every
                                            cell in order, write what each one printed
    cells.py apply LESSON_DIR RESULT.json   compare; exit 1 on the first difference
    cells.py apply --write LESSON_DIR RESULT.json
                                            write the outputs into the .md AND the .pt.md, whose
                                            fences are the English ones byte for byte

What a cell PRINTS, as recorded here, is the text a notebook keeps for it: what went to stdout
and stderr, the `text/plain` of the value of its last line, and, for an error, the last line of
the traceback, `ValueError: …`, which is the line a reader acts on. A chart is not text: it is
saved beside the result and the cell carries no output fence.

A fence labelled `py` is shown and never run — a file's contents, a line written to be wrong.
`py` is an alias the highlighter knows, so the reader sees the same colours either way.

A cell with no output fence after it must print nothing; one that does fails `apply`, because a
lesson that shows code and hides what it printed is a lesson with a gap in it.

Timings are the one thing that cannot repeat byte for byte. A cell whose code contains `timeit`
or `perf_counter` is compared with its digits masked, and `--write` leaves its recorded text
alone when the mask agrees, so a rerun does not churn every number in the lesson.
"""
import json
import os
import re
import sys

FENCE = re.compile(r"^```([^\n]*)\n(.*?)^```[ \t]*$", re.S | re.M)
ANSI = re.compile(r"\x1b\[[0-9;]*m")
TIMED = re.compile(r"timeit|perf_counter")


def sections(lesson_dir):
    with open(os.path.join(lesson_dir, "lesson.json"), encoding="utf-8") as f:
        lesson = json.load(f)
    return [s["slug"] for s in lesson["sections"]]


def cells_of(text):
    """Every cell in a section: (code, output_or_None, span_of_output_body_or_None, kind)."""
    fences = list(FENCE.finditer(text))
    out = []
    for i, m in enumerate(fences):
        info = m.group(1).strip()
        if info == "python":
            nxt = fences[i + 1] if i + 1 < len(fences) else None
            if nxt and nxt.group(1).strip() == "" and text[m.end():nxt.start()].strip() == "":
                out.append((m.group(2), nxt.group(2), nxt.span(2), "fence"))
            else:
                out.append((m.group(2), None, None, "fence"))
        elif info == "schooling-example":
            block = json.loads(m.group(2))
            if block.get("language") != "python":
                continue
            code = "".join(p["code"] for p in block["parts"])
            output = block.get("output")
            out.append((code, None if output is None else output, m.span(2), "example"))
    return out


def lesson_cells(lesson_dir):
    for slug in sections(lesson_dir):
        path = os.path.join(lesson_dir, slug + ".md")
        if not os.path.exists(path):
            continue
        with open(path, encoding="utf-8") as f:
            text = f.read()
        for n, cell in enumerate(cells_of(text)):
            yield slug, n, cell


def run(lesson_dir, result_path):
    from jupyter_client.manager import KernelManager

    figures = os.path.splitext(result_path)[0] + "-figures"
    os.makedirs(figures, exist_ok=True)
    km = KernelManager(kernel_name="python3", transport="ipc")
    km.start_kernel(cwd=os.getcwd())
    kc = km.client()
    kc.start_channels()
    kc.wait_for_ready(timeout=60)
    results = []
    try:
        for slug, n, (code, _, _, _) in lesson_cells(lesson_dir):
            msg_id = kc.execute(code)
            printed, pictures = [], 0
            while True:
                msg = kc.get_iopub_msg(timeout=600)
                if msg["parent_header"].get("msg_id") != msg_id:
                    continue
                kind, content = msg["msg_type"], msg["content"]
                if kind == "stream":
                    printed.append(content["text"])
                elif kind in ("execute_result", "display_data"):
                    data = content["data"]
                    if "image/svg+xml" in data or "image/png" in data:
                        pictures += 1
                        name = f"{slug}-{n}-{pictures}"
                        if "image/svg+xml" in data:
                            with open(os.path.join(figures, name + ".svg"), "w") as f:
                                f.write(data["image/svg+xml"])
                        else:
                            import base64
                            with open(os.path.join(figures, name + ".png"), "wb") as f:
                                f.write(base64.b64decode(data["image/png"]))
                    elif "text/plain" in data:
                        printed.append(data["text/plain"] + "\n")
                elif kind == "error":
                    printed.append(f"{content['ename']}: {ANSI.sub('', content['evalue'])}\n")
                elif kind == "status" and content["execution_state"] == "idle":
                    break
            kc.get_shell_msg(timeout=60)
            results.append({"section": slug, "cell": n, "printed": "".join(printed),
                             "pictures": pictures})
    finally:
        kc.stop_channels()
        km.shutdown_kernel(now=True)
    with open(result_path, "w", encoding="utf-8") as f:
        json.dump(results, f, ensure_ascii=False, indent=1)


def masked(s):
    return re.sub(r"\d+", "0", s)


def apply(lesson_dir, result_path, write):
    with open(result_path, encoding="utf-8") as f:
        results = {(r["section"], r["cell"]): r for r in json.load(f)}
    failed = 0
    edits = {}
    for slug, n, (code, shown, span, kind) in lesson_cells(lesson_dir):
        got = results[(slug, n)]["printed"]
        if results[(slug, n)]["pictures"] and not got.strip():
            got = ""
        want = shown if shown is not None else ""
        if got == want:
            continue
        if TIMED.search(code) and masked(got) == masked(want):
            continue
        if shown is None and kind == "fence":
            failed += 1
            print(f"{slug}.md cell {n}: printed something and the lesson shows no output\n{got}")
            continue
        if write:
            edits.setdefault(slug, []).append((span, kind, got))
        else:
            failed += 1
            print(f"{slug}.md cell {n}: the lesson shows\n{want}\n--- and the kernel printed\n{got}")
    for slug, changes in edits.items():
        with open(os.path.join(lesson_dir, slug + ".md"), encoding="utf-8") as f:
            english = cells_of(f.read())
        # The spans were measured in the English file; a translation has the same fences but
        # not the same prose, so each file's spans are found again by the same walk, and a
        # change is carried across by the cell's position among the cells.
        index = {cell[2]: i for i, cell in enumerate(english)}
        for suffix in (".md", ".pt.md"):
            path = os.path.join(lesson_dir, slug + suffix)
            if not os.path.exists(path):
                continue
            with open(path, encoding="utf-8") as f:
                text = f.read()
            spans = [cell[2] for cell in cells_of(text)]
            for span, kind, got in sorted(changes, key=lambda c: -c[0][0]):
                sp = spans[index[span]]
                if kind == "fence":
                    text = text[:sp[0]] + got + text[sp[1]:]
                else:
                    block = json.loads(text[sp[0]:sp[1]])
                    block["output"] = got
                    text = text[:sp[0]] + json.dumps(block, ensure_ascii=False, indent=2) + "\n" + text[sp[1]:]
            with open(path, "w", encoding="utf-8") as f:
                f.write(text)
            print(f"wrote {path}")
    return failed


if __name__ == "__main__":
    args = sys.argv[1:]
    if args[:1] == ["run"]:
        run(args[1], args[2])
    elif args[:1] == ["apply"]:
        write = "--write" in args
        args = [a for a in args if a != "--write"]
        sys.exit(1 if apply(args[1], args[2], write) else 0)
    else:
        sys.exit(__doc__)
