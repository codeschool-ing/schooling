---
title: Latência são dois números
version: 1
---

"Qual a velocidade" tem duas respostas, e uma pessoa sente cada uma de um jeito.

- **Tempo até o primeiro token**: do envio da requisição até o primeiro pedaço da resposta. Com
  streaming, é quanto tempo a tela fica em branco.
- **Tempo até a resposta inteira**: até o último token. É o que um programa espera quando precisa
  da resposta completa antes de fazer qualquer coisa, e o que uma pessoa espera quando a resposta é
  curta.

O primeiro depende da fila do provedor, do tamanho do prompt e de quanto um modelo de raciocínio
pensa antes de responder. O segundo soma a velocidade de geração da aula 3 seção 05 vezes o tamanho
da resposta.

## Medir, e por que uma execução só não diz nada

A latência varia de uma requisição para a outra: filas, outros clientes, a rede. Então ela é medida
muitas vezes e relatada como uma **distribuição**: a mediana (p50), o que uma requisição típica
vê, e o percentil 95 (p95), o que uma requisição em vinte vê, ou pior. O p95 é o número de que um
usuário irritado se lembra.

O `lab/latency.py` faz streaming da mesma requisição de rascunho vinte vezes para cada modelo do
substituto e cronometra os dois momentos:

```python
import statistics
import sys
import time

import anthropic

client = anthropic.Anthropic()
email = "Hello, where is my parcel? LB-20488"
print(f"{'model':14} {'first token p50':>16} {'p95':>6} {'whole reply p50':>16} {'p95':>6}")
for model in ("standin-large", "standin-small", "standin-local"):
    first, whole = [], []
    for _ in range(int(sys.argv[1])):
        start = time.perf_counter()
        with client.messages.stream(model=model, max_tokens=300,
                                    messages=[{"role": "user", "content": "Draft a reply: " + email}]) as s:
            for i, _text in enumerate(s.text_stream):
                if i == 0:
                    first.append(time.perf_counter() - start)
        whole.append(time.perf_counter() - start)
    q = lambda xs, p: statistics.quantiles(xs, n=20)[p] if len(xs) > 1 else xs[0]  # noqa: E731
    print(f"{model:14} {statistics.median(first):>15.2f}s {q(first, 18):>5.2f}s "
          f"{statistics.median(whole):>15.2f}s {q(whole, 18):>5.2f}s")
```

```
ana@desk:~/desk$ python lab/latency.py 20
model           first token p50    p95  whole reply p50    p95
standin-large             0.85s  1.84s            3.69s  4.68s
standin-small             0.23s  0.39s            1.17s  1.32s
standin-local             1.28s  3.01s            6.92s  8.66s
```

**Esses tempos medem o substituto, não modelo real nenhum.** O curso definiu o atraso de cada modelo
do substituto antes do primeiro token e por token depois dele, e mandou esticar o primeiro token por
um fator aleatório de cauda longa, como faz um serviço compartilhado. O que é real é o método: o
stream, o relógio, os percentis.

Leia como um padrão. O **standin-small** responde antes de os outros começarem e termina primeiro. O
**standin-local**, que faz o papel de um modelo auto-hospedado em hardware modesto, tem o primeiro
token mais lento e a geração mais lenta, e o p95 do primeiro token dele passa do dobro da mediana. A
distância entre as duas colunas é o tamanho da resposta: uns 3 segundos escrevendo no standin-large,
quase 6 no standin-local.

## O que importa para a ana

- **A classificação** acontece em segundo plano, e ninguém fica olhando: latência quase não importa,
  o que a torna candidata ao preço de lote (seção 05).
- **O rascunho** tem uma pessoa esperando. O streaming faz do primeiro token o número que ela sente,
  e do p95 o que decide se ela confia na ferramenta. O teto dela, anotado na seção 03 como ordenação
  com limite, vira um número aqui: **primeiro token em menos de dois segundos no p95**.

Meça nos candidatos reais, de onde o programa vai rodar, no horário em que vai rodar. Uma latência
medida de um notebook à noite é outra medição que a tirada do servidor da loja numa segunda de manhã.
