---
title: Não quão bom, mas o que mudou
version: 1
---

Toda mudança no assistente é uma versão nova: outro modelo, outro prompt, outro número de trechos,
outro piso. A aula 5 achou a versão do piso de 2 de outubro em produção, três dias e centenas de
clientes decepcionados depois de ela ir ao ar. Um **teste de regressão** faz a pergunta antes da versão
ir ao ar: rodar o conjunto de avaliação pela candidata e pela versão em produção, e compará-las **caso a
caso**.

A pergunta é mais estreita do que "a candidata é boa". É **o que a candidata mudou**: quais casos ela
agora acerta e antes errava, quais ela agora erra e antes acertava, quais respostas mudaram de redação,
e quanto ela custa e quanto demora. Uma candidata pode subir a média e quebrar o caso que os clientes
mais perguntam; um teste de regressão é feito para mostrar esse caso pelo nome.

## As candidatas

Neste laboratório uma versão é uma linha de `releases.json`: um modelo, o número de trechos e o piso. O
curso escreve três candidatas ao lado das duas versões que rodaram na semana, cada uma com início em
2099 para que nada em produção as pegue:

```
ana@lab:~/obs$ cat releases.json
{
  "2026.09.4": {"from": "2026-09-01T00:00:00", "model": "extract-1", "k": 3, "floor": 0.5},
  "2026.10.1": {"from": "2026-10-02T10:00:00", "model": "extract-1", "k": 3, "floor": 0.62},
  "2026.10.2": {"from": "2099-01-01T00:00:00", "model": "extract-2", "k": 3, "floor": 0.62},
  "2026.10.3": {"from": "2099-01-01T00:00:00", "model": "extract-1", "k": 3, "floor": 0.5},
  "2026.10.4": {"from": "2099-01-01T00:00:00", "model": "extract-2", "k": 3, "floor": 0.5}
}
```

- **A 2026.10.2 muda o modelo**: o extract-2, a segunda versão do modelo substituto do laboratório, como
  um provedor lança uma versão nova de um modelo. Ele mantém mais frases que o extract-1, e o seu preço
  por token é o dobro.
- **A 2026.10.3 põe o piso de volta** em 0,5, o ajuste de antes de 2 de outubro.
- **A 2026.10.4 faz as duas coisas.**

Cada versão responde à versão 2 do conjunto de avaliação, pelo `evalrun.py` da aula 8 com a sua opção
`--release`:

```
ana@lab:~/obs$ for r in 2026.09.4 2026.10.1 2026.10.2 2026.10.3 2026.10.4; do python evalrun.py $r --set data/eval-v2.jsonl --release $r; done
runs/2026.09.4.jsonl: 42 questions, release 2026.09.4
runs/2026.10.1.jsonl: 42 questions, release 2026.10.1
runs/2026.10.2.jsonl: 42 questions, release 2026.10.2
runs/2026.10.3.jsonl: 42 questions, release 2026.10.3
runs/2026.10.4.jsonl: 42 questions, release 2026.10.4
```

As execuções são feitas hoje, então toda resposta tem o preço de hoje, seja qual for a versão que a
produziu: a comparação é entre o que cada uma custaria agora, que é a pergunta que uma decisão de versão
faz.
