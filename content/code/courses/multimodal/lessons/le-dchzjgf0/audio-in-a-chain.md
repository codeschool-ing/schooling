---
title: A recorded call, in one chain
version: 1
---

A chain is worth having when several steps run in order and each needs the last one's output. Turning a recorded call into a support ticket is that shape: transcribe, ask for fields, check them.

```schooling-example
{
  "language": "python",
  "file": "ticket.py",
  "parts": [
    {
      "code": "\"\"\"A recorded call to a support ticket: transcribe, then ask for fields, then check them.\"\"\"\nimport re\nimport sys\n\nfrom langchain_core.prompts import ChatPromptTemplate\nfrom langchain_core.runnables import RunnableLambda\nfrom langchain_openai import ChatOpenAI\nfrom openai import OpenAI\nfrom pydantic import BaseModel\n\n\n"
    },
    {
      "code": "class Ticket(BaseModel):\n    order: str\n    title: str\n    problem: str\n    refund_cents: int\n\n\n",
      "note": "**The ticket's shape, as a Pydantic model.** `with_structured_output` turns it into a JSON schema for the request and parses the reply back into it."
    },
    {
      "code": "def transcribe(path):\n    with open(path, \"rb\") as f:\n        return {\"transcript\": OpenAI(base_url=\"http://localhost:8700/v1\").audio.transcriptions.create(\n            model=\"whisper-base\", file=f, response_format=\"text\")}\n\n\n",
      "note": "**The audio step is the provider's own SDK**, the transcriptions endpoint of lesson 10, wrapped in a plain function. It returns a dictionary so the next step can name what it needs."
    },
    {
      "code": "prompt = ChatPromptTemplate.from_messages([\n    (\"system\", \"Turn this support call into a support ticket. Use only what the caller and agent say.\"),\n    (\"user\", \"{transcript}\")])\nllm = ChatOpenAI(model=\"qwen2.5vl:3b\").with_structured_output(Ticket, method=\"json_schema\")\nchain = RunnableLambda(transcribe) | {\"transcript\": lambda x: x[\"transcript\"],\n                                      \"ticket\": prompt | llm}\n\n",
      "note": "**The chain.** `RunnableLambda` makes the function a step, the `|` joins steps, and the dictionary runs two branches on the same input: one passes the transcript through, the other turns it into a ticket."
    },
    {
      "code": "out = chain.invoke(sys.argv[1])\nticket, heard = out[\"ticket\"], out[\"transcript\"]\nprint(ticket)\n\n",
      "note": "**One call runs it all**, and keeping the transcript beside the ticket is what makes the next part possible."
    },
    {
      "code": "# The check the chain does not do: is every value the ticket states in what was heard?\ndef plain(s):\n    return re.sub(r\"[^0-9a-z]\", \"\", s.lower())\n\nprint(\"order  in transcript:\", plain(ticket.order) in plain(heard))\nprint(\"title  in transcript:\", plain(ticket.title) in plain(heard))",
      "note": "**The check no framework adds for you**: every value the ticket states should be somewhere in what was heard. Letters and digits only, so `M-1042` and `M1042` count as the same order."
    }
  ]
}
```

```
@@ticket@@
```

The log shows the two requests the chain made: a transcription by Whisper base, which is real, and a chat request answered by `l12-ticket`, **a rule the course wrote**. The ticket says what a model might say about this call; no model said it.

Then the check, and it found something. The order passes: `M-1042` and the transcript's `M1042` are the same letters and digits. **The title fails**, because lesson 7's Whisper base heard "Dom Kazmuro" and "Dom Casmorrow", never "Dom Casmurro". Here the ticket is right and the transcript is wrong, and the check cannot know that. It can only say that the ticket states something nobody was heard saying, which is exactly when a person should look.

Two things the chain did not do. It did not **send audio to a chat model**: LangChain's blocks can carry audio, for the few chat models that take it, and this chain transcribes first instead, so the text can be kept, searched and checked. And it did not **check anything**: the comparison at the end is plain Python, outside the chain, because no framework knows which fields of your ticket must come from the recording.
