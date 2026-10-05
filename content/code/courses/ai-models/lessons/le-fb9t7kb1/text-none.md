---
title: When the text is None
version: 1
---

`r.text` is a convenience, and its type says what it can be. This is the library's own code for it:

```
ana@desk:~/desk$ python -c "import inspect; from google.genai import types; print(inspect.getsource(types.GenerateContentResponse._get_text))" | head -24
  def _get_text(self) -> Optional[str]:
    """Returns the concatenation of all text parts in the response.

    This is an internal method that allows customizing or disabling the warning
    message.

    Returns:
      The concatenation of all text parts in the response.
    """
    if (
        not self.candidates
        or not self.candidates[0].content
        or not self.candidates[0].content.parts
    ):
      return None
    global _response_text_warning_logged
    if len(self.candidates) > 1 and not _response_text_warning_logged:
      logger.warning(
          f'there are {len(self.candidates)} candidates, returning text result'
          ' from the first candidate. Access response.candidates directly to'
          ' get the result from other candidates.'
      )
      _response_text_warning_logged = True
    text = ''
```

`Optional[str]`, and the first thing it does is return **`None`** when the first candidate has no
content or no parts. A reply can arrive that way: a 200, a candidate, and no text, because
generation stopped before writing any. Why it stopped is in the candidate's `finish_reason`, and
the library lists the reasons it knows:

```
ana@desk:~/desk$ python -c "from google.genai import types; print(types.FinishReason.__members__.keys())"
dict_keys(['FINISH_REASON_UNSPECIFIED', 'STOP', 'MAX_TOKENS', 'SAFETY', 'RECITATION', 'LANGUAGE', 'OTHER', 'BLOCKLIST', 'PROHIBITED_CONTENT', 'SPII', 'MALFORMED_FUNCTION_CALL', 'IMAGE_SAFETY', 'UNEXPECTED_TOOL_CALL', 'TOO_MANY_TOOL_CALLS', 'IMAGE_PROHIBITED_CONTENT', 'NO_IMAGE', 'IMAGE_RECITATION', 'IMAGE_OTHER', 'CONTINUATION'])
```

`STOP` is the ordinary end and `MAX_TOKENS` the limit, as with Claude's `stop_reason` in lesson 17.
The rest are reasons a provider declined to finish: `SAFETY` and `PROHIBITED_CONTENT` for its
content filters, `RECITATION` for output that may repeat a source, `SPII` for content that may
contain sensitive personal information. Whether an ordinary customer e-mail ever trips one of them
is not something this machine could test, so the program has to be ready for it either way.

The failure that follows is predictable. A program that writes `r.text.strip()` raises
`AttributeError` on a `None`, deep in the sorting loop; one that writes `label = r.text` stores a
`None` as the label and passes it on. Either way the cause is three objects away from the error.
**Read `finish_reason` before `text`**, and decide what each reason means for the desk: a
`MAX_TOKENS` is a limit to raise, a `SAFETY` is an e-mail for a person to sort. Lesson 5's harness
counts both as failures, which is right for scoring, and the production code has to do something
more useful with them than crash.

Every API in this course has the same field under its own name, `finish_reason`, `stop_reason`,
`done_reason`, `status`, and the same rule applies to all of them.
