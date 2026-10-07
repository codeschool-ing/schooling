---
title: Por que uma conversa longa custa mais do que parece
version: 2
---

A aula 1 seção 10 mostrou que um chat manda a conversa inteira a cada mensagem nova. A
consequência para o custo é a que as pessoas não esperam: **o preço de uma conversa cresce com o
quadrado do tamanho dela**, e não em proporção a ele. A décima mensagem não custa dez vezes a
primeira; a décima *requisição* leva as nove trocas anteriores, e a nona também levava, e a oitava.

## Medindo

O `~/shop/scratch/conversation.py` simula vinte turnos. Cada pergunta tem uns trinta tokens e cada
resposta é o mesmo texto fixo de uns cem, para que a única coisa que cresce seja o histórico. Toda
requisição vai com `max_tokens=1`, o que faz o Ollama ler a conversa inteira, escrever um único
token e informar quanto leu: a contagem da aula 2 seção 03, vinte vezes.

```python
import anthropic

client = anthropic.Anthropic()
REPLY = "Here is a reply of about a hundred tokens. " * 10
history, sent = [], 0
for turn in range(1, 21):
    history.append({"role": "user", "content": f"Question number {turn} about the cart, in about thirty tokens of text."})
    r = client.messages.create(model="llama3.2:3b", max_tokens=1, messages=history)
    n = r.usage.input_tokens + (r.usage.cache_read_input_tokens or 0)
    sent += n
    if turn in (1, 2, 5, 10, 15, 20):
        print(f"turn {turn:2}: this request {n:5} tokens, all requests so far {sent:6}")
    history.append({"role": "assistant", "content": REPLY})
```

```
ana@dev:~/shop$ python scratch/conversation.py
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Duas curvas ao longo de vinte turnos de uma conversa. O tamanho de cada requisição cresce em linha reta, até 2.434 tokens no turno 20. O total de todas as requisições até ali faz uma curva para cima, até 24.740 tokens no turno 20.\"><defs><marker id=\"gr-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M80 260 L650 260\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M80 260 L80 30\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72\" y=\"260.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><text x=\"72\" y=\"216.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">5.000</text><text x=\"72\" y=\"172.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10.000</text><text x=\"72\" y=\"128.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">15.000</text><text x=\"72\" y=\"84.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">20.000</text><text x=\"72\" y=\"40.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">25.000</text><text x=\"80.0\" y=\"274\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">turno 1</text><text x=\"197.89473684210526\" y=\"274\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">turno 5</text><text x=\"345.2631578947368\" y=\"274\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">turno 10</text><text x=\"492.63157894736844\" y=\"274\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">turno 15</text><text x=\"640.0\" y=\"274\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">turno 20</text><path d=\"M80.0 259.6 L109.5 258.5 L197.9 255.2 L345.3 249.7 L492.6 244.1 L640.0 238.6\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M80.0 259.6 L109.5 258.2 L197.9 247.2 L345.3 206.6 L492.6 138.3 L640.0 42.3\" stroke=\"var(--amber)\" stroke-width=\"1.8\" fill=\"none\"></path><circle cx=\"80.0\" cy=\"259.6\" r=\"2.5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"109.5\" cy=\"258.5\" r=\"2.5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"197.9\" cy=\"255.2\" r=\"2.5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"345.3\" cy=\"249.7\" r=\"2.5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"492.6\" cy=\"244.1\" r=\"2.5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"640.0\" cy=\"238.6\" r=\"2.5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"80.0\" cy=\"259.6\" r=\"2.5\" fill=\"var(--amber)\" stroke=\"none\"></circle><circle cx=\"109.5\" cy=\"258.2\" r=\"2.5\" fill=\"var(--amber)\" stroke=\"none\"></circle><circle cx=\"197.9\" cy=\"247.2\" r=\"2.5\" fill=\"var(--amber)\" stroke=\"none\"></circle><circle cx=\"345.3\" cy=\"206.6\" r=\"2.5\" fill=\"var(--amber)\" stroke=\"none\"></circle><circle cx=\"492.6\" cy=\"138.3\" r=\"2.5\" fill=\"var(--amber)\" stroke=\"none\"></circle><circle cx=\"640.0\" cy=\"42.3\" r=\"2.5\" fill=\"var(--amber)\" stroke=\"none\"></circle><text x=\"648.0\" y=\"238.6\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">2.434</text><text x=\"648.0\" y=\"42.3\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">24.740</text><text x=\"404.2\" y=\"234.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">esta requisição</text><text x=\"374.7\" y=\"180.8\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">todas até aqui</text></svg>", "caption": "Cada requisição cresce uma troca; o total cresce a requisição inteira a cada turno. Medido pelo `conversation.py`, com os seis turnos que ele imprimiu marcados."}
```

A vigésima requisição tem 2.434 tokens, umas quinze vezes a segunda. Essa parte é linear. A segunda
coluna é a conta: **24.740 tokens de entrada em vinte requisições**, para uma conversa cujo texto,
lido uma vez, tem menos de dois mil e quinhentos. Dobrar o tamanho de uma conversa mais ou menos
quadruplica o que a entrada dela custa, que é o que acontece entre o turno 10 (6.070) e o turno 20.

## O que fazer

- **Limite o histórico.** Mantenha o prompt de sistema e as últimas trocas, e descarte as mais
  antigas. O modelo esquece o que foi descartado, então faça isso onde esquecer é aceitável, como
  num chat de suporte que trata de um problema por vez.
- **Resuma em vez de descartar.** Troque os turnos antigos por um resumo curto escrito por um
  modelo barato. Custa uma requisição extra de vez em quando e guarda a essência do que foi dito.
- **Comece do zero quando o assunto muda.** Uma pergunta nova numa conversa velha paga cada turno
  da velha. Interfaces de chat que oferecem um botão de "nova conversa" estão oferecendo um
  desconto.
- **Ponha em cache a parte que não muda.** O começo de cada requisição de uma conversa é idêntico ao
  começo da anterior; a aula 2 seção 07 mostra como pagar menos por ele.

Nenhum desses é de graça: cada um tira algo que o modelo poderia ter usado. É a medição que permite
decidir, e a medição é o `usage`, registrado por requisição e somado por conversa.
