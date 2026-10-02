---
title: Quanto custa uma requisição, e quanto custa uma funcionalidade
version: 1
---

Uma única requisição custa frações de centavo, e por isso ninguém se preocupa com ela; uma
funcionalidade faz essa requisição milhares de vezes por dia, e por isso a fatura surpreende. Os
dois números saem da mesma conta, e vale tê-la em código desde o primeiro dia em vez de numa
planilha que alguém fez uma vez.

## A função de custo

Dinheiro é calculado com `Decimal`, nunca com `float`, pelo mesmo motivo de a loja guardar os
preços em centavos inteiros: uma fração de centavo multiplicada por alguns milhões de requisições é
onde erros de arredondamento ficam visíveis. Os preços são os que o `prices.py` leu, com a data ao
lado:

```schooling-example
{
  "language": "python",
  "file": "lab/cost.py",
  "parts": [
    {
      "code": "from decimal import Decimal\n\nimport anthropic\n\n# Dollars per million tokens, read from Anthropic's pricing page on 2026-10-02 (prices.py).\nPRICES = {\n    \"claude-opus-5-5\": (Decimal(\"4\"), Decimal(\"20\")),\n    \"claude-sonnet-5-5\": (Decimal(\"2\"), Decimal(\"10\")),\n    \"claude-haiku-4-5\": (Decimal(\"1\"), Decimal(\"5\")),\n}\nMILLION = Decimal(1_000_000)\n\n\n",
      "note": "**Uma tabela, com a data e a fonte.** Um preço sem data é um número que ninguém consegue conferir, e esses mudam várias vezes por ano."
    },
    {
      "code": "def cost(model: str, input_tokens: int, output_tokens: int) -> Decimal:\n    price_in, price_out = PRICES[model]\n    return (input_tokens * price_in + output_tokens * price_out) / MILLION\n\n\n",
      "note": "**A fórmula inteira.** Um modelo que falta na tabela levanta `KeyError` em vez de custar zero, e essa é a falha que você quer."
    },
    {
      "code": "client = anthropic.Anthropic()\nr = client.messages.create(model=\"scripted-1\", max_tokens=300,\n                           messages=[{\"role\": \"user\", \"content\": \"Explain the shop's shipping rule.\"}])\nu = r.usage\nprint(f\"usage: {u.input_tokens} in, {u.output_tokens} out\")\nfor model in PRICES:\n    print(f\"  at {model} prices: ${cost(model, u.input_tokens, u.output_tokens):.6f}\")\n\n",
      "note": "**O uso de uma requisição real, com três preços.** A resposta vem do `scripted-1`, então o texto dela foi escrito pelo curso; as contagens de tokens são contagens reais desse texto."
    },
    {
      "code": "print(\"a month of 3,000 requests a day, 1,800 tokens in and 250 out each:\")\nfor model in PRICES:\n    print(f\"  {model}: ${cost(model, 1_800, 250) * 3_000 * 30:,.2f}\")",
      "note": "**A mesma fórmula no tamanho de uma funcionalidade**, com o volume e as contagens de tokens como suposições escritas no código, onde qualquer um pode mudá-las."
    }
  ],
  "output": "usage: 10 in, 147 out\n  at claude-opus-5-5 prices: $0.002980\n  at claude-sonnet-5-5 prices: $0.001490\n  at claude-haiku-4-5 prices: $0.000745\na month of 3,000 requests a day, 1,800 tokens in and 250 out each:\n  claude-opus-5-5: $1,098.00\n  claude-sonnet-5-5: $549.00\n  claude-haiku-4-5: $274.50"
}
```

## Lendo o resultado

A resposta teve 10 tokens de entrada e 147 de saída. **A saída é quase 99% do custo** dessa
requisição em qualquer um dos três preços, porque a pergunta era curta e a resposta não. A maioria
das requisições do tipo chat é assim, e a alavanca que importa ali é quanto você deixa a resposta
crescer.

O número mensal é o que mostrar a quem aprova a funcionalidade: 3.000 requisições por dia, com
1.800 tokens de entrada e 250 de saída, dá pouco mais de mil dólares por mês no mais caro dos três e
um quarto disso no mais barato. **As entradas dessa estimativa são chutes até você medi-las**, e o
jeito de medir é o `usage` que você registra em toda chamada (aula 2 seção 03). Revise a estimativa
depois de uma semana de tráfego real; as contagens de tokens quase sempre saem maiores que o chute,
porque usuários de verdade colam coisas.

## Custos que ninguém põe na primeira estimativa

- **Novas tentativas.** Uma requisição que falha no provedor e é mandada de novo em geral não é
  cobrada, mas uma que dá certo e é jogada fora pelo seu código (uma resposta que falhou na
  validação, aula 8) é cobrada inteira.
- **A conversa.** Um chat manda o histórico a cada turno, então o custo por turno cresce; a aula 2
  seção 06 mede o quanto.
- **Desenvolvimento.** Os seus próprios testes e experimentos rodam contra a mesma tabela de
  preços. A aula 4 deixa chamadas a modelos fora dos testes de unidade também por isso.
