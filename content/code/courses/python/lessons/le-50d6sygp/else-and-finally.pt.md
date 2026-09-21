---
title: Duas cláusulas, e um trabalho cada
version: 1
---

```python
try:
    f = open(caminho)
except FileNotFoundError:
    print(f"não existe este arquivo: {caminho}")
else:
    processar(f)        # só se o open deu certo
finally:
    print("pronto")     # de um jeito ou de outro
```

## O `else`

O `else` roda quando o `try` NÃO levantou erro. O trabalho dele é manter fora do `try` código que
nunca foi para ser protegido:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 244\" role=\"img\" aria-label=\"Uma tabela das quatro cláusulas contra três desfechos. O corpo do try sempre começa; o except roda só para a classe que ele nomeia; o else roda só quando nada foi levantado; e o finally roda nos três, inclusive na saída daquele que ninguém pegou.\"> <text x=\"259\" y=\"22\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\">nada é levantado</text> <text x=\"435\" y=\"22\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\">um ValueError</text> <text x=\"611\" y=\"22\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\">um KeyError</text> <rect x=\"21\" y=\"32\" width=\"678\" height=\"30\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"31\" y=\"47\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">try:</text> <text x=\"259\" y=\"47\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">roda até o fim</text> <text x=\"435\" y=\"47\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">roda até aquela linha</text> <text x=\"611\" y=\"47\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">roda até aquela linha</text> <rect x=\"21\" y=\"68\" width=\"678\" height=\"30\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"31\" y=\"83\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">except ValueError:</text> <text x=\"259\" y=\"83\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">pulado</text> <text x=\"435\" y=\"83\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">roda</text> <text x=\"611\" y=\"83\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">pulado</text> <rect x=\"21\" y=\"104\" width=\"678\" height=\"30\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"31\" y=\"119\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">else:</text> <text x=\"259\" y=\"119\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">roda</text> <text x=\"435\" y=\"119\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">pulado</text> <text x=\"611\" y=\"119\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">pulado</text> <rect x=\"21\" y=\"140\" width=\"678\" height=\"30\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"31\" y=\"155\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">finally:</text> <text x=\"259\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">roda</text> <text x=\"435\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">roda</text> <text x=\"611\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">roda</text> <text x=\"360\" y=\"190\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">Na última coluna o KeyError segue subindo depois de o finally ter rodado.</text> <text x=\"360\" y=\"207\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">É para esse caso que o finally foi escrito, e o único em que ele é necessário.</text> </svg>", "caption": "O finally é a única linha sem buraco — e é essa a razão inteira de ele existir."}
```

```python
try:
    valor = int(bruto)
except ValueError:
    ...
else:
    salvar(valor)       # um KeyError dentro do salvar NÃO é capturado acima
```

Escrito dentro do `try`, o `salvar(valor)` fica na rede — e no dia em que ele levantar a mesma
classe, o tratamento responde pela falha errada. **O `else` é como o `try` fica com uma linha.**

## O `finally`

O `finally` roda em todo caminho de saída do bloco: sucesso, exceção tratada, exceção não tratada,
e até um `return`. Ele é para a limpeza que precisa acontecer de qualquer jeito — fechar um
arquivo, soltar uma trava, apagar um temporário.

```python
f = open(caminho)
try:
    processar(f)
finally:
    f.close()           # acontece mesmo se o processar levantar erro
```

**Um `try`/`finally` sem `except` é uma coisa perfeitamente comum de escrever.** Ele diz: eu não
estou tratando isto, e ainda assim estou arrumando.

## E o `with` escreve isso por você

```python
with open(caminho) as f:
    processar(f)
```

Essa é a mesma garantia numa linha — o assunto da aula 9. Qualquer coisa com um `close`, uma trava,
uma conexão ou uma transação tem uma forma `with`, e ela existe precisamente porque todo mundo
esquecia o `finally`.

## A única armadilha

```python
try:
    return calcular()
finally:
    return reserva()         # este return VENCE
```

Um `return` no `finally` substitui o que estava a caminho da saída, exceção inclusive. É válido, é
confuso, e a regra é simples: **nunca dê `return` de dentro de um `finally`.**
