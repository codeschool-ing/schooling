---
title: Quatro preços para um modelo
version: 1
---

A aula 4 viu dois preços por modelo, normal e lote. A entrada do Gemini Pro traz mais:

```
ana@desk:~/desk$ sheet show gemini/gemini-pro-latest | grep -E "^(input|output)_cost_per_token"
input_cost_per_token                       2e-06
input_cost_per_token_above_200k_tokens     4e-06
input_cost_per_token_above_200k_tokens_priority 7.2e-06
input_cost_per_token_batches               1e-06
input_cost_per_token_flex                  1e-06
input_cost_per_token_priority              3.6e-06
output_cost_per_token                      1.2e-05
output_cost_per_token_above_200k_tokens    1.8e-05
output_cost_per_token_above_200k_tokens_priority 3.24e-05
output_cost_per_token_batches              6e-06
output_cost_per_token_flex                 6e-06
output_cost_per_token_priority             2.16e-05
```

Por milhão de tokens, entrada e saída:

| nível | entrada | saída | o que compra |
|---|---|---|---|
| normal | US$ 2 | US$ 12 | uma resposta agora |
| lote | US$ 1 | US$ 6 | uma resposta em algumas horas, para um arquivo de requisições |
| flex | US$ 1 | US$ 6 | um preço menor por promessas mais fracas sobre velocidade |
| priority | US$ 3,60 | US$ 21,60 | um preço maior por promessas mais fortes |

As linhas **flex** e **priority** são o registro, na tabela, de o Google vender o mesmo modelo em
níveis diferentes de serviço. A tabela registra preços e não promessas, então o que cada nível
garante é algo para ler na página do provedor antes de depender disso. Onde eles são uma escolha por
requisição e não por conta, viram uma troca de latência exatamente do tipo da aula 4 seção 06: a
classificação em segundo plano poderia rodar no flex pela metade do preço, um rascunho para um
atendente esperando poderia pagar pelo priority no p95.

## O preço que muda com o prompt

Duas linhas acima trazem `above_200k_tokens`, e elas mudam a conta dos prompts longos. Uma estimativa
ingênua de uma requisição de 300.000 tokens usa o preço normal:

```
ana@desk:~/desk$ sheet cost gemini/gemini-pro-latest 300000 1000
# LiteLLM model sheet at 21881c57, 4472 entries
300,000 in  x $2/M = $0.6000
1,000 out x $12/M = $0.0120
total $0.6120
```

É o que o `sheet cost` faz, e está errado para este modelo. O próprio código do LiteLLM, que usa
esses mesmos campos para cobrar os usuários dele, diz como o limite se aplica:

```
ana@desk:~/desk$ sources quote litellm-cost "If input_tokens > threshold|for all token types"
# BerriAI/litellm@21881c57 litellm/litellm_core_utils/llm_cost_calc/utils.py
 627: If input_tokens > threshold and `input_cost_per_token_above_[x]k_tokens` or
      `input_cost_per_token_above_[x]_tokens` is set,
 628: then we use the corresponding threshold cost for all token types.
```

**Quando o prompt passa de 200.000 tokens, todo token da requisição vai para o preço mais alto**, os
primeiros 200.000 incluídos, e a saída junto. O `lab/tiered.py` aplica essa regra:

```python
import json
import sys

sheet = json.load(open("/opt/aimodels/share/litellm-21881c57.json"))
model, tokens_in, tokens_out = sys.argv[1], int(sys.argv[2]), int(sys.argv[3])
e = sheet[model]
rate_in, rate_out = e["input_cost_per_token"], e["output_cost_per_token"]
if tokens_in > 200_000 and "input_cost_per_token_above_200k_tokens" in e:
    # the whole request moves to the higher rate, in and out
    rate_in = e["input_cost_per_token_above_200k_tokens"]
    rate_out = e["output_cost_per_token_above_200k_tokens"]
print(f"{tokens_in:,} in at ${rate_in * 1e6:g}/M, {tokens_out:,} out at ${rate_out * 1e6:g}/M: "
      f"${tokens_in * rate_in + tokens_out * rate_out:.4f}")
```

```
ana@desk:~/desk$ python lab/tiered.py gemini/gemini-pro-latest 190000 1000; python lab/tiered.py gemini/gemini-pro-latest 210000 1000
190,000 in at $2/M, 1,000 out at $12/M: $0.3920
210,000 in at $4/M, 1,000 out at $18/M: $0.8580
```

Vinte mil tokens de prompt a mais, e a requisição custa **mais que o dobro**: US$ 0,3920 contra US$
0,8580. Uma carga de contexto longo que fica rondando a linha é uma carga cuja conta depende de que
lado dela cada requisição cai, e o conserto costuma estar antes: recuperar menos (aula 4 seção 07),
ou dividir o documento.

Um lembrete sobre a ferramenta: a tabela registra esses níveis; o `sheet cost` os ignora. **Uma
calculadora de custo que só conhece o preço normal está certa até o dia em que erra feio**, que é um
motivo de a aula 21 ler a conta que o provedor de fato manda.
