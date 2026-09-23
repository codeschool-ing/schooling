---
title: `X | None`, e a união que é sintoma
version: 2
---

```python
def find(code: str) -> Rate | None:
    ...
```

**A anotação mais útil da aula.** Ela diz que a função às vezes não acha nada, e um verificador
então aponta toda chamada que usou o resultado sem perguntar.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 272\" role=\"img\" aria-label=\"Um tipo de retorno Rate ou None diz que a função tem duas respostas possíveis. Perguntar se é None separa as duas, e dentro de cada braço o verificador sabe qual delas está na mão. Quem chama sem perguntar é onde o verificador aponta.\"> <defs><marker id=\"ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs> <defs><marker id=\"ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs> <rect x=\"150\" y=\"26\" width=\"420\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"360\" y=\"44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">def find(code: str) -&gt; Rate | None</text> <text x=\"360\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">duas respostas possíveis, e só uma tem uma taxa dentro</text> <path d=\"M360 90 L360 104\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <rect x=\"210\" y=\"110\" width=\"300\" height=\"32\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"360\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">if rate is None:</text> <path d=\"M300 146 L300 166 L180 166 L180 182\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-amber)\"></path> <path d=\"M420 146 L420 166 L540 166 L540 182\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <rect x=\"20\" y=\"186\" width=\"320\" height=\"36\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.2\" stroke=\"var(--amber)\"></rect> <text x=\"180\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">None — tratado aqui, e em nenhum outro lugar</text> <rect x=\"380\" y=\"186\" width=\"320\" height=\"36\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"540\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Rate — e daqui para a frente o verificador sabe disso</text> <text x=\"360\" y=\"240\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">Optional[Rate] é a mesma coisa na grafia antiga, e o nome dela é a armadilha:</text> <text x=\"360\" y=\"257\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">ela nunca quis dizer que este argumento pode ser omitido.</text> </svg>", "caption": "A anotação não impede a função de não devolver nada. Ela impede quem chama de esquecer que isso pode acontecer."}
```

## A grafia antiga

```python
Optional[Rate]        # from typing — the same thing
Union[int, str]       # from typing — now int | str
```

`Optional[X]` quer dizer `X | None` e nunca quis dizer "este argumento pode ser omitido", que é o
que o nome sugere e o que todo mundo supõe uma vez. A forma com `|` é a de escrever agora.

## Estreitar

```python
rate = find(code)
if rate is None:
    return 0.0
return total * rate          # here the checker knows it is a Rate
```

Um verificador segue o `if` e sabe que `rate` não pode ser `None` abaixo dele. É isso que torna a
anotação útil em vez de irritante: você confere uma vez, e o resto da função fica limpo.

Um `if rate is not None:` e um `return` antecipado fazem o mesmo, que é a cláusula de guarda da
aula 4 se pagando de novo.

## Um padrão `None`

```python
def connect(timeout: int | None = None) -> None:
    if timeout is None:
        timeout = 30
```

A anotação é `int | None` e o padrão é `None`. Escrever `timeout: int = None` é um escorregão
comum, e um verificador recusa.

## Quando uma união é sintoma de projeto

```python
def load(source: str | Path | bytes | IO) -> list[dict]: ...
```

Quatro coisas, e o corpo precisa se ramificar sobre qual chegou. **Duas costuma estar bem; quatro
em geral é uma função que deveria ser duas funções**, ou uma que recebe algo estreito e um
chamador que converte.

A exceção honesta é uma fronteira — um analisador, um adaptador, a coisa que encontra o mundo lá
fora. Esse é o único lugar em que aceitar várias formas é o trabalho.
