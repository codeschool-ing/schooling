---
title: Custo é uma carga de trabalho, não um preço
version: 1
---

A aula 3 multiplicou um preço por um volume. Para escolher entre modelos essa é a ideia certa no
nível de detalhe errado, porque três coisas mexem mais na conta do que o preço de vitrine: **quanto
do prompt se repete**, **quanto o modelo escreve** e **se a resposta é necessária agora**.

É na tarefa de rascunho da ana que elas aparecem. A carga dela, suposição do curso: **400
requisições por dia**, cada uma levando a **política da loja de 5.000 tokens** (a mesma em toda
requisição), **60 tokens** de e-mail novo e uma resposta de **200 tokens**. O `lab/monthly.py` dá
preço a ela de três jeitos a partir dos campos da tabela, para seis candidatos:

```python
import json

sheet = json.load(open("/opt/aimodels/share/litellm-21881c57.json"))
CANDIDATES = ["claude-haiku-4-5", "claude-sonnet-5-5", "gemini/gemini-3.5-flash-lite",
              "gpt-5.4-mini", "mistral/mistral-small-latest", "deepseek/deepseek-v3.2"]
# The drafting task, as the course assumes it: the shop's policy is the same
# 5,000 tokens on every request, the e-mail is 60 more, the reply is 200.
PER_DAY, POLICY, FRESH, OUT = 400, 5000, 60, 200
n = PER_DAY * 30


def money(x):
    return f"${x:8.2f}" if x is not None else "       -"


print(f"{'model':30} {'list':>9} {'cached':>9} {'batch':>9}   output share")
for m in CANDIDATES:
    e = sheet[m]
    i, o = e["input_cost_per_token"], e["output_cost_per_token"]
    plain = n * ((POLICY + FRESH) * i + OUT * o)
    read = e.get("cache_read_input_token_cost")
    cached = n * (POLICY * read + FRESH * i + OUT * o) if read else None
    bi, bo = e.get("input_cost_per_token_batches"), e.get("output_cost_per_token_batches")
    batch = n * ((POLICY + FRESH) * bi + OUT * bo) if bi and bo else None
    print(f"{m:30} {money(plain)} {money(cached)} {money(batch)}   {n * OUT * o / plain:6.0%}")
```

```
ana@desk:~/desk$ python lab/monthly.py
model                               list    cached     batch   output share
claude-haiku-4-5               $   72.72 $   18.72 $   36.36      17%
claude-sonnet-5-5              $  145.44 $   37.44 $   72.72      17%
gemini/gemini-3.5-flash-lite   $   24.22 $    8.02 $   12.11      25%
gpt-5.4-mini                   $   56.34 $   15.84 $   28.17      19%
mistral/mistral-small-latest   $   10.55 $    2.45        -      14%
deepseek/deepseek-v3.2         $   17.96 $    2.84        -       5%
```

**List** é cada token pelo preço normal. **Cached** cobra os 5.000 tokens repetidos pelo preço de
leitura de cache da tabela, o que supõe que toda requisição encontra a política ainda em cache: é um
piso, já que a primeira requisição depois que o cache expira paga o preço cheio, e alguns provedores
cobram a mais para gravar o cache. **Batch** é o preço de requisições mandadas em lote e respondidas
em algumas horas, onde o provedor oferece.

Três leituras:

- **O cache muda a ordem mais do que a lista.** O Claude Haiku vai de US$ 72,72 para US$ 18,72, a
  DeepSeek de US$ 17,96 para US$ 2,84. Uma carga que repete um prefixo longo deve ser precificada
  pela taxa com cache, senão a comparação é entre contas que ninguém vai pagar.
- **O lote corta a conta pela metade**, em todo provedor da tabela que o lista, e não serve para
  um rascunho que um atendente está esperando. Ele combina com o trabalho da madrugada:
  reclassificar um acúmulo, avaliar candidatos (aula 5).
- **A saída é uma fatia pequena aqui**, de 5% a 25%. Isso é uma propriedade desta carga, prompt
  longo e resposta curta. Inverta, uma pergunta curta e uma resposta longa, e o preço de saída
  domina; ele é de quatro a oito vezes o preço de entrada em cinco dos seis provedores acima.

Nenhum desses números diz qual modelo escolher. Eles dizem quanto cada um custaria **para esta
carga**, que é o único custo que significa alguma coisa. Repare que `batch` está em branco em duas
linhas: a tabela não tem preço de lote para elas, o que não é o mesmo que o provedor não oferecer. Um
branco é uma pergunta a conferir, não uma resposta.
