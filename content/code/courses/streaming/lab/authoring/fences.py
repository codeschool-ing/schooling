"""Line-based fence scanning shared by the authoring tools."""
def split(text):
    """Yield ('text', str) and ('fence', info, body) pieces, in order; joining them gives text back."""
    lines = text.split("\n")
    out, buf, i = [], [], 0
    while i < len(lines):
        ln = lines[i]
        if ln.startswith("```"):
            info = ln[3:]
            j = i + 1
            while j < len(lines) and lines[j] != "```":
                j += 1
            if buf: out.append(("text", "\n".join(buf))); buf = []
            out.append(("fence", info, "\n".join(lines[i + 1:j])))
            i = j + 1
            continue
        buf.append(ln); i += 1
    out.append(("text", "\n".join(buf)))
    return out
def join(pieces):
    parts = []
    for p in pieces:
        parts.append(p[1] if p[0] == "text" else "```" + p[1] + "\n" + p[2] + "\n```")
    return "\n".join(parts)
