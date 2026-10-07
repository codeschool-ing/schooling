---
title: What the assistant sees
version: 2
---

An assistant in the editor looks as though it reads your project. **It reads what the editor sends
it**, and the editor decides that in the moment before each request. It sends some of the file you
are in, some of the other files that look related, and the project's instruction file if there is
one, all cut down to fit a budget. Lesson 1 section 10 said the model knows only what is in the
request; this section is about who fills the request in, and how.

## An assistant small enough to read

Real assistants do not publish their exact rules, and they change them often. So this lesson
uses one written for the course, `assist`, which follows the same three steps the real ones
describe in their documentation and, unlike them, prints what it sent. Save it as
`~/shop/scratch/assist.py`:

```schooling-example
{
  "language": "python",
  "file": "scratch/assist.py",
  "parts": [
    {
      "code": "\"\"\"assist: an editor assistant small enough to read, written for this course.\n\nThe assistants built into editors do three things before a model sees anything:\nthey decide which text to send (the file around the cursor, other files that look\nrelated, the project's instruction file), they leave out what they were told to\nleave out, and they fit the rest into a token budget. This does the same three\nthings against your local models, prints what it sent, and keeps the whole\nrequest in scratch/sent.json and the reply in scratch/reply.txt, which the real\nones do not show you. It is not a\ncopy of any of them: their exact rules are their own and mostly unpublished.\n\n    python scratch/assist.py complete FILE:LINE [--open FILE ...] [--accept]\n    python scratch/assist.py ask \"QUESTION\" [--open FILE ...] [--write FILE]\n\nCompletion uses a small code model trained to fill a gap between the text before\nthe cursor and the text after it; questions go to the chat model. Rules:\nAGENTS.md, if present, goes first. Paths matching a line of .assistignore are\nnever read. A file holding something shaped like a secret is refused rather than\nsent. The budget is 3,000 tokens of context. --accept puts the suggestion into\nthe file at the cursor, as pressing Tab would; --write puts the first block of\ncode in the reply into FILE, as a chat panel's Apply button would.\n\"\"\"\n",
      "note": "**What it is and how to call it.** It is a course's tool, not a product: about a hundred and fifty lines that do what editor assistants describe in their documentation, so that every step can be read."
    },
    {
      "code": "import argparse\nimport fnmatch\nimport json\nimport os\nimport re\nimport sys\nimport urllib.request\n\nimport anthropic\nimport tiktoken\n\nENC = tiktoken.get_encoding(\"o200k_base\")\nBUDGET = 3000\nSECRET = re.compile(r\"(?i)(token|secret|password|api_key)\\s*[=:]\\s*\\S{8,}\")\nCHAT, CODE = \"llama3.2:3b\", \"qwen2.5-coder:1.5b\"\n\n\n",
      "note": "**The settings of the whole tool**: a budget of 3,000 tokens, counted with `tiktoken` because that is fast and close enough for a budget, a pattern for things shaped like a secret, and the two models. `CHAT` answers questions; `CODE` fills gaps."
    },
    {
      "code": "def ignored(path):\n    try:\n        patterns = [p.strip() for p in open(\".assistignore\") if p.strip() and not p.startswith(\"#\")]\n    except FileNotFoundError:\n        return False\n    return any(fnmatch.fnmatch(path, p) or fnmatch.fnmatch(os.path.basename(path), p) for p in patterns)\n\n\ndef gather(paths, used):\n    \"\"\"The other files, in order, each whole or not at all, within what is left of the budget.\"\"\"\n    parts, notes = [], []\n    for p in paths:\n        if ignored(p):\n            notes.append(f\"skipped {p}: listed in .assistignore\")\n            continue\n        text = open(p).read()\n        if SECRET.search(text):\n            notes.append(f\"refused {p}: it holds something shaped like a secret\")\n            continue\n        n = len(ENC.encode(text))\n        if used + n > BUDGET:\n            notes.append(f\"dropped {p}: {n} tokens would pass the budget\")\n            continue\n        parts.append((p, text, n))\n        used += n\n    return parts, used, notes\n\n\n",
      "note": "**The two filters and the budget.** A path on `.assistignore` is never opened; a file whose text matches the secret pattern is refused whole; the rest go in, in the order they were opened, until the budget runs out, and a file that does not fit is dropped whole rather than cut."
    },
    {
      "code": "def as_comment(name, text):\n    \"\"\"Another file, for a code model: commented out, so it reads as context and not as code.\"\"\"\n    return \"\".join(f\"# {line}\\n\".replace(\"# \\n\", \"#\\n\") for line in [f\"Path: {name}\"] + text.split(\"\\n\"))\n\n\n",
      "note": "**How a code model is shown other files**: as comments at the top of the file it is completing. A completion model continues code, so text it should read and not imitate has to look like something code can contain."
    },
    {
      "code": "def report(sections, used, notes):\n    print(f\"context sent ({used} of {BUDGET} tokens):\", file=sys.stderr)\n    for name, _, n in sections:\n        print(f\"  {n:5}  {name}\", file=sys.stderr)\n    for note in notes:\n        print(f\"  {note}\", file=sys.stderr)\n    print(\"---\", file=sys.stderr)\n\n\n",
      "note": "**What it tells you and the real ones do not**: every file it sent, with its size, and every file it left out, with the reason."
    },
    {
      "code": "def complete(target, opened, accept):\n    path, line = target.rsplit(\":\", 1)\n    lines = open(path).read().split(\"\\n\")\n    k = int(line)\n    before, after = \"\\n\".join(lines[:k - 1]) + \"\\n\", \"\\n\" + \"\\n\".join(lines[k:])\n    sections, used = [], 0\n    if os.path.exists(\"AGENTS.md\"):\n        text = open(\"AGENTS.md\").read()\n        sections.append((\"AGENTS.md\", text, len(ENC.encode(text))))\n        used += sections[-1][2]\n    n = len(ENC.encode(before + after))\n    sections.append((f\"{path} (cursor at line {line})\", None, n))\n    used += n\n    others, used, notes = gather(opened, used)\n    sections += others\n    report(sections, used, notes)\n    context = \"\".join(as_comment(name, text) for name, text, _ in sections if text is not None)\n    # Stop at the first blank line, so that one suggestion is one block.\n    request = {\"model\": CODE, \"prompt\": context + before, \"suffix\": after, \"stream\": False,\n               \"options\": {\"num_predict\": 300, \"stop\": [\"\\n\\n\"]}}\n    json.dump(request, open(\"scratch/sent.json\", \"w\"), indent=1)\n    req = urllib.request.Request(\"http://127.0.0.1:11434/api/generate\", json.dumps(request).encode())\n    suggestion = json.load(urllib.request.urlopen(req))[\"response\"].rstrip(\"\\n\")\n    open(\"scratch/reply.txt\", \"w\").write(suggestion + \"\\n\")\n    print(suggestion)\n    if accept:\n        lines[k - 1:k] = suggestion.split(\"\\n\")\n        open(path, \"w\").write(\"\\n\".join(lines))\n\n\n",
      "note": "**A completion is a gap with text on both sides.** `prompt` is everything before the cursor, `suffix` everything after it, and Ollama's `/api/generate` puts them into the code model's own fill-in-the-middle format. The request is kept in `scratch/sent.json`, and `--accept` writes the suggestion where the cursor was."
    },
    {
      "code": "def ask(question, opened, write):\n    sections, used = [], 0\n    if os.path.exists(\"AGENTS.md\"):\n        text = open(\"AGENTS.md\").read()\n        sections.append((\"AGENTS.md\", text, len(ENC.encode(text))))\n        used += sections[-1][2]\n    others, used, notes = gather(opened, used)\n    sections += others\n    report(sections, used, notes)\n    prompt = \"\".join(f\"### {name}\\n{text}\\n\" for name, text, _ in sections) + \"\\n\" + question\n    request = {\"model\": CHAT, \"max_tokens\": 1500,\n               \"system\": \"You answer questions about the files shown, briefly, as a senior colleague would.\",\n               \"messages\": [{\"role\": \"user\", \"content\": prompt}]}\n    json.dump(request, open(\"scratch/sent.json\", \"w\"), indent=1)\n    reply = anthropic.Anthropic().messages.create(**request).content[0].text\n    open(\"scratch/reply.txt\", \"w\").write(reply + \"\\n\")\n    print(reply)\n    if write:\n        block = re.search(r\"```\\w*\\n(.*?)\\n```\", reply, re.S)\n        if not block:\n            sys.exit(\"assist: the reply has no block of code to write\")\n        open(write, \"w\").write(block.group(1) + \"\\n\")\n\n\n",
      "note": "**A question goes to the chat model**, through the `anthropic` SDK like every other program in this course, with the files in the message. `--write` takes the first block of code in the reply and writes it to a file."
    },
    {
      "code": "def main():\n    ap = argparse.ArgumentParser(prog=\"assist\")\n    ap.add_argument(\"mode\", choices=[\"complete\", \"ask\"])\n    ap.add_argument(\"target\")\n    ap.add_argument(\"--open\", nargs=\"*\", default=[], help=\"other files open in the editor\")\n    ap.add_argument(\"--accept\", action=\"store_true\", help=\"insert the completion at the cursor\")\n    ap.add_argument(\"--write\", metavar=\"FILE\", help=\"write the reply's first block of code to FILE\")\n    a = ap.parse_args()\n    if a.mode == \"complete\":\n        complete(a.target, a.open, a.accept)\n    else:\n        ask(a.target, a.open, a.write)\n\n\nif __name__ == \"__main__\":\n    main()\n",
      "note": "**The two commands.**"
    }
  ]
}
```

