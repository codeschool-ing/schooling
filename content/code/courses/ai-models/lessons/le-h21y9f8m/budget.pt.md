---
title: O limite no seu próprio código
version: 1
---

Todo limite das seções 03 e 04 é definido no servidor de outra pessoa, e só conhece o dinheiro. O
que conhece o que o programa *pretendia* fazer precisa estar no programa. A classificação da ana tem
um defeito de um tipo comum: quando a resposta não é um dos cinco rótulos, ela pergunta de novo. O
`budget.py` carrega o defeito, e um orçamento que conta o que cada resposta diz ter usado. Suba o
relay de novo sem `--rpm` antes, para que só o orçamento o pare:

```schooling-example
{
  "language": "python",
  "file": "budget.py",
  "parts": [
    {
      "code": "import json\n\nfrom openai import OpenAI\n\n# gpt-5.4-mini's prices from lesson 8's sheet, dollars per million tokens\nPRICE_IN, PRICE_OUT = 0.75, 4.50\nLABELS = {\"order-status\", \"refund\", \"address-change\", \"product-question\", \"other\"}\n\n\n",
      "note": "Os preços do gpt-5.4-mini na tabela, e os cinco rótulos entre os quais uma resposta precisa estar."
    },
    {
      "code": "class Budget:\n    \"\"\"Adds up what each response says it used; refuses the next call once the money is gone.\"\"\"\n\n    def __init__(self, dollars):\n        self.left, self.calls = dollars, 0\n\n    def charge(self, usage):\n        self.calls += 1\n        self.left -= (usage.prompt_tokens * PRICE_IN + usage.completion_tokens * PRICE_OUT) / 1e6\n        if self.left < 0:\n            raise RuntimeError(f\"budget spent after {self.calls} calls\")\n\n\n",
      "note": "A proteção. Ela não estima: soma o que o `usage` de cada resposta diz que foi usado, aos preços acima, e levanta erro quando o dinheiro acaba. A chamada seguinte não acontece."
    },
    {
      "code": "client = OpenAI()\nbudget = Budget(dollars=0.002)\nprompt = open(\"prompts/triage.txt\").read()\ncases = [json.loads(line) for line in open(\"cases/triage.jsonl\")]\n\n",
      "note": "Um orçamento de US$ 0,002, pequeno o bastante para ser gasto em um minuto. Um de verdade sai da estimativa mensal da aula 4, com folga para um dia ruim."
    },
    {
      "code": "try:\n    for c in cases:\n        label = None\n        while label not in LABELS:   # the bug: ask again until the answer is a label\n            r = client.chat.completions.create(model=\"llama3.2:3b\", temperature=0, messages=[\n                {\"role\": \"system\", \"content\": prompt}, {\"role\": \"user\", \"content\": c[\"text\"]}])\n            budget.charge(r.usage)\n            label = r.choices[0].message.content\n        print(c[\"id\"], label)\n",
      "note": "O defeito, no próprio laço: perguntar de novo até a resposta ser um rótulo. Com temperatura 0, um modelo que responde uma vez algo que não é rótulo responde isso toda vez, e o laço não termina sozinho."
    },
    {
      "code": "except RuntimeError as e:\n    print(f\"stopped at {c['id']}, whose last answer was {label!r}: {e}\")\n",
      "note": "Como a exceção da proteção aparece de fora: que caso, o que ele disse por último e quantas chamadas levou."
    }
  ]
}
```

```
ana@desk:~/desk$ python budget.py
c01 order-status
c02 refund
c03 address-change
stopped at c04, whose last answer was 'order-status, refund, address-change, product-question, other.': budget spent after 18 calls
```

```
ana@desk:~/desk$ python relay.py show --count 200 | grep -c "^POST /v1/chat/completions -> 200"
18
```

O `c04` foi respondido com a lista inteira de rótulos, que não é um rótulo. Com temperatura 0 o
modelo responde a mesma coisa toda vez, então o laço perguntou quinze vezes e teria continuado a
noite inteira. **A proteção o parou em dois décimos de centavo**, disse onde e por quê, e o log do
relay concorda com a contagem. A sua execução pode parar em outro caso, ou em nenhum; o defeito está
no laço do mesmo jeito, e a proteção é o que faz a diferença entre uma linha no log e uma conta.

