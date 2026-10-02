---
title: Quanto custa um mês
version: 1
---

A aula 2 leu as tabelas de preço. Esta seção as usa para comparar provedores numa carga: **o
assistente de suporte da loja, 2.000 perguntas por dia, cada uma com 1.500 tokens de prompt e 300 de
resposta**. Os preços foram lidos com o `prices.py` em 2 de outubro de 2026: os da Anthropic na
própria página de preços dela, os da OpenAI e do Google na cópia do LiteLLM num commit fixo, porque
as páginas deles não puderam ser acessadas da máquina em que o curso foi gravado.

```python
"""What one workload costs a month at each model's list price."""
# Dollars per million tokens, input and output, read with prices.py on 2026-10-02.
PRICES = {
    "claude-opus-5-5": (4, 20), "claude-sonnet-5-5": (2, 10), "claude-haiku-4-5": (1, 5),
    "gpt-5.5": (5, 30), "gpt-5.4": (2.5, 15), "gpt-5.4-mini": (0.75, 4.5), "gpt-5.4-nano": (0.2, 1.25),
    "gemini-pro-latest": (2, 12), "gemini-3.5-flash": (1.5, 9), "gemini-3.5-flash-lite": (0.3, 2.5),
}
REQUESTS, TOKENS_IN, TOKENS_OUT = 2_000 * 30, 1_500, 300

print(f"{REQUESTS:,} requests a month, {TOKENS_IN:,} tokens in and {TOKENS_OUT} out each")
rows = []
for model, (p_in, p_out) in PRICES.items():
    month = REQUESTS * (TOKENS_IN * p_in + TOKENS_OUT * p_out) / 1_000_000
    rows.append((month, model))
for month, model in sorted(rows):
    print(f"  {model:22} ${month:>9,.2f}")
```

```
ana@dev:~/shop$ python cost.py
60,000 requests a month, 1,500 tokens in and 300 out each
  gpt-5.4-nano           $    40.50
  gemini-3.5-flash-lite  $    72.00
  gpt-5.4-mini           $   148.50
  claude-haiku-4-5       $   180.00
  gemini-3.5-flash       $   297.00
  claude-sonnet-5-5      $   360.00
  gemini-pro-latest      $   396.00
  gpt-5.4                $   495.00
  claude-opus-5-5        $   720.00
  gpt-5.5                $   990.00
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Um gráfico de barras do custo de um mês da mesma carga, 60.000 requisições de 1.500 tokens de entrada e 300 de saída, nos preços de tabela de dez modelos. De 40,50 dólares no gpt-5.4-nano a 990 dólares no gpt-5.5; o claude-haiku-4-5 custa 180, o claude-sonnet-5-5 360 e o claude-opus-5-5 720.\"><defs><marker id=\"cs-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"180\" y=\"29\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">gpt-5.4-nano</text><rect x=\"190\" y=\"20\" width=\"18.0\" height=\"18\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"214.0\" y=\"29\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">$40.50</text><text x=\"180\" y=\"56\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">gemini-3.5-flash-lite</text><rect x=\"190\" y=\"47\" width=\"32.0\" height=\"18\" rx=\"2\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"228.0\" y=\"56\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">$72.00</text><text x=\"180\" y=\"83\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">gpt-5.4-mini</text><rect x=\"190\" y=\"74\" width=\"66.0\" height=\"18\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"262.0\" y=\"83\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">$148.50</text><text x=\"180\" y=\"110\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">claude-haiku-4-5</text><rect x=\"190\" y=\"101\" width=\"80.0\" height=\"18\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"276.0\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">$180.00</text><text x=\"180\" y=\"137\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">gemini-3.5-flash</text><rect x=\"190\" y=\"128\" width=\"132.0\" height=\"18\" rx=\"2\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"328.0\" y=\"137\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">$297.00</text><text x=\"180\" y=\"164\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">claude-sonnet-5-5</text><rect x=\"190\" y=\"155\" width=\"160.0\" height=\"18\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"356.0\" y=\"164\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">$360.00</text><text x=\"180\" y=\"191\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">gemini-pro-latest</text><rect x=\"190\" y=\"182\" width=\"176.0\" height=\"18\" rx=\"2\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"372.0\" y=\"191\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">$396.00</text><text x=\"180\" y=\"218\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">gpt-5.4</text><rect x=\"190\" y=\"209\" width=\"220.0\" height=\"18\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"416.0\" y=\"218\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">$495.00</text><text x=\"180\" y=\"245\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">claude-opus-5-5</text><rect x=\"190\" y=\"236\" width=\"320.0\" height=\"18\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"516.0\" y=\"245\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">$720.00</text><text x=\"180\" y=\"272\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">gpt-5.5</text><rect x=\"190\" y=\"263\" width=\"440.0\" height=\"18\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"636.0\" y=\"272\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">$990.00</text></svg>", "caption": "Uma carga, dez preços de tabela, um fator de 24 entre as pontas. A diferença dentro de cada provedor é quase tão grande quanto entre eles."}
```

**Do mais barato ao mais caro há um fator de cerca de 24.** Dentro de um provedor a diferença é
quase tão grande: o Opus custa quatro vezes o Haiku, e o `gpt-5.5` custa cerca de 24 vezes o
`gpt-5.4-nano`. A escolha do modelo dentro de um provedor mexe mais na conta que a escolha do
provedor.

## O que a tabela deixa de fora

- **Cada provedor conta tokens do seu jeito.** 1.500 tokens é uma suposição sobre um tokenizador.
  Conte uma amostra dos seus prompts reais com o endpoint de contagem de cada provedor antes de
  confiar numa comparação até o dólar.
- **Saída é mais cara que entrada**, de cinco a oito vezes em toda linha aqui. Um modelo que escreve
  o dobro do que precisa custa mais do que o preço por token sugere, então meça o tamanho da
  resposta na sua tarefa também.
- **O cache muda o lado da entrada.** O prompt de sistema da loja é o mesmo em toda pergunta; nos
  preços de leitura de cache da aula 2, a parte repetida do prompt custa um décimo ou menos.
- **O modelo mais barato que falha é o mais caro.** Uma resposta errada custa um chamado, um
  reembolso ou um cliente, e nada disso está na tabela de preços. A aula 10 seção 07 trata de
  descobrir que modelos são bons o bastante antes de comparar preços.
