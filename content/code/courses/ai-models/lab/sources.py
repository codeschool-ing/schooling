#!/opt/aimodels/bin/python
"""sources: the documents this course quotes, each at one pinned commit.

A licence, a model card, an API reference: the lessons quote them, and a quote
is only worth something if the reader can find the same words. So every
document below is named with its repository, the commit it was read at, and
its path, and fetched from GitHub's raw file host, which the machine the
course was recorded on could reach when the providers' own sites could not.

    sources list                  every document, and where it comes from
    sources quote NAME PATTERN    the lines that match PATTERN (a regular
                                  expression, case-insensitive), each with its
                                  line number, wrapped at 88 columns
    sources lines NAME FROM TO    lines FROM to TO, exactly as they are
    sources words NAME            how long the document is
    sources fetch                 read every document into the cache, once

The wrapping is this program's, so a long paragraph fits a page; the words
are the document's. Standard library only.

A FEW ARE WEB PAGES, AND A WEB PAGE HAS NO COMMIT. Those are read once, on
the day `sources fetch` runs, reduced from HTML to one line per piece of text,
and kept with the date they were read; every quote from one prints that date,
and the lessons repeat it.
"""
import datetime
import html
import os
import signal
import re
import sys
import textwrap
import urllib.parse
import urllib.request

CACHE = os.environ.get("SOURCES_CACHE", "/opt/aimodels/share/sources")
LLAMA = ("meta-llama/llama-models", "0e0b8c519242d5833d8c11bffc1232b77ad7f301")
DOCS = {
    "llama3.1-licence": LLAMA + ("models/llama3_1/LICENSE",),
    "llama3.1-use-policy": LLAMA + ("models/llama3_1/USE_POLICY.md",),
    "llama3.1-card": LLAMA + ("models/llama3_1/MODEL_CARD.md",),
    "llama3.1-prompt-format": LLAMA + ("models/llama3_1/prompt_format.md",),
    "llama-skus": LLAMA + ("models/sku_list.py",),
    "llama4-licence": LLAMA + ("models/llama4/LICENSE",),
    "llama4-card": LLAMA + ("models/llama4/MODEL_CARD.md",),
    "qwen-licence": ("QwenLM/Qwen", "2df8e8ac450fa185c421a08b0090ef81826caa6e",
                     "Tongyi Qianwen LICENSE AGREEMENT"),
    "deepseek-v3-licence": ("deepseek-ai/DeepSeek-V3", "9b4e9788e4a3a731f7567338ed15d3ec549ce03b",
                            "LICENSE-MODEL"),
    "deepseek-v3-readme": ("deepseek-ai/DeepSeek-V3", "9b4e9788e4a3a731f7567338ed15d3ec549ce03b", "README.md"),
    "deepseek-r1-licence": ("deepseek-ai/DeepSeek-R1", "0cf78561f1d51c84a21b2190626b21116d5c68bb", "LICENSE"),
    "deepseek-r1-readme": ("deepseek-ai/DeepSeek-R1", "0cf78561f1d51c84a21b2190626b21116d5c68bb", "README.md"),
    "gemma-readme": ("google-deepmind/gemma", "e2e0a7d39d117b3bff6a773815ee9b1244733ef7", "README.md"),
    "gemma-code-licence": ("google-deepmind/gemma", "e2e0a7d39d117b3bff6a773815ee9b1244733ef7", "LICENSE"),
    "mistral-inference-licence": ("mistralai/mistral-inference", "9eaeb91c17450e09021b6065a1d5cc69876507c8",
                                  "LICENSE"),
    "ollama-api": ("ollama/ollama", "42e911bc3d05798cad729cb474bf62f378cb2e26", "docs/api.md"),
    "hub-model-cards": ("huggingface/hub-docs", "08175d0f6f70d4aa3d1c40404e6aa8c9172f6ec6",
                        "docs/hub/model-cards.md"),
    "hub-models": ("huggingface/hub-docs", "08175d0f6f70d4aa3d1c40404e6aa8c9172f6ec6",
                   "docs/hub/models-the-hub.md"),
    "hf-tasks": ("huggingface/huggingface.js", "3064743fce9a4b29b4d9c4ab4c38217526de2c2f",
                 "packages/tasks/src/pipelines.ts"),
}
PAGES = {
    "claude-models": "https://platform.claude.com/docs/en/about-claude/models/overview",
    "claude-pricing": "https://platform.claude.com/docs/en/about-claude/pricing",
}


