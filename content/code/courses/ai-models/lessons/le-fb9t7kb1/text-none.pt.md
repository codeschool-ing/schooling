---
title: Quando o texto é None
version: 1
---

O `r.text` é uma conveniência, e o tipo dele diz o que ele pode ser. Este é o código da própria
biblioteca para ele:

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

`Optional[str]`, e a primeira coisa que ele faz é devolver **`None`** quando o primeiro candidato não
tem conteúdo ou não tem partes. Uma resposta pode chegar assim: um 200, um candidato e nenhum texto,
porque a geração parou antes de escrever qualquer coisa. Por que parou está no `finish_reason` do
candidato, e a biblioteca lista os motivos que conhece:

```
ana@desk:~/desk$ python -c "from google.genai import types; print(types.FinishReason.__members__.keys())"
dict_keys(['FINISH_REASON_UNSPECIFIED', 'STOP', 'MAX_TOKENS', 'SAFETY', 'RECITATION', 'LANGUAGE', 'OTHER', 'BLOCKLIST', 'PROHIBITED_CONTENT', 'SPII', 'MALFORMED_FUNCTION_CALL', 'IMAGE_SAFETY', 'UNEXPECTED_TOOL_CALL', 'TOO_MANY_TOOL_CALLS', 'IMAGE_PROHIBITED_CONTENT', 'NO_IMAGE', 'IMAGE_RECITATION', 'IMAGE_OTHER', 'CONTINUATION'])
```

`STOP` é o fim comum e `MAX_TOKENS` o limite, como o `stop_reason` do Claude na aula 17. O resto são
motivos pelos quais um provedor recusou terminar: `SAFETY` e `PROHIBITED_CONTENT` pelos filtros de
conteúdo dele, `RECITATION` por saída que pode repetir uma fonte, `SPII` por conteúdo que pode ter
informação pessoal sensível. Se um e-mail comum de cliente chega a esbarrar num deles não é algo que
esta máquina pôde testar, então o programa precisa estar pronto de qualquer jeito.

A falha que vem depois é previsível. Um programa que escreve `r.text.strip()` levanta
`AttributeError` num `None`, no fundo do laço de classificação; um que escreve `label = r.text` guarda
`None` como rótulo e o passa adiante. De um jeito ou de outro, a causa fica a três objetos de
distância do erro. **Leia o `finish_reason` antes do `text`**, e decida o que cada motivo significa
para a mesa: um `MAX_TOKENS` é um limite a aumentar, um `SAFETY` é um e-mail para uma pessoa
classificar. O harness da aula 5 conta os dois como falhas, o que é certo para a pontuação, e o
código de produção precisa fazer algo mais útil com eles do que quebrar.

Toda API deste curso tem o mesmo campo com outro nome, `finish_reason`, `stop_reason`,
`done_reason`, `status`, e a mesma regra vale para todas.
