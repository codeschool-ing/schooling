---
title: The harness
version: 1
---

Everything in this course lives in one directory, `~/triage`, and you build it here. It holds
three kinds of file:

- **`pl.py`**, the harness: a Python program of about two hundred lines that runs a prompt over a
  test set and counts the replies that pass;
- **`cases/`**, the test sets: messages, one per line, each with the answer a person decided was
  right;
- **`prompts/`**, the prompts: plain text with a placeholder where each message goes.

Make the directories first:

```sh
mkdir -p ~/triage/cases ~/triage/prompts ~/triage/runs
cd ~/triage
```

## The program

Save this as `pl.py`:

```schooling-example
{"language": "python", "file": "pl.py", "parts": [{"code": "\"\"\"pl: run a prompt over a test set, and count what passes.\"\"\"\nimport argparse\nimport hashlib\nimport json\nimport math\nimport os\nimport re\nimport sys\nimport time\nimport urllib.error\nimport urllib.request\n\nOLLAMA = os.environ.get(\"OLLAMA_HOST\", \"http://127.0.0.1:11434\")\nDEFAULTS = {\"model\": \"llama3.2:3b\", \"temperature\": \"0\", \"seed\": \"1\", \"num_predict\": \"400\"}\nLABELS = {\"category\": [\"billing\", \"delivery\", \"returns\", \"account\", \"other\"],\n          \"urgency\": [\"low\", \"normal\", \"high\"]}\nCHECKS = [\"json\", \"fields\", \"labels\", \"category\", \"urgency\"]\n\n", "note": "Only the standard library, so there is nothing to install beyond Python. `DEFAULTS` is what every call gets unless a prompt file or `--set` says otherwise: temperature 0 and a fixed seed, so that running the same prompt twice gives the same replies and a difference between two runs means the prompt changed. `num_predict` is the most tokens a reply may have. `LABELS` is the contract the replies are checked against."}, {"code": "def die(msg):\n    sys.exit(\"pl: \" + msg)\n\n\ndef read_jsonl(path):\n    with open(path, encoding=\"utf-8\") as f:\n        return [json.loads(line) for line in f if line.strip()]\n\n", "note": "A test set is JSON Lines: one object per line, so a file of forty messages can be read, grepped and diffed a line at a time."}, {"code": "def read_prompt(path):\n    raw = open(path, encoding=\"utf-8\").read()\n    params = {}\n    head, sep, rest = raw.partition(\"\\n---\\n\")\n    if sep and all(re.match(r\"[a-z_]+: \", l) for l in head.splitlines() if l.strip()):\n        for line in head.splitlines():\n            if line.strip():\n                name, _, value = line.partition(\": \")\n                params[name] = value.strip()\n        raw = rest\n    return params, raw\n\n", "note": "A prompt file may start with settings, one `name: value` per line and a line `---` under them. Lesson 8 uses that to give one prompt its own temperature. Most prompt files have no header and are all template."}, {"code": "def render(template, values):\n    used = set()\n\n    def fill(m):\n        name, how = m.group(1), m.group(2)\n        if name not in values:\n            die(\"no value for {{%s}}\" % name)\n        used.add(name)\n        value = str(values[name])\n        if how == \"xml\":\n            value = value.replace(\"&\", \"&amp;\").replace(\"<\", \"&lt;\").replace(\">\", \"&gt;\")\n        return value\n\n    text = re.sub(r\"\\{\\{\\s*([a-z_]+)(?:\\|(xml))?\\s*\\}\\}\", fill, template)\n    for name in sorted(set(values) - used):\n        print(\"pl: warning: {{%s}} is not in the template\" % name, file=sys.stderr)\n    return text\n\n", "note": "`{{message}}` is replaced by the case's value. A placeholder with no value stops the run rather than sending the braces to the model, and a value the template never uses is a warning: lesson 4 is about both. `|xml` escapes the value, for lesson 9."}, {"code": "def call(prompt, params):\n    \"\"\"One request to the model, and the only function that knows it is Ollama.\"\"\"\n    options = {k: float(v) if \".\" in v else int(v) for k, v in params.items() if k != \"model\"}\n    body = {\"model\": params[\"model\"], \"stream\": False, \"options\": options,\n            \"messages\": [{\"role\": \"user\", \"content\": prompt}]}\n    req = urllib.request.Request(OLLAMA + \"/api/chat\", json.dumps(body).encode(),\n                                 {\"Content-Type\": \"application/json\"})\n    start = time.time()\n    try:\n        with urllib.request.urlopen(req, timeout=600) as r:\n            reply = json.load(r)\n    except urllib.error.HTTPError as e:\n        die(\"Ollama answered %d: %s\" % (e.code, e.read().decode().strip()))\n    except urllib.error.URLError as e:\n        die(\"cannot reach Ollama at %s (%s). Is it running?\" % (OLLAMA, e.reason))\n    return {\"text\": reply[\"message\"][\"content\"], \"stop\": reply.get(\"done_reason\"),\n            \"tokens_in\": reply.get(\"prompt_eval_count\", 0),\n            \"tokens_out\": reply.get(\"eval_count\", 0),\n            \"seconds\": round(time.time() - start, 2)}\n\n", "note": "The one function that talks to a model. It posts the prompt to Ollama's chat endpoint and keeps four things: the text, why it stopped, the tokens in and out, and the seconds it took. If you use a paid API instead of Ollama, this is the function you replace."}, {"code": "def values_of(case, extra):\n    values = {k: v for k, v in case.items() if k not in (\"id\", \"expect\")}\n    values.update(extra)\n    return values\n\n\ndef pairs(items):\n    return dict(item.partition(\"=\")[::2] for item in items or [])\n\n\ndef cmd_render(a):\n    params, template = read_prompt(a.prompt)\n    case = {}\n    if a.case:\n        case = next((c for c in read_jsonl(a.cases) if c[\"id\"] == a.case), None)\n        if case is None:\n            die(\"no case %s in %s\" % (a.case, a.cases))\n    print(render(template, values_of(case, pairs(a.var))), end=\"\")\n\n", "note": "`pl render` prints the prompt exactly as the model will receive it, with a case's values filled in. Reading the rendered prompt is the cheapest test there is."}, {"code": "def cmd_run(a):\n    params, template = read_prompt(a.prompt)\n    params = {**DEFAULTS, **params, **pairs(a.set)}\n    pid = hashlib.sha256(open(a.prompt, \"rb\").read()).hexdigest()[:8]\n    cases = read_jsonl(a.cases)\n    with open(a.out, \"w\", encoding=\"utf-8\") as out:\n        for case in cases:\n            prompt = render(template, values_of(case, pairs(a.var)))\n            for n in range(a.samples):\n                seed = str(int(params[\"seed\"]) + n)\n                row = {\"case\": case[\"id\"], \"sample\": n, \"cases\": a.cases, \"prompt\": pid}\n                row.update(call(prompt, {**params, \"seed\": seed}))\n                out.write(json.dumps(row, ensure_ascii=False) + \"\\n\")\n    print(\"%d calls, prompt %s, %s, written to %s\"\n          % (len(cases) * a.samples, pid, params[\"model\"], a.out))\n\n", "note": "`pl run` renders the prompt once per case, calls the model and writes one line per reply. The run file keeps which cases it ran and a short hash of the prompt file, so a result can always be traced back to the exact prompt that produced it. `--samples` asks several times per case with different seeds; lesson 8 needs it."}, {"code": "def parse(text, lenient=False):\n    if lenient:\n        found = re.search(r\"\\{.*\\}\", text, re.S)\n        text = found.group(0) if found else text\n    try:\n        obj = json.loads(text)\n    except ValueError:\n        return None\n    return obj if isinstance(obj, dict) else None\n\n\ndef judge(row, expect, lenient=False):\n    \"\"\"The first check a reply fails, and why; (None, None) if it passes them all.\"\"\"\n    obj = parse(row[\"text\"], lenient)\n    if obj is None:\n        return \"json\", \"cut off at num_predict\" if row[\"stop\"] == \"length\" else \"not a JSON object\"\n    missing = [k for k in LABELS if k not in obj]\n    extra = [k for k in obj if k not in LABELS and k != \"summary\"]\n    if missing:\n        return \"fields\", \"missing \" + \", \".join(missing)\n    if extra:\n        return \"fields\", \"unexpected \" + \", \".join(extra)\n    for k in LABELS:\n        if obj[k] not in LABELS[k]:\n            return \"labels\", \"%s %r\" % (k, obj[k])\n    for k in LABELS:\n        if obj[k] != expect[k]:\n            return k, \"%s, expected %s\" % (obj[k], expect[k])\n    return None, None\n\n", "note": "The checks, in order, and the first failure ends them: a reply that is not JSON cannot have the right fields, and one with the wrong fields cannot be checked for its labels. `summary` may be anything; it is there for the person who reads the ticket. `--lenient` digs a JSON object out of surrounding text, and lesson 3 says when that is a good idea."}, {"code": "def verdicts(path, lenient=False):\n    rows = read_jsonl(path)\n    if not rows:\n        die(\"%s has no replies in it\" % path)\n    expect = {c[\"id\"]: c[\"expect\"] for c in read_jsonl(rows[0][\"cases\"])}\n    return [(r, *judge(r, expect[r[\"case\"]], lenient)) for r in rows]\n\n\ndef tag(row):\n    return row[\"case\"] + (\"#%d\" % row[\"sample\"] if row[\"sample\"] else \"\")\n\n\ndef cmd_check(a):\n    results = verdicts(a.run, a.lenient)\n    print(\"%-9s %5s %5s\" % (\"check\", \"pass\", \"fail\"))\n    failed = 0\n    for check in CHECKS:\n        failed += sum(1 for _, c, _ in results if c == check)\n        print(\"%-9s %5d %5d\" % (check, len(results) - failed, failed))\n    print(\"%-9s %5d %5d\" % (\"all\", len(results) - failed, failed))\n    if a.failures:\n        print()\n        for row, check, why in results:\n            if check:\n                print(\"%-6s %-9s %s\" % (tag(row), check, why))\n\n", "note": "`pl check` counts, per check, how many replies were still passing at that point. `--failures` lists the ones that failed and why."}, {"code": "def cmd_show(a):\n    for row in read_jsonl(a.run):\n        if row[\"case\"] == a.id and row[\"sample\"] == a.sample:\n            for line in row[\"text\"].split(\"\\n\"):\n                print((\"│ \" + line).rstrip())\n            print(\"stop: %s, tokens in %d, out %d, %.1f s\"\n                  % (row[\"stop\"], row[\"tokens_in\"], row[\"tokens_out\"], row[\"seconds\"]))\n            return\n    die(\"no reply for %s in %s\" % (a.id, a.run))\n\n", "note": "`pl show` prints one reply exactly as the model wrote it, each line behind a bar, so where it starts and ends is visible, blank lines included."}, {"code": "def cmd_compare(a):\n    if a.answers:\n        x = {tag(r): (parse(r[\"text\"], True) or {}).get(\"category\") for r in read_jsonl(a.a)}\n        y = {tag(r): (parse(r[\"text\"], True) or {}).get(\"category\") for r in read_jsonl(a.b)}\n        changed = [k for k in x if k in y and x[k] != y[k]]\n        print(\"%d cases, same answer %d, different answer %d\" % (len(x), len(x) - len(changed), len(changed)))\n        for k in changed:\n            print(\"  %-6s %s -> %s\" % (k, x[k], y[k]))\n        return\n    x = {tag(r): c is None for r, c, _ in verdicts(a.a)}\n    y = {tag(r): c is None for r, c, _ in verdicts(a.b)}\n    fixed = [k for k in x if not x[k] and y[k]]\n    broken = [k for k in x if x[k] and not y[k]]\n    for path, passed in ((a.a, x), (a.b, y)):\n        print(\"%-24s passes %d/%d\" % (path, sum(passed.values()), len(passed)))\n    print(\"fixed %d, broken %d\" % (len(fixed), len(broken)))\n    if broken:\n        print(\"broken: \" + \" \".join(broken))\n    n, k = len(fixed) + len(broken), min(len(fixed), len(broken))\n    p = min(1.0, 2 * sum(math.comb(n, i) for i in range(k + 1)) / 2 ** n) if n else 1.0\n    print(\"sign test on the %d that changed: p = %.3f\" % (n, p))\n\n", "note": "`pl compare` lines two runs up case by case. Only the cases whose result changed say anything about the change, and the sign test asks how often a fair coin would split them that unevenly. `--answers` compares the categories instead of the verdicts."}, {"code": "def main():\n    p = argparse.ArgumentParser(prog=\"pl\")\n    sub = p.add_subparsers(dest=\"command\", required=True)\n    r = sub.add_parser(\"render\")\n    r.add_argument(\"prompt\")\n    r.add_argument(\"--cases\")\n    r.add_argument(\"--case\")\n    r.add_argument(\"--var\", action=\"append\")\n    r = sub.add_parser(\"run\")\n    r.add_argument(\"prompt\")\n    r.add_argument(\"cases\")\n    r.add_argument(\"--out\", required=True)\n    r.add_argument(\"--samples\", type=int, default=1)\n    r.add_argument(\"--set\", action=\"append\")\n    r.add_argument(\"--var\", action=\"append\")\n    r = sub.add_parser(\"check\")\n    r.add_argument(\"run\")\n    r.add_argument(\"--failures\", action=\"store_true\")\n    r.add_argument(\"--lenient\", action=\"store_true\")\n    r = sub.add_parser(\"show\")\n    r.add_argument(\"run\")\n    r.add_argument(\"id\")\n    r.add_argument(\"--sample\", type=int, default=0)\n    r = sub.add_parser(\"compare\")\n    r.add_argument(\"a\")\n    r.add_argument(\"b\")\n    r.add_argument(\"--answers\", action=\"store_true\")\n    a = p.parse_args()\n    globals()[\"cmd_\" + a.command](a)\n\n\nif __name__ == \"__main__\":\n    main()"}]}
```

