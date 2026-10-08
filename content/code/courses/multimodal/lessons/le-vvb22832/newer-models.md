---
title: Whisper and the models after it
version: 2
---

This lesson's title is the **Whisper API**, and `whisper-1` is still one of the names the endpoint takes. It now has company. LiteLLM's sheet, read with lesson 3's `prices.py`, lists the transcription models like this:

```
ana@lab:~/mm$ python prices.py find transcribe | grep " openai "
gpt-4o-mini-transcribe                       openai                     2027-02-26
gpt-4o-mini-transcribe-2025-03-20            openai                     2027-01-20
gpt-4o-mini-transcribe-2025-12-15            openai                     
gpt-4o-transcribe                            openai                     2027-02-26
gpt-4o-transcribe-diarize                    openai                     2027-02-26
gpt-live-transcribe                          openai                     
gpt-transcribe                               openai                     
ana@lab:~/mm$ for m in whisper-1 gpt-4o-transcribe gpt-4o-mini-transcribe; do printf "%-24s" $m; python prices.py show $m | grep -E "input_cost_per_second|input_cost_per_token|deprecation" | tr -s " " | tr "\n" " "; echo; done
whisper-1               deprecation_date 2027-02-26 input_cost_per_second 0.0001 
gpt-4o-transcribe       deprecation_date 2027-02-26 input_cost_per_second 0.0001 input_cost_per_token 2.5e-06 
gpt-4o-mini-transcribe  deprecation_date 2027-02-26 input_cost_per_second 5e-05 input_cost_per_token 1.25e-06 
```

The sheet has seven OpenAI entries with *transcribe* in the name. Two are dated snapshots of the mini model, and one of those ends earlier than the name without a date, on 20 January 2027. `gpt-transcribe` and `gpt-live-transcribe` carry no deprecation date at all.

**`whisper-1` is priced per second of audio**, 0.0001 dollars, which is 0.006 dollars a minute and 0.36 dollars an hour. The two `gpt-4o` transcription models are priced per token: 2.5e-06 dollars an input token for `gpt-4o-transcribe`, which is 2.50 dollars a million, and half that for the mini model. The sheet also gives them a per-second figure, the same 0.0001 for `gpt-4o-transcribe` and half that for the mini. **All three carry a deprecation date of 26 February 2027.** None of them was called for this course, since that takes a paid key, and lesson 13 turns these prices into the cost of a month of support calls.

What changes when moving from `whisper-1` to the newer models, according to OpenAI's documentation, is worth checking against your own test set rather than taking on trust:

- **Accuracy**: OpenAI reports lower error rates for the newer models; lesson 7's test set is how you find out on your calls.
- **Response shapes**: the documentation lists no `srt`, `vtt` or `verbose_json` for the newer models (section 03), so a pipeline that needs timed segments would have to get them another way.
- **Streaming**: the newer models can stream text as it is decoded, which matters for live captions and voice agents (lesson 6's latency).

The same habits as lesson 9 apply: name the model in one place, read the deprecation dates every quarter, and re-run the test set before switching. A transcriber that is better on average and worse on your shop's names is worse for you (lesson 7).
