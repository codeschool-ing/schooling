---
title: Uma pergunta, três SDKs
version: 1
---

Anthropic, OpenAI e Google publicam cada um uma API e um SDK para ela, e os três concordam na ideia:
**uma instrução de sistema, uma conversa, um limite para a resposta e uma resposta com contagens de
tokens**. Eles discordam em quase todo nome. Esta aula põe os três lado a lado e depois trata do que
rodar contra qualquer um deles envolve: chaves, limites de taxa, repetições, preços e o que acontece
com os dados que você manda.

Toda requisição aqui vai ao labllm, que fala os três formatos. Os SDKs são os de verdade e mandam o
que mandariam aos provedores de verdade; as respostas foram escritas pelo curso.

## A mesma pergunta, de três jeitos

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
      "note": "**A mesma instrução de sistema e a mesma pergunta para os três**, para só os SDKs mudarem."
    },
    {
      "code": "def ask_anthropic():\n    r = anthropic.Anthropic().messages.create(\n        model=\"scripted-1\", max_tokens=300, system=SYSTEM,\n        messages=[{\"role\": \"user\", \"content\": QUESTION}])\n    return r.content[0].text, r.usage.input_tokens, r.usage.output_tokens, r.stop_reason\n\n\n",
      "note": "**Anthropic**: o `system` é um argumento próprio, e o `max_tokens` é obrigatório."
    },
    {
      "code": "def ask_openai():\n    r = openai.OpenAI().chat.completions.create(\n        model=\"scripted-1\", max_completion_tokens=300,\n        messages=[{\"role\": \"system\", \"content\": SYSTEM}, {\"role\": \"user\", \"content\": QUESTION}])\n    return r.choices[0].message.content, r.usage.prompt_tokens, r.usage.completion_tokens, r.choices[0].finish_reason\n\n\n",
      "note": "**OpenAI**: a instrução de sistema é a primeira mensagem, e o limite é `max_completion_tokens`."
    },
    {
      "code": "def ask_google():\n    client = genai.Client(http_options=types.HttpOptions(base_url=os.environ[\"GEMINI_BASE_URL\"]))\n    r = client.models.generate_content(\n        model=\"scripted-1\", contents=QUESTION,\n        config=types.GenerateContentConfig(\n            system_instruction=SYSTEM, max_output_tokens=300,\n            automatic_function_calling=types.AutomaticFunctionCallingConfig(disable=True)))\n    u = r.usage_metadata\n    return r.text, u.prompt_token_count, u.candidates_token_count, r.candidates[0].finish_reason\n\n\n",
      "note": "**Google**: o endereço do labllm vai em `http_options`; a instrução e o limite vão num objeto de configuração, com a chamada automática de funções desligada."
    },
    {
      "code": "for name, ask in [(\"anthropic\", ask_anthropic), (\"openai\", ask_openai), (\"google\", ask_google)]:\n    text, n_in, n_out, why = ask()\n    print(f\"{name:9} {n_in:3} in {n_out:3} out  {why!s:18} {text[:34]}…\")",
      "note": "**Cada função devolve as mesmas quatro coisas**, para o laço imprimi-las num formato só."
    }
  ]
}
```

```
ana@dev:~/shop$ python three.py
anthropic  20 in  82 out  end_turn           The cart stores prices as integer …
openai     20 in  82 out  stop               The cart stores prices as integer …
google     20 in  82 out  FinishReason.STOP  The cart stores prices as integer …
```

Mesmo texto, mesmas contagens, três jeitos de dizer que a resposta terminou. **As contagens batem só
porque o labllm conta toda requisição com um tokenizador só.** Os provedores de verdade contam cada
um com o seu, então o mesmo prompt dá um número diferente de tokens em cada um, e um preço por
milhão de tokens só se compara depois de você contar o seu próprio texto com o contador de cada
provedor.

## Onde ficam as diferenças

| | Anthropic | OpenAI | Google |
| --- | --- | --- | --- |
| instrução de sistema | `system=` | uma mensagem com `role: "system"` | `system_instruction` na configuração |
| limite da resposta | `max_tokens`, obrigatório | `max_completion_tokens` | `max_output_tokens` |
| texto da resposta | `content[0].text` | `choices[0].message.content` | `.text` |
| tokens de entrada | `usage.input_tokens` | `usage.prompt_tokens` | `usage_metadata.prompt_token_count` |
| por que parou | `stop_reason` | `finish_reason` | `candidates[0].finish_reason` |

**O `max_tokens` é o que morde.** A API da Anthropic recusa uma requisição sem ele; as outras duas
têm padrões. Um código levado de um SDK para outro continua rodando e passa, sem aviso, a produzir
respostas de outro tamanho.

## Uma diferença que não é um nome

O SDK do Google roda funções Python por você: passe funções como ferramentas e ele mesmo as chama e
devolve os resultados, o que ele chama de chamada automática de funções. **Esse é o trabalho do host
da aula 7, feito por uma biblioteca**, sem as verificações da aula 8. O `three.py` a desliga, o que
também cala o aviso que o SDK imprime sobre ela na primeira chamada. Religá-la é uma decisão sobre
quem roda as suas ferramentas, não sobre conveniência.