Quanto uma noite dessas custa sem ela é aritmética. A seção 05 da aula 4 calculou o rascunho da ana
no gpt-5.4-mini em US$ 56,34 por mês, 12.000 requisições, então cerca de **US$ 0,0047 por
requisição**. Um laço que manda uma a cada três segundos, uma suposição sobre quanto um rascunho
demora, faz 1.200 por hora: **US$ 5,63 por hora, e a estimativa do mês inteiro em dez**. Ninguém
precisa errar em algo maior que um `while` para isso acontecer, e nenhum dos limites do provedor o
pararia, porque o orçamento de um mês gasto numa noite ainda está abaixo do teto.

Quatro limites, então, e o trabalho de cada um:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"Quatro limites por que uma requisição passa até ser cobrada, do mais próximo ao mais distante: um orçamento no próprio programa da ana, um limite de crédito na chave, um limite de gasto que a ana define na conta, e o teto do nível da conta. Quanto mais próximo o limite, mais cedo ele para um programa descontrolado e menos protege contra qualquer coisa além desse programa.\"><defs><marker id=\"l21layers-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"40\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">a requisição</text><line x1=\"40\" y1=\"44\" x2=\"680\" y2=\"44\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" marker-end=\"url(#l21layers-ah)\"></line><rect x=\"20\" y=\"70\" width=\"155\" height=\"86\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"97.5\" y=\"97.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">orçamento no código</text><text x=\"97.5\" y=\"113.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">por execução</text><text x=\"97.5\" y=\"129.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">definido pela ana</text><line x1=\"175\" y1=\"113\" x2=\"195\" y2=\"113\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" marker-end=\"url(#l21layers-ah)\"></line><rect x=\"195\" y=\"70\" width=\"155\" height=\"86\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"272.5\" y=\"97.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">limite de crédito da chave</text><text x=\"272.5\" y=\"113.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">por chave</text><text x=\"272.5\" y=\"129.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">definido pela ana, no roteador</text><line x1=\"350\" y1=\"113\" x2=\"370\" y2=\"113\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" marker-end=\"url(#l21layers-ah)\"></line><rect x=\"370\" y=\"70\" width=\"155\" height=\"86\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"447.5\" y=\"97.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">limite de gasto da conta</text><text x=\"447.5\" y=\"113.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">por mês</text><text x=\"447.5\" y=\"129.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">definido pela ana, no provedor</text><line x1=\"525\" y1=\"113\" x2=\"545\" y2=\"113\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" marker-end=\"url(#l21layers-ah)\"></line><rect x=\"545\" y=\"70\" width=\"155\" height=\"86\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"622.5\" y=\"97.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">teto do nível</text><text x=\"622.5\" y=\"113.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">por mês</text><text x=\"622.5\" y=\"129.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">definido pelo provedor</text><text x=\"20\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">mais próximo: conhece o programa</text><text x=\"700\" y=\"190\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">mais distante: só conhece o dinheiro</text></svg>", "caption": "Quatro limites, cada um definido por alguém diferente e cada um parando uma coisa diferente. O mais próximo é o único que sabe o que o programa pretendia fazer."}
```

- **O orçamento no código** é o único que pode parar uma execução por estar errada, e não por estar
  cara. Ele conta o que as respostas informam, o `usage` que toda API deste curso devolve, não uma
  estimativa.
- **O limite da chave** isola um programa dos outros: a chave da classificação secar não para o
  rascunho.
- **O limite de gasto da conta** é o piso sob tudo o que a ana escreve, na estimativa do mês mais
  uma margem.
- **O teto do nível** é do provedor, e é o único em que nunca se deve confiar.

E uma coisa que nenhum deles faz: **avisar uma pessoa.** Um limite atingido às 3 da manhã para o
gasto e também para a classificação. Onde o console de um provedor oferece um alerta num limiar, a
ana define um; a proteção no código pode fazer o mesmo, registrando o que parou e por quê onde uma
pessoa vai ver. A ordem de uma manhã depois de uma noite ruim deveria ser: ler o alerta, corrigir o
defeito, não aumentar nada.