You do not need to follow every line of it today. Each lesson says what a command counts, and
that is enough to argue with the number. **But it is all here**, nothing in it is hidden, and when a
number surprises you the answer is in a few lines of this file.

Typing `python3 ~/triage/pl.py` every time gets old, so give it a short name. This line at the end
of `~/.bashrc` makes `pl` mean exactly that in every new terminal:

```sh
echo "alias pl='python3 ~/triage/pl.py'" >> ~/.bashrc
```

Open a new terminal, or run `source ~/.bashrc` in this one, and `pl` works from any directory.

## The test set

Folio is an online bookshop, invented for the course. Its support inbox needs every message
sorted before a person reads it: a category (billing, delivery, returns, account or other), an
urgency (low, normal or high) and a one-sentence summary. The answer is JSON, because a program
reads it next.

These are forty of its messages, each with the labels a person gave it. Save them as
`cases/dev.jsonl`:

```
{"id": "t01", "message": "I was charged twice for order 4471. Please refund the second payment.", "expect": {"category": "billing", "urgency": "high"}}
{"id": "t02", "message": "My parcel was meant to arrive on Monday and the tracking hasn't moved since Friday.", "expect": {"category": "delivery", "urgency": "normal"}}
{"id": "t03", "message": "The book arrived with the cover torn. Can I send it back for a replacement?", "expect": {"category": "returns", "urgency": "normal"}}
{"id": "t04", "message": "I can't log in. The password reset email never comes.", "expect": {"category": "account", "urgency": "high"}}
{"id": "t05", "message": "Do you have any signed copies of the new Carla Mendes novel?", "expect": {"category": "other", "urgency": "low"}}
{"id": "t06", "message": "Where can I find a copy of my invoice for last month's order?", "expect": {"category": "billing", "urgency": "low"}}
{"id": "t07", "message": "The courier says the address is wrong but it's the same one I always use.", "expect": {"category": "delivery", "urgency": "normal"}}
{"id": "t08", "message": "I ordered the hardback and you sent the paperback. I'd like to exchange it.", "expect": {"category": "returns", "urgency": "normal"}}
{"id": "t09", "message": "Please delete my account and all my data.", "expect": {"category": "account", "urgency": "normal"}}
{"id": "t10", "message": "Are you open on the bank holiday?", "expect": {"category": "other", "urgency": "low"}}
{"id": "t11", "message": "My card was declined but the money left my account anyway.", "expect": {"category": "billing", "urgency": "high"}}
{"id": "t12", "message": "Tracking says delivered but there is nothing at my door.", "expect": {"category": "delivery", "urgency": "high"}}
{"id": "t13", "message": "How long do I have to return a book I didn't like?", "expect": {"category": "returns", "urgency": "low"}}
{"id": "t14", "message": "I changed my email address and now the newsletter goes to the old one.", "expect": {"category": "account", "urgency": "low"}}
{"id": "t15", "message": "Could you recommend something like The Quiet Harbour for a twelve-year-old?", "expect": {"category": "other", "urgency": "low"}}
{"id": "t16", "message": "The price on the website was \u00a312 but I paid \u00a315 at checkout.", "expect": {"category": "billing", "urgency": "normal"}}
{"id": "t17", "message": "My order was dispatched ten days ago and still hasn't arrived. I need it for a birthday on Saturday.", "expect": {"category": "delivery", "urgency": "high"}}
{"id": "t18", "message": "Two pages are missing from chapter 3. Faulty print?", "expect": {"category": "returns", "urgency": "normal"}}
{"id": "t19", "message": "Someone else seems to have logged into my account and changed the delivery address.", "expect": {"category": "account", "urgency": "high"}}
{"id": "t20", "message": "Do you buy second-hand books?", "expect": {"category": "other", "urgency": "low"}}
{"id": "t21", "message": "I returned a book three weeks ago and I still haven't had the refund.", "expect": {"category": "returns", "urgency": "high"}}
{"id": "t22", "message": "Can I pay with a gift card and a credit card on the same order?", "expect": {"category": "billing", "urgency": "low"}}
{"id": "t23", "message": "The parcel came but it was soaked and the books inside are ruined.", "expect": {"category": "returns", "urgency": "high"}}
{"id": "t24", "message": "Is it possible to change the delivery address on an order I placed an hour ago?", "expect": {"category": "delivery", "urgency": "normal"}}
{"id": "t25", "message": "Your app keeps logging me out every few minutes.", "expect": {"category": "account", "urgency": "normal"}}
{"id": "t26", "message": "I'd like to cancel my subscription to the monthly box before the next payment.", "expect": {"category": "billing", "urgency": "normal"}}
{"id": "t27", "message": "Can I collect my order from the shop instead of having it delivered?", "expect": {"category": "delivery", "urgency": "low"}}
{"id": "t28", "message": "I want to return a gift but I don't have the receipt.", "expect": {"category": "returns", "urgency": "low"}}
{"id": "t29", "message": "Why do I need an account to buy a book?", "expect": {"category": "account", "urgency": "low"}}
{"id": "t30", "message": "Are there any author events in the shop this month?", "expect": {"category": "other", "urgency": "low"}}
{"id": "t31", "message": "You took payment for the monthly box but I cancelled it last week.", "expect": {"category": "billing", "urgency": "high"}}
{"id": "t32", "message": "The tracking number you sent doesn't work on the courier's website.", "expect": {"category": "delivery", "urgency": "normal"}}
{"id": "t33", "message": "I received someone else's order. What should I do with it?", "expect": {"category": "returns", "urgency": "normal"}}
{"id": "t34", "message": "How do I turn off the marketing emails?", "expect": {"category": "account", "urgency": "low"}}
{"id": "t35", "message": "I love the shop. Thank you for the lovely wrapping on my last order!", "expect": {"category": "other", "urgency": "low"}}
{"id": "t36", "message": "There's a charge from you on my statement that I don't recognise.", "expect": {"category": "billing", "urgency": "high"}}
{"id": "t37", "message": "The book I ordered says 'in stock' but my order still says 'awaiting dispatch' after a week.", "expect": {"category": "delivery", "urgency": "normal"}}
{"id": "t38", "message": "The ebook I bought won't open on my reader.", "expect": {"category": "returns", "urgency": "normal"}}
{"id": "t39", "message": "I'm locked out after too many attempts. How long before I can try again?", "expect": {"category": "account", "urgency": "normal"}}
{"id": "t40", "message": "What is your policy on reviewing self-published books?", "expect": {"category": "other", "urgency": "low"}}
```

Check that everything is where `pl` expects it, and look at the first prompt as the model will
receive it, with `t01` filled in:

```
ana@lab:~/triage$ ls
cases
pl.py
prompts
runs
ana@lab:~/triage$ wc -l cases/dev.jsonl
40 cases/dev.jsonl
ana@lab:~/triage$ pl render prompts/v1-bare.txt --cases cases/dev.jsonl --case t01
Sort this customer message for the support team. Say what it is about and how urgent it is.

Message: I was charged twice for order 4471. Please refund the second payment.
```

`{{message}}` in a prompt is replaced by the case's `message`. `expect` never reaches the model:
it is what `pl check` compares the reply with.

## Three commands

| command | what it does |
|---|---|
| `pl run PROMPT CASES --out RUN` | fills the prompt with each message, calls the model, and writes every reply to a file |
| `pl check RUN` | holds every reply to five checks and counts the passes |
| `pl show RUN ID` | prints one reply exactly as the model wrote it |

The checks run in order, and a reply that fails one fails every check after it: `json` (does it
parse), `fields` (does it have the fields and no others), `labels` (are the values from the
lists), `category` and `urgency` (do they match the person's answer). `all` counts the replies
that passed everything.
