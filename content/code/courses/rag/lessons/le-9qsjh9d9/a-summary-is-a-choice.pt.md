---
title: Um resumo é uma escolha
version: 2
---

O `compact.py` pede ao modelo um resumo num número dado de palavras:

```schooling-example
{
  "language": "python",
  "file": "compact.py",
  "parts": [
    {
      "code": "\"\"\"Making a long conversation short: pin what must survive word for word, summarise the rest, keep the\nlatest turns as they were.\"\"\"\nimport re\n\nimport tiktoken\nfrom memory import ORDER\nfrom openai import OpenAI\n\nclient = OpenAI()\nenc = tiktoken.get_encoding(\"cl100k_base\")\n# A sentence is pinned when it carries something a later turn may need exactly: an identifier, or a\n# choice the customer made. The patterns are the team's, written down and tested like any code.\nPIN = re.compile(rf\"{ORDER.pattern}|\\b(only|please|would like|want|instead|should go to)\\b\", re.I)\nKEEP = 3",
      "note": "Uma frase é fixada quando leva um número de pedido ou uma das poucas palavras que marcam uma escolha. A regra fica escrita junto do código, para poder ser lida, discutida e testada."
    },
    {
      "code": "def tokens(text):\n    return len(enc.encode(text))",
      "note": "Tokens contados com o tiktoken, como na aula 12."
    },
    {
      "code": "def sentences(text):\n    return [s for s in re.split(r\"(?<=[.!?])\\s+(?=[A-Z])\", text.strip()) if s]",
      "note": "Frases, divididas no fim de cada uma."
    },
    {
      "code": "def summarise(turns, words):\n    \"\"\"The model's summary of the turns, in at most WORDS words. The turns go in as one text to\n    summarise, never as messages: sent as messages, they are a conversation, and a model answers it.\"\"\"\n    reply = client.chat.completions.create(model=\"llama3.2:3b\", temperature=0, messages=[\n        {\"role\": \"system\", \"content\": f\"Summarise the text the user sends in at most {words} words. \"\n                                      \"Reply with the summary and nothing else.\"},\n        {\"role\": \"user\", \"content\": \"\\n\".join(turns)}])\n    return reply.choices[0].message.content",
      "note": "O resumo é do modelo: a instrução e o limite de palavras na mensagem de sistema, e os turnos como um texto só na mensagem do usuário. Mandados como mensagens próprias, os turnos eram uma conversa, e o llama3.2:3b respondeu a ela em vez de resumi-la. Quais detalhes o resumo mantém é escolha do modelo."
    },
    {
      "code": "def pinned(turns):\n    return [s for t in turns for s in sentences(t) if PIN.search(s)]",
      "note": "Frases fixadas são mantidas palavra por palavra, nunca resumidas."
    },
    {
      "code": "def compact(turns, words=30, keep=KEEP):\n    \"\"\"The pinned sentences of the older turns, a summary of what is left of them, and the last KEEP\n    turns as they were.\"\"\"\n    older, recent = turns[:-keep], turns[-keep:]\n    pins = pinned(older)\n    rest = [s for t in older for s in sentences(t) if s not in pins]\n    return {\"pinned\": pins, \"summary\": summarise(rest, words) if rest else \"\", \"recent\": recent}",
      "note": "Os turnos mais antigos são divididos: o que está fixado fica, o resto vai para o resumidor. Os três últimos turnos ficam como estavam, porque a próxima resposta provavelmente é sobre eles."
    },
    {
      "code": "def text_of(compacted):\n    return \"\\n\".join(compacted[\"pinned\"] + [compacted[\"summary\"]] + compacted[\"recent\"])",
      "note": "A conversa compactada como um texto só, na ordem em que um prompt a levaria."
    }
  ]
}
```

Aqui está o resumo do llama3.2:3b dos onze primeiros turnos da Beatriz em no máximo 40 palavras:

```schooling-example
{
  "language": "python",
  "file": "one.py",
  "parts": [
    {
      "code": "import json\nimport sys\n\nfrom compact import summarise\n\nturns = [json.loads(line)[\"text\"] for line in open(\"data/chat-a.jsonl\")]\nprint(summarise(turns[:11], int(sys.argv[1])))",
      "note": "Os onze primeiros turnos da Beatriz, resumidos em tantas palavras quantas a linha de comando disser."
    }
  ]
}
```
```
ana@vm:~/rag$ python one.py 40
Beatriz Costa's order MG-20481937 had two issues: a water-damaged Persuasion book and a wrong book, Mansfield Park instead of Middlemarch. She wants a replacement Persuasion and a refund for Middlemarch, with replacement to be sent to Rua das Flores 120, Curitiba.
```

Duas frases, fluentes e verdadeiras. Elas mantiveram o número do pedido, os dois livros, o que ela
quer para cada um e o endereço novo. **Largaram uma coisa, e é a de que um atendente precisa antes de
responder**: a Beatriz pediu para ser contatada só por e-mail, porque não pode atender telefonemas no
trabalho, e nada no resumo diz isso. A próxima resposta pode prometer um telefonema.

Este resumo escolheu bem, com 40 palavras, nesta conversa, nesta execução. **O ponto não são as
escolhas deste resumo; é que todo resumo é uma escolha**, feita por algo que não sabe de quais detalhes
o próximo turno vai precisar, e que um resumo que se lê perfeitamente não diz nada do que deixou de
fora. A próxima seção mede a escolha em vez de lê-la.
