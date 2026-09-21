---
title: O `yield`, e a função que pausa
version: 1
---

```python
def contagem(n):
    while n > 0:
        yield n
        n -= 1

for i in contagem(3):
    print(i)          # 3, 2, 1
```

Uma função com um `yield` em qualquer lugar dela é uma FUNÇÃO GERADORA. Chamá-la não roda nada do
corpo: ela devolve um objeto gerador. Cada `next` roda o corpo até o próximo `yield`, devolve
aquele valor, e **pausa ali** — com o `n` e todos os outros locais ainda vivos.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 268\" role=\"img\" aria-label=\"Chamar uma função geradora não roda nada do corpo dela. Cada next a roda até o próximo yield, devolve aquele valor e para ali com todos os locais ainda vivos. Quando o laço acaba a geradora levanta StopIteration em vez de devolver um valor.\"> <text x=\"360\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper-dim)\">def contagem(n): while n &gt; 0: yield n; n -= 1</text> <rect x=\"20\" y=\"40\" width=\"150\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"95\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">contagem(3)</text> <text x=\"186\" y=\"55\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">nada do corpo rodou ainda</text> <text x=\"700\" y=\"55\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--phosphor)\">um objeto gerador</text> <rect x=\"20\" y=\"78\" width=\"150\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"95\" y=\"93\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">next(...)</text> <text x=\"186\" y=\"93\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">roda até o yield, e para ali</text> <text x=\"700\" y=\"93\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--phosphor)\">3</text> <rect x=\"20\" y=\"116\" width=\"150\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"95\" y=\"131\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">next(...)</text> <text x=\"186\" y=\"131\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">volta DEPOIS do yield, com n ainda 3</text> <text x=\"700\" y=\"131\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--phosphor)\">2</text> <rect x=\"20\" y=\"154\" width=\"150\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"95\" y=\"169\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">next(...)</text> <text x=\"186\" y=\"169\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">volta de novo, e o n continua vivo</text> <text x=\"700\" y=\"169\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--phosphor)\">1</text> <rect x=\"20\" y=\"192\" width=\"150\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"95\" y=\"207\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">next(...)</text> <text x=\"186\" y=\"207\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">o while acaba, então o corpo termina</text> <text x=\"700\" y=\"207\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--amber)\">StopIteration</text> <text x=\"360\" y=\"236\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">Tudo o que o corpo sabe sobrevive à pausa: o n, e todos os outros locais.</text> <text x=\"360\" y=\"253\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">É essa a diferença inteira para uma função que devolve uma lista.</text> </svg>", "caption": "Uma geradora é uma função que pode ser parada no meio e recomeçada dali, e é por isso que ela consegue produzir um valor por vez para sempre."}
```

## O que ela substitui

```python
class Contagem:                      # a mesma coisa, à mão
    def __init__(self, n): self.n = n
    def __iter__(self): return self
    def __next__(self):
        if self.n <= 0: raise StopIteration
        self.n -= 1
        return self.n + 1
```

Oito linhas contra três, e as oito têm onde pôr um defeito. **Qualquer coisa que você escreveria
como classe guardando uma posição é um gerador em vez disso**, e a última seção desta aula escreve
uma dos dois jeitos de propósito.

## `return` dentro de um gerador

```python
def ate_a_linha_vazia(linhas):
    for linha in linhas:
        if not linha.strip():
            return            # encerra — nenhum valor volta
        yield linha
```

Um `return` pelado encerra o gerador, o que levanta `StopIteration` para quem chama. Um `return
valor` define o atributo `value` da exceção, que quase nada lê — então trate o `return` como
"pare" e dê `yield` em tudo que você pretende entregar.

## Repassar de outro gerador

```python
def os_dois(a, b):
    yield from a
    yield from b
```

O `yield from` entrega a outro iterável até ele se esgotar. É o mesmo que um laço `for` com um
`yield` dentro, e é mais curto e mais rápido.

## O caso a observar

```python
def carregado():
    linhas = caro()           # isto NÃO roda na hora da chamada
    for l in linhas:
        yield l
```

Nada no corpo acontece até o primeiro `next`. Esse é o ponto inteiro, e é uma surpresa quando a
linha cara estava ali para falhar cedo — um gerador que nunca é iterado nunca roda, e nunca
levanta erro.