**It uses two models, because editors do.** The ghost text that appears as you type comes from a
small model trained for one job, filling a gap in code, and it has to answer within a second or two.
Questions in a chat panel go to a larger general model. A model trained for **fill-in-the-middle**
is given the text before the cursor and the text after it, and writes only what goes between.
`llama3.2:3b`, the course's model, is the second kind, and Ollama says so when asked for an
insertion:

```
ana@dev:~/shop$ curl -s http://127.0.0.1:11434/api/generate -d '{"model": "llama3.2:3b", "prompt": "def add(a, b):\n", "suffix": "\n\nprint(add(1, 2))\n", "stream": false}'; echo
```

`qwen2.5-coder:1.5b` is a model of the first kind, from Alibaba's Qwen family, about 1 GB:

```sh
ollama pull qwen2.5-coder:1.5b
```

It is used for completions in this lesson and nowhere else; every question still goes to
`llama3.2:3b`.

## A completion request

ana has started a method in `shop/cart.py`: the signature and the docstring that says what it is
for. The cursor is on the empty line after the docstring:

```
ana@dev:~/shop$ sed -n 28,34p shop/cart.py
    def remove(self, sku: str, quantity: int = 1) -> None:
        """Take `quantity` units of `sku` out of the cart.

        A line that reaches zero is removed. Removing more than the cart
        holds, or a sku it does not hold, raises ValueError.
        """
```

