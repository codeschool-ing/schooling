"""What the lab recognises as personal data or a secret in free text.

Five detectors, each a pattern for the SHAPE and, where the thing has one, a
check for the ARITHMETIC: a CPF carries two check digits and a card number
carries a Luhn digit, so eleven digits that fail the check are probably an
order number and are left alone. --strict drops the arithmetic and redacts
every shape, which is the other side of the same trade: a CPF typed with one
digit wrong is still most of somebody's CPF.

What it does NOT recognise, on purpose, so nobody trusts it further than
this: a person's name, a street address, a date of birth, anything written
in words. A pattern finds what has a pattern.
"""
import re

EMAIL = re.compile(r"[A-Za-z0-9._%+-]+@[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)+")
CPF = re.compile(r"(?<!\d)\d{3}\.?\d{3}\.?\d{3}-?\d{2}(?!\d)")
CARD = re.compile(r"(?<!\d)\d(?:[ -]?\d){12,18}(?!\d)")
PHONE = re.compile(r"(?<![\d+])(?:\+55\s?)?\(?\d{2}\)?\s?9\d{4}-?\d{4}(?!\d)")
SECRET = re.compile(r"\b(?:sk-[A-Za-z0-9_-]{20,}|AKIA[0-9A-Z]{16})\b")


def digits(s):
    return [int(c) for c in s if c.isdigit()]


def cpf_ok(s):
    d = digits(s)
    if len(d) != 11 or len(set(d)) == 1:
        return False
    for n in (9, 10):
        total = sum(x * w for x, w in zip(d[:n], range(n + 1, 1, -1)))
        if (total * 10) % 11 % 10 != d[n]:
            return False
    return True


def luhn_ok(s):
    d = digits(s)
    total = 0
    for i, x in enumerate(reversed(d)):
        if i % 2:
            x *= 2
            if x > 9:
                x -= 9
        total += x
    return total % 10 == 0


# Order matters, because the shapes overlap: a phone with +55 in front has
# thirteen digits, which is a short card number, and a card number has eleven
# digits inside it that look like a CPF. Whatever is first claims its
# characters and the later rules do not look at them again. The phone goes
# before the card because its shape is the narrowest of the three.
RULES = [
    ("secret", SECRET, None),
    ("email", EMAIL, None),
    ("phone", PHONE, None),
    ("card", CARD, luhn_ok),
    ("cpf", CPF, cpf_ok),
]
KINDS = [name for name, _, _ in RULES]


def find(text, strict=False):
    """Every match as (kind, start, end, accepted), in the order of the text.

    accepted is False for a shape whose check digits are wrong. Those are
    reported, so a person can see what the arithmetic let through, and are
    redacted only under strict. A rejected shape that another rule then
    claims, a phone number that also looks like a short card, is that
    rule's and is not reported twice."""
    taken, rejected = [], []
    for kind, pattern, check in RULES:
        for m in pattern.finditer(text):
            a, b = m.span()
            if any(a < y and x < b for _, x, y, _ in taken):
                continue
            if strict or check is None or check(m.group()):
                taken.append((kind, a, b, True))
            else:
                rejected.append((kind, a, b, False))
    rejected = [r for r in rejected
                if not any(r[1] < y and x < r[2] for _, x, y, _ in taken)]
    return sorted(taken + rejected, key=lambda f: f[1])


def redact(text, strict=False):
    """The text with every accepted match replaced by [KIND]."""
    out, at = [], 0
    for kind, a, b, accepted in find(text, strict):
        if not accepted:
            continue
        out.append(text[at:a])
        out.append("[" + kind.upper() + "]")
        at = b
    out.append(text[at:])
    return "".join(out)
