---
title: Quatro lugares, numa ordem fixa
version: 1
---

Um nome é resolvido olhando em quatro lugares, sempre nesta ordem:

**L**ocal → **E**nvolvente → **G**lobal → em**B**utido.

```python
total = 0                 # global (nível do módulo)

def externa():
    conta = 1             # envolvente, do ponto de vista da interna
    def interna():
        n = 2             # local
        print(n, conta, total, len)     # um de cada
    interna()
```

O primeiro lugar que tem o nome vence, e o Python nunca pergunta qual deles você queria.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 244\" role=\"img\" aria-label=\"Quatro caixas aninhadas. A mais interna é a função em execução e guarda n; em volta dela a função envolvente guarda conta; em volta dessa o módulo guarda total; e fora de tudo estão os nomes embutidos. Um nome é procurado de dentro para fora e a primeira caixa que o tem vence.\"> <defs><marker id=\"ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs> <rect x=\"20\" y=\"26\" width=\"680\" height=\"164\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\"></rect> <text x=\"34\" y=\"43\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">embutido — len, print, sum</text> <rect x=\"44\" y=\"54\" width=\"632\" height=\"122\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\"></rect> <text x=\"58\" y=\"71\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">global — o módulo, onde vive total</text> <rect x=\"68\" y=\"82\" width=\"584\" height=\"80\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor)\"></rect> <text x=\"82\" y=\"99\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">envolvente — externa(), onde vive conta</text> <rect x=\"92\" y=\"110\" width=\"536\" height=\"38\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor)\"></rect> <text x=\"106\" y=\"127\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">local — interna(), onde vive n</text> <path d=\"M334 200 L334 148\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <text x=\"348\" y=\"196\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">um nome é procurado neste sentido</text> <text x=\"360\" y=\"214\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">E uma atribuição EM QUALQUER PONTO de uma função torna aquele nome local na função inteira,</text> <text x=\"360\" y=\"231\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">decidido lendo o corpo antes de uma linha dele rodar.</text> </svg>", "caption": "Quatro caixas, sempre olhadas de dentro para fora. A primeira que tem o nome vence, e nada pergunta qual delas você queria."}
```

## Atribuir é o que torna um nome local

```python
total = 0

def somar():
    total = total + 1     # UnboundLocalError
```

O erro acontece na leitura, e a leitura parece correta. **O Python decide que `total` é local
varrendo o corpo da função atrás de uma atribuição — antes de rodar uma linha dele.** Existe uma,
então `total` é local em todo o corpo, inclusive à direita da linha que o atribui. O `total` do
módulo não é consultado.

Ler uma global sem atribuir a ela funciona bem, e é isso que confunde: a função estava correta até
uma linha ser acrescentada lá embaixo.

## Sombrear um embutido

```python
list = [1, 2, 3]      # agora `list(...)` está quebrado neste escopo
```

Sem erro, e nada avisa. `list`, `dict`, `id`, `type`, `sum`, `input` e `str` são os que as pessoas
tomam por acidente. Acrescente um sublinhado — `list_` — ou escolha um nome melhor, que costuma ser
o que a colisão estava dizendo.

## A variável do laço não é um escopo

```python
for linha in linhas:
    ...
print(linha)        # ainda aqui
```

O último engano da aula 4, visto daqui: um `for`, um `if` e um `while` não fazem escopo em Python.
Só uma função faz — e um módulo, e uma classe.