She asks for a completion with two other files open in the editor, the way they would be in her
tabs:

```
ana@dev:~/shop$ python scratch/assist.py complete shop/cart.py:34 --open shop/coupons.py tests/test_cart.py
context sent (599 of 3000 tokens):
    332  shop/cart.py (cursor at line 34)
     91  shop/coupons.py
    176  tests/test_cart.py
---
        for line in self.lines:
            if line.sku == sku:
                if line.quantity > quantity:
                    line.quantity -= quantity
                    return
                elif line.quantity == quantity:
                    self.lines.remove(line)
                    return
        raise ValueError(f"no {sku} in cart")
```

The lines above `---` are what `assist` reports about its own request: **599 tokens of context
out of a budget of 3,000**, made of the file she is in and the two open tabs. Below `---` is the
suggestion. Yours will differ: this is a draw like every other.

Read it against the docstring. It finds the line, takes units off, removes the line at zero, and
refuses a sku the cart does not hold. Now ask it to take three mugs out of two: neither branch
matches, the loop ends, and the error says `no MUG-01 in cart`, which is false. It is refused for
the wrong reason. Lesson 3 section 04 does not accept this suggestion; it asks again, with tests
written first.

## What was in the request

`assist` kept the request in `scratch/sent.json`. `~/shop/scratch/sent.py` prints its beginning,
its end, and the start of the text after the gap:

