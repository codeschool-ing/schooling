---
title: Não quão bom, mas o que mudou
version: 2
---

Toda mudança no assistente é uma versão nova: outro modelo, outro prompt, outro número de trechos,
outro piso. A aula 5 achou a versão do piso de 1º de outubro em produção, depois de os clientes já a
encontrarem havia dias. Um **teste de regressão** faz a pergunta antes da versão ir ao ar: rodar o
conjunto de avaliação pela candidata e pela versão em produção, e compará-las **caso a caso**.

A pergunta é mais estreita do que "a candidata é boa". É **o que a candidata mudou**: quais casos ela
agora acerta e antes errava, quais ela agora erra e antes acertava, quais respostas mudaram de redação,
e quanto ela custa e quanto demora. Uma candidata pode subir a média e quebrar o caso que os clientes
mais perguntam; um teste de regressão é feito para mostrar esse caso pelo nome.

## As candidatas

Uma versão é uma linha de `releases.json`: um modelo, o número de trechos e o piso. O curso escreve três
candidatas ao lado das duas versões que rodaram na semana, cada uma começando em 2099 para que nada em
produção as pegue. Substitua o `releases.json` por:

```json
{
  "2026.09.4": {"from": "2026-09-01T00:00:00", "model": "llama3.2:3b", "k": 3, "floor": 0.4},
  "2026.10.1": {"from": "2026-10-01T10:00:00", "model": "llama3.2:3b", "k": 3, "floor": 0.55},
  "2026.10.2": {"from": "2099-01-01T00:00:00", "model": "llama3.2:1b", "k": 3, "floor": 0.55},
  "2026.10.3": {"from": "2099-01-01T00:00:00", "model": "llama3.2:3b", "k": 3, "floor": 0.4},
  "2026.10.4": {"from": "2099-01-01T00:00:00", "model": "llama3.2:1b", "k": 3, "floor": 0.4}
}
```

- **A 2026.10.2 troca o modelo** pelo `llama3.2:1b`, o menor que a aula 1 baixou. Nos preços do curso
  ele custa um terço do `llama3.2:3b` por token, e responde mais rápido na mesma máquina.
- **A 2026.10.3 põe o piso de volta** em 0.4, o valor de antes de 1º de outubro.
- **A 2026.10.4 faz as duas coisas.**

Cada versão responde à versão 2 do conjunto de avaliação, pelo `evalrun.py` da aula 8 com a opção
`--release`:

```
ana@dev:~/obs$ for r in 2026.09.4 2026.10.1 2026.10.2 2026.10.3 2026.10.4; do python evalrun.py $r --set data/eval-v2.jsonl --release $r; done
runs/2026.09.4.jsonl: 32 questions, release 2026.09.4
runs/2026.10.1.jsonl: 32 questions, release 2026.10.1
runs/2026.10.2.jsonl: 32 questions, release 2026.10.2
runs/2026.10.3.jsonl: 32 questions, release 2026.10.3
runs/2026.10.4.jsonl: 32 questions, release 2026.10.4
```

As execuções são feitas hoje, então toda resposta é cobrada pelos preços de hoje, qualquer que seja a
versão que a produziu: a comparação é entre o que cada uma custaria agora, que é a pergunta que uma
decisão de versão faz.
