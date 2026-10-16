#!/usr/bin/env python3
"""Make a notebook out of a section's `py` fences and run its cells in the order a person did.

THE STUDENT NEVER SEES THIS FILE. Lesson 2 is about notebooks run out of order, and a capture of
one has to have been run out of order for real: this writes the cells, starts a kernel, runs them
in ORDER (zero-based positions, a position may repeat), and saves the outputs and execution counts
each cell was left with, which is exactly what JupyterLab saves.

    order.py SECTION.md NOTEBOOK.ipynb 0 2 1
    order.py --keep NOTEBOOK.ipynb 2 2      run cells of a saved notebook again, in a new kernel,
                                            as a person who reopened it and ran those cells would

The kernel's own `language_info` is written into the metadata, as JupyterLab writes it.
"""
import re
import sys

import nbformat
from jupyter_client.manager import KernelManager


def main():
    if sys.argv[1] == "--keep":
        path, order = sys.argv[2], [int(i) for i in sys.argv[3:]]
        nb = nbformat.read(path, as_version=4)
    else:
        md, path, order = sys.argv[1], sys.argv[2], [int(i) for i in sys.argv[3:]]
        text = open(md, encoding="utf-8").read()
        sources = [c.rstrip("\n") for c in re.findall(r"^```py\n(.*?)^```$", text, re.S | re.M)]
        nb = nbformat.v4.new_notebook()
        nb.metadata["kernelspec"] = {"display_name": "Python 3 (ipykernel)",
                                     "language": "python", "name": "python3"}
        nb.cells = [nbformat.v4.new_code_cell(s) for s in sources]
    km = KernelManager(kernel_name="python3", transport="ipc")
    km.start_kernel()
    kc = km.client()
    kc.start_channels()
    kc.wait_for_ready(timeout=60)
    nb.metadata["language_info"] = kc.kernel_info(reply=True)["content"]["language_info"]
    try:
        for i in order:
            cell = nb.cells[i]
            cell.outputs = []
            msg_id = kc.execute(cell.source)
            while True:
                msg = kc.get_iopub_msg(timeout=120)
                if msg["parent_header"].get("msg_id") != msg_id:
                    continue
                kind, content = msg["msg_type"], msg["content"]
                if kind == "execute_input":
                    cell.execution_count = content["execution_count"]
                elif kind in ("stream", "execute_result", "display_data", "error"):
                    cell.outputs.append(nbformat.v4.output_from_msg(msg))
                elif kind == "status" and content["execution_state"] == "idle":
                    break
            kc.get_shell_msg(timeout=60)
    finally:
        kc.stop_channels()
        km.shutdown_kernel(now=True)
    nbformat.write(nb, path)


main()
