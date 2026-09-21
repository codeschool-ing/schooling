---
title: Duas palavras-chave, e o que precisar de uma costuma dizer
version: 1
---

```python
contagem = 0

def somar():
    global contagem
    contagem += 1
```

`global` diz que o nome é do módulo. Sem ela a atribuição tornaria `contagem` local e o valor do
módulo nunca se moveria.

```python
def contador():
    n = 0
    def passo():
        nonlocal n        # o n da função de fora, não o do módulo
        n += 1
        return n
    return passo
```

`nonlocal` diz que o nome é da função ENVOLVENTE mais próxima. Ela não alcança o nível do módulo, e
se não existir tal nome o arquivo não compila — um `SyntaxError`, levantado quando o módulo é lido e
antes de uma única linha dele rodar. Essa é a falha boa: um erro de digitação no nome é pego sem
ninguém chamar nada.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"Três cópias dos mesmos três escopos aninhados. Sem declaração a escrita cai na função mais interna e o nome do módulo nunca se move. Com global ela cai no módulo. Com nonlocal ela cai na função imediatamente em volta.\"> <text x=\"125\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--amber)\">conta += 1</text> <rect x=\"20\" y=\"36\" width=\"210\" height=\"150\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\"></rect> <text x=\"32\" y=\"52\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">módulo</text> <rect x=\"34\" y=\"76\" width=\"182\" height=\"98\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\"></rect> <text x=\"46\" y=\"92\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">externa()</text> <rect x=\"48\" y=\"112\" width=\"154\" height=\"50\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\"></rect> <text x=\"60\" y=\"128\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">interna()</text> <circle cx=\"140\" cy=\"128\" r=\"7\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></circle> <text x=\"154\" y=\"128\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">conta</text> <text x=\"125\" y=\"204\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">um nome próprio, e o módulo nunca se move</text> <text x=\"360\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--phosphor)\">global conta</text> <rect x=\"255\" y=\"36\" width=\"210\" height=\"150\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\"></rect> <text x=\"267\" y=\"52\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">módulo</text> <rect x=\"269\" y=\"76\" width=\"182\" height=\"98\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\"></rect> <text x=\"281\" y=\"92\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">externa()</text> <rect x=\"283\" y=\"112\" width=\"154\" height=\"50\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\"></rect> <text x=\"295\" y=\"128\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">interna()</text> <circle cx=\"375\" cy=\"52\" r=\"7\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></circle> <text x=\"389\" y=\"52\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">conta</text> <text x=\"360\" y=\"204\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o nome do módulo, onde quer que se escreva</text> <text x=\"595\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--phosphor)\">nonlocal conta</text> <rect x=\"490\" y=\"36\" width=\"210\" height=\"150\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\"></rect> <text x=\"502\" y=\"52\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">módulo</text> <rect x=\"504\" y=\"76\" width=\"182\" height=\"98\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\"></rect> <text x=\"516\" y=\"92\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">externa()</text> <rect x=\"518\" y=\"112\" width=\"154\" height=\"50\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\"></rect> <text x=\"530\" y=\"128\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">interna()</text> <circle cx=\"620\" cy=\"92\" r=\"7\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></circle> <text x=\"634\" y=\"92\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">conta</text> <text x=\"595\" y=\"204\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o nome da função imediatamente em volta</text> </svg>", "caption": "A declaração não muda o que é lido. Ela muda em qual caixa a escrita cai."}
```

## Por que elas são raras

Uma função que muda um nome de nível de módulo tem um efeito que a assinatura dela não menciona.
Duas coisas decorrem disso, e as duas são comuns em vez de teóricas:

- **o resultado dela depende do que rodou antes**, então um teste precisa montar o mundo e desmontar
- **duas delas são difíceis de ler juntas**, porque a ligação entre as duas é um nome num terceiro
  lugar

A alternativa de sempre é receber o valor e devolvê-lo:

```python
def somar(contagem):
    return contagem + 1
```

Agora quem chama decide o que acontece com o resultado, e nada na função depende do histórico.

## Onde `global` está bem

Uma constante de módulo, escrita uma vez na importação e nunca mais atribuída, não precisa de
palavra-chave nenhuma — ler é de graça. Um cache de processo único ou um registro preenchido na
partida é o caso em que o `global` ganha a linha dele, e **ele merece um comentário dizendo por
quê**, porque quem ler depois vai supor que foi acidente.

O `nonlocal` tem uma casa que vale conhecer: um fechamento que guarda estado entre chamadas, que é a
forma com que a aula 12 constrói decoradores.
