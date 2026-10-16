---
title: O notebook que só funciona fora de ordem
version: 1
---

**O notebook quebrado mais comum é um que funcionou todas as vezes que o autor o rodou.** Ele
quebra na primeira vez que outra pessoa o roda de cima, porque o autor nunca fez isso. Eis como um
nasce, em três células e dois minutos, sem ninguém fazer nada descuidado.

Ana quer os dias de 2025 com chuva forte. Ela abre um notebook, `order.ipynb`, e lê o arquivo do
tempo:

```py
import csv
with open("weather.csv") as f:
    days = list(csv.DictReader(f))
```

Depois a pergunta em si:

```py
wet = [d for d in days if float(d["rain_mm"] or 0) > limit]
len(wet)
```

Rodar falha, porque `limit` ainda não existe. Ela decide por dez milímetros, acrescenta uma célula
**embaixo** para dizer isso, roda, e volta para cima para rodar a segunda célula de novo:

```py
limit = 10
```

Agora a segunda célula funciona e mostra `63`, e ela grava. Eis o que o arquivo gravado guarda: o
contador de execução de cada célula, a última linha dela e a saída que gravou, lidos do JSON com
uma linha de Python:

```
(.venv) ana@lab:~/pydata$ python -c 'import json; nb = json.load(open("order.ipynb")); print(*[(c["execution_count"], c["source"][-1], c["outputs"][-1]["data"]["text/plain"] if c["outputs"] else []) for c in nb["cells"]], sep="\n")'
(1, '    days = list(csv.DictReader(f))', [])
(4, 'len(wet)', ['63'])
(3, 'limit = 10', [])
```

Os contadores vão `1`, `4`, `3`. A primeira tentativa da segunda célula, a que falhou, levou o
`2`, e a repetição, a que teve a saída gravada, levou o `4`, depois de a célula que define `limit`
rodar como `3`. Essa célula está em terceiro lugar e rodou antes da de cima.
Na tela dela tudo parece bem: três células, uma resposta embaixo da segunda, nenhum erro
sobrando na página. **A resposta está certa, e o notebook que a produziu não existe em lugar
nenhum a não ser na memória do kernel**, que some no momento em que o kernel para.

## Rodando de cima

O teste honesto de um notebook é iniciar um kernel novo e rodar cada célula na ordem da página. O
Jupyter faz isso pelo terminal, sem navegador, e para no primeiro erro:

```
(.venv) ana@lab:~/pydata$ jupyter nbconvert --to notebook --execute --stdout order.ipynb > /dev/null 2> errors.txt; tail -n 15 errors.txt
nbclient.exceptions.CellExecutionError: An error occurred while executing the following cell:
------------------
wet = [d for d in days if float(d["rain_mm"] or 0) > limit]
len(wet)
------------------


---------------------------------------------------------------------------
NameError                                 Traceback (most recent call last)
Cell In[2], line 1
----> 1 wet = [d for d in days if float(d["rain_mm"] or 0) > limit]
      2 len(wet)

NameError: name 'limit' is not defined

```

`NameError: name 'limit' is not defined`, na segunda célula, porque na ordem da página a definição
vem depois do uso. A correção é sem graça: mover `limit = 10` para cima da célula que o usa, ou
melhor, para a primeira célula junto com as outras configurações. O hábito que teria pegado isso é
o assunto da seção depois da próxima.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"Ordem da página à esquerda: a célula do csv, a dos dias chuvosos, a do limite. Ordem de execução à direita: 1 a do csv, 2 a dos dias chuvosos falhando com NameError, 3 a do limite, 4 a dos dias chuvosos de novo dando 63. Rodada de cima, a célula dos dias chuvosos vem antes do limite e falha.\" data-fig=\"order\"><defs><marker id=\"order-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"140\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">ordem da página</text><text x=\"560\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">ordem de execução</text><rect x=\"40\" y=\"40\" width=\"200\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"140.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">days = …</text><text x=\"252\" y=\"63\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">[1]</text><rect x=\"40\" y=\"110\" width=\"200\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"140.0\" y=\"133.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">wet = … &gt; limit</text><text x=\"252\" y=\"133\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">[4]</text><rect x=\"40\" y=\"180\" width=\"200\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"140.0\" y=\"203.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">limit = 10</text><text x=\"252\" y=\"203\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">[3]</text><rect x=\"460\" y=\"40\" width=\"170\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"545.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">days = …</text><text x=\"450\" y=\"62\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1</text><rect x=\"460\" y=\"98\" width=\"170\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"545.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">wet = …</text><text x=\"450\" y=\"120\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2</text><text x=\"640\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">NameError</text><rect x=\"460\" y=\"156\" width=\"170\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"545.0\" y=\"178.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">limit = 10</text><text x=\"450\" y=\"178\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">3</text><rect x=\"460\" y=\"214\" width=\"170\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"545.0\" y=\"236.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">wet = …</text><text x=\"450\" y=\"236\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">4</text><text x=\"640\" y=\"236\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">63</text><line x1=\"282\" y1=\"63\" x2=\"436\" y2=\"62\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#order-ah)\"></line><line x1=\"282\" y1=\"133\" x2=\"436\" y2=\"120\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#order-ah)\"></line><line x1=\"282\" y1=\"203\" x2=\"436\" y2=\"178\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#order-ah)\"></line><line x1=\"282\" y1=\"133\" x2=\"436\" y2=\"236\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#order-ah)\"></line><text x=\"360\" y=\"278\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">reiniciar e rodar tudo: ordem da página, e a segunda célula falha</text></svg>", "caption": "A página está numa ordem e o histórico em outra. Reiniciar e rodar tudo repete a página."}
```

## Por que é tão fácil fazer isso

Nenhum passo deu errado sozinho. Cada célula, rodada quando foi rodada, estava certa. O que deu
errado é que **o notebook convidou a editar num lugar e rodar em outro**, e a página só registra a
edição. Um script não entra nesse estado: ele não tem outra ordem senão a sua. Um notebook entra
nele toda vez que você sobe para consertar algo e roda, o que acontece várias vezes por hora
enquanto você explora. Isso não é motivo para parar de explorar num notebook. É o motivo de as
próximas seções existirem.
