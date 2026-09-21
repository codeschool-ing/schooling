---
title: A indentação é a sintaxe
version: 1
---

## Comentários

`#` e o resto da linha é ignorado.

```python
# lê o arquivo que a pessoa nomeou, não o que a gente supôs
caminho = sys.argv[1]
```

Um comentário que diz *o que* a linha faz é ruído — a linha já diz isso. Um comentário ganha o lugar
quando diz **por quê**, ou nomeia o que não está visível: o caso de borda, o motivo de esta não ser a
abordagem óbvia, o defeito que ela contorna.

## Uma docstring não é um comentário

A primeira string de um arquivo, de uma função ou de uma classe é a sua **docstring**, e ela faz
parte do objeto em tempo de execução:

```python
def normalizar(nome):
    """Tira espaços e passa para minúsculas, para comparar nomes digitados por pessoas."""
    return nome.strip().lower()
```

`help(normalizar)` imprime essa frase. Um comentário com `#` acima do `def` não — o `help` não o
enxerga. É essa a diferença inteira, e é por isso que a convenção não é arbitrária.

## Indentação não é preferência

Na maioria das linguagens são as chaves que decidem o bloco e a indentação é enfeite que um
formatador conserta. Em Python **a indentação É o bloco**.

```python
if pronto:
    enviar()
    registrar()
terminar()
```

`enviar` e `registrar` estão dentro do `if`. `terminar` não está. Não há outro marcador; mova
`terminar` quatro espaços para a direita e o significado muda.

**Quatro espaços por nível.** Não dois, não uma tabulação — quatro, porque é o que o ecossistema
inteiro faz e o que todo formatador da aula 17 vai produzir.

**Não misture tabulação e espaço.** Um arquivo que parece alinhado e mistura os dois produz
`TabError: inconsistent use of tabs and spaces in indentation`, e a causa não dá para ver lendo.
Todo editor tem um comando *converter indentação para espaços*; use uma vez e configure o editor
para inserir espaços dali em diante.

## O resto do estilo

Existe um documento, a PEP 8, e não adianta aprendê-lo de cor: **a aula 17 é uma ferramenta que o
aplica por você**, e a ferramenta é a resposta. O que vale carregar até lá é:

- `snake_case` para nomes de variáveis e funções
- `MAIUSCULAS` para constantes
- uma linha em branco entre funções, duas entre definições de topo
- e um nome que diga o que a coisa é, porque `dados`, `temp` e `x` são três jeitos de não ter
  decidido
