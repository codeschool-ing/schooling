"""What leaves Tarefa when a ticket is sent to the third-party model.

A purpose in purposes.json names the fields it needs. Everything else in the
ticket is dropped; the names it needs to talk ABOUT, but not to know, are
replaced by placeholders like <NAME_1>; and the free text is passed through
the same detectors as the logs (detect.py), with each match replaced by a
placeholder too. The placeholders and what they stand for go to vault/, which
never leaves the machine, so a reply that mentions <NAME_1> can be turned back
into one that says the client's name.

That makes the outbox PSEUDONYMISED and not anonymous: the vault reverses it.
Under the LGPD that is still personal data, for Tarefa at least.

THE SENSITIVE-DATA CHECK IS A WORD LIST, below, and it is as crude as that
sounds. It exists to stop the obvious case and to make somebody decide; it
does not understand a sentence, and it misses anything said in other words.
"""
import json
import re

from . import detect

SENSITIVE = {
    "health": ["hospital", "infection", "diagnos", "surgery", "pregnan",
               "depress", "medication", "therapy", "cancer", "hiv"],
    "religion": ["church", "mosque", "synagogue", "terreiro", "religio"],
    "union": ["trade union", "sindicato"],
}
SENTENCE = re.compile(r"[^.!?]+[.!?]?\s*")


def get(obj, path):
    for part in path.split("."):
        obj = obj[part]
    return obj


def put(obj, path, value):
    parts = path.split(".")
    for part in parts[:-1]:
        obj = obj.setdefault(part, {})
    obj[parts[-1]] = value


def leaves(obj, prefix=""):
    """Every scalar field as a dotted path, so a dropped field can be named."""
    if isinstance(obj, dict):
        for k, v in obj.items():
            yield from leaves(v, prefix + k + ".")
    else:
        yield prefix[:-1]


class Vault:
    def __init__(self):
        self.by_value, self.by_token, self.count = {}, {}, {}

    def token(self, kind, value):
        if value not in self.by_value:
            n = self.count[kind] = self.count.get(kind, 0) + 1
            tok = "<%s_%d>" % (kind.upper(), n)
            self.by_value[value] = tok
            self.by_token[tok] = value
        return self.by_value[value]


def sensitive_terms(text):
    low = text.lower()
    return {cat: [w for w in words if w in low]
            for cat, words in SENSITIVE.items() if any(w in low for w in words)}


def minimise(ticket, purpose, remove_sensitive):
    """Returns (outbox, vault, report). report is a list of (label, text)
    lines; outbox is None when sensitive data stopped it."""
    vault = Vault()
    out, report = {}, []
    needs, renames = purpose["needs"], purpose.get("pseudonymise", [])
    kept = [p for p in needs]
    dropped = [p for p in leaves(ticket)
               if not any(p == n or p.startswith(n + ".") for n in needs + renames)]
    for p in needs:
        put(out, p, json.loads(json.dumps(get(ticket, p))))
    names = {}
    for p in renames:
        value = get(ticket, p)
        names[value] = vault.token("name", value)
        put(out, p, names[value])
    report.append(("kept", ", ".join(kept)))
    report.append(("dropped", ", ".join(dropped)))
    report.append(("renamed", ", ".join("%s -> %s" % (p, vault.by_value[get(ticket, p)])
                                         for p in renames)))

    replaced, held = {}, []
    for i, msg in enumerate(out.get("messages", [])):
        text = msg["text"]
        for value, tok in names.items():
            for part in {value, value.split()[0]}:
                if part in text:
                    replaced[tok] = replaced.get(tok, 0) + text.count(part)
                    text = text.replace(part, tok)
        pieces, at = [], 0
        for kind, a, b, ok in detect.find(text):
            if not ok:
                continue
            tok = vault.token(kind, text[a:b])
            replaced[tok] = replaced.get(tok, 0) + 1
            pieces += [text[at:a], tok]
            at = b
        text = "".join(pieces) + text[at:]
        found = sensitive_terms(text)
        if found:
            where = "messages[%d]" % i
            what = "; ".join("%s (%s)" % (c, ", ".join(w)) for c, w in found.items())
            if remove_sensitive:
                kept_sentences, gone = [], 0
                for s in SENTENCE.findall(text):
                    cats = sensitive_terms(s)
                    if cats:
                        gone += 1
                        tail = " " if s.endswith(" ") else ""
                        kept_sentences.append(
                            "[removed: a %s matter]%s" % (" and ".join(cats), tail))
                    else:
                        kept_sentences.append(s)
                text = "".join(kept_sentences)
                report.append(("sensitive", "%s: %s  removed %d sentence(s)" % (where, what, gone)))
            else:
                report.append(("sensitive", "%s: %s  HOLD" % (where, what)))
                held.append(where)
        msg["text"] = text
    report.append(("in text", ", ".join("%s x%d" % (t, n) for t, n in replaced.items())))
    if held:
        return None, vault, report
    return out, vault, report


def restore(text, vault):
    """The reply with every placeholder put back, and the placeholders the
    vault has never heard of: a model can invent <NAME_3>, and putting
    nothing there silently would hide that it did."""
    unknown = []

    def back(m):
        if m.group(0) in vault:
            return vault[m.group(0)]
        unknown.append(m.group(0))
        return m.group(0)
    return re.sub(r"<[A-Z]+_\d+>", back, text), unknown
