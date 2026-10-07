"""screen: what a terminal SHOWED, from what a program wrote to it.

`ollama pull` and `ollama run` draw: a spinner, progress bars redrawn in place
by moving the cursor up and clearing lines, an answer printed a word at a time.
Pasted raw, that is escape codes; so the bytes are replayed here on a grid of
lines, and what is left at the end is the transcript, as the student's screen
shows it.

Only what those programs use is understood: carriage return, line feed, the
cursor up (ESC[nA), left and right (ESC[nD, ESC[nC) and to a column (ESC[nG),
and clearing (ESC[K, ESC[2K). Any other escape sequence changes nothing on the
screen and is dropped. A line is never
wrapped here: the programs wrap their own text to the width they were given
(`stty cols 100`), and a terminal emulator that wrapped too would get the
cursor-up counts wrong, which is what the first version of this file did.

    script -qfec 'stty cols 100; ollama pull …' /dev/null | python screen.py
"""
import re
import sys

TOKEN = re.compile(r"\x1b\[([?0-9;]*)([A-Za-z])|\x1b[()][0-9A-B]|\x1b.|\r|\n|[^\x1b\r\n]+", re.S)

data = sys.stdin.buffer.read().decode("utf-8", "replace")
lines, row, col = [""], 0, 0


def put(text):
    global col
    line = lines[row]
    if len(line) < col:
        line += " " * (col - len(line))
    lines[row] = line[:col] + text + line[col + len(text):]
    col += len(text)


for m in TOKEN.finditer(data):
    tok = m.group(0)
    if tok == "\r":
        col = 0
    elif tok == "\n":
        row += 1
        if row == len(lines):
            lines.append("")
    elif m.group(2):
        arg, cmd = m.group(1), m.group(2)
        n = int(arg) if arg.isdigit() else 1
        if cmd == "A":
            row = max(0, row - n)
        elif cmd == "G":
            col = n - 1
        elif cmd == "D":
            col = max(0, col - n)
        elif cmd == "C":
            col += n
        elif cmd == "K":
            if arg in ("", "0"):
                lines[row] = lines[row][:col]
            elif arg == "2":
                lines[row] = ""
    elif not tok.startswith("\x1b"):
        put(tok)

out = [line.rstrip() for line in lines]
while out and not out[-1]:
    out.pop()
print("\n".join(out))