def page_text(raw):
    """One line per piece of visible text, the way a reader meets it on the page."""
    raw = re.sub(r"<script.*?</script>|<style.*?</style>", "", raw, flags=re.S)
    text = html.unescape(re.sub(r"<[^>]+>", "\n", raw))
    return "\n".join(line.strip() for line in text.splitlines() if line.strip()) + "\n"


def fetch(name):
    local = os.path.join(CACHE, name)
    if name in PAGES:
        if not os.path.exists(local):
            os.makedirs(CACHE, exist_ok=True)
            req = urllib.request.Request(PAGES[name], headers={"User-Agent": "curl/8.5.0"})
            with urllib.request.urlopen(req) as r:
                text = page_text(r.read().decode("utf-8"))
            with open(local + ".part", "w", encoding="utf-8") as f:
                f.write(f"read {datetime.date.today().isoformat()}\n" + text)
            os.rename(local + ".part", local)
        with open(local, encoding="utf-8") as f:
            return f.read().split("\n", 1)[1]
    repo, commit, path = DOCS[name]
    if not os.path.exists(local):
        os.makedirs(CACHE, exist_ok=True)
        url = f"https://raw.githubusercontent.com/{repo}/{commit}/" + urllib.parse.quote(path)
        with urllib.request.urlopen(url) as r, open(local + ".part", "wb") as f:
            f.write(r.read())
        os.rename(local + ".part", local)
    with open(local, encoding="utf-8") as f:
        return f.read()


def main():
    signal.signal(signal.SIGPIPE, signal.SIG_DFL)  # a pipe into head is not an error
    args = sys.argv[1:]
    if not args or args[0] not in ("list", "quote", "lines", "words", "fetch"):
        sys.exit(__doc__)
    if args[0] == "fetch":
        for name in list(DOCS) + list(PAGES):
            fetch(name)
        return
    if args[0] == "list":
        for name, (repo, commit, path) in DOCS.items():
            print(f"{name:26} {repo}@{commit[:8]}  {path}")
        for name, url in PAGES.items():
            print(f"{name:26} {url}")
        return
    name = args[1]
    if name not in DOCS and name not in PAGES:
        sys.exit(f"sources: no document named {name}")
    text = fetch(name)
    if name in PAGES:
        with open(os.path.join(CACHE, name), encoding="utf-8") as f:
            print(f"# {PAGES[name]}, {f.readline().strip()}")
    else:
        repo, commit, path = DOCS[name]
        print(f"# {repo}@{commit[:8]} {path}")
    if args[0] == "words":
        print(f"{len(text.split()):,} words, {len(text.splitlines()):,} lines")
        return
    if args[0] == "lines":
        lines = text.splitlines()
        for i in range(int(args[2]), int(args[3]) + 1):
            print(f"{i:4}| {lines[i - 1]}".rstrip())
        return
    pattern = re.compile(args[2], re.I)
    hits = 0
    for i, line in enumerate(text.splitlines(), 1):
        if pattern.search(line):
            hits += 1
            wrapped = textwrap.wrap(line.strip(), 88) or [""]
            print(f"{i:4}: {wrapped[0]}")
            for rest in wrapped[1:]:
                print(f"      {rest}")
    if not hits:
        print("(no line matches)")


if __name__ == "__main__":
    main()
