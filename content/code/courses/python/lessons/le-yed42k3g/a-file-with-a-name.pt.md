---
title: `hello.py`, e a diferença entre rodar e importar
version: 1
---

Ponha isto num arquivo chamado `hello.py`:

```python
name = "Ada"
print("Hello,", name)
```

Depois, num terminal, no diretório em que o arquivo está:

```
python3 hello.py
```

```
Hello, Ada
```

É esse o ciclo em que você vai ficar pelo resto do curso: editar, salvar, rodar, ler.

## O nome do arquivo

`.py` é a extensão, e é o que o seu editor lê para decidir sobre cores e indentação. O resto do nome
é seu, com duas regras que mordem:

**Sem espaços e sem hifens** — `meu-script.py` não pode ser importado na aula 7, porque `-` significa
subtração. Use `meu_script.py`.

**Não dê a ele o nome de algo da biblioteca.** Um arquivo chamado `random.py` no seu diretório vai ser
encontrado antes do `random` de verdade, e o erro que você recebe diz `module 'random' has no
attribute 'randint'` — o que soa como se a biblioteca estivesse quebrada. Não está; é o seu arquivo.
A seção `where-python-looks` da aula 7 é onde isso fica preciso.

## O que rodar faz

`python3 hello.py` lê o arquivo do topo e executa cada linha uma vez. Não existe um `main` que é
chamado; o arquivo em si é o programa.

## E o que importar faz

A aula 7 trata disso direito, mas a distinção começa aqui, porque é o motivo de uma linha que você
vai ver em quase todo arquivo Python que abrir:

```python
if __name__ == "__main__":
    main()
```

Um arquivo pode ser **rodado** ou pode ser **importado por outro arquivo**. Os dois o leem do topo ao
fim. Aquela linha é como um arquivo diz *faça esta parte só quando for eu o que está sendo rodado*,
para que importá-lo só para pegar emprestada uma função não coloque o programa inteiro para andar.

Você não precisa dela hoje. Você precisa não se assustar com ela.

## De onde rodar

O terminal tem um diretório atual e o `python3 hello.py` procura o arquivo ali. Se ele disser
`can't open file`, você está em outro lugar — `ls` no macOS e no Linux, `dir` no Windows, mostra o
que ele está enxergando.
