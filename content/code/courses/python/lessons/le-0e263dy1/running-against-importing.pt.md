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

## Para que isso serve de verdade

Não é cerimônia nem estilo. É o que deixa um arquivo ser ao mesmo tempo **uma ferramenta que você
roda** e **um módulo que você importa**, que é o que o torna testável: os testes da aula 15
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