```python
import json

r = json.load(open("scratch/sent.json"))
before, after = r["prompt"].split("\n"), r["suffix"].split("\n")
print("model:", r["model"], " stop:", r["options"]["stop"])
print("\n".join(before[:2] + ["(...)"] + before[-7:]))
print("<the gap the model fills>")
print("\n".join(after[:3] + ["(...)"]))
```

```
ana@dev:~/shop$ python scratch/sent.py
```

Three things to notice, because every completion tool has a version of each:

- **The cursor is a gap between two texts.** The model gets the code before the cursor and the
  code after it, so it can see what has to come next as well as what came before. That is why a
  completion can close a block correctly and stop where the next method begins: the code below the
  cursor is in the request too.
- **The other files are chosen by the tool, not by you.** Here they are whatever ana had open, and
  they arrive as comments at the very top. Real assistants also use recently edited files and files
  that share names with the one you are in, and some search the repository. A file nobody chose can
  be in the request.
- **A budget decides what is dropped.** 3,000 tokens here. A large file, or many open tabs, means
  something is left out, and the model will not tell you what it did not see.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Where a completion request comes from. The editor holds the file with the cursor, the open tabs and the instruction file. assist leaves out files on the exclusion list and files holding something shaped like a secret, fits the rest into a budget of 3,000 tokens, and sends the result to the model.\"><defs><marker id=\"cx-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"100\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">in the editor</text><rect x=\"20\" y=\"40\" width=\"160\" height=\"38\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"100.0\" y=\"59.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">instruction file</text><rect x=\"20\" y=\"92\" width=\"160\" height=\"38\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"100.0\" y=\"111.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the file, around the cursor</text><rect x=\"20\" y=\"144\" width=\"160\" height=\"38\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"100.0\" y=\"163.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">open tabs</text><text x=\"360\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the assistant&#x27;s rules</text><rect x=\"270\" y=\"40\" width=\"180\" height=\"38\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"59.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">exclusion list</text><rect x=\"270\" y=\"92\" width=\"180\" height=\"38\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"111.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">secret check</text><rect x=\"270\" y=\"144\" width=\"180\" height=\"38\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"163.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">budget: 3,000 tokens</text><path d=\"M182 59 L266 59\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cx-ah)\"></path><path d=\"M182 111 L266 111\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cx-ah)\"></path><path d=\"M182 163 L266 163\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cx-ah)\"></path><text x=\"610\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the request</text><rect x=\"520\" y=\"40\" width=\"180\" height=\"142\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"610.0\" y=\"111.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">what the model sees</text><path d=\"M452 59 L516 59\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cx-ah)\"></path><path d=\"M452 111 L516 111\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cx-ah)\"></path><path d=\"M452 163 L516 163\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cx-ah)\"></path><path d=\"M360 196 L360 222\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cx-ah)\"></path><text x=\"360\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">left out: nothing tells you</text></svg>", "caption": "The model sees the request, and the request is what the tool assembled. Every completion tool has some version of these three rules."}
```

**The working conclusion is the same as lesson 1's, applied to the editor:** when a suggestion
ignores a convention or calls a function that does not exist, the first question is whether the
file that defines it was in the context. Opening it in a tab, or naming it in a chat question, is
often the whole fix.
