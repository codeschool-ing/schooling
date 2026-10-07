---
title: One question, three SDKs
version: 2
---

Anthropic, OpenAI and Google each publish an API and an SDK for it, and the three agree on the idea:
**a system instruction, a conversation, a limit on the reply, and a reply with token counts**. They
disagree on almost every name. This lesson puts the three side by side, then deals with what
running against any of them involves: keys, rate limits, retries, prices, and what happens to the
data you send.

Every request here goes to Ollama, which speaks Anthropic's format and OpenAI's. The SDKs are the
real ones and send what they would send to the real providers. Ollama does not speak Google's, and
the recording machine has no key for Google, so the third one is shown and not run.

## The same question, three ways

```schooling-example
{
  "language": "python",
  "file": "three.py",
  "parts": [
    {
      "code": "\"\"\"One question, three providers, each through its own SDK.\"\"\"\nimport os\n\nimport anthropic\nimport openai\nfrom google import genai\nfrom google.genai import types\n\n"
    },
    {
      "code": "SYSTEM = \"Answer in one paragraph.\"\nQUESTION = \"Explain in a paragraph why the cart stores prices in cents.\"\n\n\n",
      "note": "**The same system instruction and question for all three**, so only the SDKs differ."
    },
    {
      "code": "def ask_anthropic():\n    r = anthropic.Anthropic().messages.create(\n        model=\"llama3.2:3b\", max_tokens=300, system=SYSTEM,\n        messages=[{\"role\": \"user\", \"content\": QUESTION}])\n    n_in = r.usage.input_tokens + (r.usage.cache_read_input_tokens or 0)  # lesson 2 section 07\n    return r.content[0].text, n_in, r.usage.output_tokens, r.stop_reason\n\n\n",
      "note": "**Anthropic**: `system` is its own argument, and `max_tokens` is required. Ollama reports the part of the prompt it reused apart, so the count adds it back, as in lesson 2 section 07."
    },
    {
      "code": "def ask_openai():\n    r = openai.OpenAI().chat.completions.create(\n        model=\"llama3.2:3b\", max_completion_tokens=300,\n        messages=[{\"role\": \"system\", \"content\": SYSTEM}, {\"role\": \"user\", \"content\": QUESTION}])\n    return r.choices[0].message.content, r.usage.prompt_tokens, r.usage.completion_tokens, r.choices[0].finish_reason\n\n\n",
      "note": "**OpenAI**: the system instruction is the first message, and the limit is `max_completion_tokens`."
    },
    {
      "code": "def ask_google():\n    r = genai.Client().models.generate_content(\n        model=\"gemini-3.5-flash\", contents=QUESTION,\n        config=types.GenerateContentConfig(\n            system_instruction=SYSTEM, max_output_tokens=300,\n            automatic_function_calling=types.AutomaticFunctionCallingConfig(disable=True)))\n    u = r.usage_metadata\n    return r.text, u.prompt_token_count, u.candidates_token_count, r.candidates[0].finish_reason\n\n\n",
      "note": "**Google**: the instruction and the limit go in a config object, with automatic function calling turned off. There is no address to change: Ollama has no Gemini endpoint, so this one only runs against Google itself, with a key."
    },
    {
      "code": "for name, ask in [(\"anthropic\", ask_anthropic), (\"openai\", ask_openai), (\"google\", ask_google)]:\n    if name == \"google\" and \"GEMINI_API_KEY\" not in os.environ:\n        print(f\"{name:9} skipped: no GEMINI_API_KEY, and Ollama has no Gemini endpoint\")\n        continue\n    text, n_in, n_out, why = ask()\n    print(f\"{name:9} {n_in:3} in {n_out:3} out  {why!s:18} {' '.join(text.split())[:34]}…\")\n",
      "note": "**Each function returns the same four things**, so the loop can print them in one format, and a provider with no key is said to be skipped rather than left out in silence."
    }
  ]
}
```

```
ana@dev:~/shop$ python three.py
anthropic  43 in 156 out  end_turn           The practice of storing prices in …
openai     43 in 128 out  stop               The carton stores in the US often …
google    skipped: no GEMINI_API_KEY, and Ollama has no Gemini endpoint
```

Two replies, two ways of saying the reply ended, and **the same 43 input tokens**, because both
went to the same model behind one server and were counted by its one tokenizer. Real providers each
count with their own, so the same prompt is a different number of tokens at each. A price per million
tokens is only comparable after you count your own text with each provider's counter.

The replies differ because each is a draw, and the second one starts with "The carton stores", which
is the model misreading "cart stores", and fluently.

**Google was skipped, and the program says so.** A provider left out of a comparison without a word is
how a table ends up comparing two things while its title says three.

## Where the differences are

| | Anthropic | OpenAI | Google |
| --- | --- | --- | --- |
| system instruction | `system=` | a message with `role: "system"` | `system_instruction` in the config |
| reply limit | `max_tokens`, required | `max_completion_tokens` | `max_output_tokens` |
| reply text | `content[0].text` | `choices[0].message.content` | `.text` |
| input tokens | `usage.input_tokens` | `usage.prompt_tokens` | `usage_metadata.prompt_token_count` |
| why it stopped | `stop_reason` | `finish_reason` | `candidates[0].finish_reason` |

**`max_tokens` is the one that bites.** Anthropic's API refuses a request without it; the other two
have defaults. Code moved from one SDK to another keeps running and quietly starts producing
replies of a different length.

## One difference that is not a name

Google's SDK will run Python functions for you: pass functions as tools and it calls them itself
and sends back the results, which it calls automatic function calling. **That is the host's job
from lesson 7, done by a library**, without the checks of lesson 8. `three.py` turns it off, which
also silences the warning the SDK prints about it on the first call. Whether to turn it back on is
a decision about who runs your tools, not about convenience.
