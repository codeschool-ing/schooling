---
title: A primeira instrução do corpo
version: 1
---

```python
def separar_linhas(texto, separador=","):
    """Separa o texto em linhas de campos.

    Linhas em branco são puladas. O separador não é escapado — veja a aula 9
    para qualquer coisa que tenha saído de uma planilha.
    """
```

Uma literal de string como primeira instrução de uma função é a docstring dela. Não é um comentário:
ela fica na função como `__doc__`, `help(separar_linhas)` a imprime, e o seu editor a mostra onde a
função é chamada.

## As três linhas que valem escrever

1. **Uma linha, no imperativo, dizendo o que ela faz.** "Separa o texto em linhas de campos" — e não
   "Esta função vai separar…", que gasta quatro palavras dizendo que é uma função.
2. **O que não é óbvio**: o que acontece no caso vazio, que erros ela levanta, qual argumento é uma
   unidade em vez de uma contagem.
3. **Nada além disso.** Uma docstring que repete os nomes dos parâmetros é uma segunda cópia da
   assinatura que envelhece na primeira renomeação.

## Quando pular

Um ajudante privado de três linhas com um nome que diz o que ele faz não precisa de docstring, e
acrescentar uma é ruído que alguém vai ter de manter. **Uma função que precisa de docstring para ser
entendida provavelmente precisa de um nome melhor.**

## `"""` mesmo para uma linha

As aspas triplas são a convenção seja qual for o tamanho, para que acrescentar uma segunda linha
depois não seja uma mudança na primeira.

## O que lê isso

O `help()` no interpretador. O seu editor, ao passar o mouse e na chamada. O `pydoc`. E na aula 16,
o `doctest` — que pega os exemplos escritos dentro de uma docstring e os RODA, então uma docstring
que se descolou do código reprova a suíte em vez de enganar quem lê.
