---
title: O que o fine-tuning esquece
version: 1
---

O fine-tuning muda pesos que já faziam um trabalho. **Se o trabalho antigo ainda importa, a pergunta
é o que sobra dele depois**, e os casos em que importa são comuns: um modelo que ganha classes novas
e precisa manter as antigas, um modelo em produção estendido para uma segunda tarefa, um modelo de
linguagem ensinado numa habilidade estreita que ainda deveria responder a todo o resto.

O `base.pt` torna a pergunta fácil de fazer. A cabeça dele, `Linear(64, 5)` para os dígitos de 0 a
4, pode ser guardada antes de a cabeça nova tomar o lugar dela e posta de volta sobre o corpo
ajustado a qualquer momento. Se o corpo ainda calcula o que essa cabeça espera, os dígitos antigos
continuam reconhecidos. O programa faz fine-tuning em 5 a 9 com 10 imagens por classe, de cinco
jeitos, e mede a tarefa antiga pelo caminho. Salve como `~/dl/forget.py`:

```schooling-example
{
  "language": "python",
  "file": "forget.py",
  "parts": [
    {
      "code": "\"\"\"forget: what fine-tuning on 5 to 9 does to the digits 0 to 4 that base.pt knew.\"\"\"\nimport torch\nimport torch.nn as nn\n\nimport cnn\nimport loop\nimport tdigits\n\n(x, y), (xv, yv), _ = tdigits.load(images=True)\nnew_val = xv[yv >= 5], yv[yv >= 5] - 5\nold_val = xv[yv < 5], yv[yv < 5]\nidx = torch.cat([torch.nonzero(y == d).flatten()[:10] for d in range(5, 10)])\ntrain = x[idx], y[idx] - 5",
      "note": "Dois conjuntos de validação desta vez: os dígitos novos, e as 180 imagens de 0 a 4 em que o `base.pt` marcou 0,989 na aula 13."
    },
    {
      "code": "def old_task(model, old_head):\n    \"\"\"The body as it is now, with base.pt's own head put back: accuracy on 0 to 4.\"\"\"\n    return loop.evaluate(nn.Sequential(*model[:8], old_head), *old_val)[1]",
      "note": "O corpo ajustado com a cabeça original do `base.pt` por cima, montado como um `Sequential` novo que compartilha as camadas do corpo. Se o corpo ainda calcula o que a cabeça antiga espera, a tarefa antiga ainda funciona."
    },
    {
      "code": "SETUPS = {                 # layers that learn, body rate, head rate\n    \"head only\":            ([8], None, 1e-3),\n    \"last block\":           ([6, 8], 1e-3, 1e-3),\n    \"everything\":           ([0, 2, 6, 8], 1e-3, 1e-3),\n    \"everything at 1e-2\":   ([0, 2, 6, 8], 1e-2, 1e-2),\n    \"body 1e-4, head 1e-3\": ([0, 2, 6, 8], 1e-4, 1e-3),\n}\nCHECK = (1, 2, 5, 10, 20, 50, 100)\nprint(\"accuracy on 0 to 4 with base.pt's head put back, after epoch\")\nprint(\" \" * 23 + \"  \".join(f\"{e:5d}\" for e in (0,) + CHECK) + \"   new task\")",
      "note": "Cinco jeitos de ajustar, tirados das duas seções anteriores: as três profundidades a 1e-3, tudo na taxa que andou mais longe, e tudo com o corpo lento."
    },
    {
      "code": "for name, (learns, body_lr, head_lr) in SETUPS.items():\n    torch.manual_seed(0)\n    model = cnn.make_cnn(5)\n    model.load_state_dict(torch.load(\"base.pt\"))\n    old_head, model[8] = model[8], nn.Linear(64, 5)\n    for i, layer in enumerate(model):\n        for p in layer.parameters():\n            p.requires_grad = i in learns\n    groups = [{\"params\": model[8].parameters(), \"lr\": head_lr}]\n    if body_lr:\n        groups.append({\"params\": [p for p in model[:8].parameters() if p.requires_grad], \"lr\": body_lr})\n    opt = torch.optim.Adam(groups)\n    row = [old_task(model, old_head)]\n    for epoch in range(1, 101):\n        history = loop.fit(model, opt, train, new_val, epochs=1, seed=epoch, every=1000)\n        if epoch in CHECK:\n            row.append(old_task(model, old_head))\n    print(f\"{name:21s}  \" + \"  \".join(f\"{a:.3f}\" for a in row) + f\"   {history[-1][3]:.3f}\")",
      "note": "Uma semente por configuração, e a cabeça antiga é guardada antes de a nova tomar o lugar dela. O treino roda uma época por chamada ao `loop.fit`, com `seed=epoch` para cada época ser embaralhada de um jeito, e a tarefa antiga é medida nas épocas de `CHECK`. A última coluna é a tarefa nova no fim."
    }
  ]
}
```

```
PENDING forget
```

