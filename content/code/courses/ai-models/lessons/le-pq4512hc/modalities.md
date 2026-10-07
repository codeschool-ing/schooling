---
title: More than text in, and the web as a tool
version: 1
---

The family's other distinguishing line is what it accepts. Flash 3.5's entry:

```
ana@desk:~/desk$ python sheet.py show gemini/gemini-3.5-flash | grep -E "^(supported_|input_cost_per_audio|search_context|google_maps)"
google_maps_grounding_cost_per_query       0.014
input_cost_per_audio_token                 1.5e-06
input_cost_per_audio_token_priority        2.7e-06
search_context_cost_per_query              {'search_context_size_low': 0.014, 'search_context_size_medium': 0.014, 'search_context_size_high': 0.014}
supported_endpoints                        ['/v1/chat/completions', '/v1/completions', '/v1/batch']
supported_modalities                       ['text', 'image', 'audio', 'video']
supported_output_modalities                ['text']
```

**Four kinds of input, one kind of output.** Text, images, audio and video go in; text comes out.
Audio has its own price per token, $1.50 a million on Flash 3.5 against the same $1.50 for text at
this tier, which is the sheet recording that audio is tokenised and billed like any other input.
For Lantern Books that opens tasks nobody has asked for yet, a voicemail sorted like an e-mail or a
photo of a damaged book attached to a refund request, and leaves the text tasks exactly where they
were. `multimodal`, later in the `ai` track, is where images, audio and video become the
subject.

## Grounding is priced per query

Two more lines record tools the model can use while answering, at a price per use rather than per
token:

- `search_context_cost_per_query`: grounding a reply in a web search, **$0.014 a query** whatever
  the amount of context requested;
- `google_maps_grounding_cost_per_query`: the same for map data, at the same price.

A grounded request costs its tokens **plus** the query. At 400 requests a day that would be $5.60
a day, $168 a month, for searches alone, many times the $8.02 lesson 4 priced ana's whole drafting
task at. Grounding is the answer to lesson 1 section 10's first gap, public facts after the cutoff,
and ana's tasks do not have that gap. **A feature priced per use is a feature to switch on per
task**, not per account.

## The last line

`supported_endpoints` lists `/v1/chat/completions`, the OpenAI-shaped path. The sheet is saying
Gemini can also be called in the shape lesson 20 teaches, as well as through Google's own API in
lesson 18.
