---
title: Tente, em vez de conferir antes
version: 2
---

Dois jeitos de escrever a mesma coisa:

```python
# look before you leap
if os.path.exists(path):
    text = open(path).read()

# easier to ask forgiveness than permission
try:
    text = open(path).read()
except FileNotFoundError:
    text = ""
```

O segundo é o pythônico, e a razão não é gosto.

## A conferência tem uma corrida dentro

Entre o `exists(path)` e o `open(path)` o arquivo pode ser apagado, renomeado ou trocado. A
conferência respondeu com verdade sobre um momento que já passou, e o `open` falha do mesmo jeito —
então você precisava do `except` de qualquer forma, e a conferência não comprou nada além de uma
segunda pergunta.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 256\" role=\"img\" aria-label=\"Conferir antes faz uma pergunta, e entre a resposta e o uso qualquer coisa fora do programa pode mudar: o arquivo é apagado e o open falha do mesmo jeito. Tentar, em vez disso, testa o estado no instante do uso, que é o único instante que importa.\"> <text x=\"20\" y=\"22\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--amber)\">olhe antes de pular</text> <rect x=\"20\" y=\"34\" width=\"220\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"130\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">exists(path) é True</text> <rect x=\"250\" y=\"34\" width=\"220\" height=\"38\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.2\" stroke=\"var(--amber)\"></rect> <text x=\"360\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">outra coisa apaga o arquivo</text> <rect x=\"480\" y=\"34\" width=\"220\" height=\"38\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.2\" stroke=\"var(--amber)\"></rect> <text x=\"590\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">open(path) levanta erro</text> <path d=\"M240 80 L240 88 L480 88 L480 80\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\"></path> <text x=\"360\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">este vão não é seu para fechar</text> <text x=\"20\" y=\"140\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--phosphor)\">é mais fácil pedir perdão</text> <rect x=\"20\" y=\"152\" width=\"220\" height=\"38\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"130\" y=\"171\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">open(path)</text> <text x=\"256\" y=\"171\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\">funciona, ou levanta — de um jeito ou de outro você sabe agora</text> <text x=\"360\" y=\"214\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">Então o except era necessário de todo jeito, e a conferência comprou uma pergunta a mais.</text> <text x=\"360\" y=\"231\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">Ela também custa uma consulta a cada chamada, e a exceção só custa quando acontece.</text> </svg>", "caption": "A conferência respondeu com sinceridade sobre um momento que já passou. O try é a única coisa que pergunta no instante do uso."}
```

**Qualquer coisa fora do seu programa — um arquivo, uma rede, outro processo — pode mudar entre a
conferência e o uso.** O try é a única coisa que testa o estado no instante em que você o usa.

## Ele também costuma ser mais rápido

A conferência custa uma consulta em toda chamada, e a exceção custa só quando acontece. Para o caso
comum em que quase sempre dá certo, o try vence — e onde quase sempre falha, a diferença raramente
importa.

## Onde conferir É melhor

```python
if not rows:            # asking about your own data
    return 0
```

Quando a coisa sobre a qual você pergunta é sua, está em memória, e não muda embaixo de você, um
`if` é mais claro. Ninguém escreve `try: rows[0] except IndexError` para descobrir se uma lista
está vazia.

A linha é: **pergunte sobre os seus próprios valores; tente os que pertencem ao mundo.**

## O caso a observar

```python
try:
    value = config["port"]
except KeyError:
    value = 5432
```

Correto, e `config.get("port", 5432)` diz isso numa linha. Quando a biblioteca padrão já tem a
versão tolerante — `.get`, `.pop` com padrão, `next(it, None)` — é essa que se usa. Tratar a exceção
é para quando não existe um método desses.
