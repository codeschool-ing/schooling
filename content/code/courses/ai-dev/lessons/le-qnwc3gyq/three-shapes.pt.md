---
title: Uma pergunta, três SDKs
version: 2
---

Anthropic, OpenAI e Google publicam cada um uma API e um SDK para ela, e os três concordam na ideia:
**uma instrução de sistema, uma conversa, um limite para a resposta e uma resposta com contagens de
tokens**. Eles discordam em quase todo nome. Esta aula põe os três lado a lado e depois trata do que
rodar contra qualquer um deles envolve: chaves, limites de taxa, repetições, preços e o que acontece
com os dados que você manda.

Toda requisição aqui vai ao Ollama, que fala o formato da Anthropic e o da OpenAI. Os SDKs são os de
verdade e mandam o que mandariam aos provedores de verdade. O Ollama não fala o do Google, e a máquina
da gravação não tem chave do Google, então o terceiro é mostrado e não roda.

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
      "code": "def ask_anthropic():\n    r = anthropic.Anthropic().messages.create(\n        model=\"llama3.2:3b\", max_tokens=300, system=SYSTEM,\n        messages=[{\"role\": \"user\", \"content\": QUESTION}])\n    n_in = r.usage.input_tokens + (r.usage.cache_read_input_tokens or 0)  # lesson 2 section 07\n    return r.content[0].text, n_in, r.usage.output_tokens, r.stop_reason\n\n\n",
      "note": "**Anthropic**: `system` é um argumento próprio, e `max_tokens` é obrigatório. O Ollama informa à parte o pedaço do prompt que reaproveitou, então a conta o soma de volta, como na aula 2 seção 07."
    },
    {
      "code": "def ask_openai():\n    r = openai.OpenAI().chat.completions.create(\n        model=\"llama3.2:3b\", max_completion_tokens=300,\n        messages=[{\"role\": \"system\", \"content\": SYSTEM}, {\"role\": \"user\", \"content\": QUESTION}])\n    return r.choices[0].message.content, r.usage.prompt_tokens, r.usage.completion_tokens, r.choices[0].finish_reason\n\n\n",
      "note": "**OpenAI**: a instrução de sistema é a primeira mensagem, e o limite é `max_completion_tokens`."
    },
    {
      "code": "def ask_google():\n    r = genai.Client().models.generate_content(\n        model=\"gemini-3.5-flash\", contents=QUESTION,\n        config=types.GenerateContentConfig(\n            system_instruction=SYSTEM, max_output_tokens=300,\n            automatic_function_calling=types.AutomaticFunctionCallingConfig(disable=True)))\n    u = r.usage_metadata\n    return r.text, u.prompt_token_count, u.candidates_token_count, r.candidates[0].finish_reason\n\n\n",
      "note": "**Google**: a instrução e o limite vão num objeto de configuração, com a chamada automática de funções desligada. Não há endereço para trocar: o Ollama não tem endpoint do Gemini, então este só roda contra o próprio Google, com uma chave."
    },
    {
      "code": "for name, ask in [(\"anthropic\", ask_anthropic), (\"openai\", ask_openai), (\"google\", ask_google)]:\n    if name == \"google\" and \"GEMINI_API_KEY\" not in os.environ:\n        print(f\"{name:9} skipped: no GEMINI_API_KEY, and Ollama has no Gemini endpoint\")\n        continue\n    text, n_in, n_out, why = ask()\n    print(f\"{name:9} {n_in:3} in {n_out:3} out  {why!s:18} {' '.join(text.split())[:34]}…\")\n",
      "note": "**Cada função devolve as mesmas quatro coisas**, então o laço consegue imprimi-las num formato só, e um provedor sem chave é dito pulado em vez de deixado de fora em silêncio."
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

Duas respostas, dois jeitos de dizer que a resposta terminou, e **os mesmos 43 tokens de entrada**,
porque as duas foram ao mesmo modelo atrás de um servidor e foram contadas pelo único tokenizador
dele. Os provedores de verdade contam cada um com o seu, então o mesmo prompt dá um número diferente
de tokens em cada um. Um preço por milhão de tokens só se compara depois de você contar o seu próprio
texto com o contador de cada provedor.

As respostas diferem porque cada uma é um sorteio, e a segunda começa com "The carton stores", que é
o modelo lendo errado "cart stores", e com fluência.

**O Google foi pulado, e o programa diz isso.** Um provedor deixado de fora de uma comparação sem uma
palavra é como uma tabela acaba comparando duas coisas enquanto o título diz três.

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
