---
title: Reaproveitar uma classe, e o que o `super()` faz de fato
version: 1
---

```python
class Pessoa:
    def __init__(self, nome):
        self.nome = nome

    def saudar(self):
        return f"olá, {self.nome}"

class Aluno(Pessoa):
    def __init__(self, nome, curso):
        super().__init__(nome)      # roda o __init__ de Pessoa também
        self.curso = curso

    def saudar(self):
        return super().saudar() + f", estudando {self.curso}"
```

`class Aluno(Pessoa)` diz que um `Aluno` é uma `Pessoa`. Ele ganha todo método que `Pessoa` tem, e
sobrescrever um é simplesmente defini-lo de novo.

## O `super()`

`super().saudar()` chama a versão acima desta na cadeia. Sem ele, uma sobrescrita SUBSTITUI o
método do pai inteiro — o que às vezes é o que você quer e quase nunca é o que você quer no
`__init__`, porque aí os atributos do pai nunca são definidos.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 262\" role=\"img\" aria-label=\"Uma chamada à saudação do aluno roda o método da subclasse, que chama super e roda antes o método da classe de cima. A de cima devolve olá Ada, a subclasse acrescenta estudando python, e a string inteira volta para quem chamou.\"> <defs><marker id=\"ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs> <defs><marker id=\"ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs> <rect x=\"20\" y=\"34\" width=\"200\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"120\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">ada.saudar()</text> <rect x=\"294\" y=\"34\" width=\"226\" height=\"40\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"407\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">Aluno.saudar</text> <rect x=\"294\" y=\"140\" width=\"226\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"407\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">Pessoa.saudar</text> <path d=\"M226 46 L288 46\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <path d=\"M288 64 L226 64\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-paper-dim)\"></path> <path d=\"M340 80 L340 134\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <text x=\"328\" y=\"94\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">o super().saudar() roda a de cima</text> <path d=\"M474 134 L474 80\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-paper-dim)\"></path> <text x=\"486\" y=\"122\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper-dim)\">&quot;olá, Ada&quot;</text> <text x=\"120\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">e devolve a resposta dela</text> <text x=\"120\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">&quot;olá, Ada, estudando python&quot;</text> <text x=\"360\" y=\"204\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">Deixe o super() de fora do __init__ e os atributos da classe de cima nunca são postos,</text> <text x=\"360\" y=\"221\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">então o objeto está incompleto antes de a sua primeira linha rodar.</text> </svg>", "caption": "Uma sobrescrita substitui a de cima, a não ser que a chame. O super() é o que mantém a corrente sendo uma corrente."}
```

**Chame `super().__init__(...)` primeiro, antes dos seus próprios atributos.** Aí o objeto está
completo quando qualquer outra coisa o toca.

## A ordem de resolução de métodos

```python
Aluno.__mro__     # (Aluno, Pessoa, object)
```

Uma busca percorre essa lista e pega a primeira classe que tem o nome. Tudo herda de `object`, que
é de onde vêm `__str__` e `__eq__` antes de você escrever os seus.

Com um pai isso é uma linha. Com vários é onde mora a complexidade da herança, e este curso não vai
até lá: **se a resposta precisa de um diagrama de MRO, a pergunta era composição.**

## `isinstance`, e quando perguntar

```python
isinstance(x, Pessoa)      # True para um Aluno também
type(x) is Pessoa          # False para um Aluno
```

O `isinstance` respeita a hierarquia e o `type(...) is` não. Use o `isinstance` quando precisar
perguntar — e uma cadeia de testes `isinstance` decidindo comportamento costuma ser um método que
deveria ter sido sobrescrito.

## Quando a herança está certa

Quando a subclasse É o pai em todo lugar em que o pai é usado, e só muda COMO algo é feito. Um
`Aluno` é uma `Pessoa` — todo método que recebe uma `Pessoa` funciona com um.

**Quando a subclasse precisa recusar um método do pai** — "um quadrado é um retângulo, mas mudar a
largura dele tem de mudar a altura" — a relação não era o que parecia. A seção depois da próxima é
a alternativa.
