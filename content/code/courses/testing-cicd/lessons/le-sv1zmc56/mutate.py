"""Mutation testing by hand: change one thing, run the suite, see who notices.

Each mutation is a (file, old, new) replacement. The file is restored after
every run, whatever happened.
"""
import subprocess
import sys
from pathlib import Path

MUTATIONS = [
    ("shipquote/quote.py", "subtotal_cents >= FREE_FROM", "subtotal_cents > FREE_FROM"),
    ("shipquote/quote.py", "if weight_g <= 0:", "if weight_g < 0:"),
    ("shipquote/quote.py", "(weight_g - 1) // 500", "weight_g // 500"),
    ("shipquote/quote.py", "len(digits) != 8 or", "len(digits) != 8 and"),
    ("shipquote/quote.py", '"6": "N"', '"6": "NE"'),
    ("shipquote/store.py", "ORDER BY created_at DESC, id DESC", "ORDER BY created_at DESC"),
    ("shipquote/store.py", "CHECK (cents >= 0)", "CHECK (cents >= -1000)"),
    ("shipquote/store.py", "CHECK (length(cep) = 8)", "CHECK (length(cep) >= 7)"),
]

killed = 0
for path, old, new in MUTATIONS:
    f = Path(path)
    original = f.read_text()
    assert old in original, (path, old)
    f.write_text(original.replace(old, new, 1))
    try:
        run = subprocess.run([sys.executable, "-m", "pytest", "-q", "-x", "-p", "no:cacheprovider"],
                             capture_output=True, text=True)
    finally:
        f.write_text(original)
    verdict = "killed" if run.returncode == 1 else "SURVIVED"
    killed += verdict == "killed"
    print(f"{verdict:9} {path:20} {old}  ->  {new}")
print(f"{killed} of {len(MUTATIONS)} mutants killed")
