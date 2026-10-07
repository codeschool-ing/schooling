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

O `latency.py` faz streaming da mesma requisição de rascunho vinte vezes para cada um dos dois
modelos que a aula 1 instalou, e cronometra os dois momentos:

```python
import statistics
import sys
import time

import anthropic

client = anthropic.Anthropic()  # Ollama, through desk.env
email = "Hello, where is my parcel? LB-20488"
print(f"{'model':14} {'first token p50':>16} {'p95':>6} {'whole reply p50':>16} {'p95':>6}")
for model in ("llama3.2:3b", "llama3.2:1b"):
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
ana@desk:~/desk$ python latency.py 20
model           first token p50    p95  whole reply p50    p95
llama3.2:3b               0.24s  0.38s            9.94s 16.63s
llama3.2:1b               0.16s 10.35s            5.45s 15.15s
```

**Esses tempos são de uma máquina só**: quatro processadores, nenhuma placa de vídeo, e os dois
modelos no Ollama. Os seus vão ser outros, e o que se lê é o formato. Antes da medição o modelo 1b
foi descarregado, então a primeira requisição dele teve de carregá-lo do disco, como faz a primeira
requisição da manhã.

**O primeiro token é rápido nos dois**, um quarto de segundo ou menos na mediana. O **p95** é onde
eles se separam: 0,38 segundo no 3b e **10,35 no 1b**, e o do 1b é a única requisição que esperou o
modelo carregar. Uma requisição em vinte é exatamente o assunto de um p95, e a mediana nem se mexe.

**A resposta inteira é outro número.** O 3b levou uns dez segundos na mediana para escrever o
rascunho, e o 1b uns cinco e meio: num processador sem placa de vídeo, um modelo três vezes maior
escreve mais devagar. Os p95, 16,63 e 15,15 segundos, são os rascunhos mais longos, e o tamanho da
resposta de um modelo varia de uma requisição para outra mesmo quando o e-mail não varia.

## O que importa para a ana

- **A classificação** acontece em segundo plano, e ninguém fica olhando: latência quase não importa,
  o que a torna candidata ao preço de lote (seção 05).
- **O rascunho** tem uma pessoa esperando. O streaming faz do primeiro token o número que ela sente,
  e do p95 o que decide se ela confia na ferramenta. O teto dela, anotado na seção 03 como ordenação
  com limite, vira um número aqui: **primeiro token em menos de dois segundos no p95**. Na medição
  acima o 3b passa, e o 1b falha só pela partida a frio, o que manter o modelo carregado resolve
  (aula 14).

Meça nos candidatos reais, de onde o programa vai rodar, no horário em que vai rodar. Uma latência
medida de um notebook à noite é outra medição que a tirada do servidor da loja numa segunda de manhã.
