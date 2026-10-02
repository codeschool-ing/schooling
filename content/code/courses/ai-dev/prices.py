#!/usr/bin/env python3
"""The price sheet every number in this course's lessons 2 and 10 comes from.

TWO SOURCES, AND THEY ARE NOT THE SAME KIND OF THING.

  anthropic   The provider's own pricing page, read as it stands on the day the
              script runs. It is not versioned, so the sheet says the date it was
              read, and the lessons quote that date beside every number.
  openai,     LiteLLM's model_prices_and_context_window.json, a list of prices
  google      and limits that an open-source project keeps for every provider,
              read at ONE PINNED COMMIT so that the same sheet comes out next
              year. It is a third party's copy of the providers' pages: OpenAI's
              and Google's own pages could not be reached from the machine the
              course was recorded on, so this is the best published source that
              could be read, and the lessons say so.

Where the two overlap (Anthropic's models are in both) the script prints both,
so a disagreement between the copy and the original is visible rather than
assumed away.

    python3 prices.py            # the whole sheet
    python3 prices.py anthropic  # one block of it

Standard library only. Prices are dollars per million tokens (MTok).
"""
import datetime
import html
import json
import os
import re
import sys
import urllib.request

ANTHROPIC = "https://platform.claude.com/docs/en/about-claude/pricing"
LITELLM_COMMIT = "b9e71e990aedac89a8cf5da2a47aca51abe37076"
LITELLM = ("https://raw.githubusercontent.com/BerriAI/litellm/" + LITELLM_COMMIT
           + "/model_prices_and_context_window.json")
CACHE = os.path.expanduser("~/.cache/ai-dev-prices")

ANTHROPIC_MODELS = ["Claude Opus 5.5", "Claude Sonnet 5.5", "Claude Haiku 4.5"]
LITELLM_MODELS = {
    "anthropic": ["claude-opus-5-5", "claude-sonnet-5-5", "claude-haiku-4-5"],
    "openai": ["gpt-5.5", "gpt-5.4", "gpt-5.4-mini", "gpt-5.4-nano"],
    "google": ["gemini/gemini-pro-latest", "gemini/gemini-3.5-flash", "gemini/gemini-3.5-flash-lite"],
}


def fetch(url, name):
    os.makedirs(CACHE, exist_ok=True)
    path = os.path.join(CACHE, name)
    if not os.path.exists(path):
        # The pricing page refuses Python's default User-Agent with a 403.
        req = urllib.request.Request(url, headers={"User-Agent": "curl/8.5.0"})
        with urllib.request.urlopen(req) as r, open(path + ".part", "wb") as f:
            f.write(r.read())
        os.rename(path + ".part", path)
    return path


def anthropic_sheet():
    today = datetime.date.today().isoformat()
    page = open(fetch(ANTHROPIC, f"anthropic-{today}.html"), encoding="utf-8").read()
    print(f"anthropic: {ANTHROPIC}, read {today}")
    print(f"  {'model':<20}{'input':>8}{'output':>8}{'cache write 5m':>16}{'cache read':>12}")
    for row in re.findall(r"<tr.*?</tr>", page, flags=re.S):
        cells = [re.sub(r"\s+", " ", html.unescape(re.sub(r"<[^>]+>", " ", c))).strip()
                 for c in re.findall(r"<t[dh].*?</t[dh]>", row, flags=re.S)]
        for name in ANTHROPIC_MODELS:
            if len(cells) == 6 and cells[0].startswith(name + " "):
                p = [c.replace(" / MTok", "") for c in cells[1:]]
                print(f"  {name:<20}{p[0]:>8}{p[1]:>8}{p[2]:>16}{p[4]:>12}")


def litellm_sheet(provider):
    data = json.load(open(fetch(LITELLM, f"litellm-{LITELLM_COMMIT[:12]}.json")))
    print(f"{provider}: LiteLLM at commit {LITELLM_COMMIT[:12]}")
    print(f"  {'model':<30}{'input':>8}{'output':>8}{'cache read':>12}{'window':>10}{'max out':>9}")
    for m in LITELLM_MODELS[provider]:
        v = data[m]
        def per_m(key):
            x = v.get(key)
            return "-" if x is None else "$%g" % round(x * 1e6, 4)
        print(f"  {m:<30}{per_m('input_cost_per_token'):>8}{per_m('output_cost_per_token'):>8}"
              f"{per_m('cache_read_input_token_cost'):>12}{v.get('max_input_tokens', 0):>10}"
              f"{v.get('max_output_tokens', 0):>9}")


if __name__ == "__main__":
    which = sys.argv[1:] or ["anthropic", "openai", "google"]
    for w in which:
        if w == "anthropic":
            anthropic_sheet()
        litellm_sheet(w)
