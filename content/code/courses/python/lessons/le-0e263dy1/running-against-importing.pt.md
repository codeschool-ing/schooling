---
title: `__name__ == "__main__"`, e o script que rodou duas vezes
version: 1
---

```python
def main():
    ...

if __name__ == "__main__":
    main()
```

Todo módulo tem um `__name__`. Quando o Python RODA um arquivo ele põe o `__name__` desse arquivo
em `"__main__"`; quando ele IMPORTA um, ele põe o nome do módulo. Então o bloco roda quando o
arquivo é o programa e não roda quando ele é uma biblioteca.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 262\" role=\"img\" aria-label=\"Rodar um arquivo põe o __name__ dele em __main__, então o bloco protegido roda. Importar o mesmo arquivo põe o __name__ no nome do módulo, então o bloco protegido não roda. Um arquivo é ferramenta e biblioteca por causa dessa string.\"> <defs><marker id=\"ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs> <defs><marker id=\"ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs> <text x=\"360\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper-dim)\">relatorio.py</text> <rect x=\"196\" y=\"26\" width=\"328\" height=\"34\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"360\" y=\"43\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">if __name__ == &quot;__main__&quot;: main()</text> <path d=\"M300 64 L182 84\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <rect x=\"20\" y=\"90\" width=\"324\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"182\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">python relatorio.py</text> <text x=\"182\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">__name__ é &quot;__main__&quot;</text> <rect x=\"20\" y=\"166\" width=\"324\" height=\"36\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"182\" y=\"184\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">o bloco protegido roda</text> <path d=\"M420 64 L558 84\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-paper-dim)\"></path> <rect x=\"396\" y=\"90\" width=\"324\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"558\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">import relatorio</text> <text x=\"558\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">__name__ é &quot;relatorio&quot;</text> <rect x=\"396\" y=\"166\" width=\"324\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"558\" y=\"184\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">o bloco protegido não roda</text> <text x=\"360\" y=\"224\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">Sem ela, o import da aula 16 rodaria o programa inteiro</text> <text x=\"360\" y=\"241\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">toda vez que um arquivo de teste dissesse import relatorio.</text> </svg>", "caption": "A guarda não é cerimônia: é o que deixa um arquivo ser um programa que você roda e um módulo que os seus testes importam."}
```

## Para que isso serve de verdade

Não é cerimônia nem estilo. É o que deixa um arquivo ser ao mesmo tempo **uma ferramenta que você
roda** e **um módulo que você importa**, que é o que o torna testável: os testes da aula 16
importam o seu arquivo, e sem essa guarda a importação rodaria o programa.

```python
$ python relatorio.py       # __name__ é "__main__" — o main() roda
>>> import relatorio        # __name__ é "relatorio" — ele não roda
```

## O script que rodou duas vezes

Sem a guarda, um arquivo que faz o trabalho dele no nível de topo faz esse trabalho toda vez que
alguém o importa. A falha se parece com isto: um script grava um arquivo, um teste importa o
script para conferir uma função, e a suíte de testes grava o arquivo também — **na máquina de
outra pessoa, num diretório que ninguém esperava.**

## Ponha o trabalho numa função

```python
if __name__ == "__main__":
    total = 0
    for linha in carregar():    # funciona, e nada aqui dá para testar
        ...
```

O corpo da guarda deveria ser uma chamada. Tudo dentro dele é inalcançável por um teste e
inalcançável por outro programa, então é o único lugar do seu arquivo em que o código não dá para
reaproveitar — mantenha-o com duas linhas.

## `python -m`

```sh
python -m json.tool dados.json
python -m http.server
```

O `-m` roda um MÓDULO como programa, encontrando-o do jeito que um import encontra. Vários módulos
da biblioteca padrão têm um útil, e um pacote seu ganha um pondo o bloco guardado num
`__main__.py`.
