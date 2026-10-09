---
title: Quanto custa uma chamada
version: 2
---

Na sua própria máquina, uma chamada custa tempo e eletricidade, e o tempo é o que a última seção
mediu. Um modelo hospedado cobra por token, com um preço para tokens lidos e um mais alto para
tokens escritos. Para fazer essa conta você precisa de uma tabela de preços, e este curso escreve a
sua em vez de copiar a de um provedor, porque tabelas reais mudam o bastante para que qualquer
número copiado numa aula esteja errado em menos de um ano. Salve-a como `prices.json`:

```json
{
  "note": "cents per million tokens, written by the course for its arithmetic, not any provider's prices",
  "input": 300,
  "output": 1500
}
```

**Estes preços foram escritos pelo curso**, como o arquivo diz, e estão em centavos inteiros por
milhão de tokens: 300 centavos por um milhão de tokens de entrada, 1500 por um milhão de tokens de
saída. Tabelas reais têm a mesma forma, um preço por milhão de tokens com a saída mais cara que a
entrada. Para usar o programa abaixo com um provedor, ponha no arquivo os preços desse provedor.

## A aritmética

Este programa soma os tokens de uma execução e multiplica. Salve-o como `cost.py`:

```python
"""cost: what a run would cost at the prices in prices.json, which are whole
cents per million tokens. Every product is a whole number; the one division
happens at the end, and so does the one rounding."""
import json
import sys
from decimal import ROUND_HALF_UP, Decimal

from pl import read_jsonl

prices = json.load(open("prices.json", encoding="utf-8"))


def cents(units):
    """units are cents times tokens; a million of them is one cent."""
    return (Decimal(units) / 1_000_000).quantize(Decimal("0.0001"), ROUND_HALF_UP)


for path in sys.argv[1:]:
    rows = read_jsonl(path)
    tin = sum(r["tokens_in"] for r in rows)
    tout = sum(r["tokens_out"] for r in rows)
    units = tin * prices["input"] + tout * prices["output"]
    print("%s, %d calls" % (path, len(rows)))
    print("  input    %7d tokens   %8.1f a call" % (tin, tin / len(rows)))
    print("  output   %7d tokens   %8.1f a call" % (tout, tout / len(rows)))
    print("  these calls      %s cents" % cents(units))
    print("  a million calls  %s cents" % cents(Decimal(units) * 1_000_000 / len(rows)))
```

```
ana@lab:~/triage$ python3 cost.py runs/v3.jsonl
runs/v3.jsonl, 40 calls
  input       9926 tokens      248.2 a call
  output      1226 tokens       30.6 a call
  these calls      4.8168 cents
  a million calls  120420.0000 cents
```

As quarenta chamadas leram 9926 tokens e escreveram 1226. A 300 e 1500 centavos por milhão, isso é
9926 × 300 + 1226 × 1500 = 2.977.800 + 1.839.000 = 4.816.800 centavos-token, que o `cents()` divide
por um milhão uma vez para dar os 4,8168 centavos da linha de baixo. Divida por quarenta para uma
chamada, 0,12042 centavo, e multiplique por um milhão para a última linha. **A saída foi 11% dos
tokens e 38% do custo**, porque cada token de saída custa cinco vezes mais. É a mesma lição da última
seção, em dinheiro.

A última linha é a que se põe na frente de quem decide se publica: 120.420 centavos por um milhão de
chamadas como estas. Um custo por chamada soa como nada; um custo por milhão é um orçamento.

## Por que dinheiro nunca é float

O programa nunca toca num número fracionário no caminho até esse total, e o comentário de abertura
dele diz isso. Tokens são inteiros e preços são centavos inteiros por milhão, então o produto deles é
um número inteiro, exato. **Nada é arredondado até o fim**, uma vez, para cima na metade, na quarta
casa decimal, pelo módulo `decimal` do Python, que faz contas em dígitos decimais do jeito que uma
pessoa faz com um lápis. A alternativa parece inofensiva e não é:

```
ana@lab:~/triage$ python3 -c 'print(0.1 + 0.2)'
0.30000000000000004
```

Um número de ponto flutuante binário não consegue guardar exatamente a maioria das frações decimais,
então `0.1` é guardado como o valor mais próximo que ele consegue, e somas desses valores derivam.
Uma deriva é invisível; a mesma conta sobre todas as chamadas de um mês, comparada com uma fatura
calculada de outro jeito, produz uma diferença que alguém tem de explicar. **Guarde dinheiro como uma
contagem inteira da menor unidade que você cobra**, multiplique inteiros, e arredonde uma vez, com
uma regra escrita.