A última coluna é a tarefa nova no fim de cada execução. Ela difere um pouco da linha
correspondente do `depths.py` ou do `rates.py`, porque uma chamada longa ao `loop.fit` e cem chamadas
curtas com `seed=epoch` embaralham os lotes de jeitos diferentes.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 660 300\" role=\"img\" aria-label=\"Um gráfico de linhas da acurácia nos dígitos de 0 a 4 contra a época de ajuste em 5 a 9, nas épocas 0, 1, 2, 5, 10, 20, 50 e 100. Só a cabeça e corpo 1e-4, cabeça 1e-3 ficam em 0.989 o tempo todo. Último bloco e tudo a 1e-3 descem até 0.944 e 0.939. Tudo a 1e-2 cai de 0.989 para 0.294, com o mínimo de 0.250 na época 20.\"><text x=\"48\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">acurácia em 0 a 4, cabeça antiga de volta</text><path d=\"M56 240 L456 240\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"48\" y=\"240\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0.0</text><path d=\"M56 140.0 L456 140.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"2 4\"></path><text x=\"48\" y=\"140.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0.5</text><path d=\"M56 40.0 L456 40.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"2 4\"></path><text x=\"48\" y=\"40.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">1.0</text><text x=\"56.0\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0</text><text x=\"113.14285714285714\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">1</text><text x=\"170.28571428571428\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">2</text><text x=\"227.42857142857142\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">5</text><text x=\"284.57142857142856\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">10</text><text x=\"341.7142857142857\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">20</text><text x=\"398.85714285714283\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">50</text><text x=\"456.0\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">100</text><text x=\"256.0\" y=\"278\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">época</text><path d=\"M56.0 42.2 L113.1 41.2 L170.3 42.2 L227.4 45.6 L284.6 42.2 L341.7 45.6 L398.9 50.0 L456.0 51.2\" stroke=\"var(--paper-dim)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M56.0 42.2 L113.1 41.2 L170.3 44.4 L227.4 50.0 L284.6 44.4 L341.7 48.8 L398.9 52.2 L456.0 52.2\" stroke=\"var(--paper)\" stroke-width=\"2\" fill=\"none\" stroke-dasharray=\"6 4\"></path><path d=\"M56.0 42.2 L113.1 42.2 L170.3 42.2 L227.4 42.2 L284.6 42.2 L341.7 42.2 L398.9 42.2 L456.0 42.2\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M56.0 42.2 L113.1 42.2 L170.3 42.2 L227.4 42.2 L284.6 42.2 L341.7 41.2 L398.9 42.2 L456.0 42.2\" stroke=\"var(--phosphor-dim)\" stroke-width=\"2\" fill=\"none\" stroke-dasharray=\"6 4\"></path><path d=\"M56.0 42.2 L113.1 72.2 L170.3 68.8 L227.4 156.6 L284.6 74.4 L341.7 190.0 L398.9 177.8 L456.0 181.2\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M474 40 L498 40\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"506\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">só a cabeça</text><path d=\"M474 58 L498 58\" stroke=\"var(--phosphor-dim)\" stroke-width=\"2\" fill=\"none\" stroke-dasharray=\"6 4\"></path><text x=\"506\" y=\"58\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">corpo 1e-4, cabeça 1e-3</text><path d=\"M474 76 L498 76\" stroke=\"var(--paper-dim)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"506\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">último bloco</text><path d=\"M474 94 L498 94\" stroke=\"var(--paper)\" stroke-width=\"2\" fill=\"none\" stroke-dasharray=\"6 4\"></path><text x=\"506\" y=\"94\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">tudo</text><path d=\"M474 181.2 L498 181.2\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"506\" y=\"181.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">tudo a 1e-2</text></svg>", "caption": "Quanto de 0 a 4 sobrevive ao ajuste em 5 a 9, da execução do forget.py."}
```

## Três desfechos

**Onde o corpo quase não se moveu, nada foi esquecido.** Só a cabeça deixa o corpo exatamente como
o `base.pt` o tinha, então 0 a 4 ficam em 0,989 o tempo todo: nada do que os calcula foi tocado. O
corpo lento, a 1e-4, termina em 0,989 também, depois de andar 0,04 do próprio tamanho no
`rates.py`. O preço fica na tarefa nova, 0,667 e 0,822, os dois números mais baixos da última
coluna.

**A 1e-3 a tarefa antiga se desgasta devagar.** O último bloco e tudo terminam por volta de 0,94,
cinco pontos abaixo de 0,989, enquanto chegam a 0,900 e 0,917 nos dígitos novos. O corpo derivou na
direção de 5 a 9, e a cabeça antiga o lê um pouco pior a cada época.

**A 1e-2 a tarefa antiga desaba.** Tudo na taxa alta já estava em 0,839 depois de uma única época e
termina em 0,294, enquanto marca 0,922 na tarefa nova, o melhor da coluna. Isso é o **esquecimento
catastrófico**: os pesos que reconheciam 0 a 4 foram reescritos para reconhecer 5 a 9, e nada no
treino pediu que eles mantivessem o primeiro trabalho. A curva também salta, 0,417 na época 5 e
0,828 na época 10, porque a tarefa antiga não é o alvo dos passos; onde ela cai em cada época é um
efeito colateral.

## O que fazer a respeito

A figura é a troca inteira: **as configurações que mantiveram a tarefa antiga são as que aprenderam
pior a nova**, porque as duas coisas dependem de quanto o corpo se move. As saídas mudam isso, cada
uma de um jeito:

- **Congelar mais, ou baixar a taxa do corpo.** Barato e confiável, e abre mão do que mover teria
  comprado na tarefa nova, como as duas linhas retas fizeram aqui.
- **Ensaiar.** Misturar parte dos dados de treino antigos no treino novo, com uma cabeça que
  responde aos dez dígitos, para que a própria loss peça as duas tarefas. Precisa dos dados antigos,
  que muitas vezes são justamente o que você não tem.
- **Manter os pesos originais intocados e aprender uma correção à parte.** A próxima seção constrói
  uma, e tirá-la devolve o modelo antigo exatamente.
